import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../theme.dart';
import '../data/api/mealize_api.dart';

/// Голосова помічниця «Зоряна» — чат: текст, голос (STT) і чіпи-підказки.
const assistantName = 'Зоряна';

void showAssistant(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const _AssistantSheet(),
  );
}

class _Msg {
  final String text;
  final bool fromUser;
  const _Msg(this.text, this.fromUser);
}

class _AssistantSheet extends StatefulWidget {
  const _AssistantSheet();
  @override
  State<_AssistantSheet> createState() => _AssistantSheetState();
}

class _AssistantSheetState extends State<_AssistantSheet> {
  final _api = MealizeApi();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _stt = SpeechToText();

  final _messages = <_Msg>[const _Msg('Привіт! Що готуємо цього тижня?', false)];
  bool _sending = false;
  bool _sttReady = false;
  bool _listening = false;

  static const _suggestions = [
    'Склади меню на тиждень на 2000 грн',
    'Порахуй калорії цього обіду',
    'Заміни вечерю на щось дешевше',
    'Додай масло в список покупок',
  ];

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {})); // перемикання іконки мікрофон↔надіслати
    _stt.initialize(onError: (_) {}, onStatus: (s) {
      if (s == 'done' || s == 'notListening') {
        if (mounted) setState(() => _listening = false);
      }
    }).then((ok) {
      if (mounted) setState(() => _sttReady = ok);
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _stt.stop();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final msg = text.trim();
    if (msg.isEmpty || _sending) return;
    _input.clear();
    setState(() {
      _messages.add(_Msg(msg, true));
      _sending = true;
    });
    _scrollDown();
    try {
      final reply = await _api.assistant(msg);
      setState(() => _messages.add(_Msg(reply.isEmpty ? 'Вибач, не зрозуміла.' : reply, false)));
    } on ApiException catch (e) {
      setState(() => _messages.add(_Msg('Зоряна недоступна: ${e.message}', false)));
    } catch (_) {
      setState(() => _messages.add(const _Msg('Бекенд недоступний. Перевір, що сервер запущено.', false)));
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollDown();
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _toggleMic() async {
    if (!_sttReady) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Голос недоступний у цьому браузері — напиши текстом 🙂')));
      return;
    }
    if (_listening) {
      await _stt.stop();
      setState(() => _listening = false);
      return;
    }
    setState(() => _listening = true);
    await _stt.listen(
      listenOptions: SpeechListenOptions(localeId: 'uk_UA'),
      onResult: (r) {
        setState(() => _input.text = r.recognizedWords);
        if (r.finalResult && r.recognizedWords.trim().isNotEmpty) {
          _send(r.recognizedWords);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.82;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: height,
        child: Column(children: [
          // Handle
          Padding(padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(4)))),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
            child: Row(children: [
              Container(width: 44, height: 44,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  gradient: const RadialGradient(center: Alignment(-0.3, -0.3), radius: 0.9, colors: [Color(0xFF4FD08A), AppColors.accent]),
                  boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.35), blurRadius: 16, spreadRadius: 1)]),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text(assistantName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                Text(_listening ? 'Слухаю…' : (_sending ? 'Друкує…' : 'Онлайн'),
                  style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
              ]),
            ]),
          ),
          const Divider(height: 1, color: AppColors.line),
          // Messages
          Expanded(child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            itemCount: _messages.length,
            itemBuilder: (c, i) => _bubble(_messages[i]),
          )),
          // Suggestions (тільки поки діалог короткий)
          if (_messages.length <= 2)
            SizedBox(height: 42, child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _suggestions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (c, i) => GestureDetector(
                onTap: () => _send(_suggestions[i]),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.line)),
                  child: Text(_suggestions[i], style: const TextStyle(fontSize: 12.5, color: AppColors.text)),
                ),
              ),
            )),
          // Input
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Row(children: [
              Expanded(child: CupertinoTextField(
                controller: _input,
                placeholder: 'Напиши або натисни мікрофон…',
                onSubmitted: _send,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                style: const TextStyle(color: AppColors.text, fontSize: 14.5),
                placeholderStyle: const TextStyle(color: AppColors.muted, fontSize: 14.5),
                decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(22)),
              )),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _sending ? null : (_input.text.trim().isNotEmpty ? () => _send(_input.text) : _toggleMic),
                child: Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: _listening ? AppColors.warn : AppColors.accent, shape: BoxShape.circle),
                  child: Icon(
                    _input.text.trim().isNotEmpty ? Icons.send : (_listening ? Icons.stop : Icons.mic),
                    color: AppColors.accentInk, size: 24),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _bubble(_Msg m) {
    return Align(
      alignment: m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: m.fromUser ? AppColors.accent : AppColors.surface2,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(m.fromUser ? 16 : 4), bottomRight: Radius.circular(m.fromUser ? 4 : 16)),
        ),
        child: Text(m.text, style: TextStyle(fontSize: 14, height: 1.35,
          color: m.fromUser ? AppColors.accentInk : AppColors.text)),
      ),
    );
  }
}
