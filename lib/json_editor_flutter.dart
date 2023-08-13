import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// `ValueNotifier` for expanding and collapsing all objects
final _isExpanded = ValueNotifier<bool>(false);

/// Left padding to show an `Object` is nested
const double nestingSpace = 6;

/// Editor height
const double editorHeight = 250;

/// Editor width
const double editorWidth = 300;

/// Left space for arrow icon
const double spaceLeft = 20;

/// Font size
const double textSize = 16;

/// Toolbar buttons width
const double toolbarButtonWidth = 40;

/// Delete icon size
const double deleteIconSize = 20;

/// Text field width
const double textFieldWidth = 120;

/// Delete Icon
const Widget deleteIcon = Icon(
  Icons.delete,
  color: Colors.red,
  size: deleteIconSize,
);

/// Data Types JsonEditor can work with
enum _Types {
  number,
  bool,
  string,
  object,
}

/// Adding an item for
enum _AddingFor {
  list,
  map,
}

// Add an item to list
void _addListItem({
  required BuildContext ctx,
  required _Types type,
  required Function onSubmitted,
}) {
  if (type == _Types.bool) {
    onSubmitted(false);
    return;
  }

  String value = '';
  String fbText = '';

  bool submitData(StateSetter setState) {
    if (type == _Types.number) {
      num? data = num.tryParse(value);
      if (data == null || data.isNaN) {
        setState(() {
          fbText = 'Invalid number';
        });
        return false;
      } else {
        onSubmitted(data);
        return true;
      }
    } else if (type == _Types.object) {
      try {
        onSubmitted(jsonDecode(value));
        return true;
      } catch (_) {
        setState(() {
          fbText = 'Invalid JSON';
        });
        return false;
      }
    } else {
      onSubmitted(value);
      return true;
    }
  }

  showDialog(
    context: ctx,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return SimpleDialog(
          title: const Text('Add List item'),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          children: [
            SizedBox(
              width: 250,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (type != _Types.bool)
                    Expanded(
                      flex: 6,
                      child: TextFormField(
                        onChanged: (text) {
                          value = text;
                        },
                        decoration: const InputDecoration(
                          hintText: 'value',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                  IconButton(
                    onPressed: () {
                      if (value.isEmpty) {
                        setState(() {
                          fbText = 'Please enter a value!';
                        });
                      } else {
                        bool isSubmitted = submitData(setState);
                        if (isSubmitted) {
                          Navigator.of(context).pop();
                        }
                      }
                    },
                    icon: const Icon(
                      Icons.check,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            // feedback here
            const SizedBox(
              height: 5,
            ),
            if (fbText.isNotEmpty)
              Text(
                fbText,
                style: const TextStyle(color: Colors.red),
              ),
          ],
        );
      });
    },
  );
}

// add an item to map
void _addMapItem({
  required BuildContext ctx,
  required _Types type,
  required List keys,
  required Function onSubmitted,
}) {
  String key = '';
  String value = '';
  String fbText = '';

  bool submitData(StateSetter setState) {
    if (type == _Types.bool) {
      onSubmitted({'key': key, 'value': false});
      return true;
    } else if (type == _Types.number) {
      num? data = num.tryParse(value);
      if (data == null || data.isNaN) {
        setState(() {
          fbText = 'Invalid number';
        });
        return false;
      } else {
        onSubmitted({'key': key, 'value': data});
        return true;
      }
    } else if (type == _Types.object) {
      try {
        onSubmitted({'key': key, 'value': jsonDecode(value)});
        return true;
      } catch (_) {
        setState(() {
          fbText = 'Invalid JSON';
        });
        return false;
      }
    } else {
      onSubmitted({'key': key, 'value': value});
      return true;
    }
  }

  showDialog(
    context: ctx,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return SimpleDialog(
          title: const Text('Add Object item'),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          children: [
            SizedBox(
              width: 250,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    flex: 4,
                    child: TextFormField(
                      onChanged: (value) {
                        key = value;
                      },
                      decoration: const InputDecoration(
                        hintText: 'key',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  if (type != _Types.bool)
                    Expanded(
                      flex: 6,
                      child: TextFormField(
                        onChanged: (text) {
                          value = text;
                        },
                        decoration: const InputDecoration(
                          hintText: 'value',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                  IconButton(
                    onPressed: () {
                      if (keys.contains(key)) {
                        setState(() {
                          fbText = 'Key already exists!';
                        });
                      } else if (key.isEmpty) {
                        setState(() {
                          fbText = 'Please enter a key!';
                        });
                      } else {
                        bool isSubmitted = submitData(setState);
                        if (isSubmitted) {
                          Navigator.of(context).pop();
                        }
                      }
                    },
                    icon: const Icon(
                      Icons.check,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            // feedback here
            const SizedBox(
              height: 5,
            ),
            if (fbText.isNotEmpty)
              Text(
                fbText,
                style: const TextStyle(color: Colors.red),
              ),
          ],
        );
      });
    },
  );
}

// Builds popupmenu item for item type
PopupMenuItem _buildPopupItem(_Types type, Icon icon, String label) {
  return PopupMenuItem(
    height: 30,
    padding: const EdgeInsets.only(left: 5),
    value: type,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    ),
  );
}

// Builds popup menu to choose a type for addition
Widget _buildPopupMenu(
  BuildContext ctx,
  _AddingFor addingFor,
  Function onSubmitted, [
  keys = const [],
]) {
  return PopupMenuButton(
    tooltip: 'Add new object',
    padding: EdgeInsets.zero,
    onSelected: (value) {
      if (addingFor == _AddingFor.map) {
        _addMapItem(
          ctx: ctx,
          type: value as _Types,
          keys: keys,
          onSubmitted: onSubmitted,
        );
      } else {
        _addListItem(
          ctx: ctx,
          type: value as _Types,
          onSubmitted: onSubmitted,
        );
      }
    },
    itemBuilder: (context) {
      return [
        _buildPopupItem(
          _Types.number,
          const Icon(Icons.onetwothree),
          'Numbers',
        ),
        _buildPopupItem(
          _Types.bool,
          const Icon(Icons.check_rounded),
          'Boolean',
        ),
        _buildPopupItem(
          _Types.string,
          const Icon(Icons.abc),
          'String',
        ),
        _buildPopupItem(
          _Types.object,
          const Icon(Icons.data_object),
          'Object',
        ),
      ];
    },
    child: const Icon(Icons.add, size: 20),
  );
}

// Builds a row with key and value
Widget _buildKeyValue({
  required key,
  required value,
  required parent,
  required StateSetter setState,
  required double paddingLeft,
}) {
  if (value is Map || value is List) {
    return _buildWidget(
      key: key,
      value: value,
      parent: parent,
      setState: setState,
      paddingLeft: paddingLeft,
    );
  } else {
    if (value is num) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              if (parent is Map) {
                parent.remove(key);
              } else {
                (parent as List).removeAt(key);
              }
              setState(() {});
            },
            child: deleteIcon,
          ),
          SizedBox(width: paddingLeft),
          const SizedBox(width: spaceLeft),
          Text(
            '$key : ',
            style: const TextStyle(fontSize: textSize),
          ),
          SizedBox(
            width: textFieldWidth,
            child: _NumberInputField(
              stateKey: UniqueKey(),
              objKey: key,
              initialData: value,
              onChange: (objKey, data) {
                parent[objKey] = data;
              },
            ),
          ),
        ],
      );
    } else if (value is bool) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              if (parent is Map) {
                parent.remove(key);
              } else {
                (parent as List).removeAt(key);
              }
              setState(() {});
            },
            child: deleteIcon,
          ),
          SizedBox(width: paddingLeft),
          const SizedBox(width: spaceLeft),
          Text(
            '$key : ',
            style: const TextStyle(fontSize: textSize),
          ),
          SizedBox(
            width: textFieldWidth,
            child: _BoolInputField(
              key: UniqueKey(),
              objKey: key,
              initialData: value,
              onChange: (objKey, data) {
                parent[objKey] = data;
              },
            ),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              if (parent is Map) {
                parent.remove(key);
              } else {
                (parent as List).removeAt(key);
              }
              setState(() {});
            },
            child: deleteIcon,
          ),
          SizedBox(width: paddingLeft),
          const SizedBox(width: spaceLeft),
          Text(
            '$key : ',
            style: const TextStyle(fontSize: textSize),
          ),
          SizedBox(
            width: textFieldWidth,
            child: _StringInputField(
              stateKey: UniqueKey(),
              objKey: key,
              initialData: value,
              onChange: (objKey, data) {
                parent[objKey] = data;
              },
            ),
          ),
        ],
      );
    }
  }
}

