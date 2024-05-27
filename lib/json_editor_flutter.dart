library json_editor_flutter;

import 'dart:convert';
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _space = 18.0;
const _textStyle = TextStyle(fontSize: 16);
const _options = Icon(Icons.more_horiz, size: 16);
const _expandIconWidth = 10.0;
const _rowHeight = 30.0;
const _popupMenuHeight = 30.0;
const _popupMenuItemPadding = 20.0;
const _textSpacer = SizedBox(width: 5);
const _newKey = "new_key_added";
const _downArrow = SizedBox(
  width: _expandIconWidth,
  child: Icon(CupertinoIcons.arrowtriangle_down_fill, size: 14),
);
const _rightArrow = SizedBox(
  width: _expandIconWidth,
  child: Icon(CupertinoIcons.arrowtriangle_right_fill, size: 14),
);
const _newDataValue = {
  _OptionItems.string: "",
  _OptionItems.bool: false,
  _OptionItems.num: 0,
};
bool _enableMoreOptions = true;
bool _enableKeyEdit = true;
bool _enableValueEdit = true;

enum _OptionItems { map, list, string, bool, num, delete }

enum _SearchActions { next, prev }

/// Supported editors for JSON Editor.
enum Editors { tree, text }

/// JSON can be edited in two ways, UI editor or text editor. You can disable
/// either of them.
///
/// When UI editor is active, you can disable adding/deleting keys by using
/// [enableMoreOptions] and can disable key editing by using [enableKeyEdit].
///
/// When text editor is active, it will simply ignore [enableKeyEdit] and
/// [enableMoreOptions].
///
/// [duration] is the debounce time for [onChanged] function. Defaults to
/// 500 milliseconds.
///
/// [editors] is the supported list of editors. First element will be
/// used as default editor. Defaults to `[Editors.tree, Editors.text]`.
class JsonEditor extends StatefulWidget {
  /// JSON can be edited in two ways, UI editor or text editor. You can disable
  /// either of them.
  ///
  /// When UI editor is active, you can disable adding/deleting keys by using
  /// [enableMoreOptions] and can disable key editing by using [enableKeyEdit].
  ///
  /// When text editor is active, it will simply ignore [enableKeyEdit] and
  /// [enableMoreOptions].
  ///
  /// [duration] is the debounce time for [onChanged] function. Defaults to
  /// 500 milliseconds.
  ///
  /// [editors] is the supported list of editors. First element will be
  /// used as default editor. Defaults to `[Editors.tree, Editors.text]`.
  const JsonEditor({
    super.key,
    required this.json,
    required this.onChanged,
    this.duration = const Duration(milliseconds: 500),
    this.enableMoreOptions = true,
    this.enableKeyEdit = true,
    this.enableValueEdit = true,
    this.editors = const [Editors.tree, Editors.text],
    this.themeColor,
    this.actions = const [],
    this.enableHorizontalScroll = false,
    this.searchDuration = const Duration(milliseconds: 600),
    this.beforeScrollDuration = const Duration(milliseconds: 300),
  }) : assert(editors.length > 0, "editors list cannot be empty");

  /// JSON string to be edited.
  final String json;

  /// Callback function that will be called with the new [dynamic] data.
  final ValueChanged<dynamic> onChanged;

  /// Debounce duration for [onChanged] function.
  final Duration duration;

  /// Enables more options like adding or deleting data. Defaults to `true`.
  final bool enableMoreOptions;

  /// Enables editing of keys. Defaults to `true`.
  final bool enableKeyEdit;

  /// Enables editing of values. Defaults to `true`.
  final bool enableValueEdit;

  /// Theme color for the editor. Changes the border color and header color.
  final Color? themeColor;

  /// List of supported editors. First element will be used as default editor.
  final List<Editors> editors;

  /// A list of Widgets to display in a row at the end of header.
  final List<Widget> actions;

  /// Enables horizontal scroll for the tree view. Defaults to `false`.
  final bool enableHorizontalScroll;

  /// Debounce duration for search function.
  final Duration searchDuration;

