import 'package:flutter/material.dart';
import 'package:snack_hack_app/app/theme.dart';
import 'package:snack_hack_app/core/services/group_service.dart';
import 'package:snack_hack_app/core/services/user_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();

  bool _isPrivate = false;
  int _maxMembers = 10;
  bool _isLoading = false;
  bool _showUserSelection = false;

  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  Set<String> _selectedUsers = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    print('👥 CREATE GROUP: Loading users for invitation...');

    try {
      final users = await UserService.getAllUsers();
      print('👥 CREATE GROUP: Raw users data: $users');

      setState(() {
        _allUsers = users;
        _filteredUsers = users;
      });
      print('👥 CREATE GROUP: Loaded ${users.length} users');
      print('👥 CREATE GROUP: _allUsers length: ${_allUsers.length}');
      print('👥 CREATE GROUP: _filteredUsers length: ${_filteredUsers.length}');
    } catch (e) {
      print('❌ CREATE GROUP ERROR: $e');
      setState(() {
        _allUsers = [];
        _filteredUsers = [];
      });
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

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      print(
        '👥 CREATE GROUP: Creating group with ${_selectedUsers.length} invited users',
      );

      // Create the group
      final group = await GroupService.createGroup(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        isPrivate: _isPrivate,
        maxMembers: _maxMembers,
      );

      // Send invites to selected users
      if (_selectedUsers.isNotEmpty) {
        for (final userId in _selectedUsers) {
          await UserService.sendDirectInvite(
            targetUserId: userId,
            groupId: group.id,
            groupName: group.name,
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Group created successfully! ${_selectedUsers.length} invite${_selectedUsers.length == 1 ? '' : 's'} sent.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('❌ CREATE GROUP ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create group: $e'),
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
            Icon(Icons.create, color: AppColors.primaryCTA, size: 28),
            const SizedBox(width: 10),
            Text(
              'CREATE GROUP',
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
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Group Details Section
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Group Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Group Name',
                        prefixIcon: const Icon(Icons.group),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: AppColors.secondary.withOpacity(0.5),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a group name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Group Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: AppColors.secondary.withOpacity(0.5),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Privacy Toggle
                    Card(
                      color: AppColors.secondary.withOpacity(0.95),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              _isPrivate ? Icons.lock : Icons.public,
                              color: AppColors.primaryCTA,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isPrivate
                                        ? 'Private Group'
                                        : 'Public Group',
                                    style: const TextStyle(
                                      color: AppColors.textLight,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    _isPrivate
                                        ? 'Only invited members can join'
                                        : 'Anyone with the code can join',
                                    style: TextStyle(
                                      color: AppColors.textLight.withOpacity(
                                        0.7,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isPrivate,
                              onChanged: (value) =>
                                  setState(() => _isPrivate = value),
                              activeColor: AppColors.primaryCTA,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Max Members Slider
                    Card(
                      color: AppColors.secondary.withOpacity(0.95),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.people, color: AppColors.primaryCTA),
                                const SizedBox(width: 12),
                                Text(
                                  'Maximum Members: $_maxMembers',
                                  style: const TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Slider(
                              value: _maxMembers.toDouble(),
                              min: 5,
                              max: 50,
                              divisions: 9,
                              activeColor: AppColors.primaryCTA,
                              onChanged: (value) =>
                                  setState(() => _maxMembers = value.round()),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text(
                                  '5',
                                  style: TextStyle(color: AppColors.textLight),
                                ),
                                Text(
                                  '50',
                                  style: TextStyle(color: AppColors.textLight),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Invite Members Section
                    Card(
                      color: AppColors.secondary.withOpacity(0.95),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person_add,
                                  color: AppColors.primaryCTA,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Invite Members',
                                  style: const TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_selectedUsers.length} user${_selectedUsers.length == 1 ? '' : 's'} selected',
                              style: TextStyle(
                                color: AppColors.textLight.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () => setState(
                                () => _showUserSelection = !_showUserSelection,
                              ),
                              icon: Icon(
                                _showUserSelection
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                              ),
                              label: Text(
                                _showUserSelection
                                    ? 'Hide Users'
                                    : 'Select Users',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryCTA,
                                side: const BorderSide(
                                  color: AppColors.primaryCTA,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // User Selection Section
                    if (_showUserSelection) ...[
                      const SizedBox(height: 16),
                      Card(
                        color: AppColors.secondary.withOpacity(0.95),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Users to Invite',
                                style: const TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Search bar
                              TextField(
                                controller: _searchController,
                                onChanged: _filterUsers,
                                decoration: InputDecoration(
                                  hintText: 'Search users...',
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.background,
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Users list
                              Container(
                                height: 200,
                                child: _filteredUsers.isEmpty
                                    ? Center(
                                        child: Text(
                                          'No users found',
                                          style: TextStyle(
                                            color: AppColors.textLight
                                                .withOpacity(0.5),
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: _filteredUsers.length,
                                        itemBuilder: (context, index) {
                                          return _buildUserCard(
                                            _filteredUsers[index],
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Create Button
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createGroup,
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
                      : Text(
                          'Create Group${_selectedUsers.isNotEmpty ? ' & Send Invites' : ''}',
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final userId = user['id'];
    final isSelected = _selectedUsers.contains(userId);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.background,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => _toggleUserSelection(userId),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Selection checkbox
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryCTA : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryCTA
                        : AppColors.textLight.withOpacity(0.3),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 12)
                    : null,
              ),

              const SizedBox(width: 12),

              // User avatar
              CircleAvatar(
                backgroundColor: AppColors.primaryCTA.withOpacity(0.2),
                radius: 16,
                child: Text(
                  user['name'].toString().substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primaryCTA,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'],
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      user['email'],
                      style: TextStyle(
                        color: AppColors.textLight.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Points
              Text(
                '${user['points']} pts',
                style: TextStyle(
                  color: AppColors.textLight.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
