import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studylens_ai/shared/widgets/markdown_text.dart';

void main() {
  testWidgets('renders plain text with a normal Text widget', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MarkdownText('A plain study answer.')),
      ),
    );

    expect(find.text('A plain study answer.'), findsOneWidget);
  });

  testWidgets('renders headings, lists, inline styles, quotes, and code', (
    tester,
  ) async {
    const source = '''
## Key concepts

- **Bold** item
- `inline code` item

1. First point
2. Second point

> Quoted **text**

```dart
final answer = 42;
```
''';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: MarkdownText(source)),
        ),
      ),
    );

    expect(find.textContaining('Key concepts', findRichText: true), findsOneWidget);
    expect(find.textContaining('Bold', findRichText: true), findsOneWidget);
    expect(find.textContaining('inline code', findRichText: true), findsOneWidget);
    expect(find.textContaining('First point', findRichText: true), findsOneWidget);
    expect(find.textContaining('Quoted', findRichText: true), findsOneWidget);
    expect(find.text('final answer = 42;'), findsOneWidget);
  });

  testWidgets('keeps unmatched markers as readable text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MarkdownText('An unfinished **bold response')),
      ),
    );

    expect(
      find.textContaining('unfinished', findRichText: true),
      findsOneWidget,
    );
  });
}
