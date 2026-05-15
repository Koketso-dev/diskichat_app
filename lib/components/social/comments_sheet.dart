import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../data/models/comment_model.dart';
import '../../providers/auth_provider.dart';
import '../../utils/themes/app_colors.dart';
import '../../utils/themes/text_styles.dart';
import '../../components/avatars/custom_avatar.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentsSheet extends StatefulWidget {
  final String postId;

  const CommentsSheet({super.key, required this.postId});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isSending = false;
  String? _editingCommentId; // Track which comment is being edited

  void _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final user = context.read<AuthProvider>().user;
    final profile = context.read<AuthProvider>().userProfile;
    
    if (user == null) return;

    setState(() => _isSending = true);

    try {
      if (_editingCommentId != null) {
        // Update existing comment
        await _firestoreService.updateComment(widget.postId, _editingCommentId!, text);
        setState(() {
          _editingCommentId = null;
        });
      } else {
        // Create new comment
          final comment = CommentModel(
          id: '',
          postId: widget.postId,
          userId: user.uid,
          username: profile?.username ?? user.displayName ?? 'Anonymous',
          userAvatar: profile?.avatarUrl ?? user.photoURL,
          content: text,
          createdAt: DateTime.now(),
        );

        await _firestoreService.addComment(comment);
      }
      
      _commentController.clear();
      FocusManager.instance.primaryFocus?.unfocus(); // Dismiss keyboard
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text("Comments", style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // List
          Expanded(
            child: StreamBuilder<List<CommentModel>>(
              stream: _firestoreService.getComments(widget.postId),
              builder: (context, snapshot) {
                 if (snapshot.connectionState == ConnectionState.waiting) {
                   return const Center(child: CircularProgressIndicator());
                 }
                 if (!snapshot.hasData || snapshot.data!.isEmpty) {
                   return const Center(child: Text("No comments yet."));
                 }
                 final comments = snapshot.data!;
                 return ListView.separated(
                   padding: const EdgeInsets.all(16),
                   itemCount: comments.length,
                   separatorBuilder: (_, _) => const SizedBox(height: 16),
                   itemBuilder: (context, index) {
                     final comment = comments[index];
                     return Row(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         CustomAvatar(imageUrl: comment.userAvatar, size: 32, placeholder: '?'),
                         const SizedBox(width: 12),
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Row(
                                 children: [
                                   Text(comment.username, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                                   const SizedBox(width: 8),
                                   Text(timeago.format(comment.createdAt), style: AppTextStyles.caption.copyWith(color: AppColors.textGray, fontSize: 10)),
                                 ],
                               ),
                               const SizedBox(height: 2),
                               Text(comment.content, style: AppTextStyles.bodySmall),
                             ],
                           ),
                          ),
                          
                          // Options for owner
                          if (context.read<AuthProvider>().user?.uid == comment.userId)
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 16, color: Colors.grey),
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  setState(() {
                                    _editingCommentId = comment.id;
                                    _commentController.text = comment.content;
                                  });
                                } else if (value == 'delete') {
                                   final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: AppColors.cardSurface,
                                      title: const Text("Delete Comment?", style: TextStyle(color: Colors.white)),
                                      content: const Text("Are you sure?", style: TextStyle(color: Colors.white70)),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                                      ],
                                    ),
                                  );
                                  
                                  if (confirm == true) {
                                    await _firestoreService.deleteComment(widget.postId, comment.id);
                                  }
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                       ],
                     );
                   },
                 );
              },
            ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).viewInsets.bottom + 16),
            decoration: const BoxDecoration(
              color: AppColors.primaryDark,
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_editingCommentId != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.white10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Editing comment...", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _editingCommentId = null;
                              _commentController.clear();
                              FocusManager.instance.primaryFocus?.unfocus();
                            });
                          },
                          child: const Icon(Icons.close, size: 16, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: AppTextStyles.bodySmall,
                    decoration: InputDecoration(
                      hintText: "Add a comment...",
                      hintStyle: AppTextStyles.caption.copyWith(color: AppColors.textGray),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.cardSurface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSending ? null : _submitComment,
                    icon: _isSending 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(_editingCommentId != null ? Icons.check : Icons.send, color: AppColors.accentBlue),
                  ),
                ],
              ),
             ),
             ],
            ),
          ),
        ],
      ),
    );
  }
}
