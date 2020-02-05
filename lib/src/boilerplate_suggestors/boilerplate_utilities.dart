// Copyright 2020 Workiva Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:meta/meta.dart';
import 'package:over_react_codemod/src/constants.dart';
import 'package:over_react_codemod/src/util.dart';

typedef void YieldPatch(
    int startingOffset, int endingOffset, String replacement);

@visibleForTesting
bool isPublicForTest = false;

// Stub while <https://jira.atl.workiva.net/browse/CPLAT-9308> is in progress
bool isPublic(ClassDeclaration node) => isPublicForTest;

/// A simple evaluation of the annotation(s) of the [classNode]
/// to verify it is either a `@PropsMixin()` or `@StateMixin`.
bool isAPropsOrStateMixin(ClassDeclaration classNode) =>
    isAPropsMixin(classNode) || isAStateMixin(classNode);

/// Returns the node of a `@PropsMixin()` annotation for the provided [classNode], if one exists.
AstNode getPropsMixinAnnotationNode(ClassDeclaration classNode) =>
    classNode.sortedCommentAndAnnotations.singleWhere(
        (node) => node?.toSource()?.startsWith('@PropsMixin') == true,
        orElse: () => null);

/// A simple evaluation of the annotation(s) of the [classNode]
/// to verify it is a `@PropsMixin()`.
bool isAPropsMixin(ClassDeclaration classNode) =>
    getPropsMixinAnnotationNode(classNode) != null;

/// Returns the node of a `@PropsMixin()` annotation for the provided [classNode], if one exists.
AstNode getStateMixinAnnotationNode(ClassDeclaration classNode) =>
    classNode.sortedCommentAndAnnotations.singleWhere(
        (node) => node?.toSource()?.startsWith('@StateMixin') == true,
        orElse: () => null);

/// A simple evaluation of the annotation(s) of the [classNode]
/// to verify it is a `@StateMixin()`.
bool isAStateMixin(ClassDeclaration classNode) =>
    getStateMixinAnnotationNode(classNode) != null;

/// Whether a props or state mixin class [classNode] should be migrated as part of the boilerplate codemod.
bool shouldMigratePropsAndStateMixin(ClassDeclaration classNode) =>
    isAPropsOrStateMixin(classNode);

/// Whether a props or state class class [node] should be migrated as part of the boilerplate codemod.
bool shouldMigratePropsAndStateClass(ClassDeclaration node) {
  return isAssociatedWithComponent2(node) &&
      isAPropsOrStateClass(node) &&
      // Stub while <https://jira.atl.workiva.net/browse/CPLAT-9308> is in progress
      !isPublic(node);
}

/// A simple RegExp against the parent of the class to verify it is `UiProps`
/// or `UiState`.
bool extendsFromUiPropsOrUiState(ClassDeclaration classNode) =>
    classNode.extendsClause.superclass.name
        .toSource()
        .contains(RegExp('(UiProps)|(UiState)'));

/// A simple RegExp against the parent of the class to verify it is `UiProps`
/// or `UiState`.
bool implementsUiPropsOrUiState(ClassDeclaration classNode) {
  return classNode.implementsClause.interfaces
      .map((typeName) => typeName.toSource())
      .any((typeStr) => typeStr.contains(RegExp('(UiProps)|(UiState)')));
}

/// A simple RegExp against the name of the class to verify it contains `props`
/// or `state`.
bool isAPropsOrStateClass(ClassDeclaration classNode) => classNode.name
    .toSource()
    .contains(RegExp('([A-Za-z]+Props)|([A-Za-z]+State)'));

/// Detects if the Props or State class is considered simple.
///
/// Simple means:
/// - Has no mixins
/// - Extends from UiProps
bool isSimplePropsOrStateClass(ClassDeclaration classNode) {
  // Only validate props or state classes
  assert(isAPropsOrStateClass(classNode));

  final superClass = classNode.extendsClause.superclass.name.toSource();

  if (superClass != 'UiProps' && superClass != 'UiState') return false;
  if (classNode.withClause != null) return false;

  return true;
}

// Stub while <https://jira.atl.workiva.net/browse/CPLAT-9407> is in progress
bool isAdvancedPropsOrStateClass(ClassDeclaration classNode) {
  // Only validate props or state classes
  assert(isAPropsOrStateClass(classNode));

  return false;
}

/// A map of props / state classes that have been migrated to the new boilerplate
/// via [migrateClassToMixin].
var propsAndStateClassNamesConvertedToNewBoilerplate =
    < /*old class name*/ String, /*new mixin name*/ String>{};

