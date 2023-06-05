import 'package:after_layout/after_layout.dart';
import 'package:circle_chart/circle_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:toolbox/core/extension/navigator.dart';
import 'package:toolbox/core/extension/order.dart';
import 'package:toolbox/core/utils/misc.dart';
import 'package:toolbox/data/model/server/disk.dart';
import 'package:toolbox/data/model/server/net_speed.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:toolbox/view/page/server/regist.dart';
import 'package:toolbox/view/widget/fade_in.dart';

import '../../../core/route.dart';
import '../../../core/utils/ui.dart';
import '../../../data/model/server/server.dart';
import '../../../data/model/server/server_private_info.dart';
import '../../../data/model/server/server_status.dart';
import '../../../data/provider/server.dart';
import '../../../data/res/color.dart';
import '../../../data/model/app/menu.dart';
import '../../../data/res/ui.dart';
import '../../../data/res/url.dart';
import '../../../data/store/setting.dart';
import '../../../locator.dart';
import '../../widget/popup_menu.dart';
import '../../widget/round_rect_card.dart';
import '../../widget/url_text.dart';
import '../../widget/utils.dart';
import '../docker.dart';
import '../pkg.dart';
import '../sftp/remote.dart';
import '../ssh.dart';
import 'detail.dart';
import 'edit.dart';

class ServerPage extends StatefulWidget {
  const ServerPage({Key? key}) : super(key: key);