  /// The [Duration] between the search and the starting of scroll animation.
  ///
  /// All the objects are expanded in order to find the correct offset position
  /// of the searched key. [beforeScrollDuration] refers to the time given for
  /// rebuilding the UI to expand all objects. Once the rebuilding is completed
  /// in the given duration, the scroll animation will work properly. If the
  /// duration provided is short you will not see the scroll animation.
  ///
  /// Play around with this property to find your suitable duration.
  /// [beforeScrollDuration] is proportional to the size of the JSON object.
  final Duration beforeScrollDuration;

  @override
  State<JsonEditor> createState() => _JsonEditorState();
}

class _JsonEditorState extends State<JsonEditor> {
  Timer? _timer;
  Timer? _searchTimer;
  late dynamic _data;
  late final _themeColor = widget.themeColor ?? Theme.of(context).primaryColor;
  late Editors _editor = widget.editors.first;
  bool _onError = false;
  bool? allExpanded;
  late final _controller = TextEditingController()
    ..text = _stringifyData(_data, 0, true);
  late final _scrollController = ScrollController();
  final _offsets = <int>[];
  final _matchedKeys = <String>[];
  int _row = 0;
  int? _currentOffsetIndex;
  int? _results;

  void callOnChanged() {
    if (_timer?.isActive ?? false) _timer?.cancel();

    _timer = Timer(widget.duration, () {
      widget.onChanged(jsonDecode(jsonEncode(_data)));
    });
  }

  void parseData(String value) {
    if (_timer?.isActive ?? false) _timer?.cancel();

    _timer = Timer(widget.duration, () {
      try {
        _data = jsonDecode(value);
        widget.onChanged(_data);
        setState(() {
          _onError = false;
        });
      } catch (_) {
        setState(() {
          _onError = true;
        });
      }
    });
  }

  void copyData() async {
    await Clipboard.setData(
      ClipboardData(text: jsonEncode(_data)),
    );
  }

  void findMatchingKeys(data, String text) {
    if (data is Map) {
      final keys = data.keys.toList();
      for (var key in keys) {
        _row++;
        if ("$key".toLowerCase().contains(text)) {
          _offsets.add(_row + 1);
          _matchedKeys.add(key.toString());
        }
        if (data[key] is Map) {
          findMatchingKeys(data[key], text);
        } else if (data[key] is List) {
          findMatchingKeys(data[key], text);
        }
      }
    } else if (data is List) {
      for (var item in data) {
        _row++;
        if (item is Map) {
          findMatchingKeys(item, text);
        } else if (item is List) {
          findMatchingKeys(item, text);
        }
      }
    }
  }

  void onSearch(String text) {
    if (_searchTimer?.isActive ?? false) _searchTimer?.cancel();

    _searchTimer = Timer(widget.searchDuration, () async {
      _offsets.clear();
      _matchedKeys.clear();
      _row = 0;
      _currentOffsetIndex = null;
      if (text.isEmpty) {
        setState(() {
          _results = null;
        });
      } else {
        findMatchingKeys(_data, text.toLowerCase());
        _results = _offsets.length;
        if (_offsets.isNotEmpty) {
          expandCollapseAll(true);
          Future.delayed(widget.beforeScrollDuration, () {
            _currentOffsetIndex = 0;
            scrollTo(_offsets.first);
          });
        } else {
          setState(() {});
        }
      }
    });
  }

  void scrollTo(int offset) {
    _scrollController.animateTo(
      (offset * _rowHeight) - 90,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  void onSearchAction(_SearchActions action) {
    if (_offsets.isEmpty) return;
    if (action == _SearchActions.next) {
      if (_currentOffsetIndex != null &&
          _offsets.length - 1 > _currentOffsetIndex!) {
        _currentOffsetIndex = _currentOffsetIndex! + 1;
      } else {
        _currentOffsetIndex = 0;
      }
    } else {
      if (_currentOffsetIndex != null && _currentOffsetIndex! > 0) {
        _currentOffsetIndex = _currentOffsetIndex! - 1;
      } else {
        _currentOffsetIndex = _offsets.length - 1;
      }
    }
    scrollTo(_offsets[_currentOffsetIndex!]);
  }

  Widget wrapWithHorizontolScroll(Widget child) {
    if (widget.enableHorizontalScroll) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: child,
      );
    }
    return child;
  }

