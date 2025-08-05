import 'package:flutter/material.dart';
import 'package:snack_hack_app/app/theme.dart';
import 'package:snack_hack_app/core/services/challenge_service.dart';
import 'package:snack_hack_app/data/models/challenge_model.dart';
import 'package:snack_hack_app/core/services/modifier_service.dart';

class ChallengeHistoryScreen extends StatefulWidget {
  const ChallengeHistoryScreen({super.key});

  @override
  State<ChallengeHistoryScreen> createState() => _ChallengeHistoryScreenState();
}

class _ChallengeHistoryScreenState extends State<ChallengeHistoryScreen> {
  List<ChallengeEntry> _challenges = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  String _selectedCategory = 'all';
  String _selectedModifier = 'all';
  List<Modifier> _availableModifiers = [];

  @override
  void initState() {
    super.initState();
    _loadChallenges();
    _loadModifiers();
  }

  Future<void> _loadModifiers() async {
    await ModifierService.initialize();
    final modifiers = ModifierService.getAllModifiers();
    setState(() {
      _availableModifiers = modifiers;
    });
  }

  Future<void> _loadChallenges() async {
    print('📚 HISTORY: Loading challenge history...');
    setState(() => _isLoading = true);

    try {
      final challenges = await ChallengeService.getUserChallenges();
      setState(() {
        _challenges = challenges;
        _isLoading = false;
      });
      print('📚 HISTORY: Loaded ${challenges.length} challenges');
    } catch (e) {
      print('❌ HISTORY ERROR: $e');
      setState(() => _isLoading = false);
    }
  }

  List<ChallengeEntry> get _filteredChallenges {
    return _challenges.where((challenge) {
      // Filter by completion status
      if (_selectedFilter == 'completed' && !challenge.completed) return false;
      if (_selectedFilter == 'pending' && challenge.completed) return false;

      // Filter by category
      if (_selectedCategory != 'all' && challenge.category != _selectedCategory)
        return false;

      // Filter by modifier
      if (_selectedModifier != 'all' &&
          !challenge.modifiers.contains(_selectedModifier))
        return false;

      return true;
    }).toList();
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
            Icon(Icons.history, color: AppColors.primaryCTA, size: 28),
            const SizedBox(width: 10),
            Text(
              'CHALLENGE HISTORY',
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
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.textLight),
            onPressed: _loadChallenges,
          ),
        ],
      ),
      body: Column(
        children: [
          // Enhanced Filters
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.primary.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // First row of filters
                Row(
                  children: [
                    Expanded(
                      child: _buildFilterDropdown(
                        value: _selectedFilter,
                        items: [
                          {'value': 'all', 'label': 'All Status'},
                          {'value': 'completed', 'label': '✅ Completed'},
                          {'value': 'pending', 'label': '⏳ Not Started'},
                        ],
                        onChanged: (value) {
                          setState(() => _selectedFilter = value!);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFilterDropdown(
                        value: _selectedCategory,
                        items: [
                          {'value': 'all', 'label': 'All Categories'},
                          {'value': 'healthy', 'label': '🥗 Healthy'},
                          {'value': 'fun', 'label': '🎉 Fun'},
                          {'value': 'creative', 'label': '🎨 Creative'},
                          {'value': 'social', 'label': '🤝 Social'},
                          {'value': 'mindful', 'label': '🧘 Mindful'},
                          {'value': 'adventure', 'label': '🗺️ Adventure'},
                        ],
                        onChanged: (value) {
                          setState(() => _selectedCategory = value!);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Second row - modifier filter
                Row(
                  children: [
                    Expanded(
                      child: _buildFilterDropdown(
                        value: _selectedModifier,
                        items: [
                          {'value': 'all', 'label': 'All Modifiers'},
                          ..._availableModifiers
                              .map(
                                (modifier) => {
                                  'value': modifier.id,
                                  'label': '${modifier.icon} ${modifier.text}',
                                },
                              )
                              .toList(),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedModifier = value!);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Clear filters button
                    Container(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedFilter = 'all';
                            _selectedCategory = 'all';
                            _selectedModifier = 'all';
                          });
                        },
                        icon: const Icon(Icons.clear, size: 18),
                        label: const Text('Clear'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryCTA,
                          foregroundColor: AppColors.textDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Enhanced stats
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.list_alt,
                    title: 'Total',
                    value: '${_filteredChallenges.length}',
                    color: AppColors.primaryCTA,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.check_circle,
                    title: 'Completed',
                    value:
                        '${_filteredChallenges.where((c) => c.completed).length}',
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.pending,
                    title: 'Pending',
                    value:
                        '${_filteredChallenges.where((c) => !c.completed).length}',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          // Challenges list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryCTA,
                    ),
                  )
                : _filteredChallenges.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredChallenges.length,
                    itemBuilder: (context, index) {
                      return _buildChallengeCard(_filteredChallenges[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textLight.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<Map<String, String>> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryCTA.withOpacity(0.3)),
      ),
      child: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        underline: const SizedBox(),
        icon: Icon(Icons.arrow_drop_down, color: AppColors.primaryCTA),
        style: const TextStyle(
          color: AppColors.textLight,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        isExpanded: true,
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item['value'],
            child: Text(item['label']!, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChallengeCard(ChallengeEntry challenge) {
    final modifierPoints = ModifierService.calculateModifierPoints(
      challenge.modifiers,
    );

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
            // Header with date and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatDate(challenge.date),
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: challenge.completed
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    challenge.completed ? '✅ Completed' : '⏳ Pending',
                    style: TextStyle(
                      color: challenge.completed ? Colors.green : Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Challenge text
            Text(
              challenge.challengeText,
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            // Category and difficulty
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryCTA.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    challenge.category.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primaryCTA,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(
                      challenge.difficulty,
                    ).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    challenge.difficulty.toUpperCase(),
                    style: TextStyle(
                      color: _getDifficultyColor(challenge.difficulty),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (modifierPoints > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryCTA.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+${modifierPoints} pts',
                      style: const TextStyle(
                        color: AppColors.secondaryCTA,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            // Modifiers
            if (challenge.modifiers.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.star, color: AppColors.secondaryCTA, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Modifiers (${challenge.modifiers.length}):',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: challenge.modifiers.map((modifierId) {
                  final modifier = ModifierService.getModifierById(modifierId);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryCTA.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.secondaryCTA.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          modifier?.icon ?? '🎯',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          modifier?.text ?? modifierId,
                          style: const TextStyle(
                            color: AppColors.secondaryCTA,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+${modifier?.points ?? 0}',
                          style: const TextStyle(
                            color: AppColors.primaryCTA,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
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
            Icons.history,
            size: 64,
            color: AppColors.textLight.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No challenges found',
            style: TextStyle(
              color: AppColors.textLight.withOpacity(0.7),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or complete some challenges!',
            style: TextStyle(
              color: AppColors.textLight.withOpacity(0.5),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _selectedFilter = 'all';
                _selectedCategory = 'all';
                _selectedModifier = 'all';
              });
            },
            icon: const Icon(Icons.clear),
            label: const Text('Clear Filters'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryCTA,
              foregroundColor: AppColors.textDark,
            ),
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

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return AppColors.primaryCTA;
    }
  }
}
