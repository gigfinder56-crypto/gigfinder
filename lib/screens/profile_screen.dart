import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // Added for kIsWeb
import 'package:mavenlink/models/user.dart';
import 'package:mavenlink/services/user_service.dart';
import 'package:mavenlink/services/application_service.dart';
import 'package:mavenlink/services/experience_service.dart';
import 'package:mavenlink/screens/profile_setup_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApplicationService _applicationService = ApplicationService();
  final ExperienceService _experienceService = ExperienceService();

  User? _currentUser;
  Map<String, int> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await UserService.getCurrentUser();
      if (user != null) {
        // Load user stats
        final applications = await _applicationService.getUserApplications(user.id);
        final experiences = await _experienceService.getUserExperiences(user.id);
        final acceptedApplications = applications.where((app) => app.status == 'Accepted').length;

        setState(() {
          _currentUser = user;
          _stats = {
            'totalApplications': applications.length,
            'acceptedApplications': acceptedApplications,
            'experiencesShared': experiences.length,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  void _editProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileSetupScreen(),
      ),
    ).then((_) => _loadData()); // Refresh after editing
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit,
              color: colorScheme.primary,
            ),
            onPressed: _editProfile,
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 24),
                    _buildStatsSection(),
                    const SizedBox(height: 24),
                    _buildInfoSection(),
                    const SizedBox(height: 24),
                    _buildSkillsSection(),
                    const SizedBox(height: 24),
                    _buildInterestsSection(),
                    if (_currentUser?.role == 'Student' && _currentUser?.studentInfo != null) ...[
                      const SizedBox(height: 24),
                      _buildStudentInfoSection(),
                    ],
                    if (_currentUser?.role == 'Employee' && _currentUser?.employeeInfo != null) ...[
                      const SizedBox(height: 24),
                      _buildEmployeeInfoSection(),
                    ],
                    if (_currentUser?.others.isNotEmpty == true) ...[
                      const SizedBox(height: 24),
                      _buildOthersSection(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [colorScheme.primary, colorScheme.tertiary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Profile Photo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.onPrimary.withOpacity(0.3),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: _getProfileImage(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Name
            Text(
              _currentUser?.name ?? 'User',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // Email
            Text(
              _currentUser?.email ?? '',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onPrimary.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Role badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.onPrimary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.onPrimary.withOpacity(0.3),
                ),
              ),
              child: Text(
                _currentUser?.role ?? 'User',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getProfileImage() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final path = _currentUser?.profilePhotoPath;

    if (path == null || path.isEmpty) {
      return _buildAvatarFallback();
    }

    if (path.startsWith('http')) {
      // If it's a URL (e.g., from cloud storage), use Image.network (works on all platforms)
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(),
      );
    } else if (!kIsWeb) {
      // For local file paths, use Image.file only on non-web platforms
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(),
      );
    } else {
      // On web, local files aren't accessible; fall back to avatar
      return _buildAvatarFallback();
    }
  }

  Widget _buildAvatarFallback() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.onPrimary.withOpacity(0.2),
      ),
      child: Icon(
        Icons.person,
        size: 50,
        color: colorScheme.onPrimary.withOpacity(0.8),
      ),
    );
  }

  Widget _buildStatsSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total\nApplications',
                    '${_stats['totalApplications'] ?? 0}',
                    Icons.work_outline,
                    colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Accepted\nApplications',
                    '${_stats['acceptedApplications'] ?? 0}',
                    Icons.check_circle_outline,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Experiences\nShared',
                    '${_stats['experiencesShared'] ?? 0}',
                    Icons.rate_review_outlined,
                    colorScheme.tertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow(Icons.cake_outlined, 'Age', '${_currentUser?.age ?? 0} years old'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone_outlined, 'Mobile', _currentUser?.mobileNumber ?? 'Not provided'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on_outlined, 'Location', _currentUser?.location ?? 'Not provided'),
            
            if (_currentUser?.resumePath.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              _buildInfoRow(Icons.description_outlined, 'Resume', 'Uploaded', hasFile: true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool hasFile = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          color: colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: hasFile ? Colors.green : colorScheme.onSurface.withOpacity(0.8),
              fontWeight: hasFile ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        if (hasFile)
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 16,
          ),
      ],
    );
  }

  Widget _buildSkillsSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_currentUser?.skills.isEmpty == true) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.build_outlined,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Skills',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _currentUser!.skills.map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    skill,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestsSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_currentUser?.interests.isEmpty == true) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.favorite_outline,
                  color: colorScheme.secondary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Interests',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _currentUser!.interests.map((interest) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.secondary.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    interest,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentInfoSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final studentInfo = _currentUser!.studentInfo!;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.school_outlined,
                  color: colorScheme.tertiary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Academic Information',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow(Icons.location_city_outlined, 'College', studentInfo.college),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.class_outlined, 'Year', studentInfo.year),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.account_tree_outlined, 'Branch', studentInfo.branch),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeInfoSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final employeeInfo = _currentUser!.employeeInfo!;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.work_outline,
                  color: colorScheme.tertiary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Professional Information',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow(Icons.business_outlined, 'Company', employeeInfo.company),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.badge_outlined, 'Role', employeeInfo.role),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.timeline_outlined, 'Experience', '${employeeInfo.yearsOfExperience} years'),
          ],
        ),
      ),
    );
  }

  Widget _buildOthersSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: colorScheme.onSurface.withOpacity(0.7),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Additional Information',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _currentUser!.others,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}