  void expandCollapseAll(bool value) {
    setState(() {
      allExpanded = value;
    });
  }

  @override
  void initState() {
    super.initState();
    _data = jsonDecode(widget.json);
    _enableMoreOptions = widget.enableMoreOptions;
    _enableKeyEdit = widget.enableKeyEdit;
    _enableValueEdit = widget.enableValueEdit;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          width: _onError ? 2 : 1,
          color: _onError ? Colors.red : _themeColor,
        ),
      ),
      child: SizedBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                  color: _themeColor,
                  border: _onError
                      ? const Border(
                          bottom: BorderSide(color: Colors.red, width: 2),
                        )
                      : null),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 10,
                ),
                child: Row(
                  children: [
                    PopupMenuButton<Editors>(
                      initialValue: _editor,
                      tooltip: 'Change editor',
                      padding: EdgeInsets.zero,
                      onSelected: (value) {
                        if (value == Editors.text) {
                          _controller.text = _stringifyData(_data, 0, true);
                        }
                        setState(() {
                          _editor = value;
                        });
                      },
                      position: PopupMenuPosition.under,
                      enabled: widget.editors.length > 1,
                      constraints: const BoxConstraints(
                        minWidth: 50,
                        maxWidth: 150,
                      ),
                      itemBuilder: (context) {
                        return <PopupMenuEntry<Editors>>[
                          PopupMenuItem<Editors>(
                            height: _popupMenuHeight,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            enabled: widget.editors.contains(Editors.tree),
                            value: Editors.tree,
                            child: const Text("Tree"),
                          ),
                          PopupMenuItem<Editors>(
                            height: _popupMenuHeight,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            enabled: widget.editors.contains(Editors.text),
                            value: Editors.text,
                            child: const Text("Text"),
                          ),
                        ];
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_editor.name, style: _textStyle),
                          const Icon(Icons.arrow_drop_down, size: 20),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (_editor == Editors.text) ...[
                      const SizedBox(width: 20),
                      InkWell(
                        onTap: () {
                          _controller.text = _stringifyData(_data, 0, true);
                        },
                        child: const Tooltip(
                          message: 'Format',
                          child: Icon(Icons.format_align_left, size: 20),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(width: 20),
                      if (_results != null) ...[
                        Text("$_results results"),
                        const SizedBox(width: 5),
                      ],
                      _SearchField(onSearch, onSearchAction),
                      const SizedBox(width: 20),
                      InkWell(
                        onTap: () {
                          expandCollapseAll(true);
                        },
                        child: const Tooltip(
                          message: 'Expand All',
                          child: Icon(Icons.expand, size: 20),
                        ),
                      ),
                      const SizedBox(width: 20),
                      InkWell(
                        onTap: () {
                          expandCollapseAll(false);
                        },
                        child: const Tooltip(
                          message: 'Collapse All',
                          child: Icon(Icons.compress, size: 20),
                        ),
                      ),
                    ],
                    const SizedBox(width: 20),
                    InkWell(
                      onTap: copyData,
                      child: const Tooltip(
                        message: 'Copy',
                        child: Icon(Icons.copy, size: 20),
                      ),
                    ),
                    if (widget.actions.isNotEmpty) const SizedBox(width: 20),
                    ...widget.actions,
                  ],
                ),
              ),
            ),
            if (_editor == Editors.tree)
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const ClampingScrollPhysics(),
                  child: wrapWithHorizontolScroll(
                    _Holder(
                      key: UniqueKey(),
                      data: _data,
                      keyName: "object",
                      paddingLeft: _space,
                      onChanged: callOnChanged,
                      parentObject: {"object": _data},
                      setState: setState,
                      matchedKeys: _matchedKeys,
                      isExpanded: allExpanded ?? false,
                    ),
                  ),
                ),
              ),
            if (_editor == Editors.text)
              Expanded(
                child: TextFormField(
                  controller: _controller,
                  onChanged: parseData,
                  maxLines: null,
                  minLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(
                      left: 5,
                      top: 8,
                      bottom: 8,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Holder extends StatefulWidget {
  const _Holder({
    super.key,
    this.keyName,
    required this.data,
    required this.paddingLeft,
    required this.onChanged,
    required this.parentObject,
    required this.setState,
    required this.matchedKeys,
    this.isExpanded = false,
  });

  final dynamic keyName;
  final dynamic data;
  final double paddingLeft;
  final VoidCallback onChanged;
  final dynamic parentObject;
  final StateSetter setState;
  final bool isExpanded;
  final List<String> matchedKeys;

  @override
  State<_Holder> createState() => _HolderState();
}

class _HolderState extends State<_Holder> {
  late bool isExpanded = widget.isExpanded;

  void _toggleState() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }

  void onSelected(_OptionItems selectedItem) {
    if (selectedItem == _OptionItems.delete) {
      if (widget.parentObject is Map) {
        widget.parentObject.remove(widget.keyName);
      } else {
        widget.parentObject.removeAt(widget.keyName);
      }

      widget.setState(() {});
    } else if (selectedItem == _OptionItems.map) {
      if (widget.data is Map) {
        widget.data[_newKey] = {};
      } else {
        widget.data.add({});
      }

      setState(() {});
    } else if (selectedItem == _OptionItems.list) {
      if (widget.data is Map) {
        widget.data[_newKey] = [];
      } else {
        widget.data.add([]);
      }

      setState(() {});
    } else {
      if (widget.data is Map) {
        widget.data[_newKey] = _newDataValue[selectedItem];
      } else {
        widget.data.add(_newDataValue[selectedItem]);
      }

      setState(() {});
    }

    widget.onChanged();
  }

  void onKeyChanged(Object key) {
    final val = widget.parentObject.remove(widget.keyName);
    widget.parentObject[key] = val;

    widget.onChanged();
    widget.setState(() {});
  }

  void onValueChanged(Object value) {
    widget.parentObject[widget.keyName] = value;

    widget.onChanged();
  }

  Widget wrapWithColoredBox(Widget child, String key) {
    if (widget.matchedKeys.contains(key)) {
      return ColoredBox(color: Colors.amber, child: child);
    }
    return child;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data is Map) {
      final mapWidget = <Widget>[];

      final List keys = widget.data.keys.toList();
      for (var key in keys) {
        mapWidget.add(_Holder(
          key: Key(key),
          data: widget.data[key],
          keyName: key,
          onChanged: widget.onChanged,
          parentObject: widget.data,
          paddingLeft: widget.paddingLeft + _space,
          setState: setState,
          matchedKeys: widget.matchedKeys,
          isExpanded: widget.isExpanded,
        ));
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: _rowHeight,
            child: Row(
              children: [
                const SizedBox(width: _expandIconWidth),
                if (_enableMoreOptions) _Options<Map>(onSelected),
                SizedBox(width: widget.paddingLeft),
                InkWell(
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  onTap: _toggleState,
                  child: isExpanded ? _downArrow : _rightArrow,
                ),
                const SizedBox(width: _expandIconWidth),
                if (_enableKeyEdit && widget.parentObject is! List) ...[
                  _ReplaceTextWithField(
                    key: Key(widget.keyName.toString()),
                    initialValue: widget.keyName,
                    isKey: true,
                    onChanged: onKeyChanged,
                    setState: setState,
                    isHighlighted: widget.matchedKeys.contains(
                      "${widget.keyName}",
                    ),
                  ),
                  _textSpacer,
                  Text(
                    "{${widget.data.length}}",
                    style: _textStyle,
                  ),
                ] else
                  InkWell(
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    onTap: _toggleState,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        wrapWithColoredBox(
                          Text("${widget.keyName}", style: _textStyle),
                          "${widget.keyName}",
                        ),
                        _textSpacer,
                        Text("{${widget.data.length}}", style: _textStyle),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (isExpanded)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: mapWidget,
            ),
        ],
      );
    } else if (widget.data is List) {
      final listWidget = <Widget>[];

      for (int i = 0; i < widget.data.length; i++) {
        listWidget.add(_Holder(
          key: Key(i.toString()),
          keyName: i,
          data: widget.data[i],
          onChanged: widget.onChanged,
          parentObject: widget.data,
          paddingLeft: widget.paddingLeft + _space,
          setState: setState,
          matchedKeys: widget.matchedKeys,
          isExpanded: widget.isExpanded,
        ));
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: _rowHeight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: _expandIconWidth),
                if (_enableMoreOptions) _Options<List>(onSelected),
                SizedBox(width: widget.paddingLeft),
                InkWell(
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  onTap: _toggleState,
                  child: isExpanded ? _downArrow : _rightArrow,
                ),
                const SizedBox(width: _expandIconWidth),
                if (_enableKeyEdit && widget.parentObject is! List) ...[
                  _ReplaceTextWithField(
                    key: Key(widget.keyName.toString()),
                    initialValue: widget.keyName,
                    isKey: true,
                    onChanged: onKeyChanged,
                    setState: setState,
                    isHighlighted: widget.matchedKeys.contains(
                      "${widget.keyName}",
                    ),
                  ),
                  _textSpacer,
                  Text(
                    "[${widget.data.length}]",
                    style: _textStyle,
                  ),
                ] else
                  InkWell(
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    onTap: _toggleState,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        wrapWithColoredBox(
                          Text("${widget.keyName}", style: _textStyle),
                          "${widget.keyName}",
                        ),
                        _textSpacer,
                        Text("[${widget.data.length}]", style: _textStyle),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (isExpanded)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: listWidget,
            ),
        ],
      );
    } else {
      return SizedBox(
        height: _rowHeight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: _expandIconWidth),
            if (_enableMoreOptions) _Options<String>(onSelected),
            SizedBox(
              width: widget.paddingLeft + (_expandIconWidth * 2),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_enableKeyEdit) ...[
                  _ReplaceTextWithField(
                    key: Key(widget.keyName.toString()),
                    initialValue: widget.keyName,
                    isKey: true,
                    onChanged: onKeyChanged,
                    setState: setState,
                    isHighlighted: widget.matchedKeys.contains(
                      "${widget.keyName}",
                    ),
                  ),
                  const Text(' :', style: _textStyle),
                ] else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      wrapWithColoredBox(
                        Text("${widget.keyName}", style: _textStyle),
                        "${widget.keyName}",
                      ),
                      _textSpacer,
                      const Text(" :", style: _textStyle),
                    ],
                  ),
                _textSpacer,
                if (_enableValueEdit) ...[
                  _ReplaceTextWithField(
                    key: UniqueKey(),
                    initialValue: widget.data,
                    onChanged: onValueChanged,
                    setState: setState,
                  ),
                  _textSpacer,
                ] else ...[
                  Text(widget.data.toString(), style: _textStyle),
                  _textSpacer,
                ],
              ],
            ),
          ],
        ),
      );
    }
  }
}

