import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:snack_hack_app/core/services/challenge_submission_service.dart';
import 'package:snack_hack_app/core/services/group_service.dart';
import 'package:snack_hack_app/core/services/challenge_service.dart';
import 'package:snack_hack_app/data/models/challenge_submission.dart';
import 'package:snack_hack_app/data/models/group_model.dart';
import 'package:snack_hack_app/app/theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChallengeSubmissionScreen extends StatefulWidget {
  final String challengeText;
  final DateTime date;
  final List<String> modifiers;
  const ChallengeSubmissionScreen({
    required this.challengeText,
    required this.date,
    this.modifiers = const [],
    super.key,
  });

  @override
  State<ChallengeSubmissionScreen> createState() =>
      _ChallengeSubmissionScreenState();
}

class _ChallengeSubmissionScreenState extends State<ChallengeSubmissionScreen> {
  final _controller = TextEditingController();
  File? _imageFile;
  bool _saving = false;
  List<Group> _userGroups = [];
  Set<String> _selectedGroupIds = {}; // Changed to Set for multiple selection
  bool _isLoadingGroups = true;

  @override
  void initState() {
    super.initState();
    _loadUserGroups();
  }

  Future<void> _loadUserGroups() async {
    try {
      final groups = await GroupService.getUserGroups();
      setState(() {
        _userGroups = groups;
        _isLoadingGroups = false;
        // Auto-select first group if available
        if (groups.isNotEmpty) {
          _selectedGroupIds.add(groups.first.id);
        }
      });
    } catch (e) {
      print('❌ SUBMISSION ERROR: Failed to load groups: $e');
      setState(() => _isLoadingGroups = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      // Copy the image to the app's documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
      final savedImage = await File(
        picked.path,
      ).copy('${appDir.path}/$fileName');
      setState(() {
        _imageFile = savedImage;
      });
    }
  }

  Future<void> _submit() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a picture as proof.')),
      );
      return;
    }
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description.')),
      );
      return;
    }
    if (_selectedGroupIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one group to submit to.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

      // Save to local submissions
      final submission = ChallengeSubmission(
        id: widget.date.toIso8601String(),
        typeId: 0,
        challengeId: widget.challengeText,
        userId: currentUserId,
        userName: 'You',
        submissionTitle: widget.challengeText,
        submissionDescription: _controller.text,
        imageUrl: _imageFile?.path,
        videoUrl: null,
        tags: [],
        submittedAt: widget.date,
        updatedAt: null,
        status: SubmissionStatus.pending,
        likesCount: 0,
        commentsCount: 0,
        likedBy: [],
        metadata: null,
      );
      await ChallengeSubmissionService.saveSubmission(submission);

      // Create and submit to all selected groups
      for (final groupId in _selectedGroupIds) {
        final group = _userGroups.firstWhere((g) => g.id == groupId);
        final groupSubmission = GroupSubmission(
          id: '${widget.date.millisecondsSinceEpoch}_${groupId}',
          groupId: groupId,
          userId: currentUserId,
          challengeId: widget.challengeText,
          title: widget.challengeText,
          description: _controller.text,
          imageUrl: _imageFile!.path,
          modifiers: widget.modifiers,
          submittedAt: DateTime.now(),
          votes: {},
        );

        await GroupService.submitToGroup(groupSubmission);
      }

      // Mark challenge as completed
      await ChallengeService.completeTodaysChallenge();

      setState(() => _saving = false);

      if (mounted) {
        // Get selected group names for the success message
        final selectedGroupNames = _userGroups
            .where((group) => _selectedGroupIds.contains(group.id))
            .map((group) => group.name)
            .toList();

        // Show informative popup about the approval process
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            final screenSize = MediaQuery.of(context).size;
            final isTablet = screenSize.width > 600;
            final isIPhone = screenSize.width < 400;
            final isSmallScreen = screenSize.height < 700;

            return AlertDialog(
              backgroundColor: AppColors.secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isTablet ? 20 : 18),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: isTablet ? 32 : (isIPhone ? 24 : 28),
                  ),
                  SizedBox(width: isIPhone ? 8 : 10),
                  Expanded(
                    child: Text(
                      'Proof Submitted Successfully!',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: isTablet ? 22 : (isIPhone ? 16 : 18),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedGroupIds.length == 1
                        ? 'Your proof has been submitted to ${selectedGroupNames.first}! 🎉'
                        : 'Your proof has been submitted to ${_selectedGroupIds.length} groups: ${selectedGroupNames.join(', ')}! 🎉',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: isTablet ? 18 : (isIPhone ? 14 : 16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: isIPhone ? 12 : 16),
                  Container(
                    padding: EdgeInsets.all(isIPhone ? 10 : 12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCTA.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(isIPhone ? 10 : 12),
                      border: Border.all(
                        color: AppColors.primaryCTA.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.primaryCTA,
                          size: isIPhone ? 16 : 20,
                        ),
                        SizedBox(width: isIPhone ? 6 : 8),
                        Expanded(
                          child: Text(
                            'Your proof is currently pending review. You will be notified within 10 minutes whether your challenge is approved or rejected.',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: isTablet ? 16 : (isIPhone ? 12 : 14),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(); // Go back to previous screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryCTA,
                      foregroundColor: AppColors.textLight,
                      textStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isTablet ? 18 : (isIPhone ? 14 : 16),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: isIPhone ? 12 : 16,
                        horizontal: isIPhone ? 16 : 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isIPhone ? 8 : 10),
                      ),
                    ),
                    child: const Text('Got it!'),
                  ),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('❌ SUBMISSION ERROR: $e');
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.camera_alt, color: AppColors.primaryCTA, size: 26),
            const SizedBox(width: 10),
            Text(
              'SUBMIT PROOF',
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              Card(
                color: AppColors.secondary,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: AppColors.primaryCTA,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.challengeText,
                          style: const TextStyle(
                            color: AppColors.textLight,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Group selection card
              if (!_isLoadingGroups) ...[
                Card(
                  color: AppColors.secondary,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryCTA.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.groups,
                                color: AppColors.primaryCTA,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Choose Your Group',
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select which group to submit your challenge proof to:',
                          style: TextStyle(
                            color: AppColors.textLight.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_userGroups.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'No Groups Available',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'You need to join or create a group first to submit challenges',
                                        style: TextStyle(
                                          color: Colors.orange.withOpacity(0.8),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          Column(
                            children: _userGroups.map((group) {
                              final isSelected = _selectedGroupIds.contains(
                                group.id,
                              );
                              return CheckboxListTile(
                                value: isSelected,
                                onChanged: (bool? newValue) {
                                  setState(() {
                                    if (newValue == true) {
                                      _selectedGroupIds.add(group.id);
                                    } else {
                                      _selectedGroupIds.remove(group.id);
                                    }
                                  });
                                },
                                title: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryCTA.withOpacity(
                                          0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Center(
                                        child: Text(
                                          group.name
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: TextStyle(
                                            color: AppColors.primaryCTA,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            group.name,
                                            style: const TextStyle(
                                              color: AppColors.textLight,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            '${group.members.length} members',
                                            style: TextStyle(
                                              color: AppColors.textLight
                                                  .withOpacity(0.6),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle,
                                        color: AppColors.primaryCTA,
                                        size: 20,
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          if (_selectedGroupIds.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryCTA.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primaryCTA.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: AppColors.primaryCTA,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Selected: ${_selectedGroupIds.length} groups',
                                          style: TextStyle(
                                            color: AppColors.primaryCTA,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (_selectedGroupIds.length > 0)
                                          Text(
                                            _userGroups
                                                .where(
                                                  (group) => _selectedGroupIds
                                                      .contains(group.id),
                                                )
                                                .map((group) => group.name)
                                                .join(', '),
                                            style: TextStyle(
                                              color: AppColors.primaryCTA
                                                  .withOpacity(0.8),
                                              fontSize: 12,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              Card(
                color: AppColors.secondary,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.edit, color: AppColors.primaryCTA),
                          const SizedBox(width: 8),
                          const Text(
                            'Describe your proof',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'What did you do? Any details...',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: AppColors.background,
                        ),
                        maxLines: 3,
                        style: const TextStyle(color: AppColors.textLight),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_imageFile != null)
                Card(
                  color: AppColors.secondary,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          _imageFile!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => setState(() => _imageFile = null),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.redAccent,
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo, color: AppColors.secondaryCTA),
                  label: const Text('Pick Image'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondaryCTA,
                    side: const BorderSide(
                      color: AppColors.secondaryCTA,
                      width: 2,
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _saving
                  ? const CircularProgressIndicator(color: AppColors.primaryCTA)
                  : SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Submit'),
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
                      ),
                    ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
