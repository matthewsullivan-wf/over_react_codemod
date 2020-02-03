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
import 'package:over_react_codemod/src/boilerplate_suggestors/boilerplate_utilities.dart';

/// Suggestor that looks for `meta` getter access on props classes found within
/// [propsAndStateClassNamesConvertedToNewBoilerplate] as a result of being converted to the new
/// boilerplate via `SimplePropsAndStateClassMigrator` or `AdvancedPropsAndStateClassMigrator`, and converts
/// them to the way meta is accessed using the new boilerplate.
///
/// ```dart
/// // Before
/// FooProps.meta
///
/// // After
/// propsMeta.forMixin(FooProps)
/// ```
///
/// > Related: [PropsMixinMigrator]
class PropsMetaMigrator extends GeneralizingAstVisitor
    with AstVisitingSuggestorMixin
    implements Suggestor {
  @override
  visitPrefixedIdentifier(PrefixedIdentifier node) {
    super.visitPrefixedIdentifier(node);

    if (node.identifier.name == 'meta') {
      if (propsAndStateClassNamesConvertedToNewBoilerplate
          .containsKey(node.prefix.name)) {
        yieldPatch(
          node.prefix.offset,
          node.identifier.end,
          'propsMeta.forMixin(${propsAndStateClassNamesConvertedToNewBoilerplate[node.prefix.name]})',
        );
      }
    }
  }
}
