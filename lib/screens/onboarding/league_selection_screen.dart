import 'package:flutter/material.dart';
import '../../components/avatars/custom_avatar.dart';
import '../../services/competitions_service.dart';
import '../../services/follow_service.dart';
import '../../services/subscription_service.dart';
import '../../utils/themes/app_colors.dart';
import '../../components/common/loading_indicator.dart';

class LeagueSelectionScreen extends StatefulWidget {
  final String userId;
  final String subscriptionType;
  final int currentFollowCount;

  const LeagueSelectionScreen({
    super.key,
    required this.userId,
    required this.subscriptionType,
    required this.currentFollowCount,
  });

  @override
  State<LeagueSelectionScreen> createState() => _LeagueSelectionScreenState();
}

class _LeagueSelectionScreenState extends State<LeagueSelectionScreen> {
  final CompetitionsService _compService = CompetitionsService();
  final FollowService _followService = FollowService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  
  List<League> _allLeagues = [];
  List<League> _filteredLeagues = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeagues();
  }

  Future<void> _loadLeagues() async {
    try {
      final leagues = await _compService.getCompetitions(); 
      setState(() {
        _allLeagues = leagues;
        _filteredLeagues = leagues;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load leagues: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterLeagues(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredLeagues = _allLeagues;
      } else {
        _filteredLeagues = _allLeagues.where((l) {
          return l.name.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _handleFollow(League league) async {
    if (!_subscriptionService.canFollowMoreLeagues(widget.currentFollowCount, widget.subscriptionType)) {
      _showLimitDialog();
      return;
    }

    try {
      await _followService.followLeague(widget.userId, league.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Followed ${league.name}')),
        );
        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limit Reached'),
        content: Text(
          'You are on the ${widget.subscriptionType} plan. You can only follow ${_subscriptionService.getLeagueLimit(widget.subscriptionType)} league(s). Upgrade to PRO to follow more.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('Follow a League'),
        backgroundColor: AppColors.primaryDark,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _filterLeagues,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search leagues...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: AppColors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: LoadingIndicator())
                : ListView.builder(
                    itemCount: _filteredLeagues.length,
                    itemBuilder: (context, index) {
                      final league = _filteredLeagues[index];
                      return ListTile(
                        leading: CustomAvatar(
                          imageUrl: league.logo,
                          size: 40,
                          placeholder: '?',
                        ),
                        title: Text(
                          league.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          league.country,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => _handleFollow(league),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentBlue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Follow'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
