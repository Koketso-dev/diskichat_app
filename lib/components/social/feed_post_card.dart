import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../components/avatars/custom_avatar.dart';
import '../../data/models/post_model.dart';
import '../../utils/themes/app_colors.dart';
import '../../utils/themes/text_styles.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'comments_sheet.dart';
import 'video_post_player.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

class FeedPostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onLike;

  const FeedPostCard({super.key, required this.post, required this.onLike});

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsSheet(postId: post.id),
    );
  }

  void _showPostOptions(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    if (user == null || user.uid != post.userId) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white),
              title: const Text('Edit Post', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.push('/create-post', extra: post);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Post', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColors.cardSurface,
                    title: const Text("Delete Post?", style: TextStyle(color: Colors.white)),
                    content: const Text("Are you sure you want to delete this post?", style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Delete", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await FirestoreService().deletePost(post.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(color: AppColors.cardSurface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                CustomAvatar(imageUrl: post.userAvatar, size: 32, placeholder: '?'),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.username,
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (post.userTeam != null)
                        Text(
                          post.userTeam!,
                          style: AppTextStyles.caption.copyWith(color: AppColors.textGray),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: AppColors.textGray),
                  onPressed: () => _showPostOptions(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          if (post.imageUrl != null)
            GestureDetector(
              onDoubleTap: onLike,
              child: Image.network(
                post.imageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: MediaQuery.sizeOf(context).height * 0.4,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: MediaQuery.sizeOf(context).height * 0.4,
                    width: double.infinity,
                    color: Colors.black12,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            )
          else if (post.videoUrl != null)
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.4,
              child: VideoPostPlayer(videoUrl: post.videoUrl!),
            )
          else
            const SizedBox.shrink(),

          const SizedBox(height: 12),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(post.isLiked ? Icons.favorite : Icons.favorite_border, color: post.isLiked ? Colors.red : Colors.white),
                  onPressed: onLike,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                  onPressed: () => _showComments(context),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: () {},
                  visualDensity: VisualDensity.compact,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.bookmark_border, color: Colors.white),
                  onPressed: () {},
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // Likes & Caption
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.likesCount > 0)
                  Text('${post.likesCount} likes', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.bodySmall,
                    children: [
                      TextSpan(text: post.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const TextSpan(text: ' '),
                      TextSpan(text: post.content),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                if (post.commentsCount > 0)
                  GestureDetector(
                    onTap: () => _showComments(context),
                    child: Text(
                      'View all ${post.commentsCount} comments',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textGray),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  timeago.format(post.createdAt),
                  style: AppTextStyles.caption.copyWith(color: AppColors.textGray, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