// Builds a folder widget or a key value
Widget _buildWidget({
  required key,
  required value,
  required parent,
  required StateSetter setState,
  required double paddingLeft,
}) {
  if (value is Map) {
    return AnimatedBuilder(
        animation: _isExpanded,
        builder: (context, _) {
          return _JsonFolder(
            key: UniqueKey(),
            objectKey: key,
            value: value,
            parent: parent,
            setState: setState,
            initiallyExpanded: _isExpanded.value,
            paddingLeft: paddingLeft,
          );
        });
  } else if (value is List) {
    return AnimatedBuilder(
        animation: _isExpanded,
        builder: (context, _) {
          return _ListFolder(
            key: UniqueKey(),
            listKey: key,
            value: value,
            parent: parent,
            setState: setState,
            initiallyExpanded: _isExpanded.value,
            paddingLeft: paddingLeft,
          );
        });
  } else {
    return _buildKeyValue(
      key: key,
      value: value,
      parent: parent,
      setState: setState,
      paddingLeft: paddingLeft,
    );
  }
}

// List holder
class _ListFolder extends StatefulWidget {
  final List value;
  final dynamic listKey;
  final dynamic parent;
  final StateSetter setState;
  final bool initiallyExpanded;
  final double nestSpace;

  const _ListFolder({
    super.key,
    required this.listKey,
    required this.value,
    required this.parent,
    required this.setState,
    required this.initiallyExpanded,
    required double paddingLeft,
  }) : nestSpace = nestingSpace + paddingLeft;

