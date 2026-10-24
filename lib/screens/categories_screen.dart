import 'package:flutter/material.dart';

import '../store.dart';
import '../utils.dart';
import '../widgets.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SpentScope.of(context);
    final parts = s.month.split('-').map(int.parse).toList();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader('By category'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionTitle('${monthNames[parts[1] - 1]} ${parts[0]}'),
                        const SizedBox(height: 16),
                        CategoryBars(s.entriesFor(s.month)),
                      ],
                    ),
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
