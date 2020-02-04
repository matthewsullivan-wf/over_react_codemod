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
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:codemod/codemod.dart';

import '../util.dart';
import 'boilerplate_utilities.dart';

/// Suggestor that updates props and state classes to new boilerplate.
///
/// This should only be done on cases where the props and state classes are not
/// simple use cases. E.g. when a prop class uses mixins or anytime it doesn't extend
/// UiProps / UiState.
///
/// Note: This should not operate on a class that does fit the criteria for _simple_.
class AdvancedPropsAndStateClassMigrator extends GeneralizingAstVisitor
    with AstVisitingSuggestorMixin
    implements Suggestor {
  final bool shouldMigrateCustomClassAndMixins;

  AdvancedPropsAndStateClassMigrator(
      {this.shouldMigrateCustomClassAndMixins = false});

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    super.visitClassDeclaration(node);

    if (!shouldMigrateAdvancedPropsAndStateClass(node)) return;

    final extendsFromCustomClass = !extendsFromUiPropsOrUiState(node);
    final hasMixins = node.withClause != null;

    // Don't operate if the props class uses mixins and extends a custom class,
    // unless the flag has been set.
    if (hasMixins &&
        extendsFromCustomClass &&
        !shouldMigrateCustomClassAndMixins) return;

    final className = stripPrivateGeneratedPrefix(node.name.name);
    final newDeclarationBuffer = StringBuffer()
      // Create the class name
      ..write('\n\nclass $className = ')
      // Decide if the class is a Props or a State class
      ..write('Ui${className.contains('Props') ? 'Props' : 'State'} ')
      // Add the width clause
      ..write('with ');

    if (extendsFromCustomClass) {
      final parentClass = node.extendsClause.superclass.name.name + 'Mixin';
      newDeclarationBuffer
          .write('$parentClass, ${className}Mixin${hasMixins ? ',' : ''}');
    }

    if (hasMixins) {
      if (!extendsFromCustomClass) {
        newDeclarationBuffer.write('${className}Mixin,');
      }

      newDeclarationBuffer.write(node.withClause.mixinTypes.joinByName());
    }

    newDeclarationBuffer.write(';');

    migrateClassToMixin(node, yieldPatch,
        shouldAddMixinToName: true,
        shouldSwapParentClass: extendsFromCustomClass);
    yieldPatch(node.end, node.end, newDeclarationBuffer.toString());
  }
}

bool shouldMigrateAdvancedPropsAndStateClass(ClassDeclaration node) =>
    shouldMigratePropsAndStateClass(node) && isAdvancedPropsOrStateClass(node);