  @override
  State<_ListFolder> createState() => _ListFolderState();
}

class _ListFolderState extends State<_ListFolder> {
  late bool isFolderVisible;

  List<Widget> _listBuilder() {
    List<Widget> list = [];

    for (int i = 0; i < widget.value.length; i++) {
      list.add(_buildKeyValue(
        key: i,
        value: widget.value[i],
        parent: widget.value,
        setState: setState,
        paddingLeft: widget.nestSpace + nestingSpace,
      ));
    }

    return list;
  }

  @override
  void initState() {
    super.initState();
    isFolderVisible = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                if (widget.parent is Map) {
                  (widget.parent as Map).remove(widget.listKey);
                } else {
                  (widget.parent as List).removeAt(widget.listKey);
                }
                widget.setState(() {});
              },
              child: deleteIcon,
            ),
            SizedBox(width: widget.nestSpace - nestingSpace),
            SizedBox(
              width: spaceLeft,
              child: InkWell(
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                onTap: () {
                  setState(() {
                    isFolderVisible = !isFolderVisible;
                  });
                },
                child: isFolderVisible
                    ? const Icon(Icons.arrow_drop_down_rounded)
                    : const Icon(Icons.arrow_right_rounded),
              ),
            ),
            Text(
              '${widget.listKey} [${widget.value.length}]',
              style: const TextStyle(fontSize: textSize),
            ),
            const SizedBox(width: 5),
            _buildPopupMenu(
              context,
              _AddingFor.list,
              (value) {
                setState(() {
                  widget.value.add(value);
                });
              },
            ),
          ],
        ),
        if (isFolderVisible)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _listBuilder(),
          ),
      ],
    );
  }
}

