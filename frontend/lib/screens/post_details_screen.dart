import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:volunsphere/services/auth_service.dart';

import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../services/community_service.dart';

class PostDetailsScreen extends StatefulWidget {
  final Post post;

  const PostDetailsScreen({super.key, required this.post});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  late Post post;
  List<Comment> comments = [];
  bool loadingComments = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    post = widget.post;
    fetchComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> fetchComments() async {
    final token = await AuthService.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be logged in to view comments')),
      );
      return;
    }
    setState(() => loadingComments = true);
    try {
      final fetchedComments = await CommunityService.fetchComments(post.id);
      setState(() {
        comments = fetchedComments;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load comments')),
      );
    } finally {
      setState(() => loadingComments = false);
    }
  }

  Future<void> addComment() async {
    final content = _commentController.text.trim();
    final token = await AuthService.getToken();
    if (content.isEmpty || token == null) return;

    try {
      await CommunityService.createComment(post.id, content);
      _commentController.clear();
      await fetchComments();
      setState(() {
        post = post.copyWith(commentsCount: post.commentsCount + 1);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send comment')),
      );
    }
  }

  Future<void> toggleLike() async {
    try {
      if (post.likedByMe) {
        await CommunityService.unlikePost(post.id);
        setState(() {
          post = post.copyWith(
            likesCount: (post.likesCount - 1).clamp(0, 999999),
            likedByMe: false,
          );
        });
      } else {
        await CommunityService.likePost(post.id);
        setState(() {
          post = post.copyWith(
            likesCount: post.likesCount + 1,
            likedByMe: true,
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update like status')),
      );
    }
  }

  String formatDateTime(DateTime dt) {
    return DateFormat('MMM d, yyyy HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text("Post Details"),
        elevation: 0,
        backgroundColor: theme.colorScheme.background,
        foregroundColor: theme.colorScheme.onBackground,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(20),
            color: theme.cardColor,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (post.user.profileImageUrl != null && post.user.profileImageUrl!.isNotEmpty)
                        CircleAvatar(
                          radius: 26,
                          backgroundImage: CachedNetworkImageProvider(post.user.profileImageUrl!),
                        )
                      else
                        const CircleAvatar(
                          radius: 26,
                          child: Icon(Icons.person, size: 28),
                        ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.user.username,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Posted on: ${formatDateTime(post.createdAt)}",
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    post.content,
                    style: theme.textTheme.bodyLarge?.copyWith(fontSize: 17, height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      IconButton(
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                          child: Icon(
                            post.likedByMe ? Icons.favorite : Icons.favorite_border,
                            key: ValueKey(post.likedByMe),
                            color: post.likedByMe ? Colors.redAccent : theme.iconTheme.color,
                            size: 28,
                          ),
                        ),
                        onPressed: toggleLike,
                        splashRadius: 22,
                      ),
                      Text(
                        "${post.likesCount}",
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "likes",
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 20),
                      Icon(Icons.comment, size: 24, color: theme.iconTheme.color?.withOpacity(0.8)),
                      const SizedBox(width: 4),
                      Text(
                        "${post.commentsCount}",
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        "comments",
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: loadingComments
                  ? const Center(child: CircularProgressIndicator())
                  : comments.isEmpty
                      ? Center(
                          child: Text(
                            "No comments yet",
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          itemCount: comments.length,
                          separatorBuilder: (_, __) => Divider(
                            indent: 70,
                            endIndent: 16,
                            height: 0,
                            color: Colors.grey[200],
                          ),
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            return ListTile(
                              leading: (comment.profileImageUrl != null && comment.profileImageUrl!.isNotEmpty)
                                  ? CircleAvatar(
                                      backgroundImage: CachedNetworkImageProvider(comment.profileImageUrl!),
                                      radius: 22,
                                    )
                                  : const CircleAvatar(child: Icon(Icons.person), radius: 22),
                              title: Text(
                                comment.username,
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  comment.content,
                                  style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15),
                                ),
                              ),
                              trailing: Text(
                                DateFormat('MMM d, yyyy').format(comment.createdAt),
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500], fontSize: 12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            );
                          },
                        ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: "Write a comment...",
                        filled: true,
                        fillColor: theme.inputDecorationTheme.fillColor ?? Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      minLines: 1,
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                      backgroundColor: theme.colorScheme.primary,
                      elevation: 2,
                    ),
                    onPressed: addComment,
                    child: const Icon(Icons.send, color: Colors.white, size: 22),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
