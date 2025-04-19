HealthyChoice
HealthyChoice is a cross-platform Flutter application designed to help users make informed and healthier food choices. The app allows users to scan packaged food labels and determine the nutritional values and safety of the product based on their dietary preferences or allergies.

🧠 How It Works
Scan or Input Food Labels:
Users can take a photo or upload a food label to the app.

AI-Based Analysis:
The app extracts text using OCR (Optical Character Recognition) and analyzes the ingredients.

Nutritional Breakdown:
It breaks down the nutritional values like sugar, fat, sodium, etc., and displays them visually.

Safety Detection:
Based on user preferences (like allergies), it flags any harmful or unwanted ingredients.

Recommendations:
Offers healthier alternatives or alerts users if the product is unsafe for them.

🖥️ How to Run HealthyChoice on Any Computer
🔧 Prerequisites
Flutter SDK (version 3.0+ recommended)

Dart SDK (comes with Flutter)

An editor like VS Code or Android Studio

Git (to clone the repo)

📥 Step-by-Step Setup
bash
Copy
Edit
# 1. Clone the repository
git clone https://github.com/VikramDevadiga/HealthyChoice.git
cd HealthyChoice

# 2. Install dependencies
flutter pub get

# 3. Run the app
flutter run
✅ The app supports Android, iOS, Web, Windows, macOS, and Linux — just make sure Flutter is properly set up for your platform (use flutter doctor to check).

📁 Project Structure Overview
text
Copy
Edit
├── lib/               # Main application logic
├── android/           # Android-specific code
├── ios/               # iOS-specific code
├── web/               # Web-specific code
├── macos/             # macOS-specific code
├── windows/           # Windows-specific code
├── linux/             # Linux-specific code
├── assets/            # Static assets like images, icons
├── test/              # Unit and widget tests
└── pubspec.yaml       # Dependency and config file