class _ReplaceTextWithField extends StatefulWidget {
  const _ReplaceTextWithField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    required this.setState,
    this.isKey = false,
    this.isHighlighted = false,
  });

  final dynamic initialValue;
  final bool isKey;
  final ValueChanged<Object> onChanged;
  final StateSetter setState;
  final bool isHighlighted;

  @override
  State<_ReplaceTextWithField> createState() => _ReplaceTextWithFieldState();
}

class _ReplaceTextWithFieldState extends State<_ReplaceTextWithField> {
  late final _focusNode = FocusNode();
  bool _isFocused = false;
  bool _value = false;
  String _text = "";
  late final BoxConstraints _constraints;

  void handleChange() {
    if (!_focusNode.hasFocus) {
      _text = _text.trim();
      final val = num.tryParse(_text);
      if (val == null) {
        widget.onChanged(_text);
      } else {
        widget.onChanged(val);
      }

      setState(() {
        _isFocused = false;
      });
    }
  }

  Widget wrapWithColoredBox(String keyName) {
    if (widget.isHighlighted) {
      return ColoredBox(
        color: Colors.amber,
        child: Text(keyName, style: _textStyle),
      );
    }
    return Text(keyName, style: _textStyle);
  }

  @override
  void initState() {
    super.initState();

    if (widget.initialValue is bool) {
      _value = widget.initialValue;
    } else {
      if (widget.initialValue == _newKey) {
        _text = "";
        _isFocused = true;
        _focusNode.requestFocus();
      } else {
        _text = widget.initialValue.toString();
      }
    }

    if (widget.isKey) {
      _constraints = const BoxConstraints(minWidth: 20, maxWidth: 100);
    } else if (widget.initialValue is num) {
      _constraints = const BoxConstraints(minWidth: 20, maxWidth: 80);
    } else {
      _constraints = const BoxConstraints(minWidth: 20, maxWidth: 200);
    }

    _focusNode.addListener(handleChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(handleChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.initialValue is bool) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.scale(
            scale: 0.75,
            child: Checkbox(
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
              value: _value,
              onChanged: (value) {
                widget.onChanged(value!);
                setState(() {
                  _value = value;
                });
              },
            ),
          ),
          Text(_value.toString(), style: _textStyle),
        ],
      );
    } else {
      if (_isFocused) {
        return TextFormField(
          initialValue: _text,
          focusNode: _focusNode,
          onChanged: (value) => _text = value,
          autocorrect: false,
          cursorWidth: 1,
          style: _textStyle,
          cursorHeight: 12,
          decoration: InputDecoration(
            constraints: _constraints,
            border: InputBorder.none,
            fillColor: Colors.transparent,
            filled: true,
            isDense: true,
            contentPadding: const EdgeInsets.all(3),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(width: 0.3),
            ),
          ),
        );
      } else {
        return InkWell(
          onTap: () {
            setState(() {
              _isFocused = true;
            });
            _focusNode.requestFocus();
          },
          mouseCursor: MaterialStateMouseCursor.textable,
          child: widget.initialValue is String && _text.isEmpty
              ? const SizedBox(width: 200, height: 18)
              : wrapWithColoredBox(_text),
        );
      }
    }
  }
}

