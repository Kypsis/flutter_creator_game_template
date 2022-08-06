import 'package:creator/creator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:game_template/src/settings/settings_controller.dart';

void showCustomNameDialog(BuildContext context) {
  showGeneralDialog(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) => CustomNameDialog(animation: animation));
}

class CustomNameDialog extends HookWidget {
  final Animation<double> animation;

  const CustomNameDialog({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();

    useEffect(() {
      Future.microtask(() {
        controller.text = context.ref.read(SettingsController.playerName);
      });
      return null;
    }, []);

    return ScaleTransition(
      scale: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ),
      child: SimpleDialog(
        title: const Text('Change name'),
        children: [
          Watcher((context, ref, _) {
            return TextField(
              controller: controller,
              autofocus: true,
              maxLength: 12,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onChanged: (value) {
                SettingsController.setPlayerName(ref, name: value);
              },
              onSubmitted: (value) {
                Navigator.pop(context);
              },
            );
          }),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
