import 'package:flutter/material.dart';
import 'package:mobile/features/developer/view/edge_function_test_screen.dart';

class DeveloperMenuScreen extends StatefulWidget {
  const DeveloperMenuScreen({super.key});

  @override
  State<DeveloperMenuScreen> createState() => _DeveloperMenuScreenState();
}

class _DeveloperMenuScreenState extends State<DeveloperMenuScreen> {
  // ... (existing code)

  @override
  Widget build(BuildContext context) {
    // ... (existing code)

    return Scaffold(
      // ... (existing code)

      body: Column(
        children: [
          // ... (existing code)

          ListTile(
            title: const Text('Edge Function 테스트'),
            leading: const Icon(Icons.cloud_outlined),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EdgeFunctionTestScreen(),
                ),
              );
            },
          ),

          // ... (rest of the existing code)
        ],
      ),
    );
  }
}
