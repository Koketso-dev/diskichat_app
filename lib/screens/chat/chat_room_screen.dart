import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/match_model.dart';
import '../../data/models/message_model.dart';
import '../../data/models/lineup_model.dart'; // Import
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart'; // Import
import '../../services/api_service.dart'; // Import
import '../../utils/themes/app_colors.dart';
import '../../utils/themes/text_styles.dart';
import '../../utils/themes/gradients.dart';
import '../../components/inputs/custom_text_field.dart';
import '../../components/common/loading_indicator.dart';
import '../../components/common/empty_state.dart';
import 'tabs/lineup_view.dart'; // Import
import 'tabs/events_view.dart'; // Import
import 'package:image_picker/image_picker.dart';
import 'video_player_screen.dart'; // Import

import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../../utils/constants/app_constants.dart';

class ChatRoomScreen extends StatefulWidget {
  final MatchModel match;

  const ChatRoomScreen({
    super.key,
    required this.match,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<LineupModel> _lineups = [];
  bool _isLoadingLineups = false;
  late MatchModel _match; // Local state for match (to allow updates)
  Timer? _timer;
  final FirestoreService _firestoreService = FirestoreService();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _match = widget.match; // Initialize with passed match
    _loadLineups();
    
    // Auto-refresh match data and lineups every 60s
    _timer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted) {
        _refreshMatchData();
        _loadLineups(); // Optional: Refresh lineups too if subs happen
      }
    });
    // Load messages and join room
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _joinRoom();
      context.read<ChatProvider>().loadMessages(widget.match.id);
      context.read<ChatProvider>().loadActiveUsersCount(widget.match.id);
    });
  }

  Future<void> _refreshMatchData() async {
    try {
      // Fetch single match doc from Firestore
      final docSnapshot = await _firestoreService.firestore
          .collection('matches')
          .doc(widget.match.id)
          .get();

      if (docSnapshot.exists && mounted) {
        final updatedMatch = MatchModel.fromMap(docSnapshot.data()!);
        // Add ID if missing (fromMap might handle it but being safe)
        final matchWithId = updatedMatch.copyWith(id: docSnapshot.id);
        
        if (_match != matchWithId) {
             setState(() {
              _match = matchWithId;
            });
        }
      }
    } catch (e) {
      debugPrint("Error refreshing match data: $e");
    }
  }

  Future<void> _loadLineups() async {
    setState(() => _isLoadingLineups = true);
    try {
      final lineups = await _firestoreService.getLineups(widget.match.id);
      if (mounted) {
        setState(() => _lineups = lineups);
      }
    } catch (e) {
      debugPrint('Error loading lineups: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingLineups = false);
      }
    }
  }

  Future<void> _joinRoom() async {
    try {
      await context.read<ChatProvider>().joinRoom(widget.match.id);
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Room Check'),
          content: Text(e.toString().replaceAll('Exception: ', '')),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Close screen
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _leaveRoom() {
    context.read<ChatProvider>().leaveRoom(widget.match.id);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final chatProvider = context.read<ChatProvider>();
    
    // Clear immediately for better UX
    _messageController.clear();

    final success = await chatProvider.sendMessage(
      matchId: widget.match.id,
      message: text,
    );

    if (!success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(chatProvider.errorMessage ?? 'Failed to send message')),
      );
    } else {
      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0, // Lists are often reversed for chat
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.primaryDark,
        appBar: AppBar(
          backgroundColor: AppColors.cardSurface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
            onPressed: () => Navigator.pop(context), // Resume later (keep joined)
          ),
          title: Text(
            widget.match.competitionName,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textWhite),
          ),
          centerTitle: true,
          actions: [
            // Live User Count
            Center(
              child: Consumer<ChatProvider>(
                builder: (_, provider, __) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    '${provider.activeUsersCount}/100',
                    style: AppTextStyles.caption.copyWith(
                      color: provider.activeUsersCount >= 100 
                          ? AppColors.errorRed 
                          : AppColors.liveGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: AppColors.errorRed),
              onPressed: _leaveRoom,
              tooltip: 'Leave Room',
            ),
          ],
        ),
        body: Column(
          children: [
            _buildMatchHeader(),
            Container(
              color: AppColors.cardSurface,
              child: const TabBar(
                labelColor: AppColors.accentBlue,
                unselectedLabelColor: AppColors.textGray,
                indicatorColor: AppColors.accentBlue,
                tabs: [
                  Tab(text: "Chat"),
                  Tab(text: "Line Ups"),
                  Tab(text: "Events"),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Chat (Existing Logic)
                  Column(
                    children: [
                      Expanded(child: _buildMessageList()),
                      _buildMessageInput(),
                    ],
                  ),
                  
                  // Tab 2: Line Ups
                  _isLoadingLineups 
                      ? const Center(child: LoadingIndicator()) 
                      : LineupView(lineups: _lineups, match: _match),
                  
                  // Tab 3: Events
                  EventsView(match: _match),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderTab(String message) {
    return Center(
      child: Text(
        message,
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textGray),
      ),
    );
  }

  Widget _buildMatchHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Home Team
          Expanded(
            child: Text(
              _match.homeTeam,
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
          
          // Score & Time
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Text(
                  _match.scoreDisplay,
                  style: AppTextStyles.scoreMedium.copyWith(fontSize: 18),
                ),
                Text(
                _match.isLive && _match.elapsedTime != null 
                    ? "${_match.elapsedTime}'" 
                    : _match.statusDisplay,
                style: AppTextStyles.caption.copyWith(
                  color: _match.isLive ? AppColors.liveGreen : AppColors.textGray,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ],
            ),
          ),

          // Away Team
          Expanded(
            child: Text(
              _match.awayTeam,
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        if (chatProvider.isLoading && chatProvider.messages.isEmpty) {
          return const LoadingIndicator();
        }

        final messages = chatProvider.messages;

        if (messages.isEmpty) {
          return EmptyState(
            icon: Icons.chat_bubble_outline,
            title: 'No messages yet',
            description: 'Be the first to cheer for your team!',
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          reverse: true, // Chat usually starts from bottom
          itemBuilder: (context, index) {
            final msg = messages[index];
            final currentUser = context.read<AuthProvider>().user;
            final isMe = currentUser != null && msg.userId == currentUser.uid;
            
            return _buildMessageItem(msg, isMe);
          },
        );
      },
    );
  }

  Widget _buildMessageItem(MessageModel msg, bool isMe) {
    return GestureDetector(
      onLongPress: () => _showMessageOptions(msg, isMe),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end, // Align to bottom for better bubble look
          children: [
            if (!isMe) ...[
               CircleAvatar(
                backgroundColor: AppColors.textGray,
                radius: 16,
                backgroundImage: msg.avatarUrl != null ? NetworkImage(msg.avatarUrl!) : null,
                child: msg.avatarUrl == null 
                    ? const Icon(Icons.person, size: 20, color: AppColors.primaryDark) 
                    : null,
              ),
              const SizedBox(width: 8),
            ],
            
            Flexible(
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                   Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.accentBlue : AppColors.cardSurface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 0),
                        bottomRight: Radius.circular(isMe ? 0 : 16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMe && msg.username != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              msg.username!,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        
                        // Media Rendering
                        if (msg.imageUrl != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: msg.imageUrl!,
                                placeholder: (context, url) => const SizedBox(
                                  height: 150, 
                                  width: 200, 
                                  child: Center(child: CircularProgressIndicator())
                                ),
                                errorWidget: (context, url, error) => const Icon(Icons.error),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),

                        if (msg.videoUrl != null)
                           GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VideoPlayerScreen(videoUrl: msg.videoUrl!),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Container(
                                height: 150,
                                width: 200,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Icon(Icons.play_circle_fill, size: 48, color: Colors.white.withOpacity(0.8)),
                                ),
                              ),
                            ),
                          ),

                        if (msg.message.isNotEmpty)
                          Text(
                            msg.message,
                            style: AppTextStyles.bodyMedium,
                          ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('HH:mm').format(msg.createdAt),
                          style: AppTextStyles.caption.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  
                  // Reactions Display
                  if (msg.reactions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 4,
                        children: _buildReactionChips(msg),
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

  List<Widget> _buildReactionChips(MessageModel msg) {
    // Group reactions by emoji
    final Map<String, int> counts = {};
    for (var emoji in msg.reactions.values) {
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }

    return counts.entries.map((entry) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.textGray.withOpacity(0.3)),
        ),
        child: Text(
          '${entry.key} ${entry.value}',
          style: const TextStyle(fontSize: 10, color: AppColors.textWhite),
        ),
      );
    }).toList();
  }

  void _showMessageOptions(MessageModel msg, bool isMe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reactions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['👍', '❤️', '😂', '😮', '😢', '😡'].map((emoji) {
                return GestureDetector(
                  onTap: () {
                    context.read<ChatProvider>().toggleReaction(
                      matchId: widget.match.id,
                      messageId: msg.id,
                      emoji: emoji,
                    );
                    Navigator.pop(context);
                  },
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                );
              }).toList(),
            ),
            
            if (isMe) ...[
              const SizedBox(height: 16),
              const Divider(color: AppColors.textGray),
              
              // Edit Option
              ListTile(
                leading: const Icon(Icons.edit, color: AppColors.accentBlue),
                title: const Text('Edit Message', style: TextStyle(color: AppColors.textWhite)),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(msg);
                },
              ),
              
              // Delete Option
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.errorRed),
                title: const Text('Delete Message', style: TextStyle(color: AppColors.textWhite)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(msg);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditDialog(MessageModel msg) {
    final editController = TextEditingController(text: msg.message);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text('Edit Message', style: TextStyle(color: AppColors.textWhite)),
        content: TextField(
          controller: editController,
          style: const TextStyle(color: AppColors.textWhite),
          decoration: const InputDecoration(
            hintText: 'Enter new message',
            hintStyle: TextStyle(color: AppColors.textGray),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.textGray)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accentBlue)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textGray)),
          ),
          TextButton(
            onPressed: () {
              final newText = editController.text.trim();
              if (newText.isNotEmpty && newText != msg.message) {
                context.read<ChatProvider>().editMessage(
                  matchId: widget.match.id,
                  messageId: msg.id,
                  newContent: newText,
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: AppColors.accentBlue)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(MessageModel msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text('Delete Message', style: TextStyle(color: AppColors.textWhite)),
        content: const Text('Are you sure you want to delete this message?', style: TextStyle(color: AppColors.textGray)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textGray)),
          ),
          TextButton(
            onPressed: () {
              context.read<ChatProvider>().deleteMessage(
                matchId: widget.match.id,
                messageId: msg.id,
              );
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.cardSurface,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.accentBlue),
            onPressed: _showAttachmentOptions,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CustomTextField(
              controller: _messageController,
              hintText: 'Join the conversation...',
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.primaryButton,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardSurface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo, color: AppColors.accentBlue),
              title: const Text('Photo', style: TextStyle(color: AppColors.textWhite)),
              onTap: () {
                Navigator.pop(context);
                _pickMedia(ImageSource.gallery, false);
              },
            ),
             ListTile(
              leading: const Icon(Icons.videocam, color: AppColors.accentBlue),
              title: const Text('Video', style: TextStyle(color: AppColors.textWhite)),
              onTap: () {
                Navigator.pop(context);
                _pickMedia(ImageSource.gallery, true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.accentBlue),
              title: const Text('Camera', style: TextStyle(color: AppColors.textWhite)),
              onTap: () {
                Navigator.pop(context);
                _pickMedia(ImageSource.camera, false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickMedia(ImageSource source, bool isVideo) async {
    final picker = ImagePicker();
    final XFile? file;
    
    try {
      if (isVideo) {
        file = await picker.pickVideo(source: source);
      } else {
        file = await picker.pickImage(source: source, imageQuality: 70);
      }

      if (file != null && mounted) {
        final success = await context.read<ChatProvider>().sendMediaMessage(
          matchId: widget.match.id, 
          file: File(file.path), 
          isVideo: isVideo
        );
        
        if (success && mounted) {
           if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking media: $e');
      if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Error picking media: $e')),
           );
      }
    }
  }
}
