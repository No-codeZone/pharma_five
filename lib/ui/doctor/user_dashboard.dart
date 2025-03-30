import 'package:flutter/material.dart';
import 'package:pharma_five/ui/login_screen.dart';
import '../../helper/shared_preferences.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({Key? key}) : super(key: key);

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _allProducts = [];
  List<Map<String, String>> _filteredProducts = [];

  int _currentPage = 0;
  final int _itemsPerPage = 10;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _allProducts = List.generate(50, (index) {
      return {
        'medicineName': 'Medicine name ${index + 1}',
        'genericName': 'Generic Name ${index + 1}'
      };
    });

    _filteredProducts = List.from(_allProducts);
    _updateHasMore();
  }

  void _searchProducts(String query) {
    setState(() {
      _filteredProducts = _allProducts
          .where((product) =>
      product['medicineName']!.toLowerCase().contains(query.toLowerCase()) ||
          product['genericName']!.toLowerCase().contains(query.toLowerCase()))
          .toList();
      _currentPage = 0;
      _updateHasMore();
    });
  }

  void _updateHasMore() {
    final totalPages = (_filteredProducts.length / _itemsPerPage).ceil();
    _hasMore = _currentPage + 1 < totalPages;
  }

  Future<void> _logout() async {
    await SharedPreferenceHelper.clearSession();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  List<Map<String, String>> _getCurrentPageItems() {
    int start = _currentPage * _itemsPerPage;
    int end = (_currentPage + 1) * _itemsPerPage;
    end = end > _filteredProducts.length ? _filteredProducts.length : end;
    return _filteredProducts.sublist(start, end);
  }

  Widget _buildPagination() {
    int totalPages = _hasMore
        ? (_filteredProducts.length / _itemsPerPage).ceil()
        : _currentPage + 1;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: List.generate(totalPages, (index) {
          final pageNumber = index + 1;
          final isSelected = index == _currentPage;

          return GestureDetector(
            onTap: () {
              setState(() {
                _currentPage = index;
                _updateHasMore();
              });
            },
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              child: Text(
                '$pageNumber',
                style: TextStyle(
                  color: const Color(0xff262A88),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: isSelected ? 18 : 14,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final horizontalPadding = isSmallScreen ? 12.0 : 24.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/pharmafive_512x512.png',
                    width: 60,
                    height: 60,
                    errorBuilder: (_, __, ___) =>
                    const Icon(Icons.local_pharmacy, size: 40, color: Colors.blue),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Color(0xff262A88), size: 28),
                    onPressed: _showLogoutDialog,
                  )
                ],
              ),
            ),

            // Search
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: TextField(
                controller: _searchController,
                onChanged: _searchProducts,
                decoration: InputDecoration(
                  hintText: 'Search Products',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _searchProducts('');
                    },
                  )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Table Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                color: Color(0xff185794),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: const [
                      Expanded(flex: 1, child: Text('No.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                      Expanded(flex: 3, child: Text('Medicine Name', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                      Expanded(flex: 3, child: Text('Generic Name', style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white))),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Product List
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: ListView.builder(
                  itemCount: _getCurrentPageItems().length,
                  itemBuilder: (context, index) {
                    final item = _getCurrentPageItems()[index];
                    final serial = _currentPage * _itemsPerPage + index + 1;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      color: Colors.white,
                      elevation: 1.5,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(flex: 1, child: Text('$serial')),
                            Expanded(flex: 3, child: Text(item['medicineName']!)),
                            Expanded(flex: 3, child: Text(item['genericName']!)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            _buildPagination(),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          actions: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  height: 30,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      side: const BorderSide(color: Color(0xff262A88)),
                      elevation: 0,
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const Expanded(child: SizedBox(width: 80)),
                SizedBox(
                  height: 30,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await SharedPreferenceHelper.clearSession();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                        );
                      } catch (e) {
                        print('Logout failed: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Logout failed. Please try again.')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                    child: const Text('Logout'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

}
