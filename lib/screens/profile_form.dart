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
  final List<String> allergens = [];
  final List<String> goals = [];
  final List<String> avoidItems = [];

  void handleSubmit() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('full_name', nameController.text);
    await prefs.setStringList('allergens', allergens);
    await prefs.setStringList('goals', goals);
    await prefs.setStringList('avoid', avoidItems);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
  }

  void toggleChip(List<String> list, String value) {
    setState(() => list.contains(value) ? list.remove(value) : list.add(value));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4A4EDA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Center(
              child: Image.asset(
                'assets/images/logo.png',
                height: 120,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      "Complete Profile",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A4EDA),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
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
                        "Done",
                        style: TextStyle(
                          fontSize: 19,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget customLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
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

  Widget allergenChip(String title) => chipWidget(title, allergens);
  Widget goalChip(String title) => chipWidget(title, goals);
  Widget avoidChip(String title) => chipWidget(title, avoidItems);

  Widget chipWidget(String title, List<String> targetList) {
    return FilterChip(
      label: Text(title),
      selected: targetList.contains(title),
      onSelected: (_) => toggleChip(targetList, title),
      backgroundColor: const Color(0xFFE7E9FD),
      selectedColor: const Color(0xFF4A4EDA),
      labelStyle: const TextStyle(color: Colors.black),
    );
  }
}
