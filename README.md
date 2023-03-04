Edit your JSON object with the help of this package. Create and delete objects using this user friendly widget.

## Features

![JSON Editor](https://github.com/SanjaySodani/media/blob/main/jsoneditor.jpeg "JSON Editor")

## Getting started

- Add the package in your flutter project.
- Import the package `import 'package:json_editor_flutter/json_editor_flutter.dart';`.

## Usage

```dart
JsonEditor(
  onSaved: (value) {
    print(value);
  },
  json: '''{
    'firstname': 'sanjay',
    'age': 24,
    'hobbies': ['dance', 'cricket'],
    'other': {
      'isGoodLooking': true
    }
  }''',
)
```

## Additional information

> You can raise an issue/feature request on github. <br>Please leave a like if you find this package useful.
