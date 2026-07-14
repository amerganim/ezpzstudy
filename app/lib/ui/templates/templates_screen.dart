import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_services.dart';
import '../../data/writing_templates_repository.dart';
import '../../l10n/strings_bn.dart';
import '../../theme/app_theme.dart';

/// "Magic templates": ready-made writing skeletons a weak student can reuse by
/// just typing the topic. The list groups templates by category; tapping one
/// opens a fill-in screen with a live, always-complete preview.
class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  late Future<List<WritingTemplate>> _future;

  @override
  void initState() {
    super.initState();
    _future = AppServices.of(context).writingTemplates.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Bn.templatesTitle)),
      body: FutureBuilder<List<WritingTemplate>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final templates = snap.data!;
          return ListView(
            padding: EdgeInsets.fromLTRB(
                16, 16, 16, MediaQuery.of(context).padding.bottom + 24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Text('✨', style: TextStyle(fontSize: 26)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(Bn.templatesIntro,
                          style: TextStyle(fontSize: 13.5, height: 1.4)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              for (final t in templates) _TemplateCard(t: t),
            ],
          );
        },
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final WritingTemplate t;
  const _TemplateCard({required this.t});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Text(_emoji(t.category), style: const TextStyle(fontSize: 30)),
          title: Text(t.titleBn,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              t.marks == null
                  ? t.categoryBn
                  : '${t.categoryBn} • ${Bn.digits(t.marks!)} ${Bn.worthMarks}',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
          trailing: const Icon(Icons.chevron_right, color: AppTheme.accent),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => TemplateDetailScreen(template: t),
          )),
        ),
      ),
    );
  }

  static String _emoji(String category) {
    switch (category) {
      case 'paragraph':
        return '📝';
      case 'letter':
        return '✉️';
      case 'dialogue':
        return '💬';
      case 'story':
        return '📖';
      case 'graph':
        return '📊';
      default:
        return '🪄';
    }
  }
}

/// Fill-in screen: one field per slot, and a live preview that always shows a
/// complete answer (a slot's sample fills in until the student types their own).
class TemplateDetailScreen extends StatefulWidget {
  final WritingTemplate template;
  const TemplateDetailScreen({super.key, required this.template});

  @override
  State<TemplateDetailScreen> createState() => _TemplateDetailScreenState();
}

class _TemplateDetailScreenState extends State<TemplateDetailScreen> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (final s in widget.template.slots) {
      _controllers[s.key] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, String> get _values =>
      {for (final e in _controllers.entries) e.key: e.value.text};

  @override
  Widget build(BuildContext context) {
    final t = widget.template;
    final filled = t.fill(_values);
    return Scaffold(
      appBar: AppBar(title: Text(t.titleBn)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(context).padding.bottom + 32),
        children: [
          if (t.introBn.isNotEmpty) ...[
            Text(t.introBn,
                style: const TextStyle(
                    fontSize: 14, height: 1.45, color: Colors.black54)),
            const SizedBox(height: 20),
          ],

          // Fillable slots.
          const _SectionLabel(Bn.templateFillTitle, sub: Bn.templateFillHint),
          const SizedBox(height: 12),
          for (final s in t.slots) ...[
            TextField(
              controller: _controllers[s.key],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: s.labelBn,
                hintText: s.example,
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 8),

          // Live, always-complete preview.
          const _SectionLabel(Bn.templateReadyTitle),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceTint,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.hairline),
            ),
            child: SelectableText(
              filled,
              style: const TextStyle(
                  fontSize: 15.5, height: 1.55, color: AppTheme.ink),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: filled));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text(Bn.copied)));
              }
            },
            icon: const Icon(Icons.copy_rounded, size: 20),
            label: const Text(Bn.copyText),
          ),

          // Exam tips.
          if (t.tipsBn.isNotEmpty) ...[
            const SizedBox(height: 24),
            const _SectionLabel(Bn.templateTipsTitle),
            const SizedBox(height: 8),
            for (final tip in t.tipsBn)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡  ', style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: Text(tip,
                          style: const TextStyle(
                              fontSize: 13.5, height: 1.4, color: Colors.black87)),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final String? sub;
  const _SectionLabel(this.text, {this.sub});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        if (sub != null) ...[
          const SizedBox(height: 2),
          Text(sub!,
              style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
        ],
      ],
    );
  }
}
