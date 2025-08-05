import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:snack_hack_app/data/models/challenge_submission.dart';
import 'dart:io';
import 'package:snack_hack_app/app/theme.dart';
import 'package:snack_hack_app/core/services/challenge_submission_service.dart';

class SubmissionHistoryScreen extends StatefulWidget {
  final List<ChallengeSubmission> submissions;

  const SubmissionHistoryScreen({super.key, required this.submissions});

  @override
  State<SubmissionHistoryScreen> createState() =>
      _SubmissionHistoryScreenState();
}

class _SubmissionHistoryScreenState extends State<SubmissionHistoryScreen> {
  List<ChallengeSubmission> get _submissions => widget.submissions;
  SubmissionStatus? _selectedFilter;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _autoApproveOldSubmissions();
  }

  Future<void> _autoApproveOldSubmissions() async {
    bool updated = false;
    final now = DateTime.now();
    for (final submission in _submissions) {
      if (submission.status == SubmissionStatus.pending &&
          now.difference(submission.submittedAt) >
              const Duration(minutes: 10)) {
        final approvedSubmission = ChallengeSubmission(
          id: submission.id,
          typeId: submission.typeId,
          challengeId: submission.challengeId,
          userId: submission.userId,
          userName: submission.userName,
          submissionTitle: submission.submissionTitle,
          submissionDescription: submission.submissionDescription,
          imageUrl: submission.imageUrl,
          videoUrl: submission.videoUrl,
          tags: submission.tags,
          submittedAt: submission.submittedAt,
          updatedAt: DateTime.now(),
          status: SubmissionStatus.approved,
          likesCount: submission.likesCount,
          commentsCount: submission.commentsCount,
          likedBy: submission.likedBy,
          metadata: submission.metadata,
        );
        await ChallengeSubmissionService.saveSubmission(approvedSubmission);
        updated = true;
      }
    }
    if (updated && mounted) {
      final fresh = await ChallengeSubmissionService.getAllSubmissions();
      setState(() {
        widget.submissions.clear();
        widget.submissions.addAll(fresh);
      });
    }
  }

  List<ChallengeSubmission> get _filteredSubmissions {
    if (_selectedFilter == null) return _submissions;
    return _submissions.where((s) => s.status == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isSmallScreen = screenSize.height < 700;
    final isIPhone = screenSize.width < 400; // iPhone detection

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
            Icon(Icons.history, color: AppColors.primaryCTA, size: 26),
            const SizedBox(width: 12),
            Text(
              'SUBMISSION HISTORY',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: isTablet ? 24 : (isIPhone ? 18 : 20),
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStatsSection(isTablet, isIPhone),
            _buildFilterSection(isTablet, isIPhone),
            Expanded(
              child: _filteredSubmissions.isEmpty
                  ? _buildEmptyState(isTablet, isIPhone)
                  : _buildSubmissionsList(isTablet, isIPhone),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(bool isTablet, bool isIPhone) {
    final approvedCount = _submissions
        .where((s) => s.status == SubmissionStatus.approved)
        .length;
    final pendingCount = _submissions
        .where((s) => s.status == SubmissionStatus.pending)
        .length;
    final rejectedCount = _submissions
        .where((s) => s.status == SubmissionStatus.rejected)
        .length;

    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;

    return Container(
      margin: EdgeInsets.all(isTablet ? 24 : (isIPhone ? 8 : (isSmallScreen ? 12 : 16))),
      child: Card(
        color: AppColors.secondary,
        elevation: 8,
        shadowColor: AppColors.primaryCTA.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 32 : (isIPhone ? 12 : (isSmallScreen ? 16 : 24))),
          child: Column(
            children: [
              Text(
                'Submission Overview',
                style: TextStyle(
                  fontSize: isTablet ? 22 : (isIPhone ? 14 : (isSmallScreen ? 16 : 18)),
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
              SizedBox(height: isIPhone ? 12 : (isSmallScreen ? 16 : 20)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    isIPhone ? 'Approved' : 'Proof Approved',
                    approvedCount,
                    Colors.green,
                    Icons.check_circle,
                    isTablet,
                    isIPhone,
                  ),
                  _buildStatItem(
                    isIPhone ? 'Pending' : 'Proof Pending',
                    pendingCount,
                    Colors.orange,
                    Icons.pending,
                    isTablet,
                    isIPhone,
                  ),
                  _buildStatItem(
                    isIPhone ? 'Rejected' : 'Proof Rejected',
                    rejectedCount,
                    Colors.red,
                    Icons.cancel,
                    isTablet,
                    isIPhone,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    int count,
    Color color,
    IconData icon,
    bool isTablet,
    bool isIPhone,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isTablet ? 16 : (isIPhone ? 8 : 12)),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: isTablet ? 28 : (isIPhone ? 20 : 24)),
              SizedBox(height: isIPhone ? 4 : 8),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: isTablet ? 32 : (isIPhone ? 24 : 28),
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isIPhone ? 8 : 12),
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 16 : (isIPhone ? 11 : 14),
            color: AppColors.textLight,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFilterSection(bool isTablet, bool isIPhone) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : (isIPhone ? 8 : (isSmallScreen ? 12 : 16)),
        vertical: isIPhone ? 6 : (isSmallScreen ? 8 : 12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', null, isTablet, isIPhone),
            SizedBox(width: isIPhone ? 4 : (isSmallScreen ? 6 : 8)),
            _buildFilterChip(
              isIPhone ? 'Approved' : 'Proof Approved',
              SubmissionStatus.approved,
              isTablet,
              isIPhone,
            ),
            SizedBox(width: isIPhone ? 4 : (isSmallScreen ? 6 : 8)),
            _buildFilterChip(
              isIPhone ? 'Pending' : 'Proof Pending',
              SubmissionStatus.pending,
              isTablet,
              isIPhone,
            ),
            SizedBox(width: isIPhone ? 4 : (isSmallScreen ? 6 : 8)),
            _buildFilterChip(
              isIPhone ? 'Rejected' : 'Proof Rejected',
              SubmissionStatus.rejected,
              isTablet,
              isIPhone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    SubmissionStatus? status,
    bool isTablet,
    bool isIPhone,
  ) {
    final isSelected = _selectedFilter == status;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? AppColors.textLight
              : AppColors.textLight.withOpacity(0.7),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: isIPhone ? 12 : 14,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? status : null;
        });
      },
      backgroundColor: AppColors.secondary,
      selectedColor: AppColors.primaryCTA,
      checkmarkColor: AppColors.textLight,
      side: BorderSide(
        color: isSelected
            ? AppColors.primaryCTA
            : AppColors.primaryCTA.withOpacity(0.3),
        width: 1.5,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: EdgeInsets.symmetric(
        horizontal: isIPhone ? 8 : 12,
        vertical: isIPhone ? 6 : 8,
      ),
    );
  }

  Widget _buildEmptyState(bool isTablet, bool isIPhone) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 40 : (isIPhone ? 16 : (isSmallScreen ? 24 : 32))),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isIPhone ? 16 : (isSmallScreen ? 20 : 24)),
                decoration: BoxDecoration(
                  color: AppColors.secondaryCTA.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.history,
                  size: isTablet ? 100 : (isIPhone ? 50 : (isSmallScreen ? 60 : 80)),
                  color: AppColors.secondaryCTA.withOpacity(0.6),
                ),
              ),
              SizedBox(height: isIPhone ? 16 : (isSmallScreen ? 20 : 24)),
              Text(
                _selectedFilter == null
                    ? 'No proof submissions yet'
                    : 'No ${_getStatusLabel(_selectedFilter!)} submissions',
                style: TextStyle(
                  fontSize: isTablet ? 28 : (isIPhone ? 18 : (isSmallScreen ? 20 : 24)),
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isIPhone ? 8 : (isSmallScreen ? 10 : 12)),
              Text(
                _selectedFilter == null
                    ? 'Your challenge submissions will appear here once you start participating in challenges.'
                    : 'Try changing the filter or submit a new challenge to see your submissions here.',
                style: TextStyle(
                  fontSize: isTablet ? 18 : (isIPhone ? 13 : (isSmallScreen ? 14 : 16)),
                  color: AppColors.textLight.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isIPhone ? 20 : (isSmallScreen ? 24 : 32)),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.add, size: isTablet ? 24 : (isIPhone ? 18 : 20)),
                label: Text(
                  'Start a Challenge',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : (isIPhone ? 14 : (isSmallScreen ? 14 : 16)),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryCTA,
                  foregroundColor: AppColors.textLight,
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 32 : (isIPhone ? 16 : (isSmallScreen ? 20 : 24)),
                    vertical: isIPhone ? 10 : (isSmallScreen ? 12 : 16),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              // Add bottom padding to prevent overflow
              SizedBox(height: isIPhone ? 20 : 32),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusLabel(SubmissionStatus status) {
    switch (status) {
      case SubmissionStatus.approved:
        return 'proof approved';
      case SubmissionStatus.pending:
        return 'proof pending';
      case SubmissionStatus.rejected:
        return 'proof rejected';
      case SubmissionStatus.underReview:
        return 'proof under review';
    }
  }

  Widget _buildSubmissionsList(bool isTablet, bool isIPhone) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : (isIPhone ? 8 : (isSmallScreen ? 12 : 16)),
        vertical: isIPhone ? 8 : (isSmallScreen ? 12 : 16),
      ),
      itemCount: _filteredSubmissions.length,
      itemBuilder: (context, index) {
        final submission = _filteredSubmissions[index];
        return _buildSubmissionCard(submission, isTablet, isIPhone);
      },
    );
  }

  Widget _buildSubmissionCard(ChallengeSubmission submission, bool isTablet, bool isIPhone) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;

    return Card(
      color: AppColors.secondary,
      elevation: 4,
      shadowColor: AppColors.primaryCTA.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.only(
        bottom: isTablet ? 20 : (isIPhone ? 8 : (isSmallScreen ? 12 : 16)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showSubmissionDetails(submission, isTablet),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 24 : (isIPhone ? 12 : (isSmallScreen ? 16 : 20))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            submission.submissionTitle,
                            style: TextStyle(
                              fontSize: isTablet
                                  ? 20
                                  : (isIPhone ? 14 : (isSmallScreen ? 16 : 18)),
                              fontWeight: FontWeight.bold,
                              color: AppColors.textLight,
                            ),
                          ),
                          SizedBox(height: isIPhone ? 4 : (isSmallScreen ? 6 : 8)),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: isIPhone ? 14 : 16,
                                color: AppColors.primaryCTA,
                              ),
                              SizedBox(width: isIPhone ? 4 : 6),
                              Text(
                                DateFormat(
                                  'MMM dd, yyyy • HH:mm',
                                ).format(submission.submittedAt),
                                style: TextStyle(
                                  fontSize: isTablet
                                      ? 15
                                      : (isIPhone ? 11 : (isSmallScreen ? 12 : 14)),
                                  color: AppColors.textLight.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: isIPhone ? 8 : 12),
                    _buildStatusChip(submission.status, isTablet, isIPhone),
                  ],
                ),
                if (submission.submissionDescription.isNotEmpty) ...[
                  SizedBox(height: isIPhone ? 8 : (isSmallScreen ? 12 : 16)),
                  Text(
                    submission.submissionDescription,
                    style: TextStyle(
                      fontSize: isTablet ? 16 : (isIPhone ? 12 : (isSmallScreen ? 13 : 15)),
                      color: AppColors.textLight.withOpacity(0.9),
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (submission.imageUrl != null &&
                    submission.imageUrl!.isNotEmpty) ...[
                  SizedBox(height: isIPhone ? 8 : (isSmallScreen ? 12 : 16)),
                  _buildImagePreview(submission.imageUrl!, isTablet, isIPhone),
                ],
                SizedBox(height: isIPhone ? 8 : (isSmallScreen ? 12 : 16)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Tap to view details',
                      style: TextStyle(
                        fontSize: isIPhone ? 10 : 12,
                        color: AppColors.primaryCTA,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(String imagePath, bool isTablet, bool isIPhone) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;

    return Builder(
      builder: (context) {
        final file = File(imagePath);
        if (file.existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              file,
              height: isTablet ? 140 : (isIPhone ? 80 : (isSmallScreen ? 100 : 120)),
              width: isTablet ? 140 : (isIPhone ? 80 : (isSmallScreen ? 100 : 120)),
              fit: BoxFit.cover,
            ),
          );
        } else {
          return Container(
            height: isTablet ? 140 : (isIPhone ? 80 : (isSmallScreen ? 100 : 120)),
            width: isTablet ? 140 : (isIPhone ? 80 : (isSmallScreen ? 100 : 120)),
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.secondaryCTA.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image,
                  color: AppColors.secondaryCTA.withOpacity(0.6),
                  size: isTablet ? 48 : (isIPhone ? 24 : (isSmallScreen ? 32 : 40)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Image not found',
                  style: TextStyle(
                    fontSize: isIPhone ? 10 : 12,
                    color: AppColors.secondaryCTA.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildStatusChip(SubmissionStatus status, bool isTablet, bool isIPhone) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;

    Color color;
    String text;
    IconData icon;

    switch (status) {
      case SubmissionStatus.approved:
        color = Colors.green;
        text = isIPhone ? 'Approved' : 'Proof Approved';
        icon = Icons.check_circle;
        break;
      case SubmissionStatus.pending:
        color = Colors.orange;
        text = isIPhone ? 'Pending' : 'Proof Pending';
        icon = Icons.pending;
        break;
      case SubmissionStatus.rejected:
        color = Colors.red;
        text = isIPhone ? 'Rejected' : 'Proof Rejected';
        icon = Icons.cancel;
        break;
      case SubmissionStatus.underReview:
        color = Colors.blue;
        text = 'Under Review';
        icon = Icons.hourglass_empty;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : (isIPhone ? 8 : (isSmallScreen ? 10 : 12)),
        vertical: isTablet ? 8 : (isIPhone ? 4 : (isSmallScreen ? 5 : 6)),
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isTablet ? 18 : (isIPhone ? 12 : (isSmallScreen ? 14 : 16)),
            color: color,
          ),
          SizedBox(width: isIPhone ? 2 : (isSmallScreen ? 4 : 6)),
          Text(
            text,
            style: TextStyle(
              fontSize: isTablet ? 14 : (isIPhone ? 9 : (isSmallScreen ? 10 : 12)),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showSubmissionDetails(ChallengeSubmission submission, bool isTablet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSubmissionDetailsSheet(submission, isTablet),
    );
  }

  Widget _buildSubmissionDetailsSheet(
    ChallengeSubmission submission,
    bool isTablet,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate responsive height and width
    final modalHeight = isTablet ? screenHeight * 0.85 : screenHeight * 0.75;
    final modalWidth = isTablet ? screenWidth * 0.8 : screenWidth;

    return Container(
      height: modalHeight,
      width: modalWidth,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isTablet ? 20 : 24),
          topRight: Radius.circular(isTablet ? 20 : 24),
          bottomLeft: isTablet ? Radius.circular(20) : Radius.zero,
          bottomRight: isTablet ? Radius.circular(20) : Radius.zero,
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: EdgeInsets.only(top: isTablet ? 20 : 16),
            width: isTablet ? 60 : 50,
            height: isTablet ? 6 : 5,
            decoration: BoxDecoration(
              color: AppColors.primaryCTA.withOpacity(0.3),
              borderRadius: BorderRadius.circular(isTablet ? 3 : 2.5),
            ),
          ),

          // Header section
          Padding(
            padding: EdgeInsets.all(isTablet ? 24 : 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    submission.submissionTitle,
                    style: TextStyle(
                      fontSize: isTablet ? 26 : 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                _buildStatusChip(submission.status, isTablet, false),
              ],
            ),
          ),

          // Content section
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 24 : 20,
                vertical: 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Submission date
                  _buildDetailRow(
                    'Submitted',
                    DateFormat(
                      'MMM dd, yyyy • HH:mm',
                    ).format(submission.submittedAt),
                    Icons.schedule,
                    isTablet,
                  ),

                  // Description section
                  if (submission.submissionDescription.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSectionHeader(
                      'Description',
                      Icons.description,
                      isTablet,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isTablet ? 20 : 16),
                      decoration: BoxDecoration(
                        color: AppColors.background.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryCTA.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        submission.submissionDescription,
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 15,
                          color: AppColors.textLight.withOpacity(0.9),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],

                  // Image section
                  if (submission.imageUrl != null &&
                      submission.imageUrl!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      'Submission Image',
                      Icons.image,
                      isTablet,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: _buildDetailImage(submission.imageUrl!, isTablet),
                    ),
                  ],

                  // Bottom spacing
                  SizedBox(height: isTablet ? 32 : 24),
                ],
              ),
            ),
          ),

          // Close button
          Padding(
            padding: EdgeInsets.all(isTablet ? 24 : 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: const Text('Close'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryCTA,
                  foregroundColor: AppColors.textLight,
                  textStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isTablet ? 18 : 16,
                  ),
                  padding: EdgeInsets.symmetric(vertical: isTablet ? 18 : 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    bool isTablet,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryCTA, size: isTablet ? 24 : 20),
          const SizedBox(width: 12),
          SizedBox(
            width: isTablet ? 120 : 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                color: AppColors.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textLight.withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailImage(String imagePath, bool isTablet) {
    return Builder(
      builder: (context) {
        final file = File(imagePath);
        if (file.existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              file,
              height: isTablet ? 200 : 160,
              width: isTablet ? 200 : 160,
              fit: BoxFit.cover,
            ),
          );
        } else {
          return Container(
            height: isTablet ? 200 : 160,
            width: isTablet ? 200 : 160,
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.secondaryCTA.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image,
                  color: AppColors.secondaryCTA.withOpacity(0.6),
                  size: isTablet ? 64 : 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'Image not found',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: AppColors.secondaryCTA.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isTablet) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryCTA, size: isTablet ? 22 : 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: isTablet ? 18 : 16,
            color: AppColors.textLight,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
