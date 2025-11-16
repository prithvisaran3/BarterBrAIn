import 'package:flutter/material.dart';
import '../../core/constants.dart';

class SearchView extends StatelessWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar at the top
        SafeArea(
          bottom: false,
          child: Container(
            margin: const EdgeInsets.all(AppConstants.spacingM),
            height: 50,
            decoration: BoxDecoration(
              color: AppConstants.systemGray6,
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingM,
                  vertical: AppConstants.spacingM,
                ),
              ),
              onChanged: (value) {
                // TODO: Implement search
              },
            ),
          ),
        ),
        // Content
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 100), // Space for nav bar
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      size: 60,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingL),
                  Text(
                    'Search Products',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppConstants.spacingS),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingXl),
                    child: Text(
                      'Find items your campus mates are trading',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppConstants.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

