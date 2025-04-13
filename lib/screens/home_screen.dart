import 'package:flutter/material.dart';
import '../models/product_scan.dart';
import '../widgets/allergen_filter_chip.dart';
import '../widgets/recent_scan_item.dart';
import 'camera_screen.dart';
import 'search_page.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Sample allergen filters
  final List<Map<String, dynamic>> allergenFilters = [
    {'label': 'Gluten Free', 'status': 'safe', 'icon': Icons.check, 'color': Colors.green},
    {'label': 'Dairy', 'status': 'caution', 'icon': Icons.warning, 'color': Colors.orange},
    {'label': 'Peanuts', 'status': 'danger', 'icon': Icons.close, 'color': Colors.red},
    {'label': 'Soy', 'status': 'safe', 'icon': Icons.check, 'color': Colors.green},
    {'label': 'Shellfish', 'status': 'danger', 'icon': Icons.close, 'color': Colors.red},
  ];

  // Sample recent scans
  final List<ProductScan> recentScans = [
    ProductScan(
      name: "Nature's Path Organic Granola",
      status: ScanStatus.safe,
      description: "Gluten-free, No nuts",
      imagePath: "assets/images/granola.png",
      scanDate: DateTime.now().subtract(Duration(hours: 2)),
    ),
    ProductScan(
      name: "Greek Yogurt with Berries",
      status: ScanStatus.caution,
      description: "Contains dairy",
      imagePath: "assets/images/yogurt.png",
      scanDate: DateTime.now().subtract(Duration(hours: 4)),
    ),
    ProductScan(
      name: "Chocolate Chip Cookies",
      status: ScanStatus.danger,
      description: "Contains peanuts",
      imagePath: "assets/images/cookies.png",
      scanDate: DateTime.now().subtract(Duration(days: 1)),
    ),
  ];

  // Open Camera for Scanning
  void _openCamera() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CameraScreen()),
    );

    if (result != null) {
      print('Scanned Barcode: $result');
    }
  }

  // Navigate to Search Page
  void _openSearchPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SearchPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ App Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'HealthyChoice',
                      style: TextStyle(
                        color: Color(0xFF6D30EA),
                        fontSize: isSmallScreen ? 24 : 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.search, color: Colors.black),
                          onPressed: _openSearchPage,
                        ),
                        IconButton(
                          icon: Icon(Icons.notifications_none, color: Colors.black),
                          onPressed: () {}, // Placeholder for notifications
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ✅ Main Banner
              Container(
                width: double.infinity,
                height: isSmallScreen ? 120 : 160,
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6D30EA), Color(0xFF9B59B6)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(
                        Icons.qr_code_scanner,
                        size: isSmallScreen ? 100 : 120,
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Scan Your Food',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 24 : 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Check ingredients and allergens instantly',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: isSmallScreen ? 14 : 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ✅ Quick Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _buildQuickActionButton(
                        icon: Icons.qr_code_scanner,
                        label: 'Scan',
                        color: Color(0xFF6D30EA),
                        onTap: _openCamera,
                        isSmallScreen: isSmallScreen,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildQuickActionButton(
                        icon: Icons.search,
                        label: 'Search',
                        color: Colors.orange,
                        onTap: _openSearchPage,
                        isSmallScreen: isSmallScreen,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ✅ Recent Scans Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Recent Scans',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 20 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ✅ Recent Scans List (Scrollable)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentScans.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: RecentScanItem(
                      scan: recentScans[index],
                      isSmallScreen: isSmallScreen,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),

      // ✅ Floating Camera Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCamera,
        backgroundColor: const Color(0xFF6D30EA),
        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
        label: const Text(
          'Scan Product',
          style: TextStyle(color: Colors.white),
        ),
        elevation: 4,
      ),
    );
  }

  // ✅ Quick Action Button Builder
  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isSmallScreen,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: isSmallScreen ? 32 : 40),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
