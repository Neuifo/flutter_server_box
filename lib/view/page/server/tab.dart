import 'package:after_layout/after_layout.dart';
import 'package:circle_chart/circle_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:toolbox/core/extension/navigator.dart';
import 'package:toolbox/core/utils/misc.dart';
import 'package:toolbox/data/model/server/disk_info.dart';
import 'package:toolbox/data/model/server/net_speed.dart';
import 'package:pie_chart/pie_chart.dart';

import '../../../core/route.dart';
import '../../../core/utils/ui.dart';
import '../../../data/model/server/server.dart';
import '../../../data/model/server/server_private_info.dart';
import '../../../data/model/server/server_status.dart';
import '../../../data/provider/server.dart';
import '../../../data/res/color.dart';
import '../../../data/res/menu.dart';
import '../../../data/res/ui.dart';
import '../../../data/res/url.dart';
import '../../../data/store/setting.dart';
import '../../../locator.dart';
import '../../widget/dropdown_menu.dart';
import '../../widget/popup_menu.dart';
import '../../widget/round_rect_card.dart';
import '../../widget/url_text.dart';
import '../docker.dart';
import '../pkg.dart';
import '../sftp/view.dart';
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AppRoute(
          const ServerEditPage(),
          'Add server info page',
        ).go(context),
        tooltip: _s.addAServer,
        heroTag: 'server page fab',
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
          if (pro.serverOrder.isEmpty) {
            return Center(
              child: Text(
                _s.serverTabEmpty,
                textAlign: TextAlign.center,
              ),
            );
          }
          return ReorderableListView(
            padding: const EdgeInsets.fromLTRB(7, 10, 7, 7),
            physics: const AlwaysScrollableScrollPhysics(),
            onReorder: (oldIndex, newIndex) => setState(() {
              pro.serverOrder.move(oldIndex, newIndex);
            }),
            children: pro.serverOrder
                .where((e) => pro.servers.containsKey(e))
                .map((e) => _buildEachServerCard(pro.servers[e]))
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildEachServerCard(Server? si) {
    if (si == null) {
      return const SizedBox();
    }
    return RoundRectCard(
      GestureDetector(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: _buildRealServerCard(si.status, si.state, si.spi),
        ),
        onTap: () => AppRoute(
          ServerDetailPage(si.spi.id),
          'server detail page',
        ).go(context),
      ),
      key: Key(si.spi.id),
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
        const SizedBox(
          height: 17,
        ),
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
    final topRightStr =
        getTopRightStr(cs, ss.cpu.temp, ss.uptime, ss.failedInfo);
    final hasError = cs == ServerState.failed && ss.failedInfo != null;
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
              hasError
                  ? GestureDetector(
                      onTap: () => showRoundDialog(
                        context: context,
                        title: Text(_s.error),
                        child: Text(ss.failedInfo ?? _s.unknownError),
                        actions: [
                          TextButton(
                            onPressed: () => copy2Clipboard(
                                ss.failedInfo ?? _s.unknownError),
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
                    ),
              const SizedBox(width: 9),
              _buildSSHBtn(spi),
              _buildMoreBtn(spi),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSSHBtn(ServerPrivateInfo spi) {
    return GestureDetector(
      child: const Icon(
        Icons.terminal,
        size: 21,
      ),
      onTap: () async {
        if (_settingStore.firstTimeUseSshTerm.fetch()!) {
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
        }
      },
    );
  }

  Widget _buildMoreBtn(ServerPrivateInfo spi) {
    return PopupMenu(
      items: <PopupMenuEntry>[
        ...ServerTabMenuItems.firstItems.map(
          (item) => PopupMenuItem<DropdownBtnItem>(
            value: item,
            child: item.build(_s),
          ),
        ),
        const PopupMenuDivider(height: 1),
        ...ServerTabMenuItems.secondItems.map(
          (item) => PopupMenuItem<DropdownBtnItem>(
            value: item,
            child: item.build(_s),
          ),
        ),
      ],
      onSelected: (value) {
        switch (value as DropdownBtnItem) {
          case ServerTabMenuItems.pkg:
            AppRoute(PkgManagePage(spi), 'pkg manage').go(context);
            break;
          case ServerTabMenuItems.sftp:
            AppRoute(SFTPPage(spi), 'SFTP').go(context);
            break;
          case ServerTabMenuItems.snippet:
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
          case ServerTabMenuItems.edit:
            AppRoute(ServerEditPage(spi: spi), 'Edit server info').go(context);
            break;
          case ServerTabMenuItems.docker:
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

  String getTopRightStr(
      ServerState cs, String temp, String upTime, String? failedInfo) {
    switch (cs) {
      case ServerState.disconnected:
        return _s.disconnected;
      case ServerState.connected:
        if (temp == '') {
          if (upTime == '') {
            return _s.serverTabLoading;
          } else {
            return upTime;
          }
        } else {
          if (upTime == '') {
            return temp;
          } else {
            return '$temp | $upTime';
          }
        }
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

  Widget _buildDiskData(DiskInfo diskInfo) {
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
