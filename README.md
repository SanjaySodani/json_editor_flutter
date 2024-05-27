# JsonEditor class

Edit your JSON object with this package. Create, edit and delete objects using this user friendly widget. 

See the sample below for an example.

## Screenshot
![JSON Editor](https://raw.githubusercontent.com/SanjaySodani/media/main/jsoneditor.png)

## Getting started
- Add the package in your flutter project.  Run this command in terminal `flutter pub add json_editor_flutter`.
- Import the package `import 'package:json_editor_flutter/json_editor_flutter.dart';`.

## Using [JsonEditor](https://pub.dev/packages/json_editor_flutter)

JSON can be edited in two ways, UI editor or text editor. You can disable either of them.

When UI editor is active, you can disable adding/deleting keys by using [enableMoreOptions] and can disable key editing by using [enableKeyEdit].

When text editor is active, it will simply ignore [enableKeyEdit] and [enableMoreOptions].

[duration] is the debounce time for [onChanged] function. Defaults to 500 milliseconds.

[editors] is the supported list of editors. First element will be used as default editor. Defaults to `[Editors.tree, Editors.text]`.

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

## Make most of this package

### beforeScrollDuration
*property*<br>
*type -> Duration*<br>
The `Duration` between the search and the starting of scroll animation.

All the objects are expanded in order to find the correct offset position of the searched key. `beforeScrollDuration` refers to the time given for rebuilding the UI to expand all objects. Once the rebuilding is completed in the given duration, the scroll animation will work properly. If the duration provided is short you will not see the scroll animation.

Play around with this property to find your suitable duration. `beforeScrollDuration` is proportional to the size of the JSON object.

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
| searchDuration         | Duration     | 600 ms        | Debounce duration for search function
| beforeScrollDuration   | Duration     | 300 ms        | The duration between the search and the starting of scroll animation


## Additional information
> You can raise an issue/feature request on github [Json Editor Issues](https://github.com/SanjaySodani/json_editor_flutter/issues)
---
*Please leave a like if you find this package useful.* :+1: