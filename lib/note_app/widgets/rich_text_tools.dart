import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// تنسيق النص بدون تغيير الـ Hive model:
/// النص بيتخزن عادي في subTitle مع علامات صغيرة:
///   **bold**   __italic__   ++underline++   {c:RRGGBB}ملوّن{/c}
///   {tags:a,b} (في آخر النص) للـ Tags
/// ---------------------------------------------------------------------------

final RegExp _tokenRe =
    RegExp(r'\*\*|__|\+\+|\{c:[0-9A-Fa-f]{6}\}|\{/c\}');
final RegExp _listRe = RegExp(r'^(• |\d+\. |☐ |☑ )');
final RegExp _tagsRe = RegExp(r'\n?\{tags:([^}]*)\}\s*$');

/// يحوّل النص لـ spans. لو keepMarkers=true العلامات بتفضل في النص
/// بس بتتخفي (عشان مكان الـ cursor يفضل مظبوط جوه الـ TextField).
List<InlineSpan> parseRich(
  String text,
  TextStyle base, {
  required bool keepMarkers,
}) {
  final spans = <InlineSpan>[];
  bool bold = false, italic = false, underline = false;
  Color? color;
  int last = 0;

  TextStyle current() => base.copyWith(
        fontWeight: bold ? FontWeight.bold : null,
        fontStyle: italic ? FontStyle.italic : null,
        decoration: underline ? TextDecoration.underline : null,
        color: color,
      );

  for (final m in _tokenRe.allMatches(text)) {
    if (m.start > last) {
      spans.add(TextSpan(text: text.substring(last, m.start), style: current()));
    }
    final t = m.group(0)!;
    if (t == '**') {
      bold = !bold;
    } else if (t == '__') {
      italic = !italic;
    } else if (t == '++') {
      underline = !underline;
    } else if (t.startsWith('{c:')) {
      color = Color(int.parse('FF${t.substring(3, 9)}', radix: 16));
    } else {
      color = null;
    }
    if (keepMarkers) {
      spans.add(TextSpan(
        text: t,
        style: base.copyWith(fontSize: 0.1, color: Colors.transparent),
      ));
    }
    last = m.end;
  }
  if (last < text.length) {
    spans.add(TextSpan(text: text.substring(last), style: current()));
  }
  return spans;
}

const String _tokenSrc = r'(?:\*\*|__|\+\+|\{c:[0-9A-Fa-f]{6}\}|\{/c\})';

/// الكلمة اللي الـ cursor جواها أو جنبها (من غير علامات التنسيق)
(int, int) _wordAt(String t, int pos) {
  bool isWs(int i) => RegExp(r'\s').hasMatch(t[i]);
  int s = pos, e = pos;
  while (s > 0 && !isWs(s - 1)) {
    s--;
  }
  while (e < t.length && !isWs(e)) {
    e++;
  }
  final w = t.substring(s, e);
  final lead = RegExp('^$_tokenSrc+').firstMatch(w)?.end ?? 0;
  final trail = RegExp('$_tokenSrc+\$').firstMatch(w);
  final trailStart = trail == null ? w.length : trail.start;
  if (trailStart <= lead) return (pos, pos);
  return (s + lead, s + trailStart);
}

(String, List<String>) splitTags(String raw) {
  final m = _tagsRe.firstMatch(raw);
  if (m == null) return (raw, <String>[]);
  final tags = m
      .group(1)!
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  return (raw.substring(0, m.start), tags);
}

String joinTags(String body, List<String> tags) =>
    tags.isEmpty ? body : '$body\n{tags:${tags.join(',')}}';

/// نص عادي بدون أي علامات (للإشعارات مثلاً)
String stripRich(String raw) =>
    splitTags(raw).$1.replaceAll(_tokenRe, '').trim();

class RichTextController extends TextEditingController {
  RichTextController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    return TextSpan(
      style: style,
      children: parseRich(text, style ?? const TextStyle(), keepMarkers: true),
    );
  }

  /// لما المستخدم يدوس Enter جوه قايمة، نكمّل القايمة تلقائي
  @override
  set value(TextEditingValue nv) {
    final old = value;
    final pos = nv.selection.start;
    if (nv.selection.isCollapsed &&
        pos > 0 &&
        nv.text.length == old.text.length + 1 &&
        nv.text[pos - 1] == '\n') {
      final before = nv.text.substring(0, pos - 1);
      final ls = before.lastIndexOf('\n') + 1;
      final line = before.substring(ls);
      final m = _listRe.firstMatch(line);
      if (m != null) {
        final marker = m.group(0)!;
        if (line.length == marker.length) {
          // بند فاضي => اخرج من القايمة
          super.value = TextEditingValue(
            text: nv.text.substring(0, ls) + nv.text.substring(pos),
            selection: TextSelection.collapsed(offset: ls),
          );
          return;
        }
        String next = marker;
        final n = RegExp(r'^(\d+)\. ').firstMatch(marker);
        if (n != null) next = '${int.parse(n.group(1)!) + 1}. ';
        if (marker == '☑ ') next = '☐ ';
        super.value = TextEditingValue(
          text: nv.text.substring(0, pos) + next + nv.text.substring(pos),
          selection: TextSelection.collapsed(offset: pos + next.length),
        );
        return;
      }
    }
    super.value = nv;
  }
}

