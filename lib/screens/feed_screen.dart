import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../providers/providers.dart';
import '../widgets/item_card.dart';
import '../services/api_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _categories = ['All', 'Tech', 'Finance', 'Study', 'Personal', 'Entertainment', 'News', 'Health'];
  
  List<dynamic> _recommendations = [];
  bool _loadingRecommendations = true;
  String? _recommendationsError;

  @override
  void initState() {
    super.initState();
    // Load items when screen is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemsProvider>().loadItems();
      _loadRecommendations();
    });
  }
  
  Future<void> _loadRecommendations() async {
    try {
      print('[Feed] Loading recommendations...');
      final recommendations = await ApiService.getTodayRecommendations();
      print('[Feed] Got ${recommendations.length} recommendations');
      if (mounted) {
        setState(() {
          _recommendations = recommendations;
          _loadingRecommendations = false;
          _recommendationsError = null;
        });
      }
    } catch (e) {
      print('[Feed] Error loading recommendations: $e');
      if (mounted) {
        setState(() {
          _loadingRecommendations = false;
          _recommendationsError = e.toString();
          _recommendations = [];
        });
      }
    }
  }
  
  Future<void> _dismissRecommendation(String recId, String itemId, {String? reason}) async {
    try {
      await ApiService.dismissRecommendation(recId, itemId, reason: reason);
      if (mounted) {
        setState(() {
          _recommendations.removeWhere((r) => r['id'] == recId);
        });
      }
      print('[Feed] Dismissed recommendation: $recId');
    } catch (e) {
      print('[Feed] Error dismissing recommendation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ───
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Brain',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 4),
                  Consumer<ItemsProvider>(
                    builder: (context, provider, _) => Text(
                      '${provider.totalCount} memories',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ─── Category Chips ───
            SizedBox(
              height: 40,
              child: Consumer<ItemsProvider>(
                builder: (context, provider, _) => ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = provider.selectedCategory == cat;
                    final color = cat == 'All'
                        ? AppTheme.primary
                        : AppTheme.categoryColors[cat] ?? AppTheme.outline;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => provider.setCategory(cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.2)
                                : AppTheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? color.withValues(alpha: 0.5) : Colors.transparent,
                              width: 1,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 12)]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (cat != 'All') ...[
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                cat,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: isSelected ? color : AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

            const SizedBox(height: 16),

            // ─── Items List with Recommendations ───
            Expanded(
              child: Consumer<ItemsProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return _buildLoadingSkeleton();
                  }

                  if (provider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.wifi_off, size: 48, color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4)),
                          const SizedBox(height: 16),
                          Text(
                            'Couldn\'t connect to your brain',
                            style: GoogleFonts.inter(
                              fontSize: 16, 
                              color: AppTheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => provider.loadItems(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (provider.items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.psychology_outlined, size: 64, color: AppTheme.primary.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text(
                            'Your brain is empty',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start dumping links, notes, and ideas!',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn();
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      await provider.loadItems();
                      await _loadRecommendations();
                    },
                    color: AppTheme.primary,
                    backgroundColor: AppTheme.surfaceContainer,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: provider.items.length + 1, // +1 for recommendations section
                      itemBuilder: (context, index) {
                        // Add recommendations section at the top
                        if (index == 0) {
                          return _buildRecommendationsSection();
                        }

                        final item = provider.items[index - 1];
                        return ItemCard(item: item)
                            .animate()
                            .fadeIn(duration: 400.ms, delay: (50 * index).ms)
                            .slideY(begin: 0.05);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 120,
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
        ),
      ).animate(onPlay: (c) => c.repeat())
       .shimmer(duration: 1200.ms, color: AppTheme.surfaceContainerHigh),
    );
  }

  Widget _buildRecommendationsSection() {
    if (_loadingRecommendations) {
      return _buildRecommendationsLoading();
    }

    if (_recommendationsError != null) {
      print('[Feed] Recommendations error: $_recommendationsError');
      return const SizedBox.shrink();
    }

    if (_recommendations.isEmpty) {
      print('[Feed] No recommendations to show');
      return const SizedBox.shrink();
    }

    print('[Feed] Showing ${_recommendations.length} recommendations');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
          child: Row(
            children: [
              Text(
                '💡 RECOMMENDED FOR YOU',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_recommendations.length}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms),

        // Recommendations cards
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recommendations.length,
            itemBuilder: (context, index) {
              final rec = _recommendations[index];
              final item = rec['item'] ?? {};
              final score = rec['score'] ?? 0;
              final reason = rec['reason'] ?? '';

              return _buildRecommendationCard(
                item: item,
                score: score,
                reason: reason,
                recommendationId: rec['id'],
              ).animate()
                  .fadeIn(duration: 300.ms, delay: (50 * index).ms)
                  .slideX(begin: 0.1);
            },
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildRecommendationsLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
          child: Container(
            height: 20,
            width: 200,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
          ).animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1200.ms, color: AppTheme.surfaceContainerHigh),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) => Container(
              width: 140,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
            ).animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 1200.ms, color: AppTheme.surfaceContainerHigh),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildRecommendationCard({
    required Map<String, dynamic> item,
    required double score,
    required String reason,
    required String recommendationId,
  }) {
    final text = (item['content_raw'] as String?) ?? 'Untitled';
    final reasonBadge = _getReasonBadge(reason);
    final reasonLabel = _getReasonLabel(reason);

    return GestureDetector(
      onTap: () {
        // Navigate to detail screen
        Navigator.pushNamed(
          context,
          '/detail',
          arguments: item['id'],
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12, bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reason badge
                  reasonBadge,
                  const SizedBox(height: 6),
                  
                  // Reason label
                  Text(
                    reasonLabel,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.onSurfaceVariant,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Text (truncated)
                  Expanded(
                    child: Text(
                      text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.onSurface,
                        height: 1.3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Score bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: score / 100,
                      minHeight: 4,
                      backgroundColor: AppTheme.outline.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        score > 80
                            ? Colors.green
                            : score > 60
                                ? Colors.amber
                                : Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${score.toInt()}% match',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Dismiss button
            Positioned(
              top: 4,
              right: 4,
              child: SizedBox(
                width: 28,
                height: 28,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _dismissRecommendation(
                      recommendationId,
                      item['id'] ?? '',
                      reason: 'not_relevant',
                    ),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getReasonBadge(String reason) {
    final badgeColor = _getReasonColor(reason);
    final badgeIcon = _getReasonIcon(reason);
    final badgeLabel = _getReasonLabel(reason);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            badgeIcon,
            style: const TextStyle(fontSize: 10),
          ),
          const SizedBox(width: 3),
          Text(
            badgeLabel,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getReasonColor(String reason) {
    switch (reason) {
      case 'has_deadline':
      case 'has_deadline_and_unviewed':
        return const Color(0xFFC41C3B); // Red for urgent
      case 'unviewed':
        return const Color(0xFF6750A4); // Purple for fresh
      case 'not_viewed_recently':
        return const Color(0xFFFFA500); // Orange for old
      default:
        return AppTheme.onSurfaceVariant;
    }
  }

  String _getReasonIcon(String reason) {
    switch (reason) {
      case 'has_deadline':
      case 'has_deadline_and_unviewed':
        return '🔴';
      case 'unviewed':
        return '✨';
      case 'not_viewed_recently':
        return '⏰';
      default:
        return '💡';
    }
  }

  String _getReasonLabel(String reason) {
    switch (reason) {
      case 'has_deadline':
      case 'has_deadline_and_unviewed':
        return 'Urgent';
      case 'unviewed':
        return 'Fresh';
      case 'not_viewed_recently':
        return 'Rediscover';
      default:
        return 'Recommended';
    }
  }
}