/// Used to switch a props/state class, or a `@PropsMixin()`/`@StateMixin()` class to a mixin.
///
/// __EXAMPLE (Concrete Class):__
/// ```dart
/// // Before
/// class _$TestProps extends UiProps {
///   String var1;
///   int var2;
/// }
///
/// // After
/// mixin TestPropsMixin on UiProps {
///   String var1;
///   int var2;
/// }
/// ```
///
/// __EXAMPLE (`@PropsMixin`):__
/// ```dart
/// // Before
/// @PropsMixin()
/// abstract class TestPropsMixin implements UiProps, BarPropsMixin {
///   // To ensure the codemod regression checking works properly, please keep this
///   // field at the top of the class!
///   // ignore: undefined_identifier, undefined_class, const_initialized_with_non_constant_value
///   static const PropsMeta meta = _$metaForTestPropsMixin;
///
///   @override
///   Map get props;
///
///   String var1;
///   String var2;
/// }
///
/// // After
/// mixin TestPropsMixin on UiProps implements BarPropsMixin {
///   String var1;
///   String var2;
/// }
/// ```
///
/// When a class is migrated, it gets added to [propsAndStateClassNamesConvertedToNewBoilerplate]
/// so that suggestors that come after the suggestor that called this function - can know
/// whether to yield a patch based on that information.
void migrateClassToMixin(ClassDeclaration node, YieldPatch yieldPatch,
    {bool shouldAddMixinToName = false}) {
  if (node.abstractKeyword != null) {
    yieldPatch(node.abstractKeyword.offset, node.abstractKeyword.charEnd, '');
  }

  yieldPatch(node.classKeyword.offset, node.classKeyword.charEnd, 'mixin');

  final originalPublicClassName =
      stripPrivateGeneratedPrefix(node.name.toSource());
  String newMixinName = originalPublicClassName;

  if (node.extendsClause?.extendsKeyword != null) {
    // --- Convert concrete props/state class to a mixin --- //

    yieldPatch(node.name.token.offset,
        node.name.token.offset + privateGeneratedPrefix.length, '');

    yieldPatch(node.extendsClause.offset,
        node.extendsClause.extendsKeyword.charEnd, 'on');

    if (shouldAddMixinToName) {
      yieldPatch(node.name.token.charEnd, node.name.token.charEnd, 'Mixin');
      newMixinName = '${newMixinName}Mixin';
    }
  } else {
    // --- Convert props/state mixin to an actual mixin --- //

    if (node.implementsClause?.implementsKeyword != null) {
      final nodeInterfaces = node.implementsClause.interfaces;
      // Implements an interface, and does not extend from another class
      if (implementsUiPropsOrUiState(node)) {
        if (nodeInterfaces.length == 1) {
          // Only implements UiProps / UiState
          yieldPatch(node.implementsClause.offset,
              node.implementsClause.implementsKeyword.charEnd, 'on');
        } else {
          // Implements UiProps / UiState along with other interfaces
          final uiInterface = nodeInterfaces.singleWhere((interface) =>
              interface.toSource() == 'UiProps' ||
              interface.toSource() == 'UiState');
          final otherInterfaces = List.of(nodeInterfaces)..remove(uiInterface);

          yieldPatch(node.implementsClause.offset, node.implementsClause.end,
              'on ${uiInterface.toSource()} implements ${otherInterfaces.joinByName()}');
        }
      } else {
        // Does not implement UiProps / UiState
        final uiInterfaceStr = isAPropsMixin(node) ? 'UiProps' : 'UiState';

        if (nodeInterfaces.isNotEmpty) {
          // But does implement other stuff
          yieldPatch(node.implementsClause.offset, node.implementsClause.end,
              'on $uiInterfaceStr implements ${nodeInterfaces.joinByName()}');
        } else {
          // Does not implement anything
          yieldPatch(node.leftBracket.offset - 1, node.leftBracket.offset - 1,
              'on $uiInterfaceStr');
        }
      }
    } else {
      // Does not implement anything
      final uiInterfaceStr = isAPropsMixin(node) ? 'UiProps' : 'UiState';

      yieldPatch(
          node.name.token.end, node.name.token.end, ' on $uiInterfaceStr');
    }
  }

  propsAndStateClassNamesConvertedToNewBoilerplate[originalPublicClassName] =
      newMixinName;
}

extension IterableAstUtils on Iterable<NamedType> {
  /// Utility to join an `Iterable` based on the `name` of the `name` field
  /// rather than the `toString()` of the object.
  String joinByName(
      {String startingString, String endingString, String seperator}) {
    final itemString = map((t) => t.name.name).join('${seperator ?? ','} ');
    final returnString = StringBuffer()
      ..write(startingString != null ? '${startingString.trimRight()} ' : '')
      ..write(itemString)
      ..write(endingString != null ? '${endingString.trimLeft()}' : '');

    return returnString.toString();
  }
}
