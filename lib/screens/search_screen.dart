import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../app/theme.dart';
import '../models/item.dart';
import '../providers/providers.dart';
import '../widgets/item_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isNotEmpty) {
        context.read<SearchProvider>().search(query.trim());
      } else {
        context.read<SearchProvider>().clearSearch();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Search Bar ───
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                decoration: glassDecoration(withGlow: _searchController.text.isNotEmpty),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppTheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search your memory...',
                    hintStyle: GoogleFonts.inter(
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                      fontSize: 16,
                    ),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppTheme.onSurfaceVariant),
                            onPressed: () {
                              _searchController.clear();
                              context.read<SearchProvider>().clearSearch();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 16),

            // ─── Results ───
            Expanded(
              child: Consumer<SearchProvider>(
                builder: (context, provider, _) {
                  if (provider.isSearching) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primary.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Searching your brain...',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (provider.query.isEmpty) {
                    return _buildEmptyState();
                  }

                  if (provider.results.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off, size: 48, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text(
                            'No memories found',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try different words',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: provider.results.length,
                    itemBuilder: (context, index) {
                      final result = provider.results[index];
                      final similarity = (result['similarity'] as num?)?.toDouble() ?? 0;
                      final item = Item.fromJson(result);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Similarity badge
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 4),
                            child: Text(
                              '${(similarity * 100).toStringAsFixed(0)}% match',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          ItemCard(item: item),
                        ],
                      ).animate()
                       .fadeIn(duration: 400.ms, delay: (80 * index).ms)
                       .slideX(begin: 0.05);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.psychology_outlined,
            size: 80,
            color: AppTheme.primary.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 20),
          Text(
            'What are you looking for?',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search naturally — like asking a friend',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildSuggestionChip('startup articles'),
              _buildSuggestionChip('machine learning'),
              _buildSuggestionChip('saved last week'),
              _buildSuggestionChip('finance tips'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () {
        _searchController.text = text;
        context.read<SearchProvider>().search(text);
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.secondaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          '"$text"',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppTheme.secondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
