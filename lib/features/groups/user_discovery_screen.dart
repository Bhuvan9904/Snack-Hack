import 'package:flutter/material.dart';
import 'package:snack_hack_app/app/theme.dart';
import 'package:snack_hack_app/core/services/user_service.dart';
import 'package:snack_hack_app/data/models/group_model.dart';

class UserDiscoveryScreen extends StatefulWidget {
  final Group group;

  const UserDiscoveryScreen({super.key, required this.group});

  @override
  State<UserDiscoveryScreen> createState() => _UserDiscoveryScreenState();
}

class _UserDiscoveryScreenState extends State<UserDiscoveryScreen> {
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  Set<String> _selectedUsers = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    print('🔍 USER DISCOVERY: Loading all users...');
    setState(() => _isLoading = true);

    try {
      final users = await UserService.getAllUsers();

      // Filter out users who are already in the group
      final availableUsers = users.where((user) {
        return !widget.group.members.contains(user['id']);
      }).toList();

      setState(() {
        _allUsers = availableUsers;
        _filteredUsers = availableUsers;
        _isLoading = false;
      });

      print(
        '🔍 USER DISCOVERY: Loaded ${availableUsers.length} available users',
      );
    } catch (e) {
      print('❌ USER DISCOVERY ERROR: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterUsers(String query) {
    if (query.isEmpty) {
      setState(() => _filteredUsers = _allUsers);
    } else {
      final filtered = _allUsers.where((user) {
        final name = user['name'].toString().toLowerCase();
        final email = user['email'].toString().toLowerCase();
        final searchQuery = query.toLowerCase();

        return name.contains(searchQuery) || email.contains(searchQuery);
      }).toList();

      setState(() => _filteredUsers = filtered);
    }
  }

  void _toggleUserSelection(String userId) {
    setState(() {
      if (_selectedUsers.contains(userId)) {
        _selectedUsers.remove(userId);
      } else {
        _selectedUsers.add(userId);
      }
    });
  }

  Future<void> _sendInvites() async {
    if (_selectedUsers.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      print(
        '📨 USER DISCOVERY: Sending invites to ${_selectedUsers.length} users',
      );

      for (final userId in _selectedUsers) {
        await UserService.sendDirectInvite(
          targetUserId: userId,
          groupId: widget.group.id,
          groupName: widget.group.name,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invites sent to ${_selectedUsers.length} users!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('❌ USER DISCOVERY ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send invites: $e'),
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
            Icon(Icons.person_add, color: AppColors.primaryCTA, size: 28),
            const SizedBox(width: 10),
            Text(
              'INVITE USERS',
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
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterUsers,
              decoration: InputDecoration(
                hintText: 'Search users by name or email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.secondary.withOpacity(0.5),
              ),
            ),
          ),

          // Selected count
          if (_selectedUsers.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.primaryCTA,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedUsers.length} user${_selectedUsers.length == 1 ? '' : 's'} selected',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Users list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryCTA,
                    ),
                  )
                : _filteredUsers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      return _buildUserCard(_filteredUsers[index]);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _selectedUsers.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendInvites,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryCTA,
                    foregroundColor: AppColors.textLight,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.textLight,
                            ),
                          ),
                        )
                      : Text('Send Invites (${_selectedUsers.length})'),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final userId = user['id'];
    final isSelected = _selectedUsers.contains(userId);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.secondary.withOpacity(0.95),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _toggleUserSelection(userId),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Selection checkbox
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryCTA : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryCTA
                        : AppColors.textLight.withOpacity(0.3),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),

              const SizedBox(width: 16),

              // User avatar
              CircleAvatar(
                backgroundColor: AppColors.primaryCTA.withOpacity(0.2),
                radius: 24,
                child: Text(
                  user['name'].toString().substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primaryCTA,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'],
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user['email'],
                      style: TextStyle(
                        color: AppColors.textLight.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.emoji_events,
                          color: AppColors.primaryCTA,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${user['points']} pts',
                          style: TextStyle(
                            color: AppColors.textLight.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.local_fire_department,
                          color: Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${user['streak']} days',
                          style: TextStyle(
                            color: AppColors.textLight.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
            Icons.people_outline,
            size: 64,
            color: AppColors.textLight.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? 'No users found'
                : 'No matching users',
            style: TextStyle(
              color: AppColors.textLight.withOpacity(0.7),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'All users are already in this group'
                : 'Try a different search term',
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
}
