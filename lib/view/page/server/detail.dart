import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:provider/provider.dart';

import '../../../core/extension/numx.dart';
import '../../../data/model/server/dist.dart';
import '../../../data/model/server/net_speed.dart';
import '../../../data/model/server/server.dart';
import '../../../data/model/server/server_status.dart';
import '../../../data/provider/server.dart';
import '../../../data/res/color.dart';
import '../../../data/res/ui.dart';
import '../../../data/store/setting.dart';
import '../../../locator.dart';
import '../../widget/round_rect_card.dart';

class ServerDetailPage extends StatefulWidget {
  const ServerDetailPage(this.id, {Key? key}) : super(key: key);

  final String id;

  @override
  _ServerDetailPageState createState() => _ServerDetailPageState();
}

class _ServerDetailPageState extends State<ServerDetailPage>
    with SingleTickerProviderStateMixin {
  late MediaQueryData _media;
  late S _s;
  final _setting = locator<SettingStore>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _media = MediaQuery.of(context);
    _s = S.of(context)!;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ServerProvider>(builder: (_, provider, __) {
      final s = provider.servers[widget.id];
      if (s == null) {
        return Scaffold(
          body: Center(
            child: Text(_s.noClient),
          ),
        );
      }
      return _buildMainPage(s);
    });
  }

  Widget _buildMainPage(Server si) {
    return Scaffold(
      appBar: AppBar(
        title: Text(si.spi.name, style: textSize18),
      ),
      body: ListView(
        padding: const EdgeInsets.all(13),
        children: [
          _buildLinuxIcon(si.status.sysVer),
          _buildUpTimeAndSys(si.status),
          _buildNetView(si.status.netSpeed),
          _buildCPUView(si.status),
          _buildMemView(si.status),
          _buildSwapView(si.status),
          _buildDiskView(si.status),
          // avoid the hieght of navigation bar
          //_buildNetView(si.status.netSpeed),
          _buildTemperature(si.status),
          // height of navigation bar
          SizedBox(height: _media.padding.bottom),
        ],
      ),
    );
  }

  Widget _buildLinuxIcon(String sysVer) {
    if (!_setting.showDistLogo.fetch()!) return placeholder;
    final iconPath = sysVer.dist?.iconPath;
    if (iconPath == null) return placeholder;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: _media.size.height * 0.13,
        maxWidth: _media.size.width * 0.6,
      ),
      child: Image.asset(
        iconPath,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildCPUView(ServerStatus ss) {
    /*final tempWidget = ss.cpu.temp.isEmpty
        ? const SizedBox()
        : Text(
            ss.cpu.temp,
            style: textSize13Grey,
          );*/
    return RoundRectCard(
      Padding(
        padding: roundRectCardPadding,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '${ss.cpu.usedPercent(coreIdx: 0).toInt()}%',
                    style: textSize27,
                    textScaleFactor: 1.0,
                  ),
                  width7,
                  //tempWidget
                ],
              ),
              Row(
                children: [
                  _buildDetailPercent(ss.cpu.user, 'user'),
                  width13,
                  _buildDetailPercent(ss.cpu.sys, 'sys'),
                  width13,
                  _buildDetailPercent(ss.cpu.iowait, 'io'),
                  width13,
                  _buildDetailPercent(ss.cpu.idle, 'idle')
                ],
              )
            ],
          ),
          height13,
          _buildCPUProgress(ss)
        ]),
      ),
    );
  }

  Widget _buildDetailPercent(double percent, String timeType) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${percent.toStringAsFixed(1)}%',
          style: const TextStyle(fontSize: 13),
          textScaleFactor: 1.0,
        ),
        Text(
          timeType,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
          textScaleFactor: 1.0,
        ),
      ],
    );
  }

  Widget _buildCPUProgress(ServerStatus ss) {
    final children = <Widget>[];
    for (var i = 0; i < ss.cpu.coresCount; i++) {
      if (i == 0) continue;
      children.add(
        Padding(
          padding: const EdgeInsets.all(2),
          child: _buildProgress(ss.cpu.usedPercent(coreIdx: i)),
        ),
      );
    }
    return Column(children: children);
  }

  Widget _buildProgress(double percent) {
    if (percent > 100) percent = 100;
    final percentWithinOne = percent / 100;
    return LinearProgressIndicator(
      value: percentWithinOne,
      minHeight: 7,
      backgroundColor: progressColor.resolve(context),
      color: primaryColor,
    );
  }

  Widget _buildUpTimeAndSys(ServerStatus ss) {
    return RoundRectCard(
      Padding(
        padding: roundRectCardPadding,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(ss.sysVer, style: textSize11, textScaleFactor: 1.0),
            Text(
              ss.uptime,
              style: textSize11,
              textScaleFactor: 1.0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemView(ServerStatus ss) {
    final free = ss.mem.free / ss.mem.total * 100;
    final avail = ss.mem.availPercent * 100;
    final used = ss.mem.usedPercent * 100;

    return RoundRectCard(
      Padding(
        padding: roundRectCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text('${used.toStringAsFixed(0)}%', style: textSize27),
                    width7,
                    Text('of ${(ss.mem.total * 1024).convertBytes}',
                        style: textSize13Grey)
                  ],
                ),
                Row(
                  children: [
                    _buildDetailPercent(free, 'free'),
                    width13,
                    _buildDetailPercent(avail, 'avail'),
                  ],
                ),
              ],
            ),
            height13,
            _buildProgress(used)
          ],
        ),
      ),
    );
  }

  Widget _buildSwapView(ServerStatus ss) {
    if (ss.swap.total == 0) return placeholder;
    final used = ss.swap.usedPercent * 100;
    final cached = ss.swap.cached / ss.swap.total * 100;
    return RoundRectCard(
      Padding(
        padding: roundRectCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text('${used.toStringAsFixed(0)}%', style: textSize27),
                    width7,
                    Text('of ${(ss.swap.total * 1024).convertBytes} ',
                        style: textSize13Grey)
                  ],
                ),
                _buildDetailPercent(cached, 'cached'),
              ],
            ),
            height13,
            _buildProgress(used)
          ],
        ),
      ),
    );
  }

  Widget _buildDiskView(ServerStatus ss) {
    ss.disk.removeWhere((e) {
      for (final ingorePath in _setting.diskIgnorePath.fetch()!) {
        if (e.path.startsWith(ingorePath)) return true;
      }
      return false;
    });
    final children = ss.disk
        .map((disk) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${disk.usedPercent}% of ${disk.size}',
                        style: textSize11,
                        textScaleFactor: 1.0,
                      ),
                      Text(disk.path, style: textSize11, textScaleFactor: 1.0)
                    ],
                  ),
                  _buildProgress(disk.usedPercent.toDouble())
                ],
              ),
            ))
        .toList();
    return RoundRectCard(
      Padding(
        padding: roundRectCardPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }

  Widget _buildNetView(NetSpeed ns) {
    final children = <Widget>[
      _buildNetSpeedTop(),
      const Divider(
        height: 7,
      )
    ];
    if (ns.devices.isEmpty) {
      children.add(Center(
        child: Text(
          _s.noInterface,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ));
    } else {
      children.addAll(ns.devices.map((e) => _buildNetSpeedItem(ns, e)));
    }

    return RoundRectCard(
      Padding(
        padding: roundRectCardPadding,
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildNetSpeedTop() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.device_hub, size: 17),
          Icon(Icons.arrow_downward, size: 17),
          Icon(Icons.arrow_upward, size: 17),
        ],
      ),
    );
  }

  Widget _buildNetSpeedItem(NetSpeed ns, String device) {
    final width = (_media.size.width - 34 - 34) / 2.9;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: width / 1.2,
            child: Text(
              device,
              style: textSize11,
              textScaleFactor: 1.0,
            ),
          ),
          SizedBox(
            width: width,
            child: Text(
              '${ns.speedIn(device: device)} | ${ns.totalIn(device: device)}',
              style: textSize11,
              textAlign: TextAlign.center,
              textScaleFactor: 0.87,
            ),
          ),
          SizedBox(
            width: width,
            child: Text(
              '${ns.speedOut(device: device)} | ${ns.totalOut(device: device)}',
              style: textSize11,
              textAlign: TextAlign.right,
              textScaleFactor: 0.87,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTemperature(ServerStatus ss) {
    if (ss.temps.isEmpty) {
      return placeholder;
    }
    final List<Widget> children = [
      const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.device_hub, size: 17),
          Icon(Icons.arrow_downward, size: 17),
        ],
      ),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 3),
        child: Divider(height: 7),
      ),
    ];
    children.addAll(ss.temps.devices.map((key) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              key,
              style: textSize11,
              textScaleFactor: 1.0,
            ),
            Text(
              '${ss.temps.get(key)}°C',
              style: textSize11,
              textScaleFactor: 1.0,
            ),
          ],
        )));
    return RoundRectCard(Padding(
      padding: roundRectCardPadding,
      child: Column(children: children),
    ));
  }
}
