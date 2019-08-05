// Copyright 2019 Workiva Inc.
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

import 'package:analyzer/analyzer.dart';
import 'package:codemod/codemod.dart';

/// Suggestor that updates `copyUnconsumedDomProps` usage.
class CopyUnconsumedDomPropsMigrator extends GeneralizingAstVisitor
    with AstVisitingSuggestorMixin
    implements Suggestor {
  CopyUnconsumedDomPropsMigrator();

  @override
  visitMethodInvocation(MethodInvocation node) {
    // TODO: implement visitMethodInvocation
    super.visitMethodInvocation(node);

    if (node.methodName.toString() == 'addProps') {
      var firstArg = node.argumentList.childEntities
          .firstWhere((a) => a.toString() != '(');

      if (firstArg.toString() == 'copyUnconsumedDomProps()' ||
          firstArg.toString() == 'copyUnconsumedProps()') {
        // Update argument name.
        yieldPatch(firstArg.offset, firstArg.end,
            'addUnconsumed${firstArg.toString().contains('Dom') ? 'Dom' : ''}Props');

        // Rename `addProps` to `modifyProps`.
        yieldPatch(node.methodName.offset, node.methodName.end, 'modifyProps');
      }
    }
  }
}