class _Options<T> extends StatelessWidget {
  const _Options(this.onSelected);

  final void Function(_OptionItems) onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_OptionItems>(
      tooltip: 'Add new object',
      padding: EdgeInsets.zero,
      onSelected: onSelected,
      itemBuilder: (context) {
        return <PopupMenuEntry<_OptionItems>>[
          if (T == Map)
            const _PopupMenuWidget(Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 5),
                Icon(Icons.add),
                SizedBox(width: 10),
                Text("Insert", style: TextStyle(fontSize: 14)),
              ],
            )),
          if (T == List)
            const _PopupMenuWidget(Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 5),
                Icon(Icons.add),
                SizedBox(width: 10),
                Text("Append", style: TextStyle(fontSize: 14)),
              ],
            )),
          if (T == Map || T == List) ...[
            const PopupMenuItem<_OptionItems>(
              height: _popupMenuHeight,
              padding: EdgeInsets.only(left: _popupMenuItemPadding),
              value: _OptionItems.string,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.abc),
                  SizedBox(width: 10),
                  Text("String", style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
            const PopupMenuItem<_OptionItems>(
              height: _popupMenuHeight,
              padding: EdgeInsets.only(left: _popupMenuItemPadding),
              value: _OptionItems.num,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.onetwothree),
                  SizedBox(width: 10),
                  Text("Number", style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
            const PopupMenuItem<_OptionItems>(
              height: _popupMenuHeight,
              padding: EdgeInsets.only(left: _popupMenuItemPadding),
              value: _OptionItems.bool,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded),
                  SizedBox(width: 10),
                  Text("Boolean", style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
            const PopupMenuItem<_OptionItems>(
              height: _popupMenuHeight,
              padding: EdgeInsets.only(left: _popupMenuItemPadding),
              value: _OptionItems.map,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.data_object),
                  SizedBox(width: 10),
                  Text("Object", style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
            const PopupMenuItem<_OptionItems>(
              height: _popupMenuHeight,
              padding: EdgeInsets.only(left: _popupMenuItemPadding),
              value: _OptionItems.list,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.data_array),
                  SizedBox(width: 10),
                  Text("List", style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
          const PopupMenuDivider(height: 1),
          const PopupMenuItem<_OptionItems>(
            height: _popupMenuHeight,
            padding: EdgeInsets.only(left: 5),
            value: _OptionItems.delete,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete),
                SizedBox(width: 10),
                Text("Delete", style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ];
      },
      child: _options,
    );
  }
}

class _PopupMenuWidget extends PopupMenuEntry<Never> {
  const _PopupMenuWidget(this.child);

  final Widget child;

  @override
  final double height = _popupMenuHeight;

  @override
  bool represents(_) => false;

  @override
  State<_PopupMenuWidget> createState() => _PopupMenuWidgetState();
}

class _PopupMenuWidgetState extends State<_PopupMenuWidget> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final ValueChanged<_SearchActions> onAction;

  const _SearchField(this.onChanged, this.onAction);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.grey.shade50,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 2),
          const Icon(CupertinoIcons.search, size: 20),
          const SizedBox(width: 5),
          TextField(
            onChanged: onChanged,
            autocorrect: false,
            cursorWidth: 1,
            style: _textStyle,
            cursorHeight: 12,
            decoration: const InputDecoration(
              hintText: "Search keys",
              hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
              constraints: BoxConstraints(maxWidth: 130),
              border: InputBorder.none,
              fillColor: Colors.transparent,
              filled: true,
              isDense: true,
              contentPadding: EdgeInsets.all(3),
              focusedBorder: InputBorder.none,
              hoverColor: Colors.transparent,
            ),
          ),
          const SizedBox(width: 5),
          InkWell(
            onTap: () {
              onAction(_SearchActions.next);
            },
            child: const Tooltip(
              message: 'Next',
              child: Icon(
                CupertinoIcons.arrowtriangle_down_fill,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 2),
          InkWell(
            onTap: () {
              onAction(_SearchActions.prev);
            },
            child: const Tooltip(
              message: 'Previous',
              child: Icon(
                CupertinoIcons.arrowtriangle_up_fill,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 5),
        ],
      ),
    );
  }
}

