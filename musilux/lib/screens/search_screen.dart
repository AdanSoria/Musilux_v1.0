import 'package:flutter/material.dart';
import '../widgets/shared_components.dart';
import '../theme/colors.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    return BaseLayout(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20 : 40,
          vertical: 30,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Buscar Productos',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                hintText: 'Ej. Guitarra eléctrica, Vinilo Rock, Luces LED...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.primaryPurple,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 20),
              ),
            ),
            const SizedBox(height: 40),
            const Center(
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 60, color: Colors.black26),
                  SizedBox(height: 16),
                  Text(
                    'Ingresa un término para comenzar a buscar.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
