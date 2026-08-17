import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/api/mealize_api.dart';
import '../theme.dart';

/// Живий статус звʼязку з BFF + підключення Сільпо (GET /api/me).
class SilpoConnectionCard extends StatefulWidget {
  const SilpoConnectionCard({super.key});
  @override
  State<SilpoConnectionCard> createState() => _SilpoConnectionCardState();
}

class _SilpoConnectionCardState extends State<SilpoConnectionCard> {
  final _api = MealizeApi.instance;
  bool _loading = true;
  bool _backendOnline = false;
  bool _silpoConnected = false;
  String? _connectUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final me = await _api.me();
      if (!mounted) return;
      setState(() {
        _backendOnline = true;
        _silpoConnected = me['silpo_connected'] == true;
        _connectUrl = me['connect_url'] as String?;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _backendOnline = false;
        _loading = false;
      });
    }
  }

  Future<void> _connect() async {
    final url = _connectUrl;
    if (url == null) return;
    await launchUrl(Uri.parse(url), webOnlyWindowName: '_blank', mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final (dotColor, label) = switch ((_loading, _backendOnline, _silpoConnected)) {
      (true, _, _) => (AppColors.muted, 'Перевірка звʼязку…'),
      (_, false, _) => (AppColors.warn, 'Бекенд офлайн · демо-режим'),
      (_, true, true) => (AppColors.green, 'Сільпо підключено · реальні дані'),
      (_, true, false) => (AppColors.amber, 'Бекенд онлайн · Сільпо не підключено'),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700))),
          IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh, size: 18, color: AppColors.muted), visualDensity: VisualDensity.compact),
        ]),
        if (_backendOnline && !_silpoConnected && _connectUrl != null) ...[
          const SizedBox(height: 8),
          const Text('Увійди в Сільпо (телефон + код), щоб меню та ціни були справжні.',
            style: TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: _connect,
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.accentInk, padding: const EdgeInsets.symmetric(vertical: 12)),
            icon: const Icon(Icons.link, size: 18),
            label: const Text('Підключити Сільпо', style: TextStyle(fontWeight: FontWeight.w800)),
          )),
        ],
      ]),
    );
  }
}
