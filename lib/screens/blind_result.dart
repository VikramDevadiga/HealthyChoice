import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../api/api_service.dart';

class BlindResultsPage extends StatefulWidget {
  final String barcode;
  const BlindResultsPage({super.key, required this.barcode});

  @override
  State<BlindResultsPage> createState() => _BlindResultsPageState();
}

class _BlindResultsPageState extends State<BlindResultsPage> {
  late Future<Map<String, dynamic>> _productData;
  final FlutterTts _flutterTts = FlutterTts();
  String _spokenText = '';
  Timer? _instructionLoop;

  @override
  void initState() {
    super.initState();
    _productData = ApiService.getProductInfo(widget.barcode);
    _speakProductDetails();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _instructionLoop?.cancel();
    super.dispose();
  }

  void _speakProductDetails() async {
    final data = await _productData;
    if (data.isNotEmpty) {
      final productName = data['product_name'] ?? 'Unknown Product';
      final ingredients = data['ingredients_text'] ?? 'No ingredient information available';
      final nutrientLevels = data['nutrient_levels'] ?? {};
      final allergens = _getAllergenAlert(ingredients);
      final nutriScore = (data['nutriscore_grade'] ?? '').toUpperCase();

      _spokenText =
      "Product: $productName. Nutri-Score: $nutriScore. Ingredients: $ingredients. Allergy Alert: $allergens. ";

      _speak(_spokenText + "To repeat, tap once. Long press to scan again.");
      _instructionLoop = Timer.periodic(const Duration(seconds: 15), (_) {
        _speak("To repeat, tap once. Long press to scan again.");
      });
    }
  }

  void _speak(String text) async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.speak(text);
  }

  void _repeatSpeech() {
    _flutterTts.stop();
    _speak(_spokenText + "To repeat, tap once. Long press to scan again.");
  }

  String _getAllergenAlert(String ingredients) {
    final lowerIngredients = ingredients.toLowerCase();
    List<String> allergens = [];

    if (lowerIngredients.contains("peanut")) allergens.add("Peanuts");
    if (lowerIngredients.contains("milk") || lowerIngredients.contains("dairy")) allergens.add("Dairy");
    if (lowerIngredients.contains("gluten") || lowerIngredients.contains("wheat")) allergens.add("Gluten");
    if (lowerIngredients.contains("soy")) allergens.add("Soy");
    if (lowerIngredients.contains("egg")) allergens.add("Egg");
    if (lowerIngredients.contains("tree nut")) allergens.add("Tree Nuts");

    return allergens.isNotEmpty ? allergens.join(", ") : "None";
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _repeatSpeech,
      onLongPress: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _productData,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator(color: Colors.white);
              } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text(
                  "Error fetching product info",
                  style: TextStyle(color: Colors.white),
                );
              }

              final data = snapshot.data!;
              final productName = data['product_name'] ?? 'Unknown Product';
              final nutriScore = (data['nutriscore_grade'] ?? '').toUpperCase();
              final ingredients = data['ingredients_text'] ?? '';
              final allergens = _getAllergenAlert(ingredients);

              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Product: $productName", style: textStyle()),
                    const SizedBox(height: 10),
                    Text("Nutri-Score: $nutriScore", style: textStyle()),
                    const SizedBox(height: 10),
                    Text("Ingredients: $ingredients", style: textStyle()),
                    const SizedBox(height: 10),
                    Text("Allergens: $allergens", style: textStyle()),
                    const SizedBox(height: 30),
                    Text(
                      "Tap to repeat, Long press to scan again",
                      style: textStyle().copyWith(color: Colors.amber),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  TextStyle textStyle() {
    return const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500);
  }
}
