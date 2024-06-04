# JsonEditor class

Edit your JSON object with this package. Create, edit and format objects using this user friendly widget. 

See the sample below for an example.

## [JsonEditor Live Demo](https://json-editor-flutter.netlify.app/)

## Screenshot
![JsonEditor](https://raw.githubusercontent.com/SanjaySodani/media/main/jsoneditor.png)

## Getting started
- Add the package in your flutter project.  Run this command in terminal `flutter pub add json_editor_flutter`.
- Import the package `import 'package:json_editor_flutter/json_editor_flutter.dart';`.

## Using [JsonEditor](https://pub.dev/packages/json_editor_flutter)

JSON can be edited in two ways, Tree editor or text editor. You can disable either of them.

When UI editor is active, you can disable adding/deleting keys by using `enableMoreOptions`. Editing keys and values can also be disabled by using `enableKeyEdit` and `enableValueEdit`.

When text editor is active, it will simply ignore `enableMoreOptions`, `enableKeyEdit` and `enableValueEdit`.

`duration` is the debounce time for `onChanged` function. Defaults to 500 milliseconds.

`editors` is the supported list of editors. First element will be used as default editor. Defaults to [Editors.tree, Editors.text].

## Example
```dart
JsonEditor(
  onChanged: (value) {
    // Do something
  },
  json: jsonEncode({
    "name": "John Doe",
    "age": 24,
    "hobbies": ["Reading", "Coding"],
    "address": {
      "street": "Main Street",
      "number": 1234567890,
      "city": "New York"
    }
  }),
)
```

## Enums
Supported editors for JSON Editor.
```dart
enum  Editors { tree, text }
```

## Properties

| Property               | Type         | Default Value | Description                                                                                                                                   |
| -----------------------|--------------|---------------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| json                   | String       | required      | JSON object to be edited
| onChanged              | Function     | required      | Callback function that will be called with the new data
| duration               | Duration     | 500 ms        | Debounce duration for `onChanged` function
| enableMoreOptions      | bool         | true          | Enables more options like adding or deleting data
| enableKeyEdit          | bool         | true          | Enables editing of keys
| enableValueEdit        | bool         | true          | Enables editing of values
| themeColor             | Color?       | null          | Theme color for the editor, changes the border color and header color
| editors                | List<Editors>| [tree, text]  | List of supported editors, first element will be used as default editor
| actions                | List\<Widget>| []            | A list of Widgets to display in a row at the end of header
| enableHorizontalScroll | bool         | false         | Enables horizontal scroll for the tree view
| searchDuration         | Duration     | 500 ms        | Debounce duration for search function
| hideEditorsMenuButton  | bool         | false         | Hides the option of changing editor

## Additional information
> You can raise an issue/feature request on github [Json Editor Issues](https://github.com/SanjaySodani/json_editor_flutter/issues)
---
*Please leave a like if you find this package useful.* :+1: