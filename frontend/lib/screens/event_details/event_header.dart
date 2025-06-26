import 'package:flutter/material.dart';
import '../../models/event_model.dart';

class EventHeader extends StatelessWidget implements PreferredSizeWidget {
  final Event event;
  final bool isCreator;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EventHeader({
    super.key,
    required this.event,
    required this.isCreator,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.teal.shade800,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.teal.withValues(alpha: 0.05)],
          ),
        ),
      ),
      title: Text(
        event.title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: Colors.teal.shade800,
          fontSize: 20,
          letterSpacing: 0.5,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      centerTitle: true,
      actions:
          isCreator
              ? [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.teal),
                    onPressed: onEdit,
                    tooltip: 'Edit Event',
                    splashRadius: 24,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    onPressed: onDelete,
                    tooltip: 'Delete Event',
                    splashRadius: 24,
                  ),
                ),
              ]
              : [],
    );
  }
}
