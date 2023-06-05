import 'dart:async';
import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_highlight/theme_map.dart';
import 'package:flutter_highlight/themes/monokai.dart';
import 'package:toolbox/core/extension/navigator.dart';
import 'package:toolbox/core/utils/misc.dart';
import 'package:toolbox/data/res/highlight.dart';
import 'package:toolbox/data/store/setting.dart';
import 'package:toolbox/locator.dart';

import '../widget/two_line_text.dart';

class EditorPage extends StatefulWidget {
  final String? path;
  const EditorPage({Key? key, this.path}) : super(key: key);

  @override
  _EditorPageState createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> with AfterLayoutMixin {
  late CodeController _controller;
  late final _focusNode = FocusNode();
  final _setting = locator<SettingStore>();
  late Map<String, TextStyle> _codeTheme;
  late S _s;
  late String? _langCode;

  @override
  void initState() {
    super.initState();
    _langCode = widget.path.highlightCode;
    _controller = CodeController(
      language: suffix2HighlightMap[_langCode],
    );
    _codeTheme = themeMap[_setting.editorTheme.fetch()] ?? monokaiTheme;
    _focusNode.requestFocus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _s = S.of(context)!;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _codeTheme['root']!.backgroundColor,
      appBar: AppBar(
        title: TwoLineText(up: getFileName(widget.path) ?? '', down: _s.editor),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: (value) {
              _controller.language = suffix2HighlightMap[value];
              _langCode = value;
            },
            initialValue: _langCode,
            itemBuilder: (BuildContext context) {
              return suffix2HighlightMap.keys.map((e) {
                return PopupMenuItem(
                  value: e,
                  child: Text(e),
                );
              }).toList();
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: CodeTheme(
          data: CodeThemeData(styles: _codeTheme),
          child: CodeField(
            focusNode: _focusNode,
            controller: _controller,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.done),
        onPressed: () {
          context.pop(_controller.text);
        },
      ),
    );
  }

  @override
  FutureOr<void> afterFirstLayout(BuildContext context) async {
    if (widget.path != null) {
      await Future.delayed(const Duration(milliseconds: 233));
      final code = await File(widget.path!).readAsString();
      setState(() {
        _controller.text = code;
      });
    }
  }
}
