import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:pharma_five/ui/login_screen.dart';
import '../../helper/shared_preferences.dart';
import '../../service/api_service.dart';
import '../../model/product_listing_response_model.dart'; // Import the model
import '../admin_approval_screen.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({Key? key}) : super(key: key);

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _allProducts = [];
  List<Map<String, String>> _filteredProducts = [];

  int _currentPage = 0;
  final int _itemsPerPage = 10;
  bool _hasMore = true;
  bool _isLoading = true;
  bool _isProductsLoading = false; // Flag for product loading
  bool isUserActive = false;
  bool _isRefreshing = false;
  String _userStatus = 'pending'; // Store the actual status string
  String _lastRefreshed = ''; // Track when status was last checked
  String _errorMessage = ''; // Store error messages from API calls

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _validateUserAndLoadData();
  }

  Future<void> _validateUserAndLoadData() async {
    setState(() {
      _isLoading = true;
    });

    await SharedPreferenceHelper.init();
    final isLoggedIn = await SharedPreferenceHelper.isLoggedIn();
    final email = await SharedPreferenceHelper.getUserEmail();

    // Redirect to login if not logged in
    if (!isLoggedIn || email == null || email.isEmpty) {
      _navigateToLogin();
      return;
    }

    // Check user status via API
    try {
      final result = await ApiService().getUsers(search: email);
      final users = result['content'] ?? [];

      if (users.isNotEmpty) {
        final currentStatus = users[0]['status'].toString().toLowerCase();
        await SharedPreferenceHelper.setUserStatus(currentStatus);

        // Set last refreshed time
        final now = DateTime.now();
        final formattedTime = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

        // Update state based on user status
        setState(() {
          _userStatus = currentStatus; // Store the actual status string
          isUserActive = currentStatus == 'active';
          _isLoading = false;
          _isRefreshing = false;
          _lastRefreshed = formattedTime; // Store time of last refresh
        });

        // Only load product data if user is active
        if (isUserActive) {
          _loadProductData();
        }
      } else {
        // No user found in API response
        setState(() {
          _userStatus = 'not found';
          isUserActive = false;
          _isLoading = false;
          _isRefreshing = false;

          // Set last refreshed time
          final now = DateTime.now();
          _lastRefreshed = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
        });
      }
    } catch (e) {
      debugPrint('Status check failed: $e');

      // Fallback to local status if API fails
      final status = (await SharedPreferenceHelper.getUserStatus())?.toLowerCase() ?? 'pending';

      // Set last refreshed time
      final now = DateTime.now();
      final formattedTime = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

      setState(() {
        _userStatus = status;
        isUserActive = status == 'active';
        _isLoading = false;
        _isRefreshing = false;
        _lastRefreshed = formattedTime;
      });

      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not connect to server. Using local status.'),
          backgroundColor: Colors.orange,
        ),
      );

      // Load product data only if user is active (based on local status)
      if (isUserActive) {
        _loadProductData();
      }
    }
  }

  Future<void> _loadProductData() async {
    setState(() {
      _isProductsLoading = true;
      _errorMessage = '';
    });

    try {
      // Call the product listing API
      final products = await ApiService().fetchProductList();

      // Convert API response to the format used by the UI
      _allProducts = products.map((product) => {
        'medicineName': product.medicineName ?? 'Unknown Medicine',
        'genericName': product.genericName ?? 'Unknown Generic Name',
        // Add any other fields you want to display
      }).toList();

      _filteredProducts = List.from(_allProducts);
      _updateHasMore();

      setState(() {
        _isProductsLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading product data: $e');
      setState(() {
        _isProductsLoading = false;
        _errorMessage = 'Failed to load products. Please try again later.';
        _allProducts = [];
        _filteredProducts = [];
      });

      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToApprovalScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AdminApprovalScreen()),
    );
  }

  void _navigateToLogin() {
    SharedPreferenceHelper.clearSession().then((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _validateUserAndLoadData();
    }
  }

  void _updateHasMore() {
    final totalPages = (_filteredProducts.length / _itemsPerPage).ceil();
    _hasMore = _currentPage + 1 < totalPages;
  }

  Future<void> _logout() async {
    try {
      final email = await SharedPreferenceHelper.getUserEmail();
      if (email != null && email.isNotEmpty) {
        await ApiService().logoutUser(userEmail: email);
      }

      await SharedPreferenceHelper.clearSession();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    } catch (e) {
      debugPrint('Logout failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout failed. Please try again.')),
      );
    }
  }

  List<Map<String, String>> _getCurrentPageItems() {
    if (_filteredProducts.isEmpty) {
      return [];
    }

    int start = _currentPage * _itemsPerPage;
    int end = (_currentPage + 1) * _itemsPerPage;
    end = end > _filteredProducts.length ? _filteredProducts.length : end;
    return _filteredProducts.sublist(start, end);
  }

  Widget _buildPagination() {
    int totalPages = (_filteredProducts.length / _itemsPerPage).ceil();

    if (totalPages <= 0) {
      return const SizedBox.shrink();
    }

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

  Widget _buildAppBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final horizontalPadding = isSmallScreen ? 12.0 : 24.0;

    return Padding(
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
    );
  }

  // Get color based on status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'reject':
        return Colors.red;
      case 'blocked':
        return Colors.red.shade800;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Get status display text
  String _getStatusText() {
    switch (_userStatus.toLowerCase()) {
      case 'active':
        return 'Approved ✓';
      case 'reject':
        return 'Rejected ✗';
      case 'blocked':
        return 'Blocked ✗';
      case 'pending':
        return 'Pending Review';
      default:
        return 'Unknown';
    }
  }

  Widget _buildPendingApprovalMessage() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset("assets/animations/waiting.json",
                width: 300, height: 150),
            const SizedBox(height: 24),

            // Status indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Account Status: ",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff262A88),
                  ),
                ),
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(_userStatus),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Text(
              _userStatus == 'active'
                  ? "Your account is now approved! You can view products."
                  : "Your account has to be approved by Admin. Please wait.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _userStatus == 'active' ? Colors.green : const Color(0xff262A88),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _userStatus.toLowerCase() == 'rejected'
                  ? "Your application was not approved. Please contact support."
                  : (_userStatus.toLowerCase() == 'blocked'
                  ? "Your account has been blocked. Please contact support."
                  : "You will be able to view product listings once approved."),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _userStatus.toLowerCase() == 'rejected' || _userStatus.toLowerCase() == 'blocked'
                    ? Colors.red.shade700
                    : Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 20),

            // Refresh button with loading indicator
            _isRefreshing
                ? Column(
              children: [
                const CircularProgressIndicator(color: Color(0xff0e63ff)),
                const SizedBox(height: 8),
                Text(
                  "Checking status...",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            )
                : Column(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isRefreshing = true;
                    });
                    // Check status
                    _validateUserAndLoadData();
                  },
                  icon: const Icon(
                    Icons.refresh,
                    color: Color(0xff0e63ff),
                    size: 40,
                  ),
                ),
              ],
            ),

            // If active, show a button to view products
            if (_userStatus.toLowerCase() == 'active') ...[
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    // This will rebuild the UI with the product listing
                    // since isUserActive is already true at this point
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff0e63ff),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("View Products", style: TextStyle(fontSize: 16)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductListing() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final horizontalPadding = isSmallScreen ? 12.0 : 24.0;

    return Expanded(
      child: RefreshIndicator(
        onRefresh: () async {
          // Show refresh indicator
          setState(() {
            _isRefreshing = true;
          });
          // Check user status and reload data
          await _validateUserAndLoadData();
        },
        color: const Color(0xff0e63ff),
        backgroundColor: Colors.white,
        displacement: 40,
        strokeWidth: 3,
        child: Column(
          children: [
            // Search
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: TextField(
                controller: _searchController,
                onChanged: _searchProducts,
                decoration: InputDecoration(
                  hintText: 'Search Products',
                  // prefixIcon: const Icon(Icons.search),
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
                color: const Color(0xff185794),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: const [
                      Expanded(flex: 1, child: Text('No.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                      Expanded(flex: 3, child: Text('Medicine Name', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                      Expanded(flex: 3, child: Text('Generic Name', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Product List or Loading State
            _isProductsLoading
                ? const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xff0e63ff)),
                    SizedBox(height: 16),
                    Text(
                      "Loading products...",
                      style: TextStyle(
                        color: Color(0xff262A88),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
                : _errorMessage.isNotEmpty
                ? Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadProductData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff0e63ff),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Try Again"),
                    ),
                  ],
                ),
              ),
            )
                : _filteredProducts.isEmpty
                ? Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                        "assets/animations/no_data_found.json",
                        width: 200),
                    const SizedBox(height: 10),
                    Text(
                      _searchController.text.isEmpty
                          ? "No products available"
                          : "No products match your search",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
                : Expanded(
              child: _buildProductListView(horizontalPadding),
            ),

            // Only show pagination if there are products and no errors
            if (!_isProductsLoading && _errorMessage.isEmpty && _filteredProducts.isNotEmpty)
              _buildPagination(),
          ],
        ),
      ),
    );
  }

  // Extracted method for the ListView to use with RefreshIndicator
  Widget _buildProductListView(double horizontalPadding) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(), // Important for pull to refresh to work even when content doesn't fill screen
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      itemCount: _getCurrentPageItems().length + 1, // +1 for the pull to refresh instruction
      itemBuilder: (context, index) {
        // First item is a hint about pull to refresh
        if (index == 0) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: Text(
                "↓ Pull down to refresh account status ↓",
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          );
        }

        // Adjust index to account for the instruction item
        final adjustedIndex = index - 1;
        final item = _getCurrentPageItems()[adjustedIndex];
        final serial = _currentPage * _itemsPerPage + adjustedIndex + 1;

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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar (visible for both active and pending/rejected users)
            _buildAppBar(),

            // Content based on user status
            isUserActive
                ? _buildProductListing()
                : _buildPendingApprovalMessage(),
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
          backgroundColor: Colors.white,
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
                    onPressed: () {
                      Navigator.of(context).pop();
                      _logout();
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