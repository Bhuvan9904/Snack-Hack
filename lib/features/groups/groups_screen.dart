import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:snack_hack_app/app/theme.dart';
import 'package:snack_hack_app/core/services/group_service.dart';
import 'package:snack_hack_app/core/services/user_service.dart';
import 'package:snack_hack_app/data/models/group_model.dart';
import 'package:snack_hack_app/features/groups/create_group_screen.dart';

import 'package:snack_hack_app/features/groups/group_detail_screen.dart';
import 'package:snack_hack_app/features/groups/invite_notifications_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  List<Group> _groups = [];
  List<Map<String, dynamic>> _pendingInvites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    print('👥 GROUPS: Loading user groups...');
    setState(() => _isLoading = true);

    try {
      final groups = await GroupService.getUserGroups();
      final invites = await UserService.getPendingInvites();

      setState(() {
        _groups = groups;
        _pendingInvites = invites;
        _isLoading = false;
      });
      print(
        '👥 GROUPS: Loaded ${groups.length} groups and ${invites.length} pending invites',
      );
    } catch (e) {
      print('❌ GROUPS ERROR: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups, color: AppColors.primaryCTA, size: 28),
            const SizedBox(width: 10),
            Text(
              'MY GROUPS',
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
        actions: [
          if (_pendingInvites.isNotEmpty)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: _navigateToInviteNotifications,
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_pendingInvites.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryCTA),
            )
          : Column(
              children: [
                // Header with group count
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.groups, color: AppColors.primaryCTA, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${_groups.length} groups',
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Groups list
                Expanded(
                  child: _groups.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _groups.length,
                          itemBuilder: (context, index) {
                            return _buildGroupCard(_groups[index]);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGroupOptions(context),
        backgroundColor: AppColors.primaryCTA,
        foregroundColor: AppColors.textLight,
        icon: const Icon(Icons.add),
        label: const Text('Add Group'),
      ),
    );
  }

  Widget _buildGroupCard(Group group) {
    return Dismissible(
      key: Key(group.id),
      direction: group.isAdmin(FirebaseAuth.instance.currentUser?.uid ?? '')
          ? DismissDirection.endToStart
          : DismissDirection.none,
      confirmDismiss: (direction) async {
        final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
        final isAdmin = group.isAdmin(currentUserId);
        final isMember = group.isMember(currentUserId);

        if (!isAdmin && !isMember) return false;

        if (isAdmin) {
          // Admin can delete group
          return await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.secondary,
                  title: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red, size: 28),
                      const SizedBox(width: 8),
                      const Text(
                        'Delete Group',
                        style: TextStyle(color: AppColors.textLight),
                      ),
                    ],
                  ),
                  content: Text(
                    'Are you sure you want to delete "${group.name}"? This action cannot be undone.',
                    style: const TextStyle(color: AppColors.textLight),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ) ??
              false;
        } else {
          // Member can leave group
          return await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.secondary,
                  title: Row(
                    children: [
                      Icon(Icons.exit_to_app, color: Colors.orange, size: 28),
                      const SizedBox(width: 8),
                      const Text(
                        'Leave Group',
                        style: TextStyle(color: AppColors.textLight),
                      ),
                    ],
                  ),
                  content: Text(
                    'Are you sure you want to leave "${group.name}"?',
                    style: const TextStyle(color: AppColors.textLight),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Leave'),
                    ),
                  ],
                ),
              ) ??
              false;
        }
      },
      onDismissed: (direction) async {
        final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
        final isAdmin = group.isAdmin(currentUserId);

        try {
          if (isAdmin) {
            await GroupService.deleteGroup(group.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Group "${group.name}" deleted'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            await GroupService.leaveGroup(group.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('You left "${group.name}"'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to ${isAdmin ? 'delete' : 'leave'} group: $e',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: group.isAdmin(FirebaseAuth.instance.currentUser?.uid ?? '')
              ? Colors.red
              : Colors.orange,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(
          group.isAdmin(FirebaseAuth.instance.currentUser?.uid ?? '')
              ? Icons.delete_forever
              : Icons.exit_to_app,
          color: Colors.white,
          size: 32,
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: AppColors.secondary.withOpacity(0.95),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => _navigateToGroupDetail(group),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group name and member count
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        group.name,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryCTA.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${group.members.length}/${group.maxMembers}',
                        style: const TextStyle(
                          color: AppColors.primaryCTA,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Group description
                Text(
                  group.description,
                  style: TextStyle(
                    color: AppColors.textLight.withOpacity(0.7),
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Group info row
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: AppColors.textLight.withOpacity(0.6),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${group.members.length} members',
                      style: TextStyle(
                        color: AppColors.textLight.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.calendar_today,
                      color: AppColors.textLight.withOpacity(0.6),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(group.createdAt),
                      style: TextStyle(
                        color: AppColors.textLight.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                // Admin badge
                if (group.isAdmin(group.createdBy))
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '👑 Admin',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.groups,
            size: 64,
            color: AppColors.textLight.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No groups yet',
            style: TextStyle(
              color: AppColors.textLight.withOpacity(0.7),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create or join a group to start\nsharing challenges with friends!',
            style: TextStyle(
              color: AppColors.textLight.withOpacity(0.5),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showGroupOptions(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Your First Group'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryCTA,
              foregroundColor: AppColors.textLight,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showGroupOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.secondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Add Group',
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToCreateGroup();
                },
                icon: const Icon(Icons.create),
                label: const Text('Create New Group'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryCTA,
                  foregroundColor: AppColors.textLight,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _navigateToCreateGroup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
    ).then((_) => _loadGroups());
  }

  void _navigateToInviteNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InviteNotificationsScreen(),
      ),
    ).then((_) {
      // Refresh groups list when returning from invite notifications
      _loadGroups();
    });
  }

  void _navigateToGroupDetail(Group group) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GroupDetailScreen(group: group)),
    ).then((_) => _loadGroups());
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';

    return '${date.day}/${date.month}/${date.year}';
  }
}
