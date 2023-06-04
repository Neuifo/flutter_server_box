import 'package:flutter/foundation.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:platform_device_id/platform_device_id.dart';
import 'package:toolbox/core/extension/navigator.dart';

import '../../../core/update.dart';
import '../../../core/utils/ui.dart';
import '../../../data/res/ui.dart';
import '../../../data/service/app.dart';
import '../../../data/store/setting.dart';
import '../../../locator.dart';

class RegistPage extends StatefulWidget {
  const RegistPage({Key? key}) : super(key: key);

  @override
  _RegistPageState createState() {
    return _RegistPageState();
  }
}

enum RegsitType {
  FREE(
      color: Color(0xFFFF6969),
      backgroundAlpha: 30,
      icon: "assets/icon_free.png",
      leftText: "试用版",
      midText: "3台",
      rightText: "免费"),
  MONTH(
      color: Color(0xFFFF00E5),
      backgroundAlpha: 30,
      icon: "assets/icon_month.png",
      leftText: "月会员",
      midText: "20台",
      rightText: "5元"),
  YEAR(
      color: Color(0xFF03CEFB),
      backgroundAlpha: 30,
      icon: "assets/icon_year.png",
      leftText: "年会员",
      midText: "50台",
      rightText: "30元"),
  LIFE(
      color: Color(0xFF00FF38),
      backgroundAlpha: 30,
      icon: "assets/icon_life.png",
      leftText: "终身会员",
      midText: "无限制",
      rightText: "99元"),
  ;

  const RegsitType({
    required this.color,
    required this.backgroundAlpha,
    required this.icon,
    required this.leftText,
    required this.midText,
    required this.rightText,
  });

  final Color color;
  final int backgroundAlpha;
  final String icon;
  final String leftText;
  final String midText;
  final String rightText;
}

class _RegistPageState extends State<RegistPage> {
  late S _s;
  late MediaQueryData _media;
  late String inputRegisterCode;
  final _setting = locator<SettingStore>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _s = S.of(context)!;
    _media = MediaQuery.of(context);
  }

  void updateCurrentStatus() {
    setState(() {});
  }

  @override
  void initState() {
    inputRegisterCode =
        _setting.registed.fetch()! ? _setting.registKey.fetch()! : "";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_s.subscribe),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        children: [
          _buildTitle(),
          _buildRegistTypeRow(RegsitType.FREE),
          _buildRegistTypeRow(RegsitType.MONTH),
          _buildRegistTypeRow(RegsitType.YEAR),
          _buildRegistTypeRow(RegsitType.LIFE),
          const SizedBox(height: 37),
          _buildRegistButton(),
        ],
      ),
    );
  }

  SizedBox _buildTitleText(double width, String text, TextAlign align) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: const TextStyle(),
        textAlign: align,
        textScaleFactor: 1.0,
      ),
    );
  }

  Widget _buildTitle() {
    final width = (_media.size.width) / 3;
    return Padding(
      padding: const EdgeInsets.only(top: 23, bottom: 17),
      child: Center(
        child: SelectionArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            textDirection: TextDirection.ltr,
            children: <Widget>[
              _buildTitleText(width * 0.7, _s.titleTry, TextAlign.center),
              _buildTitleText(width * 1.3, _s.maxServices, TextAlign.center),
              _buildTitleText(width * 0.7, _s.price, TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBodyText(
      double width, String text, Color textColor, TextAlign align) {
    return SizedBox(
      width: width,
      height: 60,
      child: Text(
        text,
        style: TextStyle(color: textColor),
        textAlign: align,
        textScaleFactor: 1.0,
      ),
    );
  }

  Widget _buildBodyIconText(double width, String iconFile, String text,
      Color textColor, TextAlign align) {
    return SizedBox(
      width: width,
      height: 100,
      child: Column(
        children: [
          Image.asset(iconFile, width: 50, height: 50, fit: BoxFit.cover),
          const SizedBox(height: 10),
          Text(
            text,
            style: TextStyle(color: textColor),
            textAlign: align,
            textScaleFactor: 1.0,
          )
        ],
      ),
    );
  }

  Widget _buildRegistTypeRow(RegsitType regsitType) {
    //final width = (_media.size.width - 34 - 34) / 3;
    final width = (_media.size.width) / 3;
    return Stack(
        //alignment:new Alignment(x, y)
        children: <Widget>[
          Container(
              color: regsitType.color.withAlpha(regsitType.backgroundAlpha),
              child: Padding(
                padding: const EdgeInsets.only(top: 23, bottom: 17),
                child: Center(
                  child: SelectionArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      textDirection: TextDirection.ltr,
                      children: <Widget>[
                        _buildBodyIconText(
                            width * 0.7,
                            regsitType.icon,
                            regsitType.leftText,
                            regsitType.color,
                            TextAlign.center),
                        _buildBodyText(width * 1.3, regsitType.midText,
                            regsitType.color, TextAlign.center),
                        _buildBodyText(width * 0.7, regsitType.rightText,
                            regsitType.color, TextAlign.center),
                      ],
                    ),
                  ),
                ),
              )),
          Positioned(
            left: width / 3,
            top: 15,
            child: _warpVisibilityView(
                _setting.registType.fetch()! == (regsitType.index),
                const Icon(Icons.done,
                    size: 35.0, color: Color.fromRGBO(205, 30, 30, 1.0))),
          )
        ]);
  }

  Widget _warpVisibilityView(bool flag, Widget children) {
    return Visibility(
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      visible: flag,
      child: children,
    );
  }

  Widget _buildRegistButton() {
    return _warpVisibilityView(
        _setting.registType.fetch()! != 3,
        Padding(
          padding: const EdgeInsets.only(left: 23, right: 17),
          child: OutlinedButton(
              //style: ButtonStyle(padding: const EdgeInsets.fromLTRB(left:0,top:0,right:0,bottom:0)),
              onPressed: () {
                inputCode();
              },
              child: Text(_s.inputCode, style: TextStyle())),
        ));
  }

  Widget _buildRegistBody() {
    return TextFormField(
      initialValue:
          _setting.registed.fetch()! ? _setting.registKey.fetch()! : "",
      cursorColor: Colors.blue,
      cursorRadius: Radius.circular(10),
      cursorWidth: 2,
      showCursor: true,
      //controller: _controller,
      //focusNode: _focusNode,
      //obscuringCharacter: "-",
      //obscureText: true,
      decoration: InputDecoration(
          isCollapsed: false,
          labelText: _s.registryCode,
          helperText: "",
          counterText: "",
          contentPadding: EdgeInsets.all(10),
          focusedBorder:
              OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
          border:
              OutlineInputBorder(borderSide: BorderSide(color: Colors.red))),
      /*onSubmitted: (str) {
        print('_TextFieldViewState.buildView--$str');
      },*/
      textInputAction: TextInputAction.search,
      onChanged: (content) {
        //print('_TextFieldViewState.buildView-changed:$content');
        inputRegisterCode = content;
      },
    );
  }

  void showErrorDialog(String errorText) {
    showRoundDialog(
      context: context,
      child: Text(errorText),
      actions: [
        TextButton(
          onPressed: () {
            context.pop();
          },
          child: Text(_s.ok),
        )
      ],
    );
  }

  Future<void> regist() async {
    if (inputRegisterCode.isEmpty) {
      showErrorDialog(_s.illegalCode);
      return;
    }
    showRoundDialog(
      context: context,
      child: const SizedBox(
        height: 50,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      actions: [],
    );
    String? id = await PlatformDeviceId.getDeviceId;
    try {
      final registInfo =
          await locator<AppService>().getRegist(id, inputRegisterCode);
      if (await handleRegistInfo(context, registInfo, inputRegisterCode)) {
        //regist success
        context.pop();
      } else {
        //regist failed
        showErrorDialog(_s.illegalCode);
      }
      context.pop();
    } catch (e) {
      context.pop();
      showErrorDialog(_s.illegalCode);
    }
    updateCurrentStatus();
    //context.pop();
  }

  void inputCode() {
    showRoundDialog(
      context: context,
      child: _buildRegistBody(),
      actions: [
        TextButton(
          onPressed: () {
            regist();
          },
          child: Text(_s.regist),
        )
      ],
    );
  }
}
