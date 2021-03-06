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

import 'package:over_react_codemod/src/react16_suggestors/dependency_override_updater.dart';
import 'package:test/test.dart';

import '../util.dart';

main() {
  group('DependencyOverrideUpdater', () {
    final testSuggestor = getSuggestorTester(DependencyOverrideUpdater());

    const defaultDependencies = '  test: 1.5.1\n'
        '  react: ^4.6.0\n'
        '  over_react: ^2.0.0\n';
    const defaultDevDependencies = '  dart_dev: ^2.0.1\n';
    const expectedOverrides = '  react: ^5.0.0-alpha\n'
        '  over_react: ^3.0.0-alpha\n';
    const expectedOutputSections = {
      'dependencies': defaultDependencies,
      'dev_dependencies': defaultDevDependencies,
      'dependency_overrides': expectedOverrides,
    };

    void testDependencyOverridesSectionByPosition(Map inputSections,
        {String additionalOverrides}) {
      var dependencyOverrides = expectedOutputSections['dependency_overrides'];
      if (additionalOverrides != null) {
        dependencyOverrides += additionalOverrides;
      }

      test('and the dependency_overrides section is last', () {
        testSuggestor(
          expectedPatchCount: 2,
          shouldDartfmtOutput: false,
          input: ''
                  'dependencies:\n' +
              inputSections['dependencies'] +
              '\n'
                  'dev_dependencies:\n' +
              inputSections['dev_dependencies'] +
              '\n'
                  'dependency_overrides:\n' +
              inputSections['dependency_overrides'] +
              '',
          expectedOutput: ''
                  'dependencies:\n' +
              expectedOutputSections['dependencies'] +
              '\n'
                  'dev_dependencies:\n' +
              expectedOutputSections['dev_dependencies'] +
              '\n'
                  'dependency_overrides:\n' +
              dependencyOverrides +
              '',
        );
      });

      test('and the dependency_overrides section is first', () {
        // The extra line-break is not ideal, but the effort to make it be a
        // single break no matter the order of the sections is not worth it, IMO.
        final lineBreaksAfterDepOverridesSection =
            additionalOverrides == null ? '\n\n' : '\n';

        testSuggestor(
          expectedPatchCount: 2,
          shouldDartfmtOutput: false,
          input: ''
                  'dependency_overrides:\n' +
              inputSections['dependency_overrides'] +
              '\n'
                  'dependencies:\n' +
              inputSections['dependencies'] +
              '\n'
                  'dev_dependencies:\n' +
              inputSections['dev_dependencies'] +
              '',
          expectedOutput: ''
                  'dependency_overrides:\n' +
              dependencyOverrides +
              lineBreaksAfterDepOverridesSection +
              'dependencies:\n' +
              expectedOutputSections['dependencies'] +
              '\n'
                  'dev_dependencies:\n' +
              expectedOutputSections['dev_dependencies'] +
              '',
        );
      });

      test('and the dependency_overrides section is in the middle', () {
        // The extra line-break is not ideal, but the effort to make it be a
        // single break no matter the order of the sections is not worth it, IMO.
        final lineBreaksAfterDepOverridesSection =
            additionalOverrides == null ? '\n\n' : '\n';

        testSuggestor(
          expectedPatchCount: 2,
          shouldDartfmtOutput: false,
          input: ''
                  'dependencies:\n' +
              inputSections['dependencies'] +
              '\n'
                  'dependency_overrides:\n' +
              inputSections['dependency_overrides'] +
              '\n'
                  'dev_dependencies:\n' +
              inputSections['dev_dependencies'] +
              '',
          expectedOutput: ''
                  'dependencies:\n' +
              expectedOutputSections['dependencies'] +
              '\n'
                  'dependency_overrides:\n' +
              dependencyOverrides +
              lineBreaksAfterDepOverridesSection +
              'dev_dependencies:\n' +
              expectedOutputSections['dev_dependencies'] +
              '',
        );
      });
    }

    group('adds the dependencies if', () {
      test('the pubspec is empty', () {
        // The output has a new line because the testSuggester appends one.
        testSuggestor(
          expectedPatchCount: 2,
          shouldDartfmtOutput: false,
          input: '',
          expectedOutput: '\n'
                  'dependency_overrides:\n' +
              expectedOverrides +
              '',
        );
      });

      test('react and over_react are not dependencies', () {
        testSuggestor(
          expectedPatchCount: 2,
          shouldDartfmtOutput: false,
          input: ''
              'dependencies:\n'
              '  test: 1.5.1\n'
              '\n'
              'dev_dependencies:\n'
              '  dart_dev: ^2.0.1\n'
              '',
          expectedOutput: ''
                  'dependencies:\n'
                  '  test: 1.5.1\n'
                  '\n'
                  'dev_dependencies:\n'
                  '  dart_dev: ^2.0.1\n'
                  '\n'
                  'dependency_overrides:\n' +
              expectedOverrides +
              '',
        );
      });

      group('the dependencies are already being overridden via', () {
        group('git (SSH)', () {
          const inputSections = {
            'dependencies': defaultDependencies,
            'dev_dependencies': defaultDevDependencies,
            'dependency_overrides': '  react:\n'
                '    git:\n'
                '      url: git@github.com:cleandart/react-dart.git\n'
                '      ref: 5.0.0-wip\n'
                '  over_react:\n'
                '    git:\n'
                '      url: git@github.com:Workiva/over_react.git\n'
                '      ref: 3.0.0-wip\n',
          };

          testDependencyOverridesSectionByPosition(inputSections);
        });

        group('git (HTTPS)', () {
          const inputSections = {
            'dependencies': defaultDependencies,
            'dev_dependencies': defaultDevDependencies,
            'dependency_overrides': '  react:\n'
                '    git:\n'
                '      url: https://github.com/cleandart/react-dart.git\n'
                '      ref: 5.0.0-wip\n'
                '  over_react:\n'
                '    git:\n'
                '      url: https://github.com/Workiva/over_react.git\n'
                '      ref: 3.0.0-wip\n',
          };

          testDependencyOverridesSectionByPosition(inputSections);
        });

        group('path', () {
          const inputSections = {
            'dependencies': defaultDependencies,
            'dev_dependencies': defaultDevDependencies,
            'dependency_overrides': '  react:\n'
                '    path: ../../anywhere\n'
                '  over_react:\n'
                '    path: ../../anywhere\n',
          };

          testDependencyOverridesSectionByPosition(inputSections);
        });
      });
    });

    test('adds dependency if missing', () {
      testSuggestor(
        expectedPatchCount: 2,
        shouldDartfmtOutput: false,
        input: ''
                'dependencies:\n' +
            defaultDependencies +
            '\n'
                'dev_dependencies:\n' +
            defaultDevDependencies +
            '',
        expectedOutput: ''
                'dependencies:\n' +
            defaultDependencies +
            '\n'
                'dev_dependencies:\n' +
            defaultDevDependencies +
            '\n'
                'dependency_overrides:\n' +
            expectedOverrides +
            '',
      );
    });

    group('preserves existing, unrelated dependency overrides', () {
      const unrelatedOverride = '  foo:\n'
          '    git:\n'
          '      url: git@github.com:Workiva/foo.git\n'
          '      ref: 100.0.0\n';
      const inputSections = {
        'dependencies': defaultDependencies,
        'dev_dependencies': defaultDevDependencies,
        'dependency_overrides': unrelatedOverride,
      };

      testDependencyOverridesSectionByPosition(inputSections,
          additionalOverrides: unrelatedOverride);
    });

    test('does not override sections after dependency_overrides', () {
      testSuggestor(
        expectedPatchCount: 2,
        shouldDartfmtOutput: false,
        testIdempotency: false,
        input: ''
            'dependencies:\n'
            '  test: 1.5.1\n'
            '  react: ^4.6.0\n'
            '  over_react: ^2.0.0\n'
            '\n'
            'dev_dependencies:\n'
            '  dart_dev: ^2.0.1\n'
            '\n'
            'dependency_overrides:\n'
            '  foo:\n'
            '    git:\n'
            '      url: git@github.com:Workiva/foo.git\n'
            '      ref: 100.0.0\n'
            '\n'
            'executables:\n'
            '  dart2_upgrade:\n'
            '  react_16_upgrade:\n'
            '',
        expectedOutput: ''
            'dependencies:\n'
            '  test: 1.5.1\n'
            '  react: ^4.6.0\n'
            '  over_react: ^2.0.0\n'
            '\n'
            'dev_dependencies:\n'
            '  dart_dev: ^2.0.1\n'
            '\n'
            'dependency_overrides:\n'
            '  react: ^5.0.0-alpha\n'
            '  over_react: ^3.0.0-alpha\n'
            '  foo:\n'
            '    git:\n'
            '      url: git@github.com:Workiva/foo.git\n'
            '      ref: 100.0.0\n'
            '\n'
            'executables:\n'
            '  dart2_upgrade:\n'
            '  react_16_upgrade:\n'
            '',
      );
    });

    test('does not fail if there is no trailing new line.', () {
      testSuggestor(
        expectedPatchCount: 2,
        shouldDartfmtOutput: false,
        testIdempotency: false,
        input: ''
            'dependencies:\n'
            '  test: 1.5.1\n'
            '  react: ^4.6.0\n'
            '  over_react: ^2.0.0\n'
            '\n'
            'dev_dependencies:\n'
            '  dart_dev: ^2.0.1\n',
        expectedOutput: ''
            'dependencies:\n'
            '  test: 1.5.1\n'
            '  react: ^4.6.0\n'
            '  over_react: ^2.0.0\n'
            '\n'
            'dev_dependencies:\n'
            '  dart_dev: ^2.0.1\n'
            '\n'
            'dependency_overrides:\n'
            '  react: ^5.0.0-alpha\n'
            '  over_react: ^3.0.0-alpha\n'
            '',
      );
    });
  });
}
