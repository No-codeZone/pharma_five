import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_snake_navigationbar/flutter_snake_navigationbar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:pharma_five/helper/color_manager.dart';
import 'package:pharma_five/service/api_service.dart';
import 'dart:io' show InternetAddress, SocketException;
import 'package:lottie/lottie.dart';
import 'package:pharma_five/ui/admin/admin_product_listing.dart';
import '../../helper/shared_preferences.dart';
import '../login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedItemPosition = 0;
  String selectedStatus = 'Pending';
  int currentPage = 1;
  late int totalPages = 5;
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  bool selectedBottomMenu = false;
  final ApiService _apiService = ApiService();
  List<dynamic> _usersList = [];
  late int _currentPage = 0;
  bool _hasMore = true;
  bool _isConnected = true;
  final TextEditingController _searchController = TextEditingController();
  late int _currentProductPage = 0;
  bool _hasMoreProduct = true;
  List<Map<String, String>> _filteredProductList = [];
  final List<Map<String, String>> _productList = List.generate(
    10,
        (index) => {
      "medicineName": "Medicine name ${index + 1}",
      "genericName": "Generic Name ${index + 1}",
    },
  );


  @override
  void initState() {
    super.initState();
    selectedStatus = 'Pending';
    _checkLoginStatus();
    _fetchUsers();
    _updateInternetStatus();
    /*_filteredProductList = List.from(_productList);

    _searchController.addListener(() {
      _filterProducts(_searchController.text);
    });*/

    // Initialize the product list and filtered list
    _filteredProductList = List.from(_productList);

    // Set up the search controller listener
    _searchController.addListener(_onSearchChanged);

    // Debug statement to confirm product list initialization
    debugPrint('Initial product list length: ${_productList.length}');
    debugPrint('Initial filtered product list length: ${_filteredProductList.length}');
    /*setState(() {
      filteredProducts = List.from(allProducts);
      _searchController.addListener(_onSearchChanged);
    });*/
  }


  Future<bool> _checkInternetConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  void _updateInternetStatus() async {
    _isConnected = await _checkInternetConnectivity();
    setState(() {});  // Trigger UI update
  }

  ///including admin
  /*Future<void> _fetchUsers() async {

    // Check internet connectivity first
    bool isConnected = await _checkInternetConnectivity();

    if (!isConnected) {
      setState(() {
        _isLoading = false;
        _hasMore = false;
        _usersList = [];
      });
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.getUsers(
        page: _currentPage,
        size: 10,
        status: selectedStatus,
      );

      setState(() {
        // Extract the content from the response
        _usersList = (response['content'] ?? []).map((user) {
          // Additional mapping if needed
          return {
            ...user,
            'status': _mapStatusToFrontend(user['status'] ?? 'PENDING')
          };
        }).toList();

        _isLoading = false;

        // Update pagination information
        _hasMore = !(response['last'] ?? true);
        totalPages = response['totalPages'] ?? 1;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasMore = false;
        _usersList = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load users: $e')),
      );
    }
  }*/

  ///excluding admin
  Future<void> _fetchUsers() async {
    // Check internet connectivity first
    bool isConnected = await _checkInternetConnectivity();

    if (!isConnected) {
      setState(() {
        _isLoading = false;
        _hasMore = false;
        _usersList = [];
      });
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.getUsers(
        page: _currentPage,
        size: 10,
        status: selectedStatus,
        excludeAdmin: true, // Add this parameter to exclude admin users
      );

      setState(() {
        // Extract the content from the response
        _usersList = (response['content'] ?? []).map((user) {
          // Additional mapping if needed
          return {
            ...user,
            'status': _mapStatusToFrontend(user['status'] ?? 'PENDING')
          };
        }).toList();

        _isLoading = false;

        // Update pagination information
        _hasMore = !(response['last'] ?? true);
        totalPages = response['totalPages'] ?? 1;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasMore = false;
        _usersList = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load users: $e')),
      );
    }
  }

// Helper method to map status
  String _mapStatusToFrontend(String backendStatus) {
    switch (backendStatus.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'active':
        return 'Approved';
      case 'reject':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  void _showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: isError ? Colors.red : const Color(0xFF0E8388),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> _updateStatus(int id, String newStatus) async {
    final user = _usersList.firstWhere(
          (u) => _safeIntConvert(u['id']) == id,
      orElse: () => null,
    );

    if (user == null || user['email'] == null) {
      debugPrint("User or email not found for ID: $id");
      return;
    }

    final url = Uri.parse("${ApiService().baseUrl}/update-status");
    final requestBody = {
      "email": user['email'],
      "status": newStatus, // "Active" or "Reject"
    };

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['success'] == true) {
        debugPrint("Status updated successfully for ${user['email']}");
        _showToast("Status updated successfully for ${user['email']}", isError: false);

        // Immediately refresh the list
        setState(() {
          _currentPage = 0; // Reset to first page
          _usersList.clear(); // Clear existing data
        });

        // Fetch users with the current selected status
        await _fetchUsers();
      } else {
        debugPrint("Status update failed: ${response.body}");
        _showToast("Status update failed: ${response.body}", isError: true);
      }
    } catch (e) {
      debugPrint("Error updating status: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating status: $e")),
      );
    }
  }

  void _refreshUserList() async{
    setState(() {
      _currentPage = 0; // Reset to first page
      _usersList.clear(); // Clear existing data
      _isLoading = true;
      _hasMore = true;
    });
    await _fetchUsers();
    // Fetch updated user list (you need to implement this function)
    // _fetchUsers().then((_) {
      setState(() {
        _isLoading = false;
      });
    // });
  }

  Future<void> _checkLoginStatus() async {
    try {
      bool isLoggedIn = await SharedPreferenceHelper.isLoggedIn();
      String? userType = await SharedPreferenceHelper.getUserType();

      if (!isLoggedIn || userType != 'admin') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error checking login status: $e');
      // Fallback to login screen in case of any error
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to get screen size and adjust layout
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 500;
    final isLargeScreen = screenWidth > 1200;

    // Responsive padding and font sizes
    final horizontalPadding =
        isSmallScreen ? 10.0 : (isLargeScreen ? 40.0 : 20.0);
    final logoSize = isSmallScreen ? 60.0 : 80.0;
    final titleFontSize = isSmallScreen ? 16.0 : 18.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Header with responsive layout
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding, vertical: 8),
                  child: Row(
                    children: [
                      // Logo with responsive sizing
                      Image.asset(
                        'assets/images/pharmafive_512x512.png',
                        width: logoSize,
                        height: logoSize,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.language,
                            size: logoSize * 0.6,
                            color: Colors.blue,
                          );
                        },
                      ),
                      const Spacer(),

                      // Dropdown only for users tab
                      if (_selectedItemPosition == 0)
                        Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: const Color(0xff262A88)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: _buildStatusDropdown()),
                      if (_selectedItemPosition == 1)
                        Container(
                          margin: const EdgeInsets.only(left: 16, right: 20),
                          width: screenWidth * 0.6,
                          height: 40,
                          child: TextField(
                            controller: _searchController,
                            decoration:
                            InputDecoration(
                              hintText: 'Search Products',
                              // prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterProducts('');
                                },
                              )
                                  : null,
                              filled: true,
                              fillColor: Color(0xffece9e9),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.blue[800]!, width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.blue[800]!, width: 2.0),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Content with responsive margin
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding, vertical: 8),
                    child: _buildContent(),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              border: Border.all(color: ColorManager.navBorder, width: 2),
              borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(30), right: Radius.circular(30)),
            ),
            child: SnakeNavigationBar.color(
              behaviour: SnakeBarBehaviour.floating,
              snakeShape: SnakeShape.circle,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              snakeViewColor: ColorManager.navBorder,
              unselectedItemColor: ColorManager.navBorder,
              currentIndex: _selectedItemPosition,
              onTap: (index) => setState(() => _selectedItemPosition = index),
              items: [
                BottomNavigationBarItem(
                  icon: _selectedItemPosition == 0
                      ? Image.asset("assets/images/user_lists.png",
                          height: 16, width: 16)
                      : Image.asset("assets/images/user_list2.png",
                          height: 26, width: 26),
                ),
                BottomNavigationBarItem(
                  icon: _selectedItemPosition == 1
                      ? Image.asset("assets/images/product_list.png",
                          height: 16, width: 16)
                      : Image.asset("assets/images/product_list2.png",
                          height: 26, width: 26),
                ),
                BottomNavigationBarItem(
                  icon: _selectedItemPosition == 2
                      ? Image.asset("assets/images/reports.png",
                          height: 16, width: 16)
                      : Image.asset("assets/images/report2.png",
                          height: 26, width: 26),
                ),
              ],
              selectedLabelStyle: TextStyle(fontSize: titleFontSize - 2),
              unselectedLabelStyle: TextStyle(fontSize: titleFontSize - 2),
              showUnselectedLabels: true,
              showSelectedLabels: true,
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    switch (_selectedItemPosition) {
      case 0:
        return _buildUsersContent();
      case 1:
        // return AdminProductListing();
        return _adminProductListing();
      case 2:
        return _buildReportsContent();
      default:
        return _buildUsersContent();
    }
  }

  Widget _adminProductListing(){
    debugPrint('Rendering product listing... Found ${_filteredProductList.length} products');

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 16),
                  child: const Text("Products Lists",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(15),
                            left: Radius.circular(15))),
                    padding: const EdgeInsets.all(12),
                  ),
                  onPressed: () {
                    debugPrint("Add product..!");
                    _showAddProductDialog();
                  },
                  child: const Icon(Icons.add, color: Colors.white,),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildTableHeader(),
            const SizedBox(height: 4),
            Expanded(
              child: _filteredProductList.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset("assets/animations/no_data_found.json", width: 200),
                    const SizedBox(height: 10),
                    const Text("No products found.", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 20),
                    // Add a refresh button to reinitialize the product list
                    /*ElevatedButton(
                      onPressed: () {
                        setState(() {
                          // Reinitialize the product list
                          _filteredProductList = List.from(_productList);
                          debugPrint('Refreshed product list: ${_filteredProductList.length} items');
                        });
                      },
                      child: const Text("Refresh Products"),
                    ),*/
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: _filteredProductList.length,
                itemBuilder: (context, index) =>
                    _buildTableRow(index, _filteredProductList[index]),
              ),
            ),
            buildProductPagination()
          ],
        ),
      ),
    );
  }

  Widget buildProductPagination() {
    // Only show pagination if we actually have products
    if (_filteredProductList.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate total pages based on product list size
    final int totalProducts = _productList.length;
    final int productsPerPage = 10;
    final int calculatedTotalPages = (totalProducts / productsPerPage).ceil();
    final int totalPages = _hasMoreProduct ? calculatedTotalPages : _currentProductPage + 1;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: List.generate(totalPages > 0 ? totalPages : 1, (index) {
          final pageNumber = index + 1;
          final isSelected = index == _currentProductPage;

          return GestureDetector(
            onTap: () {
              setState(() {
                _currentProductPage = index;
                // Implement pagination logic here if needed
                // For now, just keep the full list available
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
                    fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: isSelected ? 18 : 14),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildUsersContent() {
    return Column(
      children: [
        // List title
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          child: Text(
            '${selectedStatus} Lists',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // List content
        Expanded(
          child: buildUserList(),
        ),

        // Pagination
        buildPagination(),
      ],
    );
  }

  void _showEditProductDialog(Map<String, String> product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Create text controllers with existing product data
        final medicineNameController = TextEditingController(text: product['medicineName']);
        final genericNameController = TextEditingController(text: product['genericName']);

        return AlertDialog(
          title: const Text('Edit Product'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: medicineNameController,
                decoration: const InputDecoration(
                  labelText: 'Medicine Name',
                ),
              ),
              TextField(
                controller: genericNameController,
                decoration: const InputDecoration(
                  labelText: 'Generic Name',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement update product logic
                Navigator.of(context).pop();
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.blue[800],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: const [
          Expanded(
              flex: 1,
              child: Center(
                  child: Text('No.',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)))),
          Expanded(
              flex: 3,
              child: Center(
                  child: Text('Medicine name',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)))),
          Expanded(
              flex: 3,
              child: Center(
                  child: Text('Generic Name',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)))),
          Expanded(
              flex: 1,
              child: Center(
                  child: Text('Edit',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)))),
        ],
      ),
    );
  }

  Widget _buildTableRow(int index, Map<String, String> product) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Expanded(flex: 1, child: Text('${index + 1}.')),
            Expanded(flex: 3, child: Text(product["medicineName"]!)),
            Expanded(flex: 3, child: Text(product["genericName"]!)),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.edit, color: Colors.grey.shade800, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSearchChanged() {
    String query = _searchController.text.toLowerCase();
    debugPrint('Searching: "$query"');

    setState(() {
      if (query.isEmpty) {
        // If no search query, show all products
        _filteredProductList = List.from(_productList);
      } else {
        // Filter products based on search query
        _filteredProductList = _productList
            .where((product) =>
        product["medicineName"]!.toLowerCase().contains(query) ||
            product["genericName"]!.toLowerCase().contains(query))
            .toList();
      }

      debugPrint('Filtered count: ${_filteredProductList.length}');
    });
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final medicineNameController = TextEditingController();
        final genericNameController = TextEditingController();

        return AlertDialog(
          title: const Text('Add New Product'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: medicineNameController,
                decoration: const InputDecoration(
                  labelText: 'Medicine Name',
                ),
              ),
              TextField(
                controller: genericNameController,
                decoration: const InputDecoration(
                  labelText: 'Generic Name',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement add product logic
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReportsContent() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          child: const Text(
            'Reports',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReportCard(
                  'User Statistics',
                  Icons.person_outline,
                  Colors.blue,
                  'Total Users: 156',
                ),
                const SizedBox(height: 16),
                _buildReportCard(
                  'Medicine Analytics',
                  Icons.medication_outlined,
                  Colors.green,
                  'Total Medicines: 243',
                ),
                const SizedBox(height: 16),
                _buildReportCard(
                  'Approval Rate',
                  Icons.check_circle_outline,
                  Colors.orange,
                  'Approval Rate: 78%',
                ),
                const Spacer(),
                // Logout button
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Logout logic
                      _showLogoutDialog();
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff262A88),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportCard(
      String title, IconData icon, Color color, String content) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Last updated: Today',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
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

  Widget buildUserList() {
    // Show no internet connection screen first
    if (!_isConnected) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              "assets/animations/internet.json",
              width: 250,
              height: 250,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Internet Connection',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                _updateInternetStatus(); // Retry checking internet status
                _fetchUsers(); // Retry fetching users if internet is back
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show loading indicator if data is being fetched
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Loading...', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    // Show no data animation only when the internet is available and list is empty
    if (_usersList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              "assets/animations/no_data_found.json",
              width: 250,
              height: 250,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${selectedStatus.toLowerCase()} users found',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    // Show user list when data is available
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _usersList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _usersList[index];
        int serialNumber = (_currentPage * 10) + index + 1;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              )
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Serial
              SizedBox(
                width: 30,
                child: Text(
                  '$serialNumber.',
                  style: const TextStyle(fontSize: 13),
                ),
              ),

              // Name
              Expanded(
                flex: 2,
                child: Text(
                  item['name'] ?? 'Unknown',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ),

              // Organization
              Expanded(
                flex: 3,
                child: Text(
                  item['organisationName'] ?? 'N/A',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
              ),

              // Status
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 80),
                child: buildStatusIndicator(item['status'], item['id']),
              ),
            ],
          ),
        );
      },
    );
  }

  // Method to fetch more users when scrolling
  void _fetchMoreUsers() {
    setState(() {
      _currentPage++;
    });
    _fetchUsers();
  }

  Widget buildStatusIndicator(dynamic status, dynamic id) {
    final String userStatus = _normalizeStatus(status);
    final int userId = _safeIntConvert(id);
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isCompact = screenWidth < 400;

    const double iconSize = 10;
    const double circlePadding = 6;
    const double spacing = 10;

    switch (userStatus) {
      case 'pending':
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _statusCircle(
              color: Colors.red,
              icon: Icons.close,
              onTap: () => _showRejectDialog(userId),
              size: iconSize,
              padding: circlePadding,
            ),
            SizedBox(width: spacing),
            _statusCircle(
              color: Colors.green,
              icon: Icons.check,
              onTap: () => _showApproveDialog(userId),
              size: iconSize,
              padding: circlePadding,
            ),
          ],
        );

      case 'approved':
        return Row(
          children: [
            _statusLabel('Approved', Colors.green),
            SizedBox(width: spacing),
            _editCircle(() => _showRejectDialog(userId)),
          ],
        );

      case 'rejected':
        return Row(
          children: [
            _statusLabel('Rejected', Colors.red),
            SizedBox(width: spacing),
            _editCircle(() => _showApproveDialog(userId)),
          ],
        );

      default:
        return const SizedBox();
    }
  }

  Widget _statusCircle({
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    double size = 8,
    double padding = 2,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }

  Widget _editCircle(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.edit, color: Colors.grey.shade800, size: 14),
      ),
    );
  }

  Widget _statusLabel(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProductList = List.from(_productList);
      } else {
        _filteredProductList = _productList.where((product) {
          final medicineName = product['medicineName']!.toLowerCase();
          final genericName = product['genericName']!.toLowerCase();
          return medicineName.contains(query.toLowerCase()) ||
              genericName.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

// Helper method to normalize status
  String _normalizeStatus(dynamic status) {
    if (status == null) return 'pending';

    final String statusString = status.toString().toLowerCase().trim();

    switch (statusString) {
      case 'pending':
      case 'new':
        return 'pending';
      case 'approved':
      case 'active':
        return 'approved';
      case 'rejected':
      case 'reject':
      case 'inactive':
        return 'rejected';
      default:
        return 'pending';
    }
  }

// Safe integer conversion method
  int _safeIntConvert(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    if (value is num) {
      return value.toInt();
    }

    // If all conversions fail, return 0
    return 0;
  }

  void _showApproveDialog(int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          content: const Text(
            'Do you want to approve the request?',
            textAlign: TextAlign.center,
          ),
          actions: [
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  height: 30,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      side: const BorderSide(color: Color(0xff262A88)),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Text('Cancel'),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const Expanded(
                    child: SizedBox(
                  width: 80,
                )),
                SizedBox(
                  height: 30,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Text('Yes, Approve'),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _updateStatus(id, 'Active');
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showRejectDialog(int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          content: const Text(
            'Do you want to reject the request?',
            textAlign: TextAlign.center,
          ),
          actions: [
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  height: 30,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      side: const BorderSide(color: Color(0xff262A88)),
                    ),
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const Expanded(
                    child: SizedBox(
                  width: 80,
                )),
                SizedBox(
                  height: 30,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10)))),
                    child: const Text('Yes, Reject'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _updateStatus(id, 'Reject');
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /*void _updateStatus(dynamic id, String newStatus) async {
    // Use the safe conversion method
    final userId = _safeIntConvert(id);

    try {
      final url = Uri.parse("${_apiService.baseUrl}/update-status");
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': userId,
          'status': newStatus.toUpperCase()
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _currentPage = 0;
          _usersList.clear();
        });
        _fetchUsers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }*/

  Widget _buildStatusDropdown() {
    return DropdownButton<String>(
      value: selectedStatus,
      underline: Container(),
      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xff262A88)),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            selectedStatus = newValue;
            _currentPage = 0; // Reset to first page
            _hasMore = true; // Reset has more flag
          });
          _fetchUsers();
        }
      },
      items: <String>['Pending', 'Approved', 'Rejected']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }

  // Modify the existing method to filter users when status changes
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh list when status changes
    // _fetchUsers();
  }

  Widget buildPagination() {
    // Dynamically calculate total pages based on _hasMore flag
    final int totalPages = _hasMore ? 5 : _currentPage + 1;

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
                _fetchUsers();
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
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: isSelected ? 18 : 14),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
