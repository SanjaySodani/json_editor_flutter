import 'package:flutter/material.dart';
import 'package:json_editor_flutter/json_editor_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'JSON Editor Example',
      home: JsonEditorExample(),
    );
  }
}

class JsonEditorExample extends StatelessWidget {
  const JsonEditorExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: JsonEditor(
          onChanged: (value) {
            // Do something with the value
            // Don't call setState()
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
        ),
      ),
    );
  }
}
