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

import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'util.dart';

/// Throws if [yaml] is invalid.
void validateYaml(String yaml) {
  loadYamlDocument(yaml);
}

void sharedPubspecTest({
  @required
      Function({bool shouldAddSpace, bool useSingleQuotes}) getExpectedOutput,
  @required SuggestorTester testSuggestor,
  @required String dependency,
  @required VersionRange startingRange,
  bool shouldAddDependencies = true,
  bool shouldUpdate = true,
  bool shouldUpdateMidRange = false,
  String midVersionRange,
}) {
  final patchCount = shouldUpdate ? 1 : 0;

  test('does nothing if there is no dependency key', () {
    testSuggestor(
      expectedPatchCount: 0,
      shouldDartfmtOutput: false,
      validateContents: validateYaml,
      input: ''
          'name: nothing\n'
          'version: 0.0.0\n'
          '',
      expectedOutput: ''
          'name: nothing\n'
          'version: 0.0.0\n'
          '',
    );
  });

  test('does nothing if the dependency matches the target already', () {
    testSuggestor(
      expectedPatchCount: 0,
      shouldDartfmtOutput: false,
      validateContents: validateYaml,
      input: ''
          'name: nothing\n'
          'version: 0.0.0\n'
          'dependencies:\n'
          '${getExpectedOutput(shouldAddSpace: true)}'
          '',
      expectedOutput: ''
          'name: nothing\n'
          'version: 0.0.0\n'
          'dependencies:\n'
          '${getExpectedOutput(shouldAddSpace: true)}'
          '',
    );
  });

  test(
      '${shouldAddDependencies ? 'adds the' : 'does not add the'} dependency '
      'if missing', () {
    testSuggestor(
      expectedPatchCount: shouldAddDependencies ? 1 : 0,
      shouldDartfmtOutput: false,
      validateContents: validateYaml,
      input: ''
          'dependencies:\n'
          '  test: 1.5.1\n'
          '',
      expectedOutput: ''
          'dependencies:\n'
          '${shouldAddDependencies ? getExpectedOutput(shouldAddSpace: true) : '  test: 1.5.1\n'}'
          '',
    );
  });

  group('updates the caret syntax', () {
    test('', () {
      testSuggestor(
        expectedPatchCount: patchCount,
        shouldDartfmtOutput: false,
        validateContents: validateYaml,
        input: ''
            '$dependency: ^${startingRange.min}\n'
            'test: 1.5.1\n'
            '',
        expectedOutput: shouldUpdate
            ? getExpectedOutput()
            : ''
                '$dependency: ^${startingRange.min}\n'
                'test: 1.5.1\n'
                '',
      );
    });

    test(
        '${shouldUpdateMidRange ? '' : 'except'} when the version is within the expected range',
        () {
      testSuggestor(
        expectedPatchCount: shouldUpdateMidRange ? 1 : 0,
        shouldDartfmtOutput: false,
        validateContents: validateYaml,
        input: ''
            '$dependency: $midVersionRange\n'
            'test: 1.5.1\n'
            '',
        expectedOutput: shouldUpdateMidRange
            ? getExpectedOutput()
            : ''
                '$dependency: $midVersionRange\n'
                'test: 1.5.1\n'
                '',
      );
    });

    test('with single quotes', () {
      testSuggestor(
        expectedPatchCount: patchCount,
        shouldDartfmtOutput: false,
        validateContents: validateYaml,
        input: ''
            '$dependency: \'^${startingRange.min}\'\n'
            'test: 1.5.1\n'
            '',
        expectedOutput: shouldUpdate
            ? getExpectedOutput(useSingleQuotes: true)
            : ''
                '$dependency: \'^${startingRange.min}\'\n'
                'test: 1.5.1\n'
                '',
      );
    });

    test('with double quotes', () {
      testSuggestor(
        expectedPatchCount: patchCount,
        shouldDartfmtOutput: false,
        validateContents: validateYaml,
        input: ''
            '$dependency: "^${startingRange.min}"\n'
            'test: 1.5.1\n'
            '',
        expectedOutput: shouldUpdate
            ? getExpectedOutput()
            : ''
                '$dependency: "^${startingRange.min}"\n'
                'test: 1.5.1\n'
                '',
      );
    });
  });

  group('updates the range syntax', () {
    test('with single quotes', () {
      testSuggestor(
        expectedPatchCount: patchCount,
        shouldDartfmtOutput: false,
        validateContents: validateYaml,
        input: ''
            '$dependency: \'$startingRange\'\n'
            'test: 1.5.1\n'
            '',
        expectedOutput: shouldUpdate
            ? getExpectedOutput(useSingleQuotes: true)
            : ''
                '$dependency: \'$startingRange\'\n'
                'test: 1.5.1\n'
                '',
      );
    });

    test('with double quotes', () {
      testSuggestor(
        expectedPatchCount: patchCount,
        shouldDartfmtOutput: false,
        validateContents: validateYaml,
        input: ''
            '$dependency: "$startingRange"\n'
            'test: 1.5.1\n'
            '',
        expectedOutput: shouldUpdate
            ? getExpectedOutput()
            : ''
                '$dependency: "$startingRange"\n'
                'test: 1.5.1\n'
                '',
      );
    });
  });

  group('updates mid-only range', () {
    test('', () {
      testSuggestor(
        expectedPatchCount: patchCount,
        shouldDartfmtOutput: false,
        validateContents: validateYaml,
        input: ''
            '$dependency: >=${startingRange.min}\n'
            'test: 1.5.1\n'
            '',
        expectedOutput: shouldUpdate
            ? getExpectedOutput()
            : ''
                '$dependency: >=${startingRange.min}\n'
                'test: 1.5.1\n'
                '',
      );
    });

    test('with single quotes', () {
      testSuggestor(
        expectedPatchCount: patchCount,
        shouldDartfmtOutput: false,
        validateContents: validateYaml,
        input: ''
            '$dependency: \'>=${startingRange.min}\'\n'
            'test: 1.5.1\n'
            '',
        expectedOutput: shouldUpdate
            ? getExpectedOutput(useSingleQuotes: true)
            : ''
                '$dependency: \'>=${startingRange.min}\'\n'
                'test: 1.5.1\n'
                '',
      );
    });

    test('with double quotes', () {
      testSuggestor(
        expectedPatchCount: patchCount,
        shouldDartfmtOutput: false,
        validateContents: validateYaml,
        input: ''
            '$dependency: ">=${startingRange.min}"\n'
            'test: 1.5.1\n'
            '',
        expectedOutput: shouldUpdate
            ? getExpectedOutput()
            : ''
                '$dependency: ">=${startingRange.min}"\n'
                'test: 1.5.1\n'
                '',
      );
    });
  });
}
