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

typedef void YieldPatch(
    int startingOffset, int endingOffset, String replacement);

/// A simple RegExp against the parent of the class to verify it is `UiProps`
/// or `UiState`.
bool extendsFromUiPropsOrUiState(ClassDeclaration classNode) =>
    classNode.extendsClause.superclass.name
        .toSource()
        .contains(RegExp('(UiProps)|(UiState)'));

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

/// Used to switch a props or state class to a mixin.
///
/// __EXAMPLE:__
/// ```dart
/// // Before
/// class TestProps extends UiProps {
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
void migrateClassToMixin(ClassDeclaration node, YieldPatch yieldPatch,
    {bool shouldAddMixinToName = false}) {
  yieldPatch(node.classKeyword.offset, node.classKeyword.charEnd, 'mixin');
  yieldPatch(node.extendsClause.offset,
      node.extendsClause.extendsKeyword.charEnd, 'on');

  if (shouldAddMixinToName) {
    yieldPatch(node.name.token.charEnd, node.name.token.charEnd, 'Mixin');
  }
}