List<String> _getSpace(int count) {
  if (count == 0) return ['', '  '];

  String space = '';
  for (int i = 0; i < count; i++) {
    space += '  ';
  }
  return [space, '$space  '];
}

String _stringifyData(data, int spacing, [bool isLast = false]) {
  String str = '';
  final spaceList = _getSpace(spacing);
  final objectSpace = spaceList[0];
  final dataSpace = spaceList[1];

  if (data is Map) {
    str += '$objectSpace{';
    str += '\n';
    final keys = data.keys.toList();
    for (int i = 0; i < keys.length; i++) {
      str +=
          '$dataSpace"${keys[i]}": ${_stringifyData(data[keys[i]], spacing + 1, i == keys.length - 1)}';
      str += '\n';
    }
    str += '$objectSpace}';
    if (!isLast) str += ',';
  } else if (data is List) {
    str += '$objectSpace[';
    str += '\n';
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      if (item is Map || item is List) {
        str += _stringifyData(item, spacing + 1, i == data.length - 1);
      } else {
        str +=
            '$dataSpace${_stringifyData(item, spacing + 1, i == data.length - 1)}';
      }
      str += '\n';
    }
    str += '$objectSpace]';
    if (!isLast) str += ',';
  } else {
    if (data is String) {
      str = '"$data"';
    } else {
      str = '$data';
    }
    if (!isLast) str += ',';
  }

  return str;
}
