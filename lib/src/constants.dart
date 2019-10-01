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

/// Constants that are not specific to any particular over_react codemod or
/// suggestor.
library over_react_codemod.src.constants;

const String generatedPrefix = r'$';
const String privatePrefix = r'_';
const String privateGeneratedPrefix = '$privatePrefix$generatedPrefix';

/// File extension used for all part files generated by over_react.
const String overReactGeneratedExtension = '.over_react.g.dart';

/// Names of all the over_react annotations.
const List<String> overReactAnnotationNames = [
  'Factory',
  'Component',
  'Props',
  'State',
  'AbstractComponent',
  'AbstractProps',
  'AbstractState',
  'PropsMixin',
  'StateMixin',
];

/// Names of all the over_react Component class annotations to migrate.
const List<String> overReact16ComponentAnnotationNamesToMigrate = [
  'Component',
  'AbstractComponent',
];

/// Names of all the over_react Component2 class annotations.
const List<String> overReact16Component2AnnotationNames = [
  'Component2',
  'AbstractComponent2',
];

const List<String> overReactPropsStateAnnotationNames = [
  'Props',
  'State',
  'AbstractProps',
  'AbstractState',
  'PropsMixin',
  'StateMixin',
];

/// Annotation names for over_react's props and state classes, excluding the
/// mixin annotations.
const List<String> overReactPropsStateNonMixinAnnotationNames = [
  'Props',
  'State',
  'AbstractProps',
  'AbstractState',
];

/// Annotation names for over_react's props and state mixins.
const List<String> overReactMixinAnnotationNames = [
  'PropsMixin',
  'StateMixin',
];

/// A list of the names of the core component classes that can be upgraded to a "v2" version.
const List<String> upgradableV1ComponentClassNames = [
  'UiComponent',
  'UiStatefulComponent',
  'FluxUiComponent',
  'FluxUiStatefulComponent',
];

/// Dart type for the static meta field on props classes.
const String propsMetaType = 'PropsMeta';

/// Dart type for the static meta field on state classes.
const String stateMetaType = 'StateMeta';

/// Comment text that is attached to the props/state companion classes.
const String temporaryCompanionClassComment =
    'This will be removed once the transition to Dart 2 is complete.';

/// Regex to find a react dependency.
final RegExp reactDependencyRegExp = RegExp(
  r'''^\s*react:\s*(["']?)(.+)\1\s*$''',
  multiLine: true,
);

/// Regex to find an over_react dependency.
final RegExp overReactDependencyRegExp = RegExp(
  r'''^\s*over_react:\s*(["']?)(.+)\1\s*$''',
  multiLine: true,
);

/// Regex to find the dependency pubspec.yaml key.
final RegExp dependencyRegExp = RegExp(
  r'^dependencies:\s*$',
  multiLine: true,
);

/// Regex to find the dependency pubspec.yaml key.
final RegExp devDependencyRegExp = RegExp(
  r'^dev_dependencies:\s*$',
  multiLine: true,
);

/// Regex to find the dependency_overrides pubspec.yaml key.
final RegExp dependencyOverrideRegExp = RegExp(
  r'^dependency_overrides:\s*$',
  multiLine: true,
);
