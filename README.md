# 🥗 HealthyChoice

**HealthyChoice** is a cross-platform Flutter application designed to help users make smarter and healthier food choices. Whether you're managing allergies or tracking your nutrition, this app makes it simple by analyzing packaged food labels using AI.

---

## 🧠 How It Works

1. 📸 **Scan or Upload Food Labels**
   Users can scan a packaged food label via camera or upload an image.

2. 🧾 **Text Recognition with OCR**
   The app extracts the ingredient list and nutritional info using Optical Character Recognition (OCR).

3. 🧬 **AI-Powered Analysis**
   It analyzes nutritional values (sugar, fat, sodium, etc.) and highlights any potentially harmful or allergic content.

4. 🚨 **Safety Alerts**
   If a product contains ingredients that go against user-defined preferences (like allergens), the app shows a warning.

5. 🌿 **Healthier Suggestions**
   Offers alternative food products that are better for your dietary goals.

---
## 📷 Screenshots

<img src="https://github.com/user-attachments/assets/837dadc6-8804-4d2f-94d4-c3f509f963b6" width="300">

<img src="https://github.com/user-attachments/assets/016ac9ec-dbb5-4659-b350-9610e9535e9b" width="300">

<img src="https://github.com/user-attachments/assets/2b727c96-9308-45b3-9549-869a94db0d81" width="300">

<img src="https://github.com/user-attachments/assets/a14ba2cc-fc65-4f87-a329-2aec033b34c8" width="300">

<img src="https://github.com/user-attachments/assets/8b15c82b-6abd-43ac-aeb2-ae7398b76331" width="300">

<img src="https://github.com/user-attachments/assets/0ad32dd0-8ae3-4dd4-8781-4236ca269044" width="300">

<img src="https://github.com/user-attachments/assets/4a93a277-bbd5-4d1a-b4fd-d54d5dcb693d" width="300">
---

## 🛠️ Run HealthyChoice Locally

### 🔧 Requirements

* [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.0+)
* Dart SDK (included with Flutter)
* Git
* A code editor like [VS Code](https://code.visualstudio.com/) or [Android Studio](https://developer.android.com/studio)

### 🚀 Setup Guide

```bash
# 1. Clone the repository
git clone https://github.com/VikramDevadiga/HealthyChoice.git
cd HealthyChoice

# 2. Install Flutter dependencies
flutter pub get

# 3. Run the app
flutter run
```

✅ Supports **Android**, **iOS**, **Web**, **Windows**, **macOS**, and **Linux**. Use `flutter doctor` to verify setup for your platform.

---

## 📂 Project Structure

```text
├── lib/               # Main app logic (UI, services, state management)
├── android/           # Android native config
├── ios/               # iOS native config
├── web/               # Web app support
├── macos/             # macOS support
├── windows/           # Windows support
├── linux/             # Linux support
├── assets/            # Images, icons, fonts
├── test/              # Unit and widget tests
└── pubspec.yaml       # Project metadata and dependencies
```

---

## 🧰 Built With

* **Flutter & Dart** – Core framework for cross-platform support
* **Tesseract OCR / ML Kit** – For text extraction from images
* **AI/ML Models** – To analyze ingredients and suggest improvements
* **Platform Channels** – For native integration (C++, Swift, etc.)

---

## 🤝 Contributions Welcome

Want to help? Here's how:

```bash
# Fork the repo
# Create a feature branch
git checkout -b your-feature

# Make changes and commit
git commit -m "Added feature XYZ"

# Push your changes
git push origin your-feature

# Open a Pull Request
```

---

## 📄 License

This project is currently unlicensed. Please contact the maintainer if you plan to reuse it in production.

---

## 📬 Contact
For any inquiries or feedback, please reach out to devadigavikram1@gmail.com.

---
