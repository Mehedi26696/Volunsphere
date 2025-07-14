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
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    post = widget.post;
    _loadCurrentUser();
    fetchComments();
  }

  Future<void> _loadCurrentUser() async {
    final tokenData = await AuthService.getTokenData();
    setState(() {
      currentUserId = tokenData != null ? tokenData['sub'] as String? : null;
    });
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
        const SnackBar(
          content: Text('You need to be logged in to view comments'),
        ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to load comments')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to send comment')));
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
    final isOwner = currentUserId != null && post.userId == currentUserId;
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
                      onPressed: () => Navigator.pop(context, post),
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
                      "Post Details",
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
                  if (isOwner)
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      itemBuilder:
                          (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: const [
                                  Icon(
                                    Icons.edit_rounded,
                                    color: Color(0xFF7B2CBF),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Edit Post',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                      onSelected: (value) async {
                        if (value == 'edit') {
                          final controller = TextEditingController(
                            text: post.content,
                          );
                          final newContent = await showDialog<String>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                backgroundColor: Colors.white.withOpacity(0.97),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: const Text(
                                  'Edit Post',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF27264A),
                                  ),
                                ),
                                content: TextField(
                                  controller: controller,
                                  maxLines: 8,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    color: Color(0xFF27264A),
                                  ),
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Content',
                                    labelStyle: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: Color(0xFF7B2CBF),
                                    ),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: Color(0xFF626C7A),
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      textStyle: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    onPressed:
                                        () => Navigator.pop(
                                          context,
                                          controller.text.trim(),
                                        ),
                                    child: Ink(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFF7B2CBF),
                                            Color(0xFF9D4EDD),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(12),
                                        ),
                                      ),
                                      child: Container(
                                        constraints: const BoxConstraints(
                                          minWidth: 60,
                                          minHeight: 36,
                                        ),
                                        alignment: Alignment.center,
                                        child: const Text('Save'),
                                      ),
                                    ),
                                  ),
                                ],
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
                              setState(() {
                                post = post.copyWith(content: newContent);
                              });
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
                  if (!isOwner)
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
                        Icons.article_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),

            // Post Content
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: const Color(0xFF7B2CBF).withValues(alpha: 0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7B2CBF).withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(
                                0xFF7B2CBF,
                              ).withValues(alpha: 0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF7B2CBF,
                                ).withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child:
                              post.user.profileImageUrl != null &&
                                      post.user.profileImageUrl!.isNotEmpty
                                  ? CircleAvatar(
                                    radius: 26,
                                    backgroundColor: Colors.white,
                                    backgroundImage: CachedNetworkImageProvider(
                                      post.user.profileImageUrl!,
                                    ),
                                  )
                                  : const CircleAvatar(
                                    radius: 26,
                                    backgroundColor: Colors.white,
                                    child: Icon(
                                      Icons.person_rounded,
                                      size: 30,
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
                                  fontSize: 18,
                                  color: Color(0xFF27264A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Posted on: ${formatDateTime(post.createdAt)}",
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
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      post.content,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 17,
                        height: 1.6,
                        color: Color(0xFF27264A),
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: toggleLike,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient:
                                  post.likedByMe
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
                                    post.likedByMe
                                        ? Colors.pink.shade300
                                        : const Color(
                                          0xFF626C7A,
                                        ).withValues(alpha: 0.2),
                                width: 1,
                              ),
                              boxShadow:
                                  post.likedByMe
                                      ? [
                                        BoxShadow(
                                          color: Colors.pink.withValues(
                                            alpha: 0.3,
                                          ),
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
                                  post.likedByMe
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color:
                                      post.likedByMe
                                          ? Colors.white
                                          : const Color(0xFF626C7A),
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "${post.likesCount}",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color:
                                        post.likedByMe
                                            ? Colors.white
                                            : const Color(0xFF626C7A),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "likes",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color:
                                        post.likedByMe
                                            ? Colors.white.withValues(
                                              alpha: 0.8,
                                            )
                                            : const Color(
                                              0xFF626C7A,
                                            ).withValues(alpha: 0.7),
                                    fontWeight: FontWeight.w400,
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
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF2196F3,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(
                                0xFF2196F3,
                              ).withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.comment_rounded,
                                color: const Color(0xFF2196F3),
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "${post.commentsCount}",
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Color(0xFF2196F3),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "comments",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: const Color(
                                    0xFF2196F3,
                                  ).withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w400,
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

            // Comments Section
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: const Color(0xFF7B2CBF).withValues(alpha: 0.15),
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child:
                      loadingComments
                          ? Center(
                            child: Container(
                              padding: const EdgeInsets.all(40),
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
                                    'Loading comments...',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF27264A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          : comments.isEmpty
                          ? Center(
                            child: Container(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(
                                            0xFF626C7A,
                                          ).withValues(alpha: 0.1),
                                          const Color(
                                            0xFF626C7A,
                                          ).withValues(alpha: 0.05),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Icon(
                                      Icons.comment_outlined,
                                      size: 48,
                                      color: const Color(
                                        0xFF626C7A,
                                      ).withValues(alpha: 0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    "No comments yet",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(
                                        0xFF626C7A,
                                      ).withValues(alpha: 0.8),
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
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: comments.length,
                              separatorBuilder:
                                  (_, __) => Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    height: 1,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(
                                            0xFF7B2CBF,
                                          ).withValues(alpha: 0.1),
                                          const Color(
                                            0xFF7B2CBF,
                                          ).withValues(alpha: 0.3),
                                          const Color(
                                            0xFF7B2CBF,
                                          ).withValues(alpha: 0.1),
                                        ],
                                      ),
                                    ),
                                  ),
                              itemBuilder: (context, index) {
                                final comment = comments[index];
                                final isOwner =
                                    currentUserId != null &&
                                    comment.userId == currentUserId;
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF7B2CBF,
                                    ).withValues(alpha: 0.03),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF7B2CBF,
                                      ).withValues(alpha: 0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(
                                              0xFF7B2CBF,
                                            ).withValues(alpha: 0.3),
                                            width: 1.5,
                                          ),
                                        ),
                                        child:
                                            (comment.profileImageUrl.isNotEmpty)
                                                ? CircleAvatar(
                                                  backgroundImage:
                                                      CachedNetworkImageProvider(
                                                        comment.profileImageUrl,
                                                      ),
                                                  radius: 20,
                                                  backgroundColor: Colors.white,
                                                )
                                                : const CircleAvatar(
                                                  radius: 20,
                                                  backgroundColor: Colors.white,
                                                  child: Icon(
                                                    Icons.person_rounded,
                                                    color: Color(0xFF7B2CBF),
                                                    size: 20,
                                                  ),
                                                ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  comment.username,
                                                  style: const TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: Color(0xFF27264A),
                                                    letterSpacing: -0.3,
                                                  ),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  DateFormat(
                                                    'MMM d, yyyy',
                                                  ).format(comment.createdAt),
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 11,
                                                    color: const Color(
                                                      0xFF626C7A,
                                                    ).withValues(alpha: 0.7),
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                                if (isOwner)
                                                  PopupMenuButton<String>(
                                                    icon: Icon(
                                                      Icons.more_vert_rounded,
                                                      color: const Color(
                                                        0xFF626C7A,
                                                      ).withValues(alpha: 0.7),
                                                      size: 18,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    itemBuilder:
                                                        (context) => [
                                                          PopupMenuItem(
                                                            value: 'edit',
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    vertical: 4,
                                                                  ),
                                                              child: const Text(
                                                                'Edit',
                                                                style: TextStyle(
                                                                  fontFamily:
                                                                      'Poppins',
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  color: Color(
                                                                    0xFF27264A,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                    onSelected: (value) async {
                                                      if (value == 'edit') {
                                                        final newContent = await showDialog<
                                                          String
                                                        >(
                                                          context: context,
                                                          builder: (context) {
                                                            final controller =
                                                                TextEditingController(
                                                                  text:
                                                                      comment
                                                                          .content,
                                                                );
                                                            return AlertDialog(
                                                              backgroundColor:
                                                                  Colors.white
                                                                      .withOpacity(
                                                                        0.97,
                                                                      ),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      20,
                                                                    ),
                                                              ),
                                                              title: const Text(
                                                                'Edit Comment',
                                                                style: TextStyle(
                                                                  fontFamily:
                                                                      'Poppins',
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: Color(
                                                                    0xFF27264A,
                                                                  ),
                                                                ),
                                                              ),
                                                              content: TextField(
                                                                controller:
                                                                    controller,
                                                                maxLines: 5,
                                                                style: const TextStyle(
                                                                  fontFamily:
                                                                      'Poppins',
                                                                  fontSize: 15,
                                                                  color: Color(
                                                                    0xFF27264A,
                                                                  ),
                                                                ),
                                                                decoration: const InputDecoration(
                                                                  border:
                                                                      OutlineInputBorder(),
                                                                  labelText:
                                                                      'Content',
                                                                  labelStyle: TextStyle(
                                                                    fontFamily:
                                                                        'Poppins',
                                                                    color: Color(
                                                                      0xFF7B2CBF,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed:
                                                                      () => Navigator.pop(
                                                                        context,
                                                                      ),
                                                                  child: const Text(
                                                                    'Cancel',
                                                                    style: TextStyle(
                                                                      fontFamily:
                                                                          'Poppins',
                                                                      color: Color(
                                                                        0xFF626C7A,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                ElevatedButton(
                                                                  style: ElevatedButton.styleFrom(
                                                                    padding: const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          24,
                                                                      vertical:
                                                                          10,
                                                                    ),
                                                                    shape: RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            12,
                                                                          ),
                                                                    ),
                                                                    elevation:
                                                                        0,
                                                                    backgroundColor:
                                                                        Colors
                                                                            .transparent,
                                                                    shadowColor:
                                                                        Colors
                                                                            .transparent,
                                                                    foregroundColor:
                                                                        Colors
                                                                            .white,
                                                                    textStyle: const TextStyle(
                                                                      fontFamily:
                                                                          'Poppins',
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      fontSize:
                                                                          16,
                                                                    ),
                                                                  ),
                                                                  onPressed:
                                                                      () => Navigator.pop(
                                                                        context,
                                                                        controller
                                                                            .text
                                                                            .trim(),
                                                                      ),
                                                                  child: Ink(
                                                                    decoration: const BoxDecoration(
                                                                      gradient: LinearGradient(
                                                                        colors: [
                                                                          Color(
                                                                            0xFF7B2CBF,
                                                                          ),
                                                                          Color(
                                                                            0xFF9D4EDD,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      borderRadius:
                                                                          BorderRadius.all(
                                                                            Radius.circular(
                                                                              12,
                                                                            ),
                                                                          ),
                                                                    ),
                                                                    child: Container(
                                                                      constraints: const BoxConstraints(
                                                                        minWidth:
                                                                            60,
                                                                        minHeight:
                                                                            36,
                                                                      ),
                                                                      alignment:
                                                                          Alignment
                                                                              .center,
                                                                      child: const Text(
                                                                        'Save',
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        );
                                                        if (newContent !=
                                                                null &&
                                                            newContent
                                                                .isNotEmpty &&
                                                            newContent !=
                                                                comment
                                                                    .content) {
                                                          try {
                                                            await CommunityService.editComment(
                                                              post.id,
                                                              comment.id,
                                                              newContent,
                                                            );
                                                            await fetchComments();
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                  'Comment updated successfully!',
                                                                ),
                                                              ),
                                                            );
                                                          } catch (e) {
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  'Failed to update comment: $e',
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                        }
                                                      }
                                                    },
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              comment.content,
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 14,
                                                color: Color(0xFF27264A),
                                                fontWeight: FontWeight.w400,
                                                height: 1.4,
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                ),
              ),
            ),

            // Comment Input
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
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
                          controller: _commentController,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            color: Color(0xFF27264A),
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: const InputDecoration(
                            hintText: "Write a comment...",
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
                          maxLines: 3,
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
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded),
                        onPressed: addComment,
                        color: Colors.white,
                        iconSize: 20,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
