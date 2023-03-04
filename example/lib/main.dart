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
          height: 300,
          width: 350,
          onSaved: (value) {
            print(value);
          },
          json: '''{
            "name": "sanjay",
            "age": 24,
            "hobbies": ["dance", "cricket"],
            "other": {
              "isGoodLooking": true
            }
          }''',
        ),
      ),
    );
  }
}
