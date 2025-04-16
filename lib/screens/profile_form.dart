import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class ProfileForm extends StatefulWidget {
  const ProfileForm({super.key});

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController otherAllergenController = TextEditingController();
  final TextEditingController otherGoalController = TextEditingController();
  final TextEditingController otherAvoidController = TextEditingController();

  final List<String> allergens = [];
  final List<String> goals = [];
  final List<String> avoidItems = [];

  void handleSubmit() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString('full_name', nameController.text);
    await prefs.setStringList('allergens', allergens);
    await prefs.setString('other_allergen', otherAllergenController.text);
    await prefs.setStringList('goals', goals);
    await prefs.setString('other_goal', otherGoalController.text);
    await prefs.setStringList('avoid', avoidItems);
    await prefs.setString('other_avoid', otherAvoidController.text);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  void toggleChip(List<String> list, String value) {
    setState(() {
      if (list.contains(value)) {
        list.remove(value);
      } else {
        list.add(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A4EDA),
        title: const Text('Profile Form'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 3,
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                customLabel("Full Name"),
                TextFormField(
                  controller: nameController,
                  decoration: customInputDecoration(),
                ),

                const SizedBox(height: 20),
                customLabel("Allergens"),
                Wrap(
                  spacing: 10,
                  children: [
                    allergenChip("Milk"),
                    allergenChip("Eggs"),
                    allergenChip("Fish"),
                    allergenChip("Peanuts"),
                    allergenChip("Wheat"),
                    allergenChip("Soy"),
                  ],
                ),
                const SizedBox(height: 10),
                customLabel("Other Allergen"),
                TextFormField(
                  controller: otherAllergenController,
                  decoration: customInputDecoration(),
                ),

                const SizedBox(height: 20),
                customLabel("Goals"),
                Wrap(
                  spacing: 10,
                  children: [
                    goalChip("Weight Loss"),
                    goalChip("Stay Fit"),
                    goalChip("Gain Muscle"),
                    goalChip("Improve Digestion"),
                  ],
                ),
                const SizedBox(height: 10),
                customLabel("Other Goal"),
                TextFormField(
                  controller: otherGoalController,
                  decoration: customInputDecoration(),
                ),

                const SizedBox(height: 20),
                customLabel("Trying to Avoid"),
                Wrap(
                  spacing: 10,
                  children: [
                    avoidChip("Salt"),
                    avoidChip("Sugar"),
                    avoidChip("Caffeine"),
                    avoidChip("Fats"),
                    avoidChip("Processed Foods"),
                  ],
                ),
                const SizedBox(height: 10),
                customLabel("Other Item to Avoid"),
                TextFormField(
                  controller: otherAvoidController,
                  decoration: customInputDecoration(),
                ),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF673BDF),
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    onPressed: handleSubmit,
                    child: const Text(
                      "Submit",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget customLabel(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4A4EDA),
        ),
      ),
    );
  }

  InputDecoration customInputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF0F2FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget allergenChip(String title) {
    return FilterChip(
      label: Text(title),
      selected: allergens.contains(title),
      onSelected: (_) => toggleChip(allergens, title),
      backgroundColor: const Color(0xFFE7E9FD),
      selectedColor: const Color(0xFF4A4EDA),
      labelStyle: const TextStyle(color: Colors.black),
    );
  }

  Widget goalChip(String title) {
    return FilterChip(
      label: Text(title),
      selected: goals.contains(title),
      onSelected: (_) => toggleChip(goals, title),
      backgroundColor: const Color(0xFFE7E9FD),
      selectedColor: const Color(0xFF4A4EDA),
      labelStyle: const TextStyle(color: Colors.black),
    );
  }

  Widget avoidChip(String title) {
    return FilterChip(
      label: Text(title),
      selected: avoidItems.contains(title),
      onSelected: (_) => toggleChip(avoidItems, title),
      backgroundColor: const Color(0xFFE7E9FD),
      selectedColor: const Color(0xFF4A4EDA),
      labelStyle: const TextStyle(color: Colors.black),
    );
  }
}