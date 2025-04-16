import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../api/api_service.dart';

class ResultsPage extends StatefulWidget {
  final String barcode;
  const ResultsPage({super.key, required this.barcode});

  @override
  _ResultsPageState createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  late Future<Map<String, dynamic>> _productData;
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _productData = ApiService.getProductInfo(widget.barcode);
  }

  void _speak(String text) async {
    await _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _productData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Error fetching product information"));
          }

          final data = snapshot.data!;
          final imageUrl = data['image_url'] ?? 'https://via.placeholder.com/150';
          final productName = data['product_name'] ?? 'Unknown Product';
          final ingredients = data['ingredients_text'] ?? 'No ingredient information available';
          final nutrientLevels = data['nutrient_levels'] ?? {};
          final allergens = _getAllergenAlert(ingredients);

          String nutriScore = (data['nutriscore_grade'] ?? '').toUpperCase();
          final explanation = _getNutriScoreExplanation(data);
          final nutriScoreColor = _getNutriScoreColor(nutriScore);
          final nutriScoreIcon = _getNutriScoreIcon(nutriScore);

          String productInfo =
              "Product: $productName. Nutri-Score: $nutriScore. Ingredients: $ingredients. Allergy Alert: $allergens";

          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Custom Header
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text("Product Results",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6D30EA),
                            )),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Card Info
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Image.network(imageUrl, height: 150, fit: BoxFit.cover),
                            const SizedBox(height: 16),
                            Text(productName,
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(height: 12),

                            // Nutri Score Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(nutriScoreIcon, color: nutriScoreColor),
                                const SizedBox(width: 8),
                                Text(
                                  "Nutri-Score: $nutriScore",
                                  style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.w600, color: nutriScoreColor),
                                ),
                              ],
                            ),

                            if (explanation.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text("📌 $explanation",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey)),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Ingredients & Nutrients
                    _buildInfoCard(
                      title: "🧪 Ingredients",
                      content: ingredients,
                    ),
                    const SizedBox(height: 12),
                    _buildNutrientCard(nutrientLevels),

                    if (allergens.isNotEmpty)
                      _buildInfoCard(
                        title: "⚠️ Allergy Alert",
                        content: allergens,
                        color: Colors.red.shade100,
                      ),

                    const SizedBox(height: 20),

                    // Buttons
                    ElevatedButton.icon(
                      onPressed: () => _speak(productInfo),
                      icon: const Icon(Icons.volume_up),
                      label: const Text("Listen to Product Info"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6D30EA),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("🔍 Scan Another Product"),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF6D30EA)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String content, Color? color}) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 14, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildNutrientCard(Map<String, dynamic> levels) {
    final nutrients = {
      'Sugar': levels['sugars'],
      'Fat': levels['fat'],
      'Salt': levels['salt'],
      'Saturated Fat': levels['saturated-fat'],
    };

    return _buildInfoCard(
      title: "⚡ Nutrient Levels",
      content: nutrients.entries
          .where((e) => e.value != null)
          .map((e) => "${e.key}: ${e.value.toString().toUpperCase()}")
          .join('\n'),
    );
  }

  Color _getNutriScoreColor(String grade) {
    switch (grade) {
      case "A":
        return Colors.green;
      case "B":
        return Colors.lightGreen;
      case "C":
        return Colors.orange;
      case "D":
      case "E":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getNutriScoreIcon(String grade) {
    switch (grade) {
      case "A":
        return Icons.check_circle;
      case "B":
        return Icons.thumb_up;
      case "C":
        return Icons.warning;
      case "D":
        return Icons.error;
      case "E":
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _getNutriScoreExplanation(Map<String, dynamic> data) {
    final nutrientLevels = data['nutrient_levels'] ?? {};
    final sugar = nutrientLevels['sugars'] ?? 'unknown';
    final fat = nutrientLevels['fat'] ?? 'unknown';
    final salt = nutrientLevels['salt'] ?? 'unknown';

    if (sugar == 'high') return "This product has high sugar content.";
    if (fat == 'high') return "This product has high fat content.";
    if (salt == 'high') return "This product contains high salt levels.";
    if (sugar == 'low' && fat == 'low' && salt == 'low') return "This product has a balanced nutritional profile.";

    return "Nutritional quality is moderate.";
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

    return allergens.isNotEmpty ? allergens.join(", ") : "";
  }
}
