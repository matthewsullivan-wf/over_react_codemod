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
import 'package:codemod/codemod.dart';
import 'package:over_react_codemod/src/boilerplate_suggestors/advanced_props_and_state_class_migrator.dart';
import 'package:over_react_codemod/src/boilerplate_suggestors/simple_props_and_state_class_migrator.dart';
import 'package:over_react_codemod/src/dart2_suggestors/props_and_state_companion_class_remover.dart';

/// Suggestor that removes every companion class for props and state classes, as
/// they were only temporarily required for backwards-compatibility with Dart 1.
class StubbedPropsAndStateClassRemover
    extends PropsAndStateCompanionClassRemover implements Suggestor {
  @override
  bool shouldRemoveCompanionClassFor(
      ClassDeclaration candidate, CompilationUnit node) {
    return super.shouldRemoveCompanionClassFor(candidate, node) &&
        (shouldMigrateSimplePropsAndStateClass(candidate) ||
            shouldMigrateAdvancedPropsAndStateClass(candidate));
  }
}