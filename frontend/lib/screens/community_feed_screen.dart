// community_newsfeed_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/post_model.dart';
import '../services/community_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'post_details_screen.dart';

class CommunityNewsfeedScreen extends StatefulWidget {
  const CommunityNewsfeedScreen({super.key});

  @override
  State<CommunityNewsfeedScreen> createState() => _CommunityNewsfeedScreenState();
}

class _CommunityNewsfeedScreenState extends State<CommunityNewsfeedScreen> {
  List<Post> posts = [];
  bool loading = false;
  final TextEditingController _postController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    setState(() => loading = true);
    try {
      final fetchedPosts = await CommunityService.fetchPosts();
      setState(() {
        posts = fetchedPosts;
      });
    } catch (_) {
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> createPost() async {
    final content = _postController.text.trim();
    if (content.isEmpty) return;

    try {
      await CommunityService.createPost(content);
      _postController.clear();
      await fetchPosts();
    } catch (_) {}
  }

  Future<void> toggleLike(Post post) async {
    try {
      final isLiked = post.likedByMe;
      if (isLiked) {
        await CommunityService.unlikePost(post.id);
      } else {
        await CommunityService.likePost(post.id);
      }

      setState(() {
        final index = posts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          posts[index] = post.copyWith(
            likesCount: isLiked ? post.likesCount - 1 : post.likesCount + 1,
            likedByMe: !isLiked,
          );
        }
      });
    } catch (_) {}
  }

  String formatDateTime(DateTime dt) {
    return DateFormat('MMM d, yyyy HH:mm').format(dt);
  }

  Widget buildPostCard(Post post) {
    final isLiked = post.likedByMe;
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          final updatedPost = await Navigator.push<Post>(
            context,
            MaterialPageRoute(
              builder: (_) => PostDetailsScreen(post: post),
            ),
          );
          if (updatedPost != null) {
            setState(() {
              final index = posts.indexWhere((p) => p.id == updatedPost.id);
              if (index != -1) {
                posts[index] = updatedPost;
              }
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  post.user.profileImageUrl != null
                      ? CircleAvatar(
                          radius: 24,
                          backgroundImage: CachedNetworkImageProvider(
                            post.user.profileImageUrl!,
                          ),
                        )
                      : const CircleAvatar(
                          radius: 24,
                          child: Icon(Icons.person, size: 28),
                        ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.user.username,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatDateTime(post.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'report',
                        child: Text('Report'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                post.content,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => toggleLike(post),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLiked ? Colors.red.withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.grey[600],
                            size: 22,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${post.likesCount}",
                            style: TextStyle(
                              color: isLiked ? Colors.red : Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Row(
                    children: [
                      Icon(Icons.comment_outlined, color: Colors.grey[600], size: 22),
                      const SizedBox(width: 4),
                      Text(
                        "${post.commentsCount}",
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text("Community Newsfeed"),
        elevation: 0,
        backgroundColor: theme.colorScheme.background,
        foregroundColor: theme.colorScheme.primary,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: const Icon(Icons.edit, color: Colors.blueGrey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _postController,
                    decoration: const InputDecoration(
                      hintText: "What's on your mind?",
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    minLines: 1,
                    maxLines: 4,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    elevation: 0,
                  ),
                  onPressed: createPost,
                  child: const Text("Post", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: fetchPosts,
                    child: posts.isEmpty
                        ? Center(
                            child: Text(
                              "No posts yet. Be the first to share something!",
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: posts.length,
                            itemBuilder: (context, index) => buildPostCard(posts[index]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
