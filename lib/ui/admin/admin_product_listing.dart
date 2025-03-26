import 'package:flutter/material.dart';

class AdminProductListing extends StatefulWidget {
  const AdminProductListing({super.key});

  @override
  State<AdminProductListing> createState() => _AdminProductListingState();
}

class _AdminProductListingState extends State<AdminProductListing> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products Lists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              // TODO: Implement add product functionality
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) {
                return _buildProductListItem(index + 1);
              },
            ),
          ),
          _buildPaginationRow(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildProductListItem(int index) {
    return ListTile(
      leading: Text(
        '$index',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      title: Text('Medicine name$index'),
      subtitle: Text('Generic Name $index'),
      trailing: IconButton(
        icon: const Icon(Icons.edit_outlined),
        onPressed: () {
          // TODO: Implement edit functionality
        },
      ),
    );
  }

  Widget _buildPaginationRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              // TODO: Implement previous page functionality
            },
          ),
          ...List.generate(
            5,
                (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement page selection
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text('${index + 1}'),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              // TODO: Implement next page functionality
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.camera_alt_outlined),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list_outlined),
          label: '',
        ),
      ],
    );
  }
}