class RichToolbar extends StatelessWidget {
  final TextEditingController controller;
  final Color cardColor;
  final Color borderColor;
  final Color iconColor;

  const RichToolbar({
    super.key,
    required this.controller,
    required this.cardColor,
    required this.borderColor,
    required this.iconColor,
  });

  static const List<int> _palette = [
    0xFFE53935,
    0xFFFB8C00,
    0xFF43A047,
    0xFF1E88E5,
    0xFF8E24AA,
    0xFFEC407A,
  ];

  void _wrap(String open, String close, {TextSelection? sel}) {
    final t = controller.text;
    final selection = sel ?? controller.selection;
    int s = selection.isValid ? selection.start : t.length;
    int e = selection.isValid ? selection.end : t.length;
    bool wordMode = false;

    // مفيش تحديد؟ طبّق على الكلمة اللي عندها الـ cursor
    if (s == e) {
      final w = _wordAt(t, s);
      if (w.$1 < w.$2) {
        s = w.$1;
        e = w.$2;
        wordMode = true;
      }
    }

    // لو متنسق بالفعل => شيل التنسيق
    if (open == close &&
        s >= open.length &&
        t.startsWith(open, s - open.length) &&
        t.startsWith(close, e)) {
      final nt = t
          .replaceRange(e, e + close.length, '')
          .replaceRange(s - open.length, s, '');
      controller.value = TextEditingValue(
        text: nt,
        selection: wordMode
            ? TextSelection.collapsed(offset: e - open.length)
            : TextSelection(
                baseOffset: s - open.length,
                extentOffset: e - open.length,
              ),
      );
      return;
    }

    final nt =
        t.substring(0, s) + open + t.substring(s, e) + close + t.substring(e);
    controller.value = TextEditingValue(
      text: nt,
      selection: s == e
          ? TextSelection.collapsed(offset: s + open.length)
          : wordMode
              ? TextSelection.collapsed(offset: e + open.length)
              : TextSelection(
                  baseOffset: s + open.length,
                  extentOffset: e + open.length,
                ),
    );
  }

  void _toggleList(String kind) {
    final t = controller.text;
    final sel = controller.selection;
    final start = sel.isValid ? sel.start : t.length;
    final end = sel.isValid ? sel.end : t.length;

    final ls = start == 0 ? 0 : t.lastIndexOf('\n', start - 1) + 1;
    int le = t.indexOf('\n', end);
    if (le == -1) le = t.length;

    final lines = t.substring(ls, le).split('\n');
    final allHave = lines.every((l) {
      final m = _listRe.firstMatch(l)?.group(0);
      if (m == null) return false;
      return kind == 'bullet'
          ? m == '• '
          : kind == 'number'
              ? RegExp(r'^\d+\. $').hasMatch(m)
              : (m == '☐ ' || m == '☑ ');
    });

    final out = <String>[];
    for (var i = 0; i < lines.length; i++) {
      final clean = lines[i].replaceFirst(_listRe, '');
      if (allHave) {
        out.add(clean);
      } else {
        final prefix = kind == 'bullet'
            ? '• '
            : kind == 'number'
                ? '${i + 1}. '
                : '☐ ';
        out.add('$prefix$clean');
      }
    }
    final block = out.join('\n');
    controller.value = TextEditingValue(
      text: t.replaceRange(ls, le, block),
      selection: TextSelection.collapsed(offset: ls + block.length),
    );
  }

  Future<void> _pickColor(BuildContext context) async {
    final saved = controller.selection;
    final hex = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: _palette.map((c) {
              return GestureDetector(
                onTap: () => Navigator.pop(
                  ctx,
                  c.toRadixString(16).substring(2).toUpperCase(),
                ),
                child: CircleAvatar(radius: 20, backgroundColor: Color(c)),
              );
            }).toList(),
          ),
        ),
      ),
    );
    if (hex != null) _wrap('{c:$hex}', '{/c}', sel: saved);
  }

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, VoidCallback onTap) => InkResponse(
          onTap: onTap,
          radius: 20,
          canRequestFocus: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
            child: Icon(icon, size: 20, color: iconColor),
          ),
        );

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            btn(Icons.format_bold, () => _wrap('**', '**')),
            btn(Icons.format_italic, () => _wrap('__', '__')),
            btn(Icons.format_underlined, () => _wrap('++', '++')),
            btn(Icons.palette_outlined, () => _pickColor(context)),
            btn(Icons.format_list_bulleted, () => _toggleList('bullet')),
            btn(Icons.format_list_numbered, () => _toggleList('number')),
            btn(Icons.checklist, () => _toggleList('check')),
          ],
        ),
      ),
    );
  }
}
