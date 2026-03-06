import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/constants.dart';

class AiService {
  static GenerativeModel? _model;

  static Future<GenerativeModel> _getModel(String apiKey) async {
    _model ??= GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
    );
    return _model!;
  }

  /// Analyze user's problem and suggest service categories
  static Future<AiSuggestion> analyzeServiceNeed(String userMessage, String apiKey) async {
    final model = await _getModel(apiKey);

    final categories = AppConstants.allCategories.join(', ');

    final prompt = '''You are Sathi AI, the helpful assistant for "Local Sathi" - a local services app in India.

The user has described a problem or need. Your job is:
1. Understand what they need
2. Suggest the BEST matching service category from this list: $categories
3. Give a brief helpful tip
4. If they're just chatting, respond friendly in Hinglish

RULES:
- Reply in 2-3 short sentences max
- Use a mix of Hindi and English (Hinglish) for a friendly Indian feel
- Always suggest a category if the query is service-related
- Format: Start with the suggestion, then the tip
- If no service matches, just chat helpfully

User says: "$userMessage"

Respond as Sathi AI:''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text ?? 'Sorry, I could not understand. Please try again.';

      // Try to extract the suggested category
      String? suggestedCategory;
      for (final cat in AppConstants.allCategories) {
        if (text.toLowerCase().contains(cat.toLowerCase())) {
          suggestedCategory = cat;
          break;
        }
      }

      return AiSuggestion(
        message: text.trim(),
        suggestedCategory: suggestedCategory,
      );
    } catch (e) {
      return AiSuggestion(
        message: 'Oops! Network issue. Please check your internet and try again.',
        suggestedCategory: null,
      );
    }
  }

  /// Generate smart provider recommendation reason
  static Future<String> getRecommendationReason(
    String providerName,
    String category,
    double rating,
    int reviewCount,
    String apiKey,
  ) async {
    final model = await _getModel(apiKey);

    final prompt = '''Generate a 1-line recommendation for a service provider on Local Sathi app.
Provider: $providerName
Service: $category
Rating: $rating/5 ($reviewCount reviews)

Write a short, friendly recommendation in Hinglish (mix of Hindi & English). Max 15 words.
Example: "Top-rated electrician! Bahut accha kaam karte hain, highly recommended."
Just give the recommendation line, nothing else.''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }
}

class AiSuggestion {
  final String message;
  final String? suggestedCategory;

  AiSuggestion({required this.message, this.suggestedCategory});
}