// Map holder
class _JsonFolder extends StatefulWidget {
  final Map value;
  final dynamic objectKey;
  final dynamic parent;
  final StateSetter setState;
  final bool initiallyExpanded;
  final double nestSpace;

  const _JsonFolder({
    super.key,
    required this.objectKey,
    required this.value,
    required this.parent,
    required this.setState,
    required this.initiallyExpanded,
    required double paddingLeft,
  }) : nestSpace = nestingSpace + paddingLeft;

  @override
  State<_JsonFolder> createState() => _JsonFolderState();
}

class _JsonFolderState extends State<_JsonFolder> {
  late bool isFolderVisible;

  @override
  void initState() {
    super.initState();
    isFolderVisible = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                if (widget.parent is Map) {
                  widget.parent.remove(widget.objectKey);
                } else {
                  (widget.parent as List).removeAt(widget.objectKey);
                }
                widget.setState(() {});
              },
              child: deleteIcon,
            ),
            SizedBox(width: widget.nestSpace - nestingSpace),
            SizedBox(
              width: spaceLeft,
              child: InkWell(
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                onTap: () {
                  setState(() {
                    isFolderVisible = !isFolderVisible;
                  });
                },
                child: isFolderVisible
                    ? const Icon(
                        Icons.arrow_drop_down_rounded,
                      )
                    : const Icon(
                        Icons.arrow_right_rounded,
                      ),
              ),
            ),
            Text(
              '${widget.objectKey} {${widget.value.length}}',
              style: const TextStyle(fontSize: textSize),
            ),
            const SizedBox(width: 5),
            _buildPopupMenu(
              context,
              _AddingFor.map,
              (Map newItem) {
                setState(() {
                  widget.value[newItem['key']] = newItem['value'];
                });
              },
              widget.value.keys.toList(),
            ),
          ],
        ),
        if (isFolderVisible)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.value.keys.map((key) {
              return _buildKeyValue(
                key: key,
                value: widget.value[key],
                parent: widget.value,
                setState: setState,
                paddingLeft: widget.nestSpace + nestingSpace,
              );
            }).toList(),
          ),
      ],
    );
  }
}

class JsonEditor extends StatefulWidget {
  /// `String` JSON data
  final String json;

  /// `double?` editor height
  final double? height;

  /// `double?` editor width
  final double? width;

  /// `callback` onSaved
  final ValueChanged<Map> onSaved;

  /// `Color?` Theme color for the editor
  final Color? color;

  /// JsonEditor, `json` is required
  ///
  /// Edit Json/Map in tree view (UI).
  const JsonEditor({
    super.key,
    required this.json,
    required this.onSaved,
    this.height,
    this.width,
    this.color,
  });

  @override
  State<JsonEditor> createState() => _JsonEditorState();
}

class _JsonEditorState extends State<JsonEditor> {
  late Map<String, dynamic> json;
  late final bool isJsonValid;

  @override
  void initState() {
    super.initState();
    try {
      json = {'object': jsonDecode(widget.json)};
      isJsonValid = true;
    } catch (_) {
      isJsonValid = false;
    }
  }

  void copyData() async {
    await Clipboard.setData(
      ClipboardData(text: jsonEncode(json['object'])),
    );
  }

  void handleSave() {
    widget.onSaved(json['object'] ?? {});
  }

  void undoAllChanges() {
    setState(() {
      json = {'object': jsonDecode(widget.json)};
    });
  }

