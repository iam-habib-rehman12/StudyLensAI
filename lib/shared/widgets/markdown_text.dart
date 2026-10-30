import 'package:flutter/material.dart';

/// Renders the small Markdown subset used by StudyLens AI answers.
///
/// Supported: headings (# to ###), bullet and numbered lists, block quotes,
/// fenced code blocks, and inline bold, italic, and code spans. Plain text is
/// rendered as a normal [Text] widget so existing simple responses keep their
/// original semantics and tests.
class MarkdownText extends StatelessWidget {
  const MarkdownText(this.data, {this.style, super.key});

  final String data;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    if (data.trim().isEmpty) return const SizedBox.shrink();
    if (!_containsMarkdown(data)) return Text(data, style: base);

    final blocks = _MarkdownParser.parse(data);
    final children = <Widget>[];
    for (final block in blocks) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 10));
      children.add(_BlockView(block: block, base: base));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  static bool _containsMarkdown(String value) => _markdownPattern.hasMatch(value);

  static final _markdownPattern = RegExp(
    r'(^|\n)\s*(#{1,3}\s|[-*+]\s|\d+[.)]\s|>\s|```)'
    r'|\*\*|__|`[^`\n]+`|\*[^*\n]+\*',
  );
}

class _BlockView extends StatelessWidget {
  const _BlockView({required this.block, required this.base});

  final _Block block;
  final TextStyle base;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    switch (block) {
      case _Paragraph(:final text):
        return Text.rich(TextSpan(children: _inline(text, base, colors)));
      case _Heading(:final level, :final text):
        final scale = switch (level) {
          1 => 1.45,
          2 => 1.3,
          _ => 1.15,
        };
        final headingStyle = base.copyWith(
          fontSize: (base.fontSize ?? 16) * scale,
          fontWeight: FontWeight.w700,
          height: 1.3,
        );
        return Text.rich(
          TextSpan(children: _inline(text, headingStyle, colors)),
        );
      case _BulletList(:final items):
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in items) _listRow('•', item, colors),
          ],
        );
      case _NumberedList(:final items):
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < items.length; index++)
              _listRow('${index + 1}.', items[index], colors),
          ],
        );
      case _Quote(:final text):
        return Container(
          padding: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: colors.primary, width: 3),
            ),
          ),
          child: Text.rich(
            TextSpan(
              children: _inline(
                text,
                base.copyWith(fontStyle: FontStyle.italic),
                colors,
              ),
            ),
          ),
        );
      case _CodeBlock(:final code):
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              code,
              style: base.copyWith(
                fontFamily: 'monospace',
                fontSize: (base.fontSize ?? 16) * 0.9,
                height: 1.45,
              ),
            ),
          ),
        );
    }
  }

  Widget _listRow(String marker, String text, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text(marker, style: base),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(children: _inline(text, base, colors)),
            ),
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _inline(
    String text,
    TextStyle style,
    ColorScheme colors,
  ) {
    final spans = <InlineSpan>[];
    var start = 0;
    for (final match in _inlinePattern.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      if (match.group(1) != null) {
        spans.add(
          TextSpan(
            text: match.group(2),
            style: style.copyWith(fontWeight: FontWeight.w700),
          ),
        );
      } else if (match.group(3) != null) {
        spans.add(
          TextSpan(
            text: match.group(4),
            style: style.copyWith(fontStyle: FontStyle.italic),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: match.group(5),
            style: style.copyWith(
              fontFamily: 'monospace',
              backgroundColor: colors.surfaceContainerHigh,
            ),
          ),
        );
      }
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    if (spans.isEmpty) spans.add(TextSpan(text: text));
    return [
      TextSpan(style: style, children: spans),
    ];
  }

  static final _inlinePattern = RegExp(
    r'(\*\*|__)(.+?)\1|(\*|_)(.+?)\3|`([^`]+)`',
  );
}

abstract final class _MarkdownParser {
  static final _heading = RegExp(r'^(#{1,3})\s+(.*)$');
  static final _bullet = RegExp(r'^[-*+]\s+(.*)$');
  static final _numbered = RegExp(r'^\d+[.)]\s+(.*)$');
  static final _quote = RegExp(r'^>\s?(.*)$');

  static List<_Block> parse(String source) {
    final lines = source.replaceAll('\r\n', '\n').split('\n');
    final blocks = <_Block>[];
    var index = 0;

    while (index < lines.length) {
      final line = lines[index].trim();
      if (line.isEmpty) {
        index += 1;
        continue;
      }

      if (line.startsWith('```')) {
        final code = <String>[];
        index += 1;
        while (index < lines.length &&
            !lines[index].trim().startsWith('```')) {
          code.add(lines[index]);
          index += 1;
        }
        if (index < lines.length) index += 1;
        blocks.add(_CodeBlock(code.join('\n')));
        continue;
      }

      final heading = _heading.firstMatch(line);
      if (heading != null) {
        blocks.add(_Heading(heading.group(1)!.length, heading.group(2)!.trim()));
        index += 1;
        continue;
      }

      if (_quote.hasMatch(line)) {
        final quoted = <String>[];
        while (index < lines.length) {
          final match = _quote.firstMatch(lines[index].trim());
          if (match == null) break;
          quoted.add(match.group(1)!.trim());
          index += 1;
        }
        blocks.add(_Quote(quoted.join(' ')));
        continue;
      }

      if (_bullet.hasMatch(line)) {
        final items = <String>[];
        while (index < lines.length) {
          final match = _bullet.firstMatch(lines[index].trim());
          if (match == null) break;
          items.add(match.group(1)!.trim());
          index += 1;
        }
        blocks.add(_BulletList(items));
        continue;
      }

      if (_numbered.hasMatch(line)) {
        final items = <String>[];
        while (index < lines.length) {
          final match = _numbered.firstMatch(lines[index].trim());
          if (match == null) break;
          items.add(match.group(1)!.trim());
          index += 1;
        }
        blocks.add(_NumberedList(items));
        continue;
      }

      final paragraph = <String>[];
      while (index < lines.length) {
        final current = lines[index].trim();
        if (current.isEmpty || _isBlockStart(current)) break;
        paragraph.add(current);
        index += 1;
      }
      blocks.add(_Paragraph(paragraph.join(' ')));
    }

    return blocks;
  }

  static bool _isBlockStart(String line) =>
      line.startsWith('```') ||
      _heading.hasMatch(line) ||
      _quote.hasMatch(line) ||
      _bullet.hasMatch(line) ||
      _numbered.hasMatch(line);
}

sealed class _Block {
  const _Block();
}

class _Paragraph extends _Block {
  const _Paragraph(this.text);
  final String text;
}

class _Heading extends _Block {
  const _Heading(this.level, this.text);
  final int level;
  final String text;
}

class _BulletList extends _Block {
  const _BulletList(this.items);
  final List<String> items;
}

class _NumberedList extends _Block {
  const _NumberedList(this.items);
  final List<String> items;
}

class _Quote extends _Block {
  const _Quote(this.text);
  final String text;
}

class _CodeBlock extends _Block {
  const _CodeBlock(this.code);
  final String code;
}
