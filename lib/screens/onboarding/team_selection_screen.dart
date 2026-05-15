import 'package:flutter/material.dart';
import '../../data/models/team_model.dart';
import '../../services/teams_service.dart'; // Need to ensure this service exists or create it
import '../../services/follow_service.dart';
import '../../services/subscription_service.dart';
import '../../utils/themes/app_colors.dart';
import '../../components/common/loading_indicator.dart';
import '../../components/avatars/custom_avatar.dart';

class TeamSelectionScreen extends StatefulWidget {
  final String userId;
  final String subscriptionType;
  final int currentFollowCount;
  final String? countryName; // Country filter

  const TeamSelectionScreen({
    super.key,
    required this.userId,
    required this.subscriptionType,
    required this.currentFollowCount,
    this.countryName,
  });

  @override
  State<TeamSelectionScreen> createState() => _TeamSelectionScreenState();
}

class _TeamSelectionScreenState extends State<TeamSelectionScreen> {
  final TeamsService _teamsService = TeamsService();
  final FollowService _followService = FollowService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  
  List<Team> _allTeams = [];
  List<Team> _filteredTeams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    try {
      // Mocking fetch all teams or need to implement getTeams in service
      // Assuming getTeams returns list of teams
      final teams = await _teamsService.getTeams(country: widget.countryName); 
      setState(() {
        _allTeams = teams;
        _filteredTeams = teams;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load teams: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterTeams(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTeams = _allTeams;
      } else {
        _filteredTeams = _allTeams.where((team) {
          return team.name.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _handleFollow(Team team) async {
    if (!_subscriptionService.canFollowMoreTeams(widget.currentFollowCount, widget.subscriptionType)) {
      _showLimitDialog();
      return;
    }

    try {
      await _followService.followTeam(widget.userId, team.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Followed ${team.name}')),
        );
        Navigator.pop(context, team); // Return team object
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
          'You are on the ${widget.subscriptionType} plan. You can only follow ${_subscriptionService.getTeamLimit(widget.subscriptionType)} team(s). Upgrade to PRO to follow more.',
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
         title: const Text('Select Team'),
        backgroundColor: AppColors.primaryDark,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _filterTeams,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search teams...',
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
                : _filteredTeams.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.sports_soccer, size: 64, color: AppColors.textMuted),
                      const SizedBox(height: 16),
                      const Text(
                        'No teams found',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _filteredTeams.length,
                  itemBuilder: (context, index) {
                    final team = _filteredTeams[index];
                    return GestureDetector(
                      onTap: () => _handleFollow(team),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (team.logo != null && team.logo!.isNotEmpty)
                              CustomAvatar(
                                imageUrl: team.logo!,
                                size: 50,
                                placeholder: '?',
                              )
                            else
                              const Icon(Icons.shield, size: 50, color: Colors.grey),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                team.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
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
