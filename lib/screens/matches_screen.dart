import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/match_provider.dart';
import '../utils/themes/app_colors.dart';
import '../utils/themes/text_styles.dart';
import '../components/cards/match_card.dart';
import '../components/common/loading_indicator.dart';
import '../components/common/empty_state.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Load matches when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MatchProvider>(context, listen: false).loadMatches();
      // Start auto-refresh timer
      _startAutoRefresh();
    });
  }

  void _startAutoRefresh() {
    _timer = Timer.periodic(const Duration(seconds: 60), (timer) {
      debugPrint('MatchesScreen: Auto-refreshing matches...');
      Provider.of<MatchProvider>(context, listen: false).loadMatches();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: Text(
          'TODAY MATCH',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: Consumer<MatchProvider>(
        builder: (context, matchProvider, child) {
          if (matchProvider.isLoading) {
            return const LoadingIndicator();
          }

          final matches = matchProvider.matches;

          if (matches.isEmpty) {
            return EmptyState(
              icon: Icons.sports_soccer,
              title: 'No Matches Today',
              description: 'Check back later for live action',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              matchProvider.loadMatches();
            },
            color: AppColors.accentBlue,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Match of the Day Section
                if (matchProvider.matchOfTheDay != null) ...[
                  Row(
                    children: [
                       const Icon(Icons.star, color: AppColors.accentBlue, size: 20),
                       const SizedBox(width: 8),
                       Text(
                        'MATCH OF THE DAY',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  MatchCard(match: matchProvider.matchOfTheDay!),
                  const SizedBox(height: 24),
                  if (matches.isNotEmpty)
                    Text(
                      'ALL MATCHES',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                  const SizedBox(height: 12),
                ],

                // Live Matches List
                ...matches.map((match) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: MatchCard(match: match),
                )),

                if (matches.isEmpty && matchProvider.matchOfTheDay == null)
                   EmptyState(
                    icon: Icons.sports_soccer,
                    title: 'No Matches Today',
                    description: 'Check back later for live action',
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}