import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../data/models/post_model.dart';
import '../../components/social/feed_post_card.dart';
import '../../providers/auth_provider.dart';
import '../../utils/themes/app_colors.dart';
import '../../utils/themes/text_styles.dart';
import '../../components/common/loading_indicator.dart';
import '../../components/common/empty_state.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        backgroundColor: AppColors.cardSurface,
        title: Text("Shibobo", style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textWhite)),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<List<PostModel>>(
        stream: firestoreService.getFeed(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error loading feed: ${snapshot.error}", style: AppTextStyles.body),
            );
          }

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return const EmptyState(
              icon: Icons.feed_outlined,
              title: "No posts yet",
              description: "Be the first to share your thoughts!",
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final post = posts[index];
              return FeedPostCard(
                post: post,
                onLike: () async {
                  final user = context.read<AuthProvider>().user;
                  if (user != null) {
                    await firestoreService.likePost(post.id, user.uid);
                  }
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentBlue,
        child: const Icon(Icons.add),
        onPressed: () => context.push('/create-post'),
      ),
    );
  }
}
