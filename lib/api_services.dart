import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const geminiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const spoonacularKey= String.fromEnvironment('SPOONACULAR_API_KEY');

  Future<List<String>> identifyIngredients(String imagePath) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: geminiKey,
      );

      final File imageFile = File(imagePath);
      if (!await imageFile.exists()) return ["Error: File not found"];

      final Uint8List imageBytes = await imageFile.readAsBytes();

      final content = [
        Content.multi([
          TextPart(
            "List only the food ingredients in this image, comma separated. Example: tomatoes, onions, garlic.",
          ),
          DataPart('image/jpeg', imageBytes),
        ]),
      ];

      final response = await model.generateContent(content);

      final text = response.text ?? "";

      if (text.isEmpty) return ["Error: Gemini returned empty"];
      return text.split(',').map((e) => e.trim()).toList();
    } catch (e) {
      return ["Error: ${e.toString()}"];
    }
  }

  Future<List<dynamic>> fetchRecipes(List<String> ingredients) async {
    if (ingredients.isEmpty || ingredients[0].contains("Error")) return [];

    final query = ingredients.join(',');
    final url =
        'https://api.spoonacular.com/recipes/findByIngredients?ingredients=$query&number=10&apiKey=$spoonacularKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print(e);
    }
    return [];
  }

  Future<Map<String, dynamic>> fetchRecipeDetails(int id) async {
    final url =
        'https://api.spoonacular.com/recipes/$id/information?apiKey=$spoonacularKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load recipe details');
      }
    } catch (e) {
      print("Error fetching details: $e");
      return {};
    }
  }
}
