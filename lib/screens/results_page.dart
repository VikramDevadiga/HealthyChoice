import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import '../models/analysis_result.dart';
import '../models/product_scan.dart';
import '../services/gemini_service.dart';
import '../services/scan_history_service.dart';
import '../services/service_provider.dart';
import '../widgets/analysis_display.dart';
import '../widgets/alternative_products_section.dart';

class ResultsPage extends StatefulWidget {
  final String barcode;
  const ResultsPage({super.key, required this.barcode});

  @override
  _ResultsPageState createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  late Future<Map<String, dynamic>> _productData;
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  
  // User preferences (these would normally come from a user profile service)
  final List<String> _userAvoidancePreferences = ['salt', 'sugar', 'palm oil']; // Example preferences
  
  // For Gemini analysis
  bool _isAnalyzing = false;
  bool _analysisExpanded = false;
  AnalysisResult? _analysisResult;
  final ServiceProvider _serviceProvider = ServiceProvider();
  
  // For favorite functionality
  bool _isFavorite = false;
  static const String _favoritesKey = 'favorite_products';

  @override
  void initState() {
    super.initState();
    _productData = ApiService.getProductInfo(widget.barcode);
    _checkIfFavorite();
    _initTts();
    
    // Set up listener to run analysis for unsafe products
    _productData.then((data) {
      final bool hasAllergens = data['allergens_tags'] != null && 
                              (data['allergens_tags'] as List).isNotEmpty;
      
      // Check for user avoidance preferences
      final bool hasAvoidedIngredients = _checkForAvoidedIngredients(data);
      
      if ((hasAllergens || hasAvoidedIngredients) && mounted) {
        // Automatically run analysis for unsafe or avoided products
        _runAnalysis(data);
      }
    }).catchError((error) {
      // Handle error
    });
  }
  
  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
  
  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  Future<void> _speak(Map<String, dynamic> productData) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() {
        _isSpeaking = false;
      });
      return;
    }
    
    setState(() {
      _isSpeaking = true;
    });
    
    String speechText = _generateProductSpeechText(productData);
    await _flutterTts.speak(speechText);
  }
  
  String _generateProductSpeechText(Map<String, dynamic> productData) {
    final StringBuffer speechText = StringBuffer();
    
    // Basic product information
    final String productName = productData['product_name'] ?? 'Unknown Product';
    final String brand = productData['brands'] ?? '';
    final String quantity = productData['quantity'] ?? '';
    
    speechText.write('Product information for $productName');
    if (brand.isNotEmpty) {
      speechText.write(' by $brand');
    }
    if (quantity.isNotEmpty) {
      speechText.write(', $quantity');
    }
    speechText.write('.\n\n');
    
    // Product categories and origin
    final String categories = productData['categories'] ?? '';
    final String origin = productData['countries'] ?? '';
    
    if (categories.isNotEmpty) {
      speechText.write('This product belongs to the following categories: $categories.\n');
    }
    if (origin.isNotEmpty) {
      speechText.write('Origin: $origin.\n');
    }
    
    // Nutri-Score and Nova score
    final String nutriScore = productData['nutriscore_grade']?.toString().toUpperCase() ?? '';
    if (nutriScore.isNotEmpty) {
      speechText.write('Nutri-Score: $nutriScore. ');
      
      switch (nutriScore.toUpperCase()) {
        case 'A':
          speechText.write('This is an excellent nutritional choice.');
          break;
        case 'B':
          speechText.write('This is a good nutritional choice.');
          break;
        case 'C':
          speechText.write('This product has average nutritional quality.');
          break;
        case 'D':
          speechText.write('This product has poor nutritional quality.');
          break;
        case 'E':
          speechText.write('This product has very poor nutritional quality.');
          break;
      }
      speechText.write('\n');
    }

    final String novaScore = productData['nova_group']?.toString() ?? '';
    if (novaScore.isNotEmpty) {
      speechText.write('Food processing classification: Nova group $novaScore. ');
      
      switch (novaScore) {
        case '1':
          speechText.write('This is unprocessed or minimally processed food.');
          break;
        case '2':
          speechText.write('This contains processed culinary ingredients.');
          break;
        case '3':
          speechText.write('This is processed food.');
          break;
        case '4':
          speechText.write('This is ultra-processed food.');
          break;
      }
      speechText.write('\n');
    }
    
    // Health safety information
    bool isSafe = true;
    if (_analysisResult != null && !_analysisResult!.isError) {
      isSafe = _analysisResult!.isSafeForUser;
      
      if (isSafe) {
        speechText.write('According to our analysis, this product is safe for you.\n');
        
        // Include compatibility information
        if (_analysisResult!.compatibility.isNotEmpty) {
          String compatibility = _analysisResult!.compatibility;
          speechText.write('Compatibility with your health profile: $compatibility. ');
          
          if (compatibility == 'good') {
            speechText.write('This product aligns well with your health goals and preferences.');
          } else if (compatibility == 'moderate') {
            speechText.write('This product is acceptable but there may be better alternatives for your needs.');
          } else if (compatibility == 'poor') {
            speechText.write('This product does not align well with your health goals or preferences.');
          }
          speechText.write('\n');
        }
        
        // Include health insights
        if (_analysisResult!.healthInsights.isNotEmpty) {
          speechText.write('Health insights: ${_analysisResult!.healthInsights.join('. ')}.\n');
        }
      } else {
        speechText.write('According to our analysis, this product may not be safe for you. ');
        speechText.write('${_analysisResult!.safetyReason}\n');
        speechText.write('${_analysisResult!.explanation}\n');
        
        if (_analysisResult!.recommendations.isNotEmpty) {
          speechText.write('Recommendations: ${_analysisResult!.recommendations.join('. ')}.\n');
        }
        
        // Mention alternatives if available
        if (_analysisResult!.alternatives.isNotEmpty) {
          speechText.write('We have found some alternatives that might be better for you. ');
          speechText.write('Please check the screen for details.\n');
        }
      }
    } else {
      // Basic allergy check
      final hasAllergens = productData['allergens_tags'] != null && 
                         (productData['allergens_tags'] as List).isNotEmpty;
      
      if (hasAllergens) {
        speechText.write('Warning: This product contains allergens. ');
        
        // List the allergens
        final allergens = productData['allergens_tags'] as List;
        if (allergens.isNotEmpty) {
          speechText.write('Allergens include: ');
          List<String> formattedAllergens = [];
          
          for (var allergen in allergens) {
            String name = allergen.toString().split(':').last.replaceAll('-', ' ');
            formattedAllergens.add(name);
          }
          
          speechText.write('${formattedAllergens.join(', ')}.\n');
        }
        
        isSafe = false;
      }
      
      // Check for avoided ingredients
      final hasAvoidedIngredients = _checkForAvoidedIngredients(productData);
      if (hasAvoidedIngredients) {
        speechText.write('This product contains ingredients you prefer to avoid, such as high levels of salt, sugar, or palm oil.\n');
      }
    }
    
    // Ingredients
    final String ingredients = productData['ingredients_text'] ?? '';
    if (ingredients.isNotEmpty && ingredients.length < 200) {
      speechText.write('\nIngredients: $ingredients\n');
    } else if (ingredients.isNotEmpty) {
      speechText.write('\nThis product contains multiple ingredients. Please check the screen for the full list.\n');
    }
    
    // Basic nutrition facts
    final Map<String, dynamic> nutriments = productData['nutriments'] ?? {};
    if (nutriments.isNotEmpty) {
      speechText.write('\nKey nutrition facts per 100 grams: ');
      
      if (nutriments['energy-kcal_100g'] != null) {
        speechText.write('${nutriments['energy-kcal_100g']?.toStringAsFixed(0) ?? '0'} calories, ');
      }
      
      if (nutriments['fat_100g'] != null) {
        speechText.write('${nutriments['fat_100g']?.toStringAsFixed(1) ?? '0'} grams of fat, ');
      }
      
      if (nutriments['carbohydrates_100g'] != null) {
        speechText.write('${nutriments['carbohydrates_100g']?.toStringAsFixed(1) ?? '0'} grams of carbohydrates, ');
      }
      
      if (nutriments['sugars_100g'] != null) {
        speechText.write('${nutriments['sugars_100g']?.toStringAsFixed(1) ?? '0'} grams of sugar, ');
      }
      
      if (nutriments['proteins_100g'] != null) {
        speechText.write('${nutriments['proteins_100g']?.toStringAsFixed(1) ?? '0'} grams of protein, ');
      }
      
      if (nutriments['salt_100g'] != null) {
        speechText.write('${nutriments['salt_100g']?.toStringAsFixed(2) ?? '0'} grams of salt.');
      }
      
      speechText.write('\n');
    }
    
    // Wrap up
    if (!isSafe) {
      speechText.write('\nPlease review the detailed information on screen for more specific health concerns.');
    } else {
      speechText.write('\nTap the button again to stop this voice explanation.');
    }
    
    return speechText.toString();
  }

  Future<void> _runAnalysis(Map<String, dynamic> productData) async {
    if (_analysisResult != null) {
      // Already have an analysis, just toggle expanded state
      setState(() {
        _analysisExpanded = !_analysisExpanded;
      });
      return;
    }
    
    setState(() {
      _isAnalyzing = true;
    });
    
    try {
      final geminiService = await _serviceProvider.getGeminiService();
      
      // Get analysis result - now the service will perform a quick check first
      // and only call the API if needed for complex cases
      final result = await geminiService.analyzeProductForUser(
        productData, 
        widget.barcode
      );
      
      if (mounted) {
        setState(() {
          _analysisResult = result;
          _isAnalyzing = false;
          _analysisExpanded = true;
          
          // If the result was obtained quickly, add a small delay for UI feedback
          // This prevents the UI from flickering too quickly for the user to notice
          if (result.explanation.contains("allergens") || result.explanation.contains("avoid")) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                setState(() {});
              }
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        // Try to do a quick safety check locally if API fails
        try {
          final geminiService = await _serviceProvider.getGeminiService();
          final quickResult = await geminiService.quickSafetyCheck(productData, widget.barcode);
          
          if (mounted) {
            setState(() {
              _analysisResult = quickResult;
              _isAnalyzing = false;
              _analysisExpanded = true;
            });
          }
          return;
        } catch (innerError) {
          // If that also fails, show generic error
          print('Both API and local safety check failed: $innerError');
        }
        
        setState(() {
          _analysisResult = AnalysisResult(
            isError: true,
            errorMessage: 'Analysis failed: ${e.toString()}',
            compatibility: 'unknown',
            explanation: 'Could not complete analysis. Check your internet connection.',
            recommendations: [],
            healthInsights: [],
          );
          _isAnalyzing = false;
          _analysisExpanded = true;
        });
      }
    }
  }
  
  void _toggleAnalysisExpanded() {
    setState(() {
      _analysisExpanded = !_analysisExpanded;
    });
  }

  bool _checkForAvoidedIngredients(Map<String, dynamic> productData) {
    // Check ingredients list
    final String ingredientsText = productData['ingredients_text']?.toLowerCase() ?? '';
    
    // Check nutrients
    final Map<String, dynamic> nutriments = productData['nutriments'] ?? {};
    
    // Check for avoided ingredients in the ingredients list
    for (String avoidedItem in _userAvoidancePreferences) {
      if (ingredientsText.contains(avoidedItem.toLowerCase())) {
        return true;
      }
    }
    
    // Check for high salt content if user wants to avoid salt
    if (_userAvoidancePreferences.contains('salt')) {
      final double saltContent = nutriments['salt_100g'] ?? 0.0;
      if (saltContent > 1.0) { // High salt content threshold (example value)
        return true;
      }
    }
    
    // Check for high sugar content if user wants to avoid sugar
    if (_userAvoidancePreferences.contains('sugar')) {
      final double sugarContent = nutriments['sugars_100g'] ?? 0.0;
      if (sugarContent > 10.0) { // High sugar content threshold (example value)
        return true;
      }
    }
    
    return false;
  }

  // Method to get alternative products for unsafe products
  Future<List<Map<String, dynamic>>> _fetchAlternatives(String barcode, Map<String, dynamic> productData) async {
    try {
      // Get Gemini service instance from the ServiceProvider
      final serviceProvider = ServiceProvider();
      final geminiService = await serviceProvider.getGeminiService();
      
      // Use Gemini to get personalized alternatives
      return await geminiService.getSuggestedAlternatives(
        productData,
        barcode,
      );
    } catch (e) {
      print('Error fetching alternatives: $e');
      
      // Fallback to basic alternatives if API fails
      final String category = productData['categories'] ?? '';
      
      return [
        {
          'product_name': 'Organic ${category.split(',').first}',
          'image_url': null, // No external image
          'nutriscore_grade': 'A',
          'brand': 'Organic Choice',
          'description': 'A healthier alternative with no additives or artificial ingredients.'
        },
        {
          'product_name': 'Low Sodium ${category.split(',').first}',
          'image_url': null, // No external image
          'nutriscore_grade': 'B',
          'brand': 'Health Valley',
          'description': 'Contains 75% less sodium than regular products, perfect for low-salt diets.'
        },
      ];
    }
  }

  // Save to scan history for easy access later
  Future<void> _saveToScanHistory(Map<String, dynamic> productData) async {
    try {
      // Extract necessary data for scan history
      final String productName = productData['product_name'] ?? 'Unknown Product';
      final String description = productData['brands'] ?? '';
      
      // Get the product image directly from the API data
      String imageUrl = '';
      if (productData['image_url'] != null) {
        imageUrl = productData['image_url'];
      } else if (productData['image_front_url'] != null) {
        imageUrl = productData['image_front_url'];
      } else if (productData['image_small_url'] != null) {
        imageUrl = productData['image_small_url'];
      }
      
      // Determine product safety status
      ScanStatus status = ScanStatus.caution;
      if (_analysisResult != null) {
        status = _analysisResult!.isSafeForUser ? ScanStatus.safe : ScanStatus.danger;
      } else {
        // Basic determination based on allergens if analysis not done
        final bool hasAllergens = productData['allergens_tags'] != null && 
                               (productData['allergens_tags'] as List).isNotEmpty;
        final bool hasAvoidedIngredients = _checkForAvoidedIngredients(productData);
        
        if (hasAllergens) {
          status = ScanStatus.danger;
        } else if (hasAvoidedIngredients) {
          status = ScanStatus.caution;
        } else {
          status = ScanStatus.safe;
        }
      }
      
      // Create ProductScan object
      final scan = ProductScan(
        name: productName,
        status: status,
        description: description,
        imagePath: imageUrl, // Use only the API image URL
        scanDate: DateTime.now(),
        barcode: widget.barcode,
      );
      
      // Save to history
      await ScanHistoryService.saveProductScan(scan);
    } catch (e) {
      print('Error saving to scan history: $e');
    }
  }

  // Check if product is in favorites
  Future<void> _checkIfFavorite() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteProducts = prefs.getStringList(_favoritesKey) ?? [];
      
      setState(() {
        _isFavorite = favoriteProducts.contains(widget.barcode);
      });
    } catch (e) {
      print('Error checking favorites: $e');
    }
  }
  
  // Toggle favorite status
  Future<void> _toggleFavorite() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteProducts = prefs.getStringList(_favoritesKey) ?? [];
      
      setState(() {
        if (_isFavorite) {
          // Remove from favorites
          favoriteProducts.remove(widget.barcode);
          _isFavorite = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed from favorites'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          // Add to favorites
          favoriteProducts.add(widget.barcode);
          _isFavorite = true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added to favorites'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      });
      
      // Save updated list
      await prefs.setStringList(_favoritesKey, favoriteProducts);
    } catch (e) {
      print('Error updating favorites: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update favorites'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Share product information using clipboard and a snackbar
  Future<void> _shareProduct(Map<String, dynamic> productData) async {
    try {
      final String productName = productData['product_name'] ?? 'Unknown Product';
      final String brand = productData['brands'] ?? '';
      
      // Create text to share
      String shareText = 'Check out this product: $productName';
      if (brand.isNotEmpty) {
        shareText += ' by $brand';
      }
      
      shareText += '\nBarcode: ${widget.barcode}';
      shareText += '\n\nScanned with HealthyChoice app';
      
      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: shareText));
      
      // Show successful copy message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Copied to clipboard!', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Text('Paste in your messaging app to share', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OPEN WHATSAPP',
            textColor: Colors.white,
            onPressed: () {
              _openWhatsApp(shareText);
            },
          ),
        ),
      );
    } catch (e) {
      print('Error preparing share: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error copying to clipboard. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _openWhatsApp(String text) async {
    try {
      final encodedText = Uri.encodeComponent(text);
      final whatsappUrl = Uri.parse('https://wa.me/?text=$encodedText');
      
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch WhatsApp';
      }
    } catch (e) {
      print('Error opening WhatsApp: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open WhatsApp. Text is copied to clipboard.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _productData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || _isAnalyzing) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF4CAF50),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isAnalyzing ? "Analyzing product..." : "Loading product data...",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                    const SizedBox(height: 16),
                    Text(
                      "Failed to load product data",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Please check your internet connection and try again.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text("Go Back"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else if (snapshot.hasData) {
            final productData = snapshot.data!;
            
            // Initialize with basic check for UI rendering 
            // (we'll get more detailed safety info from the analysis)
            bool hasAllergens = productData['allergens_tags'] != null && 
                               (productData['allergens_tags'] as List).isNotEmpty;
            bool hasAvoidedIngredients = _checkForAvoidedIngredients(productData);
            bool isSafe = !hasAllergens; // Initial safety determination based on allergens
            bool matchesPreferences = !hasAvoidedIngredients;
            
            // Get a more comprehensive safety determination if the initial check is uncertain
            if (_analysisResult != null) {
              // Use the detailed analysis result if already available
              isSafe = _analysisResult!.isSafeForUser;
            } else {
              // If there's potential concern, start the analysis immediately
              if (hasAllergens || hasAvoidedIngredients) {
                // This will trigger the analysis in the background
                _runAnalysis(productData);
              }
            }
            
            // Save to scan history
            _saveToScanHistory(productData);

            return SafeArea(
              child: CustomScrollView(
                slivers: [
                  // Header with gradient (fixed height)
                  SliverToBoxAdapter(
                    child: Container(
                      height: 110,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                        ),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.arrow_back, color: Colors.black),
                            ),
                          ),
                          const Text(
                            "Product Analysis",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => _shareProduct(productData),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.copy, color: Colors.black),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _toggleFavorite,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                                    color: _isFavorite ? Colors.red : Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Product information in scrollable cards
                  SliverList(
                    delegate: SliverChildListDelegate([
                      // Product Info Card
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: productData['image_url'] != null
                                        ? Image.network(
                                            productData['image_url']!,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return _buildPlaceholderImage(100, 100);
                                            },
                                          )
                                        : _buildPlaceholderImage(100, 100),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            spacing: 4, 
                                            runSpacing: 4,
                                            children: [
                                              if (productData['brands'] != null)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.shade100,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    productData['brands']!,
                                                    style: TextStyle(
                                                      color: Colors.blue.shade800,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            productData['product_name'] ?? "Unknown Product",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black.withOpacity(0.8),
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          if (productData['quantity'] != null)
                                            Text(
                                              productData['quantity']!,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade700,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      if (productData['categories'] != null)
                                        _buildInfoChip(
                                          Icons.category,
                                          "Categories",
                                          productData['categories']!,
                                        ),
                                      const SizedBox(width: 8),
                                      if (productData['countries'] != null)
                                        _buildInfoChip(
                                          Icons.public,
                                          "Origin",
                                          productData['countries']!,
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: isSafe ? Colors.green.shade50 : Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSafe ? Colors.green.shade200 : Colors.red.shade200,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              isSafe ? Icons.check_circle : Icons.warning,
                                              color: isSafe ? Colors.green : Colors.red,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              isSafe ? "Safe for you" : "Not safe for you",
                                              style: TextStyle(
                                                color: isSafe ? Colors.green.shade700 : Colors.red.shade700,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Add preference match indicator
                                if (isSafe && !matchesPreferences) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade50,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.amber.shade200,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.info_outline,
                                                color: Colors.amber.shade700,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  "Contains ingredients you prefer to avoid",
                                                  style: TextStyle(
                                                    color: Colors.amber.shade700,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // AI Analysis card (if product is not safe)
                      if (!isSafe)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: _buildFixedExpandablePanel(
                            context,
                            productData,
                            isSafe,
                            matchesPreferences,
                          ),
                        ),
                      
                      // Health Analysis Section Title
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Text(
                          "Health Analysis",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black.withOpacity(0.8),
                          ),
                        ),
                      ),

                      // Nutrition Facts
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: _buildNutrientsSection(productData, screenWidth),
                      ),
                      
                      // Ingredients
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: _buildSectionCard(
                          title: "Ingredients",
                          icon: Icons.receipt,
                          content: productData['ingredients_text'] != null
                              ? Text(
                                  productData['ingredients_text']!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black.withOpacity(0.7),
                                    height: 1.5,
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    "No ingredients information available",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      
                      // Allergens
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: _buildSectionCard(
                          title: "Allergens",
                          icon: Icons.warning_amber,
                          content: productData['allergens_tags'] != null
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if ((productData['allergens_tags'] as List).isNotEmpty) ...[
                                      Text(
                                        "This product contains the following allergens:",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.red.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: (productData['allergens_tags'] as List)
                                            .map((allergen) => _formatAllergen(allergen))
                                            .toList()
                                            .cast<Widget>(),
                                      ),
                                    ] else
                                      Text(
                                        "Good news! No allergens detected in this product.",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                )
                              : Center(
                                  child: Text(
                                    "No allergen information available",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      
                      // Additives
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: _buildSectionCard(
                          title: "Additives",
                          icon: Icons.science,
                          content: productData['additives_tags'] != null && 
                                  (productData['additives_tags'] as List).isNotEmpty
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "This product contains the following additives:",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: (productData['additives_tags'] as List)
                                          .map((additive) => _buildAdditive(additive))
                                          .toList()
                                          .cast<Widget>(),
                                    ),
                                  ],
                                )
                              : Center(
                                  child: Text(
                                    "No additives detected",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      
                      // Personalized Nutri-Score explanation
                      if (_analysisResult != null && !_isAnalyzing) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: _buildPersonalizedNutriScoreExplanation(context, _analysisResult!),
                        ),
                      ],
                      
                      // Action Buttons
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _speak(productData);
                                },
                                icon: Icon(_isSpeaking ? Icons.stop : Icons.volume_up),
                                label: Text(_isSpeaking ? "Stop" : "Listen"),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: const Color(0xFF4CAF50),
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(color: Color(0xFF4CAF50)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.qr_code_scanner),
                                label: const Text("New Scan"),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: const Color(0xFF6D30EA),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: Text("No data available"));
          }
        },
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(
                width: 120, // Fixed width to prevent overflow
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: const Color(0xFF4CAF50),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _formatAllergen(String allergen) {
    // Extract allergen name (e.g., "en:milk" to "Milk")
    final name = allergen.split(':').last.replaceAll('-', ' ');
    final formattedName = name.split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        formattedName,
        style: TextStyle(
          fontSize: 12,
          color: Colors.red.shade900,
        ),
      ),
    );
  }

  Widget _buildAdditive(String additive) {
    // Extract additive code (e.g., "e100" from "en:e100")
    final code = additive.split(':').last.toUpperCase();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Text(
        code,
        style: TextStyle(
          fontSize: 12,
          color: Colors.orange.shade900,
        ),
      ),
    );
  }

  Widget _buildNutrientsSection(Map<String, dynamic> productData, double screenWidth) {
    final nutriments = productData['nutriments'] ?? {};
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.restaurant,
                  color: const Color(0xFF4CAF50),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "Nutrition Facts",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Nutrient Summary (scrollable horizontal list of cards)
          Container(
            height: 100,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildNutrientCard(
                  "Calories", 
                  "${nutriments['energy-kcal_100g']?.toStringAsFixed(0) ?? '0'} kcal",
                  Icons.local_fire_department,
                  Colors.orange,
                ),
                _buildNutrientCard(
                  "Fat", 
                  "${nutriments['fat_100g']?.toStringAsFixed(1) ?? '0'} g",
                  Icons.opacity,
                  Colors.yellow.shade800,
                ),
                _buildNutrientCard(
                  "Carbs", 
                  "${nutriments['carbohydrates_100g']?.toStringAsFixed(1) ?? '0'} g",
                  Icons.grain,
                  Colors.amber,
                ),
                _buildNutrientCard(
                  "Protein", 
                  "${nutriments['proteins_100g']?.toStringAsFixed(1) ?? '0'} g",
                  Icons.fitness_center,
                  Colors.blue,
                ),
                _buildNutrientCard(
                  "Sodium", 
                  "${nutriments['sodium_100g']?.toStringAsFixed(3) ?? '0'} g",
                  Icons.water_drop,
                  Colors.red,
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Nutrient Meters with reduced padding
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                _buildNutrientMeter(
                  context,
                  "NOVA Group (Food Processing)",
                  productData['nova_group']?.toString() ?? '3',
                  _getNovaGroupPercentage(productData['nova_group']?.toString() ?? '3'),
                  isNova: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 85,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.black.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  double _getNutriScorePercentage(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
        return 20.0;
      case 'B':
        return 40.0;
      case 'C':
        return 60.0;
      case 'D':
        return 80.0;
      case 'E':
        return 100.0;
      default:
        return 60.0;
    }
  }

  double _getNovaGroupPercentage(String group) {
    switch (group) {
      case '1':
        return 25.0;
      case '2':
        return 50.0;
      case '3':
        return 75.0;
      case '4':
        return 100.0;
      default:
        return 75.0;
    }
  }

  Widget _buildNutrientMeter(
    BuildContext context,
    String title,
    String grade,
    double percentage, {
    bool isNova = false,
  }) {
    final availableWidth = MediaQuery.of(context).size.width - 64; // Accounting for paddings
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isNova ? _getNovaColor(grade) : _getNutriScoreColor(grade),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                grade,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            // Background track
            Container(
              height: 6,
              width: availableWidth,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // Filled portion
            Container(
              height: 6,
              width: availableWidth * (percentage / 100),
              decoration: BoxDecoration(
                color: isNova ? _getNovaColor(grade) : _getNutriScoreColor(grade),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: isNova
              ? [
                  Text('Unprocessed', style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
                  Text('Highly processed', style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
                ]
              : [
                  Text('Healthier', style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
                  Text('Less healthy', style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
                ],
        ),
      ],
    );
  }

  Color _getNutriScoreColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
        return const Color(0xFF1E8F4E); // Dark green
      case 'B':
        return const Color(0xFF68BB59); // Light green
      case 'C':
        return const Color(0xFFFFC107); // Yellow
      case 'D':
        return const Color(0xFFFF9800); // Orange
      case 'E':
        return const Color(0xFFE53935); // Red
      default:
        return const Color(0xFFFFC107); // Default yellow
    }
  }

  Color _getNovaColor(String group) {
    switch (group) {
      case '1':
        return const Color(0xFF1E8F4E); // Dark green
      case '2':
        return const Color(0xFF68BB59); // Light green
      case '3':
        return const Color(0xFFFF9800); // Orange
      case '4':
        return const Color(0xFFE53935); // Red
      default:
        return const Color(0xFFFF9800); // Default orange
    }
  }

  // Calculate personalized score based on AI analysis
  String _getPersonalizedNutriScore(AnalysisResult? analysis) {
    if (analysis == null) return 'C'; // Default score if no analysis
    
    // Determine score based on compatibility
    switch (analysis.compatibility.toLowerCase()) {
      case 'good':
      case 'excellent':
        return 'A';
      case 'moderate':
        return 'B';
      case 'fair':
        return 'C';
      case 'poor':
        return 'D';
      case 'bad':
      case 'avoid':
        return 'E';
      default:
        return 'C'; // Default moderate score
    }
  }

  // Add a new method to build the personalized Nutri-Score explanation section
  Widget _buildPersonalizedNutriScoreExplanation(BuildContext context, AnalysisResult analysis) {
    // Calculate score on demand without caching to ensure it's fresh
    final String score = _getPersonalizedNutriScore(analysis);
    
    // Define explanation text for each grade
    Map<String, String> gradeExplanations = {
      'A': 'Excellent choice for your health profile. This product aligns very well with your nutritional needs.',
      'B': 'Good option for your health profile. This product generally meets your nutritional needs.',
      'C': 'Acceptable option but consider in moderation. This product has some nutritional aspects that may not be ideal for you.',
      'D': 'Less suitable for your health profile. This product contains elements that may not align with your nutritional needs.',
      'E': 'Not recommended for your health profile. This product contains elements that contradict your nutritional needs.'
    };
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.stars,
                color: Colors.purple.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                "Your Personalized Nutri-Score",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _getNutriScoreColor(score),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  score,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  gradeExplanations[score] ?? "Personalized nutritional assessment based on your health profile.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            "Understanding Your Score:",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 12),
          // Grade scale with explanations
          _buildGradeScaleItem('A', 'Excellent', Colors.green.shade800),
          _buildGradeScaleItem('B', 'Good', Colors.green.shade600),
          _buildGradeScaleItem('C', 'Acceptable', Colors.amber.shade700),
          _buildGradeScaleItem('D', 'Less Suitable', Colors.orange.shade800),
          _buildGradeScaleItem('E', 'Not Recommended', Colors.red.shade700),
        ],
      ),
    );
  }
  
  Widget _buildGradeScaleItem(String grade, String meaning, Color color) {
    final currentGrade = _analysisResult != null ? _getPersonalizedNutriScore(_analysisResult) : '';
    final bool isCurrentGrade = grade == currentGrade;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(isCurrentGrade ? 1.0 : 0.7),
              borderRadius: BorderRadius.circular(6),
              border: isCurrentGrade 
                ? Border.all(color: Colors.white, width: 2) 
                : null,
              boxShadow: isCurrentGrade
                ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, spreadRadius: 1)]
                : null,
            ),
            child: Text(
              grade,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isCurrentGrade ? FontWeight.bold : FontWeight.normal,
                fontSize: isCurrentGrade ? 16 : 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            meaning,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isCurrentGrade ? FontWeight.bold : FontWeight.normal,
              color: isCurrentGrade ? color : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedExpandablePanel(
    BuildContext context,
    Map<String, dynamic> productData,
    bool isSafe,
    bool matchesPreferences,
  ) {
    // Since we only show this for unsafe products, always use red color
    final mainColor = Colors.red;
    
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter panelSetState) {
        // Handle tap to expand/collapse or run analysis
        void togglePanel() async {
          if (_analysisResult == null && !_isAnalyzing) {
            // Start analysis and update both states
            setState(() => _isAnalyzing = true);
            panelSetState(() => _isAnalyzing = true);
            
            // Run analysis
            await _runAnalysis(productData);
            
            if (mounted) {
              setState(() {
                _isAnalyzing = false;
                _analysisExpanded = true;
              });
              panelSetState(() {
                _isAnalyzing = false;
                _analysisExpanded = true;
              });
            }
          } else {
            // Just toggle expansion
            final newState = !_analysisExpanded;
            setState(() => _analysisExpanded = newState);
            panelSetState(() => _analysisExpanded = newState);
          }
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: mainColor.shade200,
              width: 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header - always visible
              Material(
                color: mainColor.shade50,
                child: InkWell(
                  onTap: togglePanel,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.health_and_safety,
                          color: mainColor.shade700,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "AI Health Analysis",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: mainColor.shade800,
                            ),
                          ),
                        ),
                        _isAnalyzing
                          ? SizedBox(
                              width: 20, 
                              height: 20, 
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(mainColor.shade700),
                              )
                            )
                          : Icon(
                              _analysisExpanded ? Icons.expand_less : Icons.expand_more,
                              color: mainColor.shade700,
                            ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Expandable content - use explicit if/else logic instead of AnimatedCrossFade
              if (_analysisExpanded)
                _buildAnalysisContent(productData, isSafe, matchesPreferences),
            ],
          ),
        );
      }
    );
  }
  
  Widget _buildAnalysisContent(Map<String, dynamic> productData, bool isSafe, bool matchesPreferences) {
    // Since we only show this for unsafe products, always use red color
    final mainColor = Colors.red;
    
    if (_isAnalyzing) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(mainColor.shade400),
              ),
              const SizedBox(height: 16),
              Text(
                "Analyzing this product with AI...",
                style: TextStyle(
                  color: mainColor.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_analysisResult == null) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: const Text("No analysis available"),
      );
    }
    
    if (_analysisResult!.isError) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Text(
          _analysisResult!.errorMessage,
          style: TextStyle(color: mainColor.shade800),
        ),
      );
    }
    
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Section divider
          Divider(color: mainColor.shade100),
          const SizedBox(height: 12),
          
          // Explanation
          Text(
            !isSafe 
              ? "Why this product may not be safe for you:"
              : "Why you might want to avoid this product:",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: mainColor.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _analysisResult!.explanation,
            style: const TextStyle(
              fontSize: 14, 
              height: 1.5,
              color: Colors.black87,
            ),
          ),
          
          // Health Insights
          if (_analysisResult!.healthInsights.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              "Key Health Insights:",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: mainColor.shade800,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(
              _analysisResult!.healthInsights.length,
              (index) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: mainColor.shade50.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: mainColor.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: mainColor.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _analysisResult!.healthInsights[index],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black.withOpacity(0.8),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          // Recommendations
          if (_analysisResult!.recommendations.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              "Recommendations:",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(
              _analysisResult!.recommendations.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.tips_and_updates,
                      size: 20,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _analysisResult!.recommendations[index],
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          // Alternatives section
          if (!isSafe) ...[
            const SizedBox(height: 20),
            Text(
              "Healthier Alternatives:",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6D30EA),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 210,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchAlternatives(widget.barcode, productData),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF6D30EA),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Finding healthier alternatives...",
                            style: TextStyle(
                               color: Color(0xFF6D30EA),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (snapshot.hasError || !snapshot.hasData) {
                    return Center(
                      child: Text(
                        "Couldn't find alternatives at this time",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    );
                  } else {
                    final alternatives = snapshot.data!;
                    // Filter alternatives to ensure only equal or better Nutri-Score is shown
                    final nutriScoreMap = {
                      'A': 1, 'B': 2, 'C': 3, 'D': 4, 'E': 5
                    };
                    
                    // Get original product's Nutri-Score
                    final originalNutriScore = 
                      (productData['nutriscore_grade'] ?? 'E').toString().toUpperCase();
                    
                    // Filter alternatives with better or equal Nutri-Score
                    final filteredAlternatives = alternatives.where((alt) {
                      final altNutriScore = (alt['nutriscore_grade'] ?? 'E').toString().toUpperCase();
                      
                      // If original is B, only show A
                      if (originalNutriScore == 'B' && altNutriScore != 'A') {
                        return false;
                      }
                      
                      // For other grades, ensure alternative is better or equal
                      final originalScore = nutriScoreMap[originalNutriScore] ?? 5;
                      final alternativeScore = nutriScoreMap[altNutriScore] ?? 5;
                      
                      return alternativeScore <= originalScore;
                    }).toList();
                    
                    // Show message if no suitable alternatives after filtering
                    if (filteredAlternatives.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline, 
                              color: Colors.grey.shade400, size: 32),
                            const SizedBox(height: 12),
                            Text(
                              "No better alternatives found for this product",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: filteredAlternatives.length,
                      itemBuilder: (context, index) {
                        final alternative = filteredAlternatives[index];
                        return Container(
                          width: 160,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.green.shade100,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nutriscore badge in header section
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(11),
                                    topRight: Radius.circular(11),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getNutriScoreColor(alternative['nutriscore_grade'] ?? 'B'),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        "Nutri-Score ${alternative['nutriscore_grade']?.toUpperCase() ?? 'B'}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Details with more padding without image
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      alternative['brand'] ?? '',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      alternative['product_name'] ?? 'Alternative Product',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      alternative['description'] ?? '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade800,
                                        height: 1.3,
                                      ),
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Add this helper method for consistent placeholder images
  Widget _buildPlaceholderImage(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.no_photography,
            color: Colors.grey.shade400,
            size: height > 50 ? 40 : 24,
          ),
          if (height > 60)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                "No image",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
