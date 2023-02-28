Edit your JSON object with the help of this package. You can create new objects and delete the existing using this user friendly widget.

## Features

![JSON Editor](https://github.com/SanjaySodani/media/blob/main/jsoneditor.png "JSON Editor")

## Getting started

- Add the package in your flutter project.
- Import the package `import 'package:json_editor_flutter/json_editor_flutter.dart';`.

## Usage

```dart
JsonEditor(
  height: 300,
  width: 350,
  onSaved: (value) {
    print(value);
  },
  json: const {
    'firstname': 'sanjay',
    'age': 24,
    'hobbies': ['dance', 'cricket'],
    'other': {
      'isGoodLooking': true,
    }
  },
)
```

## Additional information

> You can raise an issue/feature request on github.