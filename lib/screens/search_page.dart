import 'package:flutter/material.dart';
// import 'package:safe_choice/api_service.dart';
import 'package:projectapp/api/api_service.dart';
// import 'package:safe_choice/results_page.dart';
import 'package:projectapp/screens/results_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  String _searchQuery = "";

  void _searchProduct() {
    if (_controller.text.isNotEmpty) {
      setState(() => _searchQuery = _controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search Product")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: "Enter product barcode"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _searchProduct, child: const Text("Search")),
            if (_searchQuery.isNotEmpty)
              FutureBuilder<Map<String, dynamic>>(
                future: ApiService.getProductInfo(_searchQuery),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
                  if (snapshot.hasError) return const Text("Error fetching data");
                  return ResultsPage(barcode: _searchQuery);
                },
              ),
          ],
        ),
      ),
    );
  }
}
