import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/services/mock_data_service.dart';
import '../../shared/models/doctor_contact.dart';
import '../../shared/models/vital_signs.dart';

class CallDoctorScreen extends StatefulWidget {
  const CallDoctorScreen({super.key});

  @override
  State<CallDoctorScreen> createState() => _CallDoctorScreenState();
}

class _CallDoctorScreenState extends State<CallDoctorScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final MockDataService _mockDataService = MockDataService();
  List<DoctorContact> _contacts = [];
  VitalSigns? _currentVitals;
  bool _isLoading = true;
  bool _isEmergencyMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadContactsAndVitals();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadContactsAndVitals() async {
    setState(() => _isLoading = true);
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    _contacts = _mockDataService.generateDoctorContacts();
    // Get current vitals for emergency context
    _mockDataService.vitalSignsStream.first.then((vitals) {
      if (mounted) {
        setState(() => _currentVitals = vitals);
      }
    });
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isEmergencyMode ? AppColors.critical.withValues(alpha: 0.05) : AppColors.background,
      appBar: AppBar(
        title: Text(
          _isEmergencyMode ? 'Emergency Contacts' : 'Healthcare Contacts',
          style: AppTypography.headlineSmall.copyWith(
            color: _isEmergencyMode ? AppColors.critical : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: _isEmergencyMode ? AppColors.critical.withValues(alpha: 0.1) : AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isEmergencyMode ? Icons.emergency_outlined : Icons.emergency,
              color: _isEmergencyMode ? AppColors.critical : AppColors.warning,
            ),
            onPressed: () => setState(() => _isEmergencyMode = !_isEmergencyMode),
          ),
        ],
        bottom: _isEmergencyMode ? null : TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Emergency'),
            Tab(text: 'Doctors'),
            Tab(text: 'Family'),
          ],
          labelStyle: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: AppTypography.labelMedium,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
        ),
      ),
      body: _isLoading 
          ? _buildLoadingState()
          : _isEmergencyMode 
              ? _buildEmergencyMode()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEmergencyTab(),
                    _buildDoctorsTab(),
                    _buildFamilyTab(),
                  ],
                ),
      floatingActionButton: _isEmergencyMode ? null : _buildSOSButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'Loading contacts...',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyMode() {
    final emergencyContacts = _contacts.where((c) => c.isEmergencyContact).toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        children: [
          // Emergency Header
          _buildEmergencyHeader(),
          
          const SizedBox(height: AppTheme.spacingL),
          
          // Current Vitals (if concerning)
          if (_currentVitals != null && _isVitalsOfConcern())
            _buildVitalsAlert(),
          
          const SizedBox(height: AppTheme.spacingL),
          
          // Emergency Contacts
          ...emergencyContacts.map((contact) => _buildEmergencyContactCard(contact)),
          
          const SizedBox(height: AppTheme.spacingXxl),
        ],
      ),
    );
  }

  Widget _buildEmergencyHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppColors.critical.withValues(alpha: 0.1),
        borderRadius: AppTheme.largeRadius,
        border: Border.all(
          color: AppColors.critical.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.emergency,
            size: 48,
            color: AppColors.critical,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'Emergency Mode',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.critical,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Quick access to emergency contacts and services. Your location and current vital signs will be shared automatically.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsAlert() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: AppTheme.mediumRadius,
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_rounded,
            color: AppColors.warning,
            size: 24,
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Health Alert',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _getVitalsAlertMessage(),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactCard(DoctorContact contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Card(
        elevation: 4,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.largeRadius,
          side: BorderSide(
            color: contact.type == ContactType.emergency 
                ? AppColors.critical.withValues(alpha: 0.3)
                : AppColors.primary.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: () => _makeEmergencyCall(contact),
          borderRadius: AppTheme.largeRadius,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Row(
              children: [
                // Contact Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: contact.type.color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    contact.type.icon,
                    color: contact.type.color,
                    size: 28,
                  ),
                ),
                
                const SizedBox(width: AppTheme.spacingM),
                
                // Contact Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.name,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        contact.specialization,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (contact.hospital != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          contact.hospital!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                      if (contact.type == ContactType.emergency) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.critical.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '24/7 Emergency',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.critical,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Call Button
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: contact.type == ContactType.emergency 
                        ? AppColors.critical 
                        : AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    PhosphorIcons.phone(),
                    color: AppColors.textInverse,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyTab() {
    final emergencyContacts = _contacts.where((c) => c.isEmergencyContact).toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emergency Info
          _buildEmergencyInfo(),
          
          const SizedBox(height: AppTheme.spacingL),
          
          // Emergency Contacts
          Text(
            'Emergency Contacts',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          
          ...emergencyContacts.map((contact) => _buildContactCard(contact)),
          
          const SizedBox(height: AppTheme.spacingXxl),
        ],
      ),
    );
  }

  Widget _buildDoctorsTab() {
    final doctors = _contacts.where((c) => 
        c.type == ContactType.obstetrician || 
        c.type == ContactType.midwife || 
        c.type == ContactType.nurse ||
        c.type == ContactType.generalDoctor ||
        c.type == ContactType.specialist
    ).toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Healthcare Providers',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          
          ...doctors.map((contact) => _buildContactCard(contact)),
          
          const SizedBox(height: AppTheme.spacingXxl),
        ],
      ),
    );
  }

  Widget _buildFamilyTab() {
    final familyContacts = _contacts.where((c) => 
        c.type == ContactType.familyMember || 
        c.type == ContactType.friend
    ).toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Family & Friends',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          
          ...familyContacts.map((contact) => _buildContactCard(contact)),
          
          const SizedBox(height: AppTheme.spacingXxl),
        ],
      ),
    );
  }

  Widget _buildEmergencyInfo() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: AppTheme.mediumRadius,
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                'Emergency Information',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'In case of emergency, these contacts will receive your current location and vital signs automatically.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(DoctorContact contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Card(
        elevation: 2,
        color: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppTheme.mediumRadius,
        ),
        child: InkWell(
          onTap: () => _showContactDetails(contact),
          borderRadius: AppTheme.mediumRadius,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              children: [
                // Contact Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: contact.type.color.withValues(alpha: 0.1),
                  child: Icon(
                    contact.type.icon,
                    color: contact.type.color,
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: AppTheme.spacingM),
                
                // Contact Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.name,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        contact.specialization,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (contact.isAvailable) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Available',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (contact.email != null)
                      IconButton(
                        icon: Icon(PhosphorIcons.envelope(), size: 20),
                        color: AppColors.textSecondary,
                        onPressed: () => _sendEmail(contact),
                      ),
                    IconButton(
                      icon: Icon(PhosphorIcons.phone(), size: 20),
                      color: AppColors.success,
                      onPressed: () => _makeCall(contact),
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

  Widget _buildSOSButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () => _triggerSOS(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.critical,
            foregroundColor: AppColors.textInverse,
            elevation: 8,
            shadowColor: AppColors.critical.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.emergency,
                size: 24,
              ),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                'EMERGENCY SOS',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textInverse,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods
  bool _isVitalsOfConcern() {
    if (_currentVitals == null) return false;
    
    // Check if any vitals are outside normal ranges
    final heartRate = _currentVitals!.heartRate ?? 0;
    final glucose = _currentVitals!.glucose ?? 0;
    final oxygen = _currentVitals!.oxygenSaturation ?? 0;
    
    return heartRate > 100 || glucose > 140 || oxygen < 95;
  }

  String _getVitalsAlertMessage() {
    if (_currentVitals == null) return 'Unable to retrieve current vitals';
    
    final concerns = <String>[];
    if ((_currentVitals!.heartRate ?? 0) > 100) concerns.add('elevated heart rate');
    if ((_currentVitals!.glucose ?? 0) > 140) concerns.add('high glucose level');
    if ((_currentVitals!.oxygenSaturation ?? 0) < 95) concerns.add('low oxygen saturation');
    
    return 'Detected ${concerns.join(', ')}. Consider contacting your healthcare provider.';
  }

  Future<void> _makeCall(DoctorContact contact) async {
    final uri = Uri.parse('tel:${contact.phoneNumber}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showError('Unable to make call to ${contact.name}');
    }
  }

  Future<void> _makeEmergencyCall(DoctorContact contact) async {
    // Show confirmation dialog for emergency calls
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Call'),
        content: Text('Call ${contact.name} immediately?\n\nYour current location and vital signs will be shared.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.critical,
            ),
            child: const Text('Call Now'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _makeCall(contact);
    }
  }

  Future<void> _sendEmail(DoctorContact contact) async {
    if (contact.email == null) return;
    
    final uri = Uri.parse('mailto:${contact.email}?subject=Health Consultation Request');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showError('Unable to send email to ${contact.name}');
    }
  }

  void _showContactDetails(DoctorContact contact) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildContactDetailsSheet(contact),
    );
  }

  Widget _buildContactDetailsSheet(DoctorContact contact) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppTheme.largeRadius,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: contact.type.color.withValues(alpha: 0.1),
                child: Icon(
                  contact.type.icon,
                  color: contact.type.color,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      contact.specialization,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingL),
          
          // Contact Details
          if (contact.hospital != null) ...[
            _buildDetailRow(Icons.local_hospital, 'Hospital', contact.hospital!),
          ],
          if (contact.rating != null) ...[
            _buildDetailRow(Icons.star, 'Rating', '${contact.rating}/5.0'),
          ],
          if (contact.yearsExperience != null) ...[
            _buildDetailRow(Icons.work, 'Experience', '${contact.yearsExperience} years'),
          ],
          if (contact.languages != null) ...[
            _buildDetailRow(Icons.language, 'Languages', contact.languages!.join(', ')),
          ],
          
          const SizedBox(height: AppTheme.spacingL),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _makeCall(contact),
                  icon: Icon(PhosphorIcons.phone()),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                ),
              ),
              if (contact.email != null) ...[
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _sendEmail(contact),
                    icon: Icon(PhosphorIcons.envelope()),
                    label: const Text('Email'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppTheme.spacingS),
          Text(
            '$label: ',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _triggerSOS() {
    // Show SOS confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emergency, color: AppColors.critical),
            SizedBox(width: AppTheme.spacingS),
            Text('Emergency SOS'),
          ],
        ),
        content: const Text(
          'This will immediately:\n\n'
          '• Call emergency services (999)\n'
          '• Send your location to emergency contacts\n'
          '• Share your current vital signs\n'
          '• Alert your healthcare provider\n\n'
          'Are you sure you want to continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _executeSOS();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.critical,
            ),
            child: const Text('ACTIVATE SOS'),
          ),
        ],
      ),
    );
  }

  void _executeSOS() {
    // Simulate SOS activation
    setState(() => _isEmergencyMode = true);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'SOS ACTIVATED - Emergency services contacted',
          style: TextStyle(color: AppColors.textInverse),
        ),
        backgroundColor: AppColors.critical,
        duration: Duration(seconds: 5),
      ),
    );

    // In a real app, this would:
    // - Get current location
    // - Call emergency services
    // - Send SMS to emergency contacts
    // - Upload current vitals to cloud
    // - Notify healthcare providers
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
} 