  @override
  Widget build(BuildContext context) {
    Color themeColor = widget.color ?? Theme.of(context).primaryColor;

    return Container(
      constraints: BoxConstraints.loose(Size(
        widget.width ?? editorWidth,
        widget.height ?? editorHeight,
      )),
      decoration: BoxDecoration(
        border: Border.all(
          width: 0.75,
          color: themeColor,
        ),
      ),
      child: isJsonValid
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  color: themeColor,
                  child: Row(
                    children: [
                      const SizedBox(width: 10),
                      const Text('JsonEditor'),
                      const Spacer(),
                      SizedBox(
                        width: 30,
                        child: Tooltip(
                          message: 'Undo all changes',
                          child: TextButton(
                            onPressed: undoAllChanges,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.all(0),
                            ),
                            child: const Icon(Icons.undo, size: 20),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 30,
                        child: Tooltip(
                          message: 'Expand all',
                          child: TextButton(
                            onPressed: json.containsKey('object')
                                ? () => _isExpanded.value = true
                                : null,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.all(0),
                            ),
                            child: const Icon(Icons.expand, size: 20),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 30,
                        child: Tooltip(
                          message: 'Collapse all',
                          child: TextButton(
                            onPressed: json.containsKey('object')
                                ? () => _isExpanded.value = false
                                : null,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.all(0),
                            ),
                            child: const Icon(Icons.compress, size: 20),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 30,
                        child: Tooltip(
                          message: 'Copy',
                          child: TextButton(
                            onPressed:
                                json.containsKey('object') ? copyData : null,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.all(0),
                            ),
                            child: const Icon(Icons.copy, size: 20),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 30,
                        child: Tooltip(
                          message: 'Save',
                          child: TextButton(
                            onPressed:
                                json.containsKey('object') ? handleSave : null,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.all(0),
                            ),
                            child: const Icon(Icons.save, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: json.keys.map((key) {
                            return _buildWidget(
                              key: key,
                              value: json[key],
                              parent: json,
                              setState: setState,
                              paddingLeft: 0,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : const Center(
              child: Text(
                'Invalid JSON!',
                style: TextStyle(color: Colors.red),
              ),
            ),
    );
  }
}

class _StringInputField extends StatelessWidget {
  final Key stateKey;
  final dynamic objKey;
  final String initialData;
  final void Function(dynamic, dynamic) onChange;

  const _StringInputField({
    required this.stateKey,
    required this.objKey,
    this.initialData = '',
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: stateKey,
      initialValue: initialData,
      cursorHeight: 14,
      style: const TextStyle(fontSize: textSize),
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.all(5),
        isDense: true,
        hintText: 'type...',
        border: InputBorder.none,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(width: 0.5),
        ),
      ),
      onChanged: (text) {
        onChange(objKey, text);
      },
    );
  }
}

class _NumberInputField extends StatelessWidget {
  final Key stateKey;
  final dynamic objKey;
  final String initialValue;
  final void Function(dynamic, dynamic) onChange;

  const _NumberInputField({
    required this.stateKey,
    required this.objKey,
    required num initialData,
    required this.onChange,
  }) : initialValue = '$initialData';

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: stateKey,
      initialValue: initialValue,
      cursorHeight: 14,
      style: const TextStyle(fontSize: textSize),
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.all(5),
        isDense: true,
        hintText: 'type...',
        border: InputBorder.none,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(width: 0.5),
        ),
      ),
      onChanged: (text) {
        onChange(objKey, num.parse(text));
      },
    );
  }
}

class _BoolInputField extends StatefulWidget {
  final dynamic objKey;
  final bool initialData;
  final void Function(dynamic, dynamic) onChange;

  const _BoolInputField({
    Key? key,
    required this.objKey,
    required this.initialData,
    required this.onChange,
  }) : super(key: key);

  @override
  State<_BoolInputField> createState() => _BoolInputFieldState();
}

class _BoolInputFieldState extends State<_BoolInputField> {
  late bool isChecked = widget.initialData;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.scale(
          scale: 0.75,
          child: Checkbox(
            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            value: isChecked,
            onChanged: (newValue) {
              widget.onChange(widget.objKey, newValue!);
              setState(() {
                isChecked = newValue;
              });
            },
          ),
        ),
        Text(isChecked ? 'true' : 'false'),
      ],
    );
  }
}
