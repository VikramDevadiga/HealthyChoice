import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_form.dart';

class ViewProfilePage extends StatefulWidget {
  const ViewProfilePage({super.key});

  @override
  State<ViewProfilePage> createState() => _ViewProfilePageState();
}

class _ViewProfilePageState extends State<ViewProfilePage> {
  String name = '';
  List<String> goals = [];
  List<String> avoid = [];
  Map<String, List<String>> preferences = {};

  final List<String> preferenceKeys = [
    "Nutritional quality*",
    "Ingredients*",
    "Environment*",
    "Food processing",
    "Labels",
    "Allergens*"
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('full_name') ?? '';
      goals = prefs.getStringList('goals') ?? [];
      avoid = prefs.getStringList('avoid') ?? [];
      preferences = {
        for (var key in preferenceKeys)
          key: prefs.getStringList('pref_$key') ?? []
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileForm()),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            Text("Name: $name", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text("Goals: ${goals.join(', ')}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Text("Avoid: ${avoid.join(', ')}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ...preferences.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(entry.value.join(', '), style: const TextStyle(color: Colors.black87)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