  @override
  _ServerPageState createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage>
    with AutomaticKeepAliveClientMixin, AfterLayoutMixin {
  late MediaQueryData _media;
  late ThemeData _theme;
  late ServerProvider _serverProvider;
  late SettingStore _settingStore;
  late S _s;

  String? _tag;

  @override
  void initState() {
    super.initState();
    _serverProvider = locator<ServerProvider>();
    _settingStore = locator<SettingStore>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _media = MediaQuery.of(context);
    _theme = Theme.of(context);
    _s = S.of(context)!;
  }

  void checkLimitService(Server server) {
    final size = _settingStore.maxServers.fetch()!;
    if (_serverProvider.serverOrder.indexOf(server.spi.id) < size) {
      AppRoute(
        ServerDetailPage(server.spi.id),
        'server detail page',
      ).go(context);
    } else {
      handleEdit(context);
    }
  }

  void handleEdit(BuildContext context) {
    int maxServices = _settingStore.maxServers.fetch()!;
    if (_serverProvider.serverOrder.length >= maxServices) {
      showRoundDialog(
        context: context,
        child: Text(_s.unregister_info(maxServices)),
        actions: [
          TextButton(
            onPressed: () => {Navigator.of(context).pop()},
            child: Text(_s.keep_use),
          ),
          TextButton(
            onPressed: () => {
              AppRoute(
                const RegistPage(),
                'subscribe',
              ).go(context)
            },
            child: Text(_s.buyService),
          )
        ],
      );
    } else {
      AppRoute(
        const ServerEditPage(),
        'Add server info page',
      ).go(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: _buildBody(),
      floatingActionButtonLocation:
          const CustomDockedFloatingActionButtonLocation(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => handleEdit(context),
        tooltip: _s.addAServer,
        heroTag: 'server',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: () async =>
          await _serverProvider.refreshData(onlyFailed: true),
      child: Consumer<ServerProvider>(
        builder: (_, pro, __) {
          if (!pro.tags.contains(_tag)) {
            _tag = null;
          }
          if (pro.serverOrder.isEmpty) {
            return Center(
              child: Text(
                _s.serverTabEmpty,
                textAlign: TextAlign.center,
              ),
            );
          }
          final filtered = pro.serverOrder
              .where((e) => pro.servers.containsKey(e))
              .where((e) =>
                  _tag == null ||
                  (pro.servers[e]?.spi.tags?.contains(_tag) ?? false))
              .toList();
          return ReorderableListView.builder(
            header: _buildTagsSwitcher(pro.tags),
            padding: const EdgeInsets.fromLTRB(7, 10, 7, 7),
            onReorder: (oldIndex, newIndex) => setState(() {
              pro.serverOrder.moveById(
                filtered[oldIndex],
                filtered[newIndex],
                _settingStore.serverOrder,
              );
            }),
            itemBuilder: (_, index) => _buildEachServerCard(
              pro.servers[filtered[index]],
              index,
            ),
            itemCount: filtered.length,
          );
        },
      ),
    );
  }

  Widget _buildTagsSwitcher(List<String> tags) {
    if (tags.isEmpty) return placeholder;
    final items = <String?>[null, ...tags];
    return Container(
      height: 37,
      width: _media.size.width,
      alignment: Alignment.center,
      color: Colors.transparent,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) => _buildTagItem(items[index]),
        itemCount: items.length,
      ),
    );
  }

  Widget _buildTagItem(String? tag) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 5, bottom: 9),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _tag = tag;
          });
        },
        child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(20.0)),
              color: primaryColor.withAlpha(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 2.7),
            child: Center(
              child: Text(
                tag == null ? _s.all : '#$tag',
                style: TextStyle(
                  color: _tag == tag ? null : _theme.disabledColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )),
      ),
    );
  }

  Widget _buildEachServerCard(Server? si, int index) {
    if (si == null) {
      return placeholder;
    }
    return GestureDetector(
      key: Key(si.spi.id + (_tag ?? '')),
      onTap: () => checkLimitService(si),
      child: RoundRectCard(
        Padding(
          padding: const EdgeInsets.all(13),
          child: _buildRealServerCard(si.status, si.state, si.spi),
        ),
      ),
    );
  }

  Widget _buildRealServerCard(
    ServerStatus serverStatus,
    ServerState serverState,
    ServerPrivateInfo serverPri,
  ) {
    final rootDisk =
        serverStatus.disk.firstWhere((element) => element.loc == '/');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildServerCardTitle(serverStatus, serverState, serverPri),
        const SizedBox(height: 17),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildPercentCircle(serverStatus.cpu.usedPercent()),
            _buildPercentCircle(serverStatus.mem.usedPercent * 100),
            _buildSpeedData(serverStatus.netSpeed),
            _buildDiskData(rootDisk),
          ],
        ),
        const SizedBox(height: 13),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildExplainText('CPU'),
            _buildExplainText('Mem'),
            _buildExplainText('Net'),
            _buildExplainText('Disk'),
          ],
        ),
        const SizedBox(height: 3),
      ],
    );
  }

  Widget _buildServerCardTitle(
    ServerStatus ss,
    ServerState cs,
    ServerPrivateInfo spi,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                spi.name,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                textScaleFactor: 1.0,
              ),
              const Icon(
                Icons.keyboard_arrow_right,
                size: 17,
                color: Colors.grey,
              )
            ],
          ),
          Row(
            children: [
              _buildTopRightText(ss, cs),
              width7,
              _buildSSHBtn(spi),
              _buildMoreBtn(spi),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTopRightText(ServerStatus ss, ServerState cs) {
    final topRightStr = _getTopRightStr(
      cs,
      ss.temps.first,
      ss.uptime,
      ss.failedInfo,
    );
    final hasError = cs == ServerState.failed && ss.failedInfo != null;
    return hasError
        ? GestureDetector(
            onTap: () => showRoundDialog(
              context: context,
              title: Text(_s.error),
              child: Text(ss.failedInfo ?? _s.unknownError),
              actions: [
                TextButton(
                  onPressed: () =>
                      copy2Clipboard(ss.failedInfo ?? _s.unknownError),
                  child: Text(_s.copy),
                )
              ],
            ),
            child: Text(
              _s.viewErr,
              style: textSize12Grey,
              textScaleFactor: 1.0,
            ),
          )
        : Text(
            topRightStr,
            style: textSize12Grey,
            textScaleFactor: 1.0,
          );
  }

  Widget _buildSSHBtn(ServerPrivateInfo spi) {
    return GestureDetector(
      child: const Icon(
        Icons.terminal,
        size: 21,
      ),
      onTap: () async {
        AppRoute(SSHPage(spi: spi), 'ssh page').go(context);
        /*if (_settingStore.firstTimeUseSshTerm.fetch()!) {
          await showRoundDialog(
            context: context,
            child: UrlText(
              text: _s.sshTip(issueUrl),
              replace: 'Github Issue',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _settingStore.firstTimeUseSshTerm.put(false);
                  context.pop();
                  AppRoute(SSHPage(spi: spi), 'ssh page').go(context);
                },
                child: Text(_s.ok),
              )
            ],
          );
        } else {
          AppRoute(SSHPage(spi: spi), 'ssh page').go(context);
        }*/
      },
    );
  }

  Widget _buildMoreBtn(ServerPrivateInfo spi) {
    return PopupMenu(
      items: ServerTabMenuType.values.map((e) => e.build(_s)).toList(),
      onSelected: (ServerTabMenuType value) {
        switch (value) {
          case ServerTabMenuType.pkg:
            AppRoute(PkgManagePage(spi), 'pkg manage').go(context);
            break;
          case ServerTabMenuType.sftp:
            AppRoute(SFTPPage(spi), 'SFTP').go(context);
            break;
          case ServerTabMenuType.snippet:
            showSnippetDialog(context, _s, (s) async {
              final result = await _serverProvider.runSnippet(spi.id, s);
              showRoundDialog(
                context: context,
                child: Text(result ?? _s.error, style: textSize13),
                actions: [
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text(_s.ok),
                  )
                ],
              );
            });
            break;
          case ServerTabMenuType.edit:
            AppRoute(ServerEditPage(spi: spi), 'Edit server info').go(context);
            break;
          case ServerTabMenuType.docker:
            AppRoute(DockerManagePage(spi), 'Docker manage').go(context);
            break;
        }
      },
    );
  }

  Widget _buildExplainText(String text) {
    return SizedBox(
      width: _media.size.width * 0.2,
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
        textAlign: TextAlign.center,
        textScaleFactor: 1.0,
      ),
    );
  }

  String _getTopRightStr(
    ServerState cs,
    double? temp,
    String upTime,
    String? failedInfo,
  ) {
    switch (cs) {
      case ServerState.disconnected:
        return _s.disconnected;
      case ServerState.connected:
        final tempStr = temp == null ? '' : '${temp.toStringAsFixed(1)}°C';
        final items = [tempStr, upTime];
        final str = items.where((element) => element.isNotEmpty).join(' | ');
        if (str.isEmpty) return _s.serverTabLoading;
        return str;
      case ServerState.connecting:
        return _s.serverTabConnecting;
      case ServerState.failed:
        if (failedInfo == null) {
          return _s.serverTabFailed;
        }
        if (failedInfo.contains('encypted')) {
          return _s.serverTabPlzSave;
        }
        return failedInfo;
      default:
        return _s.serverTabUnkown;
    }
  }

  Widget _buildSpeedData(NetSpeed netSpeed) {
    final statusTextStyle = TextStyle(
      fontSize: 8,
      color: _theme.textTheme.bodyLarge!.color!.withAlpha(177),
    );
    double inSpeed = 0;
    double outSpeed = 0;
    for (var e in netSpeed.devices) {
      inSpeed += netSpeed.getSpeedIn(device: e);
      outSpeed += netSpeed.getSpeedOut(device: e);
    }
    if (inSpeed.isInfinite || inSpeed.isNaN) {
      inSpeed = 0;
    }

    if (outSpeed.isInfinite || outSpeed.isNaN) {
      outSpeed = 0;
    }

    return SizedBox(
      width: _media.size.width * 0.2,
      child: Stack(
        children: [
          Center(child: getChart(inSpeed, outSpeed)),
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  // <-- TextButton
                  onPressed: () {},
                  icon: Icon(
                    Icons.arrow_downward,
                    size: 10.0,
                  ),
                  style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                      iconColor: Colors.red,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: Alignment.centerLeft),
                  label: Text(
                    "${inSpeed / 1024 ~/ 1024}Mb/s",
                    style: statusTextStyle,
                  ),
                ),
                TextButton.icon(
                  // <-- TextButton
                  onPressed: () {},
                  icon: Icon(
                    Icons.arrow_upward,
                    size: 10.0,
                  ),
                  style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                      iconColor: Colors.green,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: Alignment.centerLeft),
                  label: Text(
                    "${outSpeed / 1024 ~/ 1024}Mb/s",
                    style: statusTextStyle,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDiskData(Disk diskInfo) {
    final statusTextStyle = TextStyle(
        fontSize: 9, color: _theme.textTheme.bodyLarge!.color!.withAlpha(177));
    return SizedBox(
      width: _media.size.width * 0.2,
      child: Stack(
        children: [
          Center(
              child: getChart(diskInfo.usedPercent.toDouble(),
                  100 - diskInfo.usedPercent.toDouble())),
          Positioned.fill(
            child: Center(
              child: Text(
                "Total:${diskInfo.size}\nUsed:${diskInfo.usedPercent}%",
                textAlign: TextAlign.center,
                style: statusTextStyle,
                textScaleFactor: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentCircle(double percent) {
    if (percent <= 0) percent = 0.01;
    if (percent >= 100) percent = 99.9;
    return SizedBox(
      width: _media.size.width * 0.2,
      child: Stack(
        children: [
          Center(child: getChart(percent, 100 - percent)),
          Positioned.fill(
            child: Center(
              child: Text(
                '${percent.toStringAsFixed(1)}%',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11),
                textScaleFactor: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  PieChart getChart(double first, double second) {
    return PieChart(
      dataMap: {"1": first, "2": second},
      animationDuration: Duration(milliseconds: 800),
      chartLegendSpacing: 32,
      chartRadius: MediaQuery.of(context).size.width / 3.2,
      colorList: const [
        Colors.red,
        Color.fromRGBO(129, 250, 112, 1),
      ],
      initialAngleInDegree: 0,
      chartType: ChartType.ring,
      ringStrokeWidth: 5,
      centerText: "",
      legendOptions: LegendOptions(
        showLegendsInRow: false,
        legendPosition: LegendPosition.bottom,
        showLegends: false,
        legendShape: BoxShape.circle,
        legendTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      chartValuesOptions: ChartValuesOptions(
        showChartValueBackground: false,
        showChartValues: false,
        showChartValuesInPercentage: false,
        showChartValuesOutside: false,
        decimalPlaces: 1,
      ),
      // gradientList: ---To add gradient colors---
      // emptyColorGradient: ---Empty Color gradient---
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Future<void> afterFirstLayout(BuildContext context) async {
    await GetIt.I.allReady();
    if (_serverProvider.servers.isEmpty) {
      await _serverProvider.loadLocalData();
    }
    _serverProvider.startAutoRefresh();
  }
}
