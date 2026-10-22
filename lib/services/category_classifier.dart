import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import '../models/activity_category.dart';

/// Détermine la catégorie d'une activité à partir de sa photo (US#6).
abstract interface class CategoryClassifier {
  /// Retourne une valeur de [activityCategories].
  ///
  /// Lève [ClassifierBusyException] si le quota de requêtes est atteint.
  Future<String> classify(Uint8List imageBytes, String mimeType);
}

/// Trop de requêtes envoyées à l'IA : il faut patienter avant de réessayer.
class ClassifierBusyException implements Exception {
  const ClassifierBusyException();
}

/// Classification par Gemini, via Firebase AI Logic.
///
/// La réponse est contrainte par un schéma JSON dont le champ `category`
/// est une énumération : le modèle ne peut renvoyer qu'une catégorie connue.
class GeminiCategoryClassifier implements CategoryClassifier {
  GeminiCategoryClassifier({GenerativeModel? model})
    : _model =
          model ??
          FirebaseAI.googleAI().generativeModel(
            model: modelName,
            generationConfig: GenerationConfig(
              temperature: 0,
              // Tâche simple : pas besoin de « réflexion », réponse plus rapide.
              thinkingConfig: ThinkingConfig.withThinkingLevel(
                ThinkingLevel.minimal,
              ),
              responseMimeType: 'application/json',
              responseSchema: Schema.object(
                properties: {
                  'category': Schema.enumString(enumValues: activityCategories),
                },
              ),
            ),
          );

  /// ~2 s par image, contre ~25 s pour la version « lite ».
  /// Niveau gratuit : 5 requêtes par minute pour le projet.
  static const modelName = 'gemini-3.5-flash';

  static final _prompt =
      "Tu classes des activités de loisirs d'après leur photo. "
      "Choisis la catégorie qui décrit le mieux l'activité montrée, parmi : "
      '${activityCategories.join(', ')}. '
      "Réponds « Autre » seulement si aucune ne convient.";

  final GenerativeModel _model;

  @override
  Future<String> classify(Uint8List imageBytes, String mimeType) async {
    final GenerateContentResponse response;
    try {
      response = await _model.generateContent([
        Content.multi([
          TextPart(_prompt),
          InlineDataPart(mimeType, imageBytes),
        ]),
      ]);
    } on QuotaExceeded catch (e) {
      debugPrint('Quota IA atteint : ${e.message}');
      throw const ClassifierBusyException();
    }

    final text = response.text;
    debugPrint('Réponse IA : $text');
    if (text == null) {
      throw const FormatException("L'IA n'a renvoyé aucune réponse");
    }

    final category = (jsonDecode(text) as Map<String, dynamic>)['category'];
    if (category is! String || !activityCategories.contains(category)) {
      throw FormatException('Catégorie inconnue : $category');
    }
    return category;
  }
}
