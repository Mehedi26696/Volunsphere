import '../services/auth_service.dart';
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
  State<CommunityNewsfeedScreen> createState() =>
      _CommunityNewsfeedScreenState();
}

class _CommunityNewsfeedScreenState extends State<CommunityNewsfeedScreen> {
  String? currentUserId;
  List<Post> posts = [];
  bool loading = false;
  final TextEditingController _postController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    fetchPosts();
  }

  Future<void> _loadCurrentUser() async {
    final tokenData = await AuthService.getTokenData();
    setState(() {
      currentUserId = tokenData != null ? tokenData['sub'] as String? : null;
    });
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
    final isOwner = currentUserId != null && post.userId == currentUserId;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xFF7B2CBF).withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B2CBF).withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: () async {
          final updatedPost = await Navigator.push<Post>(
            context,
            MaterialPageRoute(builder: (_) => PostDetailsScreen(post: post)),
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF7B2CBF).withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7B2CBF).withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child:
                        post.user.profileImageUrl != null
                            ? CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white,
                              backgroundImage: CachedNetworkImageProvider(
                                post.user.profileImageUrl!,
                              ),
                            )
                            : const CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.person_rounded,
                                size: 28,
                                color: Color(0xFF7B2CBF),
                              ),
                            ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.user.username,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Color(0xFF27264A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatDateTime(post.createdAt),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: const Color(
                              0xFF626C7A,
                            ).withValues(alpha: 0.8),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF626C7A).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: const Color(0xFF626C7A).withValues(alpha: 0.7),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      itemBuilder: (context) {
                        return [
                          if (isOwner)
                            PopupMenuItem(
                              value: 'edit',
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: const Text(
                                  'Edit',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF27264A),
                                  ),
                                ),
                              ),
                            ),
                          PopupMenuItem(
                            value: 'report',
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: const Text(
                                'Report',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF27264A),
                                ),
                              ),
                            ),
                          ),
                        ];
                      },
                      onSelected: (value) async {
                        if (value == 'edit') {
                          final newContent = await showDialog<String>(
                            context: context,
                            builder: (context) {
                              final controller = TextEditingController(
                                text: post.content,
                              );
                              return Dialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.97),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Edit Post',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          color: Color(0xFF7B2CBF),
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      TextField(
                                        controller: controller,
                                        maxLines: 5,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          color: Color(0xFF27264A),
                                        ),
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFF7B2CBF),
                                            ),
                                          ),
                                          labelText: 'Content',
                                          labelStyle: const TextStyle(
                                            color: Color(0xFF7B2CBF),
                                          ),
                                          filled: false,
                                          fillColor: Colors.transparent,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(context),
                                            style: TextButton.styleFrom(
                                              foregroundColor: const Color(
                                                0xFF7B2CBF,
                                              ),
                                            ),
                                            child: const Text('Cancel'),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFF7B2CBF),
                                                  Color(0xFF9D4EDD),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.transparent,
                                                shadowColor: Colors.transparent,
                                                elevation: 0,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    controller.text.trim(),
                                                  ),
                                              child: const Text('Save'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                          if (newContent != null &&
                              newContent.isNotEmpty &&
                              newContent != post.content) {
                            try {
                              await CommunityService.editPost(
                                post.id,
                                newContent,
                              );
                              await fetchPosts();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Post updated successfully!'),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update post: $e'),
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                post.content,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  height: 1.5,
                  color: Color(0xFF27264A),
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => toggleLike(post),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient:
                            isLiked
                                ? LinearGradient(
                                  colors: [
                                    Colors.pink.shade400,
                                    Colors.pink.shade300,
                                  ],
                                )
                                : LinearGradient(
                                  colors: [
                                    const Color(
                                      0xFF626C7A,
                                    ).withValues(alpha: 0.05),
                                    const Color(
                                      0xFF626C7A,
                                    ).withValues(alpha: 0.02),
                                  ],
                                ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              isLiked
                                  ? Colors.pink.shade300
                                  : const Color(
                                    0xFF626C7A,
                                  ).withValues(alpha: 0.1),
                          width: 1,
                        ),
                        boxShadow:
                            isLiked
                                ? [
                                  BoxShadow(
                                    color: Colors.pink.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                                : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color:
                                isLiked
                                    ? Colors.white
                                    : const Color(0xFF626C7A),
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${post.likesCount}",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color:
                                  isLiked
                                      ? Colors.white
                                      : const Color(0xFF626C7A),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF2196F3).withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.comment_rounded,
                          color: const Color(0xFF2196F3),
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "${post.commentsCount}",
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Color(0xFF2196F3),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Purple App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7B2CBF), Color(0xFF9D4EDD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7B2CBF).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      "Community Newsfeed",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        fontSize: 22,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.forum_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // Create Post Section
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: const Color(0xFF7B2CBF).withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7B2CBF).withValues(alpha: 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF7B2CBF).withValues(alpha: 0.1),
                            const Color(0xFF9D4EDD).withValues(alpha: 0.05),
                          ],
                        ),
                        border: Border.all(
                          color: const Color(0xFF7B2CBF).withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: const CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.transparent,
                        child: Icon(
                          Icons.edit_rounded,
                          color: Color(0xFF7B2CBF),
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF626C7A,
                          ).withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(
                              0xFF626C7A,
                            ).withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _postController,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            color: Color(0xFF27264A),
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: const InputDecoration(
                            hintText: "What's on your mind?",
                            hintStyle: TextStyle(
                              fontFamily: 'Poppins',
                              color: Color(0xFF626C7A),
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          minLines: 1,
                          maxLines: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7B2CBF), Color(0xFF9D4EDD)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF7B2CBF,
                            ).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        onPressed: createPost,
                        child: const Text(
                          "Post",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Posts List
            Expanded(
              child:
                  loading
                      ? Center(
                        child: Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.9),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF7B2CBF,
                                ).withValues(alpha: 0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF7B2CBF),
                                      Color(0xFF9D4EDD),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Loading posts...',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF27264A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      : RefreshIndicator(
                        onRefresh: fetchPosts,
                        color: const Color(0xFF7B2CBF),
                        child:
                            posts.isEmpty
                                ? Center(
                                  child: Container(
                                    margin: const EdgeInsets.all(32),
                                    padding: const EdgeInsets.all(40),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.95,
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF7B2CBF,
                                        ).withValues(alpha: 0.2),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF7B2CBF,
                                          ).withValues(alpha: 0.08),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(
                                                  0xFF7B2CBF,
                                                ).withValues(alpha: 0.1),
                                                const Color(
                                                  0xFF9D4EDD,
                                                ).withValues(alpha: 0.05),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              25,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.forum_rounded,
                                            size: 48,
                                            color: const Color(
                                              0xFF7B2CBF,
                                            ).withValues(alpha: 0.7),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          "No posts yet. Be the first to share something!",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            color: const Color(
                                              0xFF626C7A,
                                            ).withValues(alpha: 0.8),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                : ScrollConfiguration(
                                  behavior: ScrollConfiguration.of(
                                    context,
                                  ).copyWith(scrollbars: false),
                                  child: ListView.builder(
                                    padding: const EdgeInsets.only(
                                      bottom: 16,
                                      top: 8,
                                    ),
                                    itemCount: posts.length,
                                    itemBuilder:
                                        (context, index) =>
                                            buildPostCard(posts[index]),
                                  ),
                                ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
