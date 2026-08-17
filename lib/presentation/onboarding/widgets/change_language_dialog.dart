import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../application/onboarding/app_state_cubit.dart';
import '../localization/localization_provider.dart';

class ChangeLanguageDialog extends StatefulWidget {
  const ChangeLanguageDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const ChangeLanguageDialog(),
    );
  }

  @override
  State<ChangeLanguageDialog> createState() => _ChangeLanguageDialogState();
}

class _ChangeLanguageDialogState extends State<ChangeLanguageDialog> {
  late String _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = context.read<AppStateCubit>().state.languageCode;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final languages = [
      {'code': 'en', 'key': 'lang_english', 'widgetKey': const Key('change_lang_en')},
      {'code': 'si', 'key': 'lang_sinhala', 'widgetKey': const Key('change_lang_si')},
      {'code': 'ta', 'key': 'lang_tamil', 'widgetKey': const Key('change_lang_ta')},
    ];

    return AlertDialog(
      title: Text(context.tr('change_language')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: languages.map((lang) {
          final code = lang['code'] as String;
          final isSelected = _selectedLanguage == code;
          return ListTile(
            key: lang['widgetKey'] as Key,
            title: Text(context.tr(lang['key'] as String)),
            trailing: isSelected
                ? Icon(Icons.check, color: theme.colorScheme.primary)
                : null,
            onTap: () {
              setState(() {
                _selectedLanguage = code;
              });
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        ElevatedButton(
          key: const Key('confirm_change_language'),
          onPressed: () async {
            await context.read<AppStateCubit>().setLanguage(_selectedLanguage);
            if (!context.mounted) return;
            Navigator.of(context).pop();
          },
          child: Text(context.tr('confirm')),
        ),
      ],
    );
  }
}
