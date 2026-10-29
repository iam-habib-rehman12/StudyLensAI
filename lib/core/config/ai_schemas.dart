import 'package:firebase_ai/firebase_ai.dart';

abstract final class AiSchemas {
  static Schema quiz({required int questionCount}) => Schema.object(
    propertyOrdering: const ['title', 'questionCount', 'questions'],
    properties: {
      'title': Schema.string(
        description: 'A concise quiz title of at most 120 characters.',
      ),
      'questionCount': Schema.integer(
        description: 'The exact number of generated questions.',
        minimum: questionCount,
        maximum: questionCount,
      ),
      'questions': Schema.array(
        minItems: questionCount,
        maxItems: questionCount,
        items: Schema.object(
          propertyOrdering: const [
            'question',
            'options',
            'correctOptionIndex',
            'explanation',
          ],
          properties: {
            'question': Schema.string(
              description: 'One clear, self-contained educational question.',
            ),
            'options': Schema.array(
              minItems: 4,
              maxItems: 4,
              items: Schema.string(
                description: 'One concise and distinct answer option.',
              ),
            ),
            'correctOptionIndex': Schema.integer(
              description: 'Zero-based index of the single correct option.',
              minimum: 0,
              maximum: 3,
            ),
            'explanation': Schema.string(
              description:
                  'A concise explanation of why the correct answer is correct.',
            ),
          },
        ),
      ),
    },
  );
}
