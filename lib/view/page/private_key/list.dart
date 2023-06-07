import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:provider/provider.dart';

import '../../../core/route.dart';
import '../../../data/provider/private_key.dart';
import '../../../data/res/ui.dart';
import '../../widget/utils.dart';
import 'edit.dart';
import '../../../view/widget/round_rect_card.dart';

class PrivateKeysListPage extends StatefulWidget {
  const PrivateKeysListPage({Key? key}) : super(key: key);

  @override
  _PrivateKeyListState createState() => _PrivateKeyListState();
}

class _PrivateKeyListState extends State<PrivateKeysListPage> {
  late S _s;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _s = S.of(context)!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_s.privateKey, style: textSize18),
      ),
      body: _buildBody(),
      floatingActionButtonLocation:
          const CustomDockedFloatingActionButtonLocation(),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => AppRoute(
          const PrivateKeyEditPage(),
          'private key edit page',
        ).go(context),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<PrivateKeyProvider>(
      builder: (_, key, __) {
        if (key.infos.isEmpty) {
          return Center(
            child: Text(_s.noSavedPrivateKey),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(13),
          itemCount: key.infos.length,
          itemBuilder: (context, idx) {
            return RoundRectCard(
              ListTile(
                title: Text(key.infos[idx].id),
                trailing: TextButton(
                  onPressed: () => AppRoute(
                    PrivateKeyEditPage(info: key.infos[idx]),
                    'private key edit page',
                  ).go(context),
                  child: Text(_s.edit),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
