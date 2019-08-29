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

import 'package:codemod/codemod.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:source_span/source_span.dart';

import '../constants.dart';

/// Suggestor that attempts to update `pubspec.yaml` files to ensure a safe
/// minimum bound on the `react` dependency.
///
/// If `react` is already listed, but the minimum bound is not high enough,
/// the version constraint will be updated. If `react` is missing from
/// the file, it will be added.
class PubspecReactUpdater implements Suggestor {
  /// Regex that matches the dependency constraint declaration for react.
  static final RegExp reactDep = reactDependencyRegExp;

  static final RegExp dependenciesKey = dependencyRegExp;

  final VersionRange targetConstraint;

  PubspecReactUpdater(this.targetConstraint);

  @override
  Iterable<Patch> generatePatches(SourceFile sourceFile) sync* {
    final contents = sourceFile.getText(0);
    final reactMatch = reactDep.firstMatch(contents);
    bool mightNeedYamlEscaping(String scalarValue) =>
        // Values starting with `>` need escaping.
    // Whitelist a non-exhaustive list of allowable characters,
    // flagging that the value should be escaped when we're not sure.
    !RegExp(r'^[^>][-+.<>=^ \w]*$').hasMatch(scalarValue);

    if (reactMatch != null) {
      // react is already in pubspec.yaml
      final line = reactMatch.group(0);
      final constraintValue = reactMatch.group(2);
      final constraint = VersionConstraint.parse(constraintValue);
      if (constraint is VersionRange && constraint != targetConstraint) {
        // Wrap the new constraint in quotes if required.
        var newValue = targetConstraint.toString();
        
        if (mightNeedYamlEscaping(newValue)
            && !line.contains("'")
            && !line.contains("\"")) {
          newValue = "'$newValue'";
        }

        // Update the version constraint to ensure a safe minimum bound.
        yield Patch(
          sourceFile,
          sourceFile.span(reactMatch.start, reactMatch.end),
          line.replaceFirst(
            constraintValue,
            newValue,
          ),
        );
      }
    } else {
      // react is missing in pubspec.yaml, so add it.
      final dependenciesKeyMatch = dependenciesKey.firstMatch(contents);

      if (dependenciesKeyMatch != null) {
        // Wrap the new constraint in quotes if required.
        var newValue = targetConstraint.toString();
        if (mightNeedYamlEscaping(newValue)) {
          newValue = "'$newValue'";
        }

        yield Patch(
          sourceFile,
          sourceFile.span(dependenciesKeyMatch.end, dependenciesKeyMatch.end),
          '\n  react: $newValue',
        );
      }
    }
  }

  @override
  bool shouldSkip(_) => false;
}
