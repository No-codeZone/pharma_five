import 'package:flutter/material.dart';

class AdminProductListing extends StatefulWidget {
  @override
  _AdminProductListingState createState() => _AdminProductListingState();
}

class _AdminProductListingState extends State<AdminProductListing> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, String>> allProducts = List.generate(
    10,
        (index) => {
      "medicine": "Medicine name${index + 1}",
      "generic": "Generic Name ${index + 1}",
    },
  );

  List<Map<String, String>> filteredProducts = [];

  @override
  void initState() {
    super.initState();
    filteredProducts = List.from(allProducts);
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredProducts = allProducts
          .where((product) =>
      product["medicine"]!.toLowerCase().contains(query) ||
          product["generic"]!.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          Expanded(flex: 1, child: Center(child: Text('No.', style: TextStyle(color: Colors.white)))),
          Expanded(flex: 3, child: Center(child: Text('Medicine name', style: TextStyle(color: Colors.white)))),
          Expanded(flex: 3, child: Center(child: Text('Generic Name', style: TextStyle(color: Colors.white)))),
          Expanded(flex: 1, child: Center(child: Text('Edit', style: TextStyle(color: Colors.white)))),
        ],
      ),
    );
  }

  Widget _buildTableRow(int index, Map<String, String> product) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Row(
          children: [
            Expanded(flex: 1, child: Text('${index + 1}.')),
            Expanded(flex: 3, child: Text(product["medicine"]!)),
            Expanded(flex: 3, child: Text(product["generic"]!)),
            Expanded(
              flex: 1,
              child: IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.black45,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.people), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.assignment), label: ''),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      // decoration: BoxDecoration(
                      //   color: Colors.grey.shade200,
                      //   borderRadius: BorderRadius.circular(10),
                      // ),
                      child: const Text("Products Lists", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(12),
                      ),
                      onPressed: () {},
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildTableHeader(),
                const SizedBox(height: 4),
                Expanded(
                  child: filteredProducts.isEmpty
                      ? const Center(child: Text("No products found."))
                      : ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) =>
                        _buildTableRow(index, filteredProducts[index]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
