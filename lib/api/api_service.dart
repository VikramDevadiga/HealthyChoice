import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  /// Fetch product details either by barcode or product name
  static Future<Map<String, dynamic>> getProductInfo(String query) async {
    final isBarcode = RegExp(r'^\d+$').hasMatch(query);

    Uri url;

    if (isBarcode) {
      url = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$query.json');
    } else {
      // Search by product name, return first match
      final searchUrl = Uri.parse('https://world.openfoodfacts.org/cgi/search.pl?search_terms=$query&search_simple=1&action=process&json=1');
      final searchResponse = await http.get(searchUrl);

      if (searchResponse.statusCode != 200) {
        throw Exception("Failed to search by name");
      }

      final searchData = json.decode(searchResponse.body);
      if (searchData['products'] != null && searchData['products'].isNotEmpty) {
        final firstProduct = searchData['products'][0];
        final code = firstProduct['code'];
        url = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$code.json');
      } else {
        throw Exception("No product found with name");
      }
    }

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['product'] ?? {};
    } else {
      throw Exception("Failed to fetch product data");
    }
  }

  /// Get product name suggestions
  static Future<List<String>> getSuggestions(String query) async {
    final url = Uri.parse('https://world.openfoodfacts.org/cgi/search.pl?search_terms=$query&search_simple=1&action=process&json=1');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final products = data['products'] as List<dynamic>;
      return products.map<String>((item) => item['product_name']?.toString() ?? '').where((name) => name.isNotEmpty).toSet().toList();
    } else {
      throw Exception("Failed to fetch suggestions");
    }
  }
}
