import 'package:flutter/material.dart';
import 'package:projectapp/api/api_service.dart';

class ResultsPage extends StatefulWidget {
  final String barcode;
  const ResultsPage({super.key, required this.barcode});

  @override
  _ResultsPageState createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  late Future<Map<String, dynamic>> _productData;

  @override
  void initState() {
    super.initState();
    _productData = ApiService.getProductInfo(widget.barcode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Product Results")),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _productData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error fetching data"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No product information available"));
          }

          final data = snapshot.data!;
          final imageUrl = data['image_url'] ?? 'https://via.placeholder.com/150';
          final productName = data['product_name'] ?? 'Unknown Product';
          final ingredients = data['ingredients_text'] ?? 'No ingredient information available';

          // Fetching Nutri-Score (A-F)
          final nutriScore = (data['nutriscore_grade'] ?? '').toUpperCase();
          final nutriScoreColor = _getNutriScoreColor(nutriScore);
          final nutriScoreIcon = _getNutriScoreIcon(nutriScore);

          // Nutrient levels (Low, Moderate, High)
          final nutrientLevels = data['nutrient_levels'] ?? {};

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                const Text("Result", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                // Nutri-Score Display
                Row(
                  children: [
                    Text("Nutrition Score: ", style: const TextStyle(fontSize: 18)),
                    Text(
                      " $nutriScore ",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: nutriScoreColor),
                    ),
                    Icon(nutriScoreIcon, color: nutriScoreColor, size: 30),
                  ],
                ),
                const SizedBox(height: 16),

                // Product Image
                Center(
                  child: Image.network(imageUrl, height: 150, fit: BoxFit.cover),
                ),
                const SizedBox(height: 16),

                // Product Name
                Text("🛒 Product: $productName",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                // Ingredients
                Text("🧪 Ingredients:", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(ingredients, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 16),

                // Nutrient Levels Display
                _buildNutrientRow("Sugar", nutrientLevels['sugars']),
                _buildNutrientRow("Fat", nutrientLevels['fat']),
                _buildNutrientRow("Salt", nutrientLevels['salt']),
                _buildNutrientRow("Saturated Fat", nutrientLevels['saturated-fat']),
              ],
            ),
          );
        },
      ),
    );
  }

  // Function to get Nutri-Score color
  Color _getNutriScoreColor(String grade) {
    switch (grade) {
      case "A": return Colors.green;
      case "B": return Colors.lightGreen;
      case "C": return Colors.orange;
      case "D": return Colors.red;
      case "E": return Colors.red;
      default: return Colors.grey;
    }
  }

  // Function to get Nutri-Score icon
  IconData _getNutriScoreIcon(String grade) {
    switch (grade) {
      case "A": return Icons.check_circle;
      case "B": return Icons.thumb_up;
      case "C": return Icons.warning;
      case "D": return Icons.error;
      case "E": return Icons.cancel;
      default: return Icons.help_outline;
    }
  }

  // Widget to display nutrient levels
  Widget _buildNutrientRow(String nutrient, String? level) {
    if (level == null) return Container();

    Color color;
    switch (level) {
      case "low":
        color = Colors.green;
        break;
      case "moderate":
        color = Colors.orange;
        break;
      case "high":
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Row(
      children: [
        Text("⚡ $nutrient: ", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(level.toUpperCase(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
