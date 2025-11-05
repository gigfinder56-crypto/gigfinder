import 'package:flutter/material.dart';
import 'package:mavenlink/models/opportunity.dart';
import 'package:mavenlink/services/opportunity_service.dart';
import 'package:mavenlink/screens/opportunity_detail_screen.dart';

class OpportunitiesScreen extends StatefulWidget {
  final String category;

  const OpportunitiesScreen({super.key, required this.category});

  @override
  State<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends State<OpportunitiesScreen> {
  final OpportunityService _opportunityService = OpportunityService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Opportunity> _opportunities = [];
  List<Opportunity> _filteredOpportunities = [];
  bool _isLoading = true;
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    _loadOpportunities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// ✅ FIXED FUNCTION
  Future<void> _loadOpportunities() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Opportunity> opportunities = [];

      // ✅ If category is Internships → show all internships
      if (widget.category.toLowerCase() == 'internships') {
        opportunities = await _opportunityService.getAllOpportunities();
      } else {
        opportunities = await _opportunityService.getOpportunitiesByCategory(widget.category);
      }

      setState(() {
        _opportunities = opportunities;
        _filteredOpportunities = opportunities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading opportunities: $e')),
        );
      }
    }
  }

  void _filterOpportunities(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredOpportunities = _opportunities;
      } else {
        _filteredOpportunities = _opportunities.where((opportunity) {
          final titleMatch = opportunity.title.toLowerCase().contains(query.toLowerCase());
          final companyMatch = opportunity.company.toLowerCase().contains(query.toLowerCase());
          final locationMatch = opportunity.location.toLowerCase().contains(query.toLowerCase());
          final skillsMatch = opportunity.requiredSkills.any(
            (skill) => skill.toLowerCase().contains(query.toLowerCase()),
          );
          return titleMatch || companyMatch || locationMatch || skillsMatch;
        }).toList();
      }
    });
  }

  void _toggleSearchBar() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _searchController.clear();
        _filteredOpportunities = _opportunities;
      }
    });
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.category,
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actions: [
          IconButton(
            icon: Icon(
              _showSearchBar ? Icons.close : Icons.search,
              color: colorScheme.onSurface,
            ),
            onPressed: _toggleSearchBar,
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showSearchBar ? 80 : 0,
            child: _showSearchBar
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterOpportunities,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search opportunities...',
                        prefixIcon: Icon(Icons.search, color: colorScheme.onSurface.withOpacity(0.6)),
                        filled: true,
                        fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredOpportunities.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadOpportunities,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _filteredOpportunities.length,
        itemBuilder: (context, index) {
          final opportunity = _filteredOpportunities[index];
          return _buildOpportunityCard(opportunity);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_off_outlined, size: 80, color: colorScheme.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty
                ? 'No opportunities found for "${_searchController.text}"'
                : 'No opportunities available\nin this category',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'Check back later for new opportunities',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOpportunityCard(Opportunity opportunity) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OpportunityDetailScreen(opportunity: opportunity),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                          opportunity.title,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          opportunity.company,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getTimeAgo(opportunity.postedDate),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 18, color: colorScheme.onSurface.withOpacity(0.6)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      opportunity.location,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.account_balance_wallet_outlined, size: 18, color: colorScheme.onSurface.withOpacity(0.6)),
                  const SizedBox(width: 6),
                  Text(
                    opportunity.salary,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (opportunity.requiredSkills.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: opportunity.requiredSkills.take(4).map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.secondary.withOpacity(0.3)),
                      ),
                      child: Text(
                        skill,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (opportunity.requiredSkills.length > 4)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '+${opportunity.requiredSkills.length - 4} more skills',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.schedule_outlined, size: 18, color: colorScheme.onSurface.withOpacity(0.6)),
                  const SizedBox(width: 6),
                  Text(
                    'Duration: ${opportunity.duration}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.onSurface.withOpacity(0.4)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
