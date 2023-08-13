Edit your JSON object with the help of this package. Create and delete objects using this user friendly widget.

## Features

![JSON Editor](https://github.com/SanjaySodani/media/blob/main/jsoneditor.png)

## Getting started

- Add the package in your flutter project.
- Import the package `import 'package:json_editor_flutter/json_editor_flutter.dart';`.

## Usage

```dart
JsonEditor(
  onChanged: (value) {
    // Do something
  },
  json: '''{
    "name": "John Doe",
    "age": 24,
    "hobbies": ["Reading", "Coding"],
    "address": {
      "street": "Main Street",
      "number": 1234567890,
      "city": "New York"
    }
  }''',
)
```

## Additional information

> You can raise an issue/feature request on github. <br>Please leave a like if you find this package useful.
