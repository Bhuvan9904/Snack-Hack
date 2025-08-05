import 'package:flutter/material.dart';
import 'package:snack_hack_app/app/theme.dart';
import 'package:snack_hack_app/core/services/user_service.dart';

class InviteNotificationsScreen extends StatefulWidget {
  const InviteNotificationsScreen({super.key});

  @override
  State<InviteNotificationsScreen> createState() =>
      _InviteNotificationsScreenState();
}

class _InviteNotificationsScreenState extends State<InviteNotificationsScreen> {
  List<Map<String, dynamic>> _pendingInvites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingInvites();
  }

  Future<void> _loadPendingInvites() async {
    print('📨 INVITE NOTIFICATIONS: Loading pending invites...');
    setState(() => _isLoading = true);

    try {
      final invites = await UserService.getPendingInvites();
      setState(() {
        _pendingInvites = invites;
        _isLoading = false;
      });
      print(
        '📨 INVITE NOTIFICATIONS: Loaded ${invites.length} pending invites',
      );
    } catch (e) {
      print('❌ INVITE NOTIFICATIONS ERROR: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _respondToInvite(String inviteId, String response) async {
    setState(() => _isLoading = true);

    try {
      print('📨 INVITE NOTIFICATIONS: Responding to invite: $response');

      // Find the invite details first
      final invite = _pendingInvites.firstWhere(
        (invite) => invite['id'] == inviteId,
      );

      await UserService.respondToInvite(inviteId: inviteId, response: response);

      if (response == 'accepted') {
        // Actually add user to the group
        try {
          await UserService.addUserToGroup(invite['groupId']);
          print(
            '✅ INVITE NOTIFICATIONS: User added to group: ${invite['groupName']}',
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Invite accepted! You\'ve joined ${invite['groupName']}.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } catch (addError) {
          print(
            '❌ INVITE NOTIFICATIONS: Failed to add user to group: $addError',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Invite accepted but failed to join group: $addError',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invite declined.'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      // Reload invites
      await _loadPendingInvites();

      // Navigate back to groups screen to show the updated groups list
      if (response == 'accepted' && mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('❌ INVITE NOTIFICATIONS ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to respond to invite: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            Icon(Icons.notifications, color: AppColors.primaryCTA, size: 28),
            const SizedBox(width: 10),
            Text(
              'GROUP INVITES',
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryCTA),
            )
          : _pendingInvites.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pendingInvites.length,
              itemBuilder: (context, index) {
                return _buildInviteCard(_pendingInvites[index]);
              },
            ),
    );
  }

  Widget _buildInviteCard(Map<String, dynamic> invite) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.secondary.withOpacity(0.95),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.group_add, color: AppColors.primaryCTA, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Group Invitation',
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
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Group info
            Text(
              'You\'ve been invited to join:',
              style: TextStyle(
                color: AppColors.textLight.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              invite['groupName'],
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // Invite details
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: AppColors.textLight.withOpacity(0.6),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Invited by: User ${invite['invitedBy'].toString().substring(0, 8)}',
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
                  _formatDate(invite['invitedAt']),
                  style: TextStyle(
                    color: AppColors.textLight.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _respondToInvite(invite['id'], 'accepted'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _respondToInvite(invite['id'], 'declined'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
              ],
            ),
          ],
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
            Icons.notifications_none,
            size: 64,
            color: AppColors.textLight.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No pending invites',
            style: TextStyle(
              color: AppColors.textLight.withOpacity(0.7),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see group invitations here\nwhen someone invites you!',
            style: TextStyle(
              color: AppColors.textLight.withOpacity(0.5),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
