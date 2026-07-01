import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:rahiq_driver/data/models/driver/product.dart';
import 'package:rahiq_driver/l10n/app_localizations.dart';
import 'package:rahiq_driver/utils/shimmer_loading.dart';
import 'package:rahiq_driver/data/api/api_client.dart';
import 'package:rahiq_driver/data/api/driver/driver_auth_api.dart';
import 'package:rahiq_driver/data/models/driver/driver_profile.dart';
import 'package:rahiq_driver/data/storage/auth_storage.dart';
import 'package:rahiq_driver/utils/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class MyAccountPage extends StatefulWidget {
  const MyAccountPage({super.key});

  @override
  State<MyAccountPage> createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {
  DriverProfile? _profile;
  bool _isLoading = true;
  String? _error;
  bool _isEditingBankDetails = false;
  bool _isSavingBankDetails = false;
  final _bankFormKey = GlobalKey<FormState>();
  final _bankFullNameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankAccountNumberController = TextEditingController();
  final _bankIbanNumberController = TextEditingController();

  @override
  void dispose() {
    _bankFullNameController.dispose();
    _bankNameController.dispose();
    _bankAccountNumberController.dispose();
    _bankIbanNumberController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final cachedData = AuthStorage.getUserData();
      if (cachedData != null) {
        setState(() {
          _profile = DriverProfile.fromJson(
            Map<String, dynamic>.from(cachedData),
          );
          _isLoading = false;
          _error = null;
        });
      } else {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }
      final api = DriverAuthApi(ApiClient());
      final profile = await api.getProfile();

      await AuthStorage.saveUserData(profile.toJson());

      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Only show error if we don't have cached data
      if (_profile == null && mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
          ? _buildFullPageError()
          : SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  // ── Header (scrolls with the page) ────────────────────
                  Container(
                    width: double.infinity,
                    color: AppColors.buttonBlueDark,
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              16,
                              16,
                              16,
                              12,
                            ),
                            child: Center(
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.myAccount,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.yourPersonalInformation,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 38),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // ── Rounded white body ─────────────────────────────────
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.buttonBlueDark,
                    ),
                    child: Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height - 160,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: _buildProfileContent(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.buttonBlueDark,
            padding: const EdgeInsetsDirectional.fromSTEB(16, 60, 16, 20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.myAccount,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context)!.yourPersonalInformation,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 38),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(color: AppColors.buttonBlueDark),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.only(top: 24.0),
                  child: FullPageShimmerLoader(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    final p = _profile!;

    bool hasBankDetails =
        (p.bankAccountNumber != null && p.bankAccountNumber!.isNotEmpty) ||
        (p.bankFullName != null && p.bankFullName!.isNotEmpty) ||
        (p.bankIbanNumber != null && p.bankIbanNumber!.isNotEmpty) ||
        (p.bankName != null && p.bankName!.isNotEmpty);

    // Show blocked screen if driver account is inactive
    if (p.isActive == false) {
      return _buildBlockedScreen(p);
    }

    final fullName = '${p.firstName} ${p.lastName}'.trim();
    final initials = _initials(p.firstName, p.lastName);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 60),
      child: Column(
        children: [
          // ── Avatar + name ────────────────────────────────────────────
          _buildAvatarSection(p, fullName, initials),

          const SizedBox(height: 32),

          // ── Personal info card ───────────────────────────────────────
          _buildInfoCard(
            title: AppLocalizations.of(context)!.personalInformation,
            icon: Icons.person_outline_rounded,
            fields: [
              _FieldData(
                label: AppLocalizations.of(context)!.firstName,
                value: p.firstName,
                icon: Icons.badge_outlined,
              ),
              _FieldData(
                label: AppLocalizations.of(context)!.lastName,
                value: p.lastName,
                icon: Icons.badge_outlined,
              ),

              _FieldData(
                label: AppLocalizations.of(context)!.phoneNumber,
                value: '${p.countryCode} ${p.phoneNumber}',
                icon: Icons.phone_rounded,
                forceLtr: true,
              ),
              if (p.type != null && p.type!.isNotEmpty)
                _FieldData(
                  label: AppLocalizations.of(context)!.driverType,
                  value: _capitalize(p.type!),
                  icon: Icons.local_shipping_rounded,
                ),
              if (p.supplier != null) ...[
                _FieldData(
                  label: AppLocalizations.of(context)!.supplier,
                  value: p.supplier!.name,
                  icon: Icons.business_outlined,
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          if (p.vehicle != null) ...[
            const SizedBox(height: 16),
            _buildInfoCard(
              title: AppLocalizations.of(context)!.vehicleDetails,
              icon: Icons.directions_car_outlined,
              fields: [
                _FieldData(
                  label: AppLocalizations.of(context)!.vehicleName,
                  value: p.vehicle!.name,
                  icon: Icons.local_shipping_outlined,
                ),
                _FieldData(
                  label: AppLocalizations.of(context)!.capacity,
                  value: p.vehicle!.capacity.toString(),
                  icon: Icons.inventory_2_outlined,
                  forceLtr: true,
                ),
              ],
            ),
          ],

          if (p.product != null) ...[
            const SizedBox(height: 16),
            _buildProductCard(p.product!),
          ],

          const SizedBox(height: 16),
          _buildBankDetailsCard(p, hasBankDetails),

          if (p.createdAt != null) ...[
            const SizedBox(height: 16),
            _buildInfoCard(
              title: AppLocalizations.of(context)!.accountHistory,
              icon: Icons.history_rounded,
              fields: [
                _FieldData(
                  label: AppLocalizations.of(context)!.memberSince,
                  value: _formatDate(p.createdAt!),
                  icon: Icons.calendar_today_rounded,
                ),
                if (p.updatedAt != null)
                  _FieldData(
                    label: AppLocalizations.of(context)!.lastUpdated,
                    value: _formatDate(p.updatedAt!),
                    icon: Icons.update_rounded,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBlockedScreen(DriverProfile p) {
    final fullName = '${p.firstName} ${p.lastName}'.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 60),
      child: Column(
        children: [
          // ── Blocked icon ─────────────────────────────────────────────
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withValues(alpha: 0.08),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withValues(alpha: 0.12),
                  ),
                ),
                const Icon(
                  Icons.block_rounded,
                  size: 44,
                  color: Colors.redAccent,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Heading ──────────────────────────────────────────────────
          Text(
            AppLocalizations.of(context)!.accountBlocked,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 12),

          // ── Driver name badge ─────────────────────────────────────────
          if (fullName.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.buttonBlueDark.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                fullName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.buttonBlueDark,
                ),
              ),
            ),

          const SizedBox(height: 20),

          // ── Description ───────────────────────────────────────────────
          Text(
            AppLocalizations.of(context)!.accountSuspendedMessage,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black45),
          ),

          const SizedBox(height: 36),

          // ── Divider with label ────────────────────────────────────────
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade200)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  AppLocalizations.of(context)!.needHelp,
                  style: TextStyle(fontSize: 12, color: Colors.black38),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade200)),
            ],
          ),

          const SizedBox(height: 24),

          // ── Contact our team button ───────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _contactSupport,
              icon: const Icon(Icons.support_agent_rounded, size: 20),
              label: Text(
                AppLocalizations.of(context)!.contactOurTeam,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonBlueDark,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Secondary: go back ────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.goBack,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _contactSupport() async {
    // Try email first, then fallback to a dialog
    final emailUri = Uri(
      scheme: 'mailto',
      path: 'info@suqyarahiq.com',
      queryParameters: {
        'subject': 'Account Blocked - Driver App',
        'body':
            'Hello Rahiq Support Team,\n\nMy driver account has been blocked. Please help me restore access.\n\nThank you.',
      },
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.support_agent_rounded,
                  color: AppColors.buttonBlueDark,
                ),
                SizedBox(width: 10),
                Text(AppLocalizations.of(context)!.contactSupport),
              ],
            ),
            content: Text(
              AppLocalizations.of(context)!.contactSupportMessage,
              style: TextStyle(fontSize: 14, height: 1.6),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.close),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _buildAvatarSection(
    DriverProfile p,
    String fullName,
    String initials,
  ) {
    return Column(
      children: [
        // Avatar
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A6A8F), Color(0xFF48B3D2)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.buttonBlueDark.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: p.avatarUrl != null && p.avatarUrl!.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    p.avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 14),
        Text(
          fullName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        // Active badge
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: (p.isActive ?? false)
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: (p.isActive ?? false)
                      ? Colors.green
                      : Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                (p.isActive ?? false)
                    ? AppLocalizations.of(context)!.active
                    : AppLocalizations.of(context)!.inactive,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: (p.isActive ?? false)
                      ? Colors.green
                      : Colors.redAccent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<_FieldData> fields,
    Widget? trailing,
    Widget? emptyState,
  }) {
    if (fields.isEmpty && emptyState == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.buttonBlueDark.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.buttonBlueDark, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEF1F4)),
          if (fields.isEmpty && emptyState != null)
            emptyState
          else
            // Fields
            ...fields.asMap().entries.map((entry) {
              final isLast = entry.key == fields.length - 1;
              return Column(
                children: [
                  _buildFieldRow(entry.value),
                  if (!isLast)
                    const Divider(
                      height: 1,
                      color: Color(0xFFEEF1F4),
                      indent: 20,
                      endIndent: 20,
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildFieldRow(_FieldData field) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Icon(field.icon, size: 16, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.black38,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  width: double.infinity,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    field.value,
                    textDirection: field.forceLtr ? TextDirection.ltr : null,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: field.valueColor ?? Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankDetailsCard(DriverProfile p, bool hasBankDetails) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.buttonBlueDark.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.account_balance_outlined,
                    color: AppColors.buttonBlueDark,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.bankAccountDetails,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    if (_isSavingBankDetails) return;
                    if (_isEditingBankDetails) {
                      if (_bankFormKey.currentState!.validate()) {
                        setState(() => _isSavingBankDetails = true);
                        try {
                          final api = DriverAuthApi(ApiClient());
                          final profile = await api.updateBankAccount({
                            "bankFullName": _bankFullNameController.text.trim(),
                            "bankName": _bankNameController.text.trim(),
                            "bankAccountNumber": _bankAccountNumberController
                                .text
                                .trim(),
                            "bankIbanNumber": _bankIbanNumberController.text
                                .trim(),
                          });
                          await AuthStorage.saveUserData(profile.toJson());
                          if (mounted) {
                            setState(() {
                              _profile = profile;
                              _isEditingBankDetails = false;
                              _isSavingBankDetails = false;
                            });
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() => _isSavingBankDetails = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        }
                      }
                    } else {
                      setState(() {
                        _isEditingBankDetails = true;
                        _bankFullNameController.text = p.bankFullName ?? '';
                        _bankNameController.text = p.bankName ?? '';
                        _bankAccountNumberController.text =
                            p.bankAccountNumber ?? '';
                        _bankIbanNumberController.text = p.bankIbanNumber ?? '';
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.buttonBlueDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _isSavingBankDetails
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _isEditingBankDetails
                                ? AppLocalizations.of(context)!.save
                                : (hasBankDetails ? AppLocalizations.of(context)!.edit : AppLocalizations.of(context)!.add),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEF1F4)),
          if (_isEditingBankDetails)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _bankFormKey,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _bankFullNameController,
                      label: AppLocalizations.of(context)!.bankFullName,
                      icon: Icons.person_outline,
                      enabled: !_isSavingBankDetails,
                      validator: (value) => value == null || value.isEmpty
                          ? AppLocalizations.of(context)!.requiredField
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _bankNameController,
                      label: AppLocalizations.of(context)!.bankName,
                      icon: Icons.account_balance,
                      enabled: !_isSavingBankDetails,
                      validator: (value) => value == null || value.isEmpty
                          ? AppLocalizations.of(context)!.requiredField
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _bankAccountNumberController,
                      label: AppLocalizations.of(context)!.bankAccountNumber,
                      icon: Icons.numbers_outlined,
                      isLtr: true,
                      enabled: !_isSavingBankDetails,
                      validator: (value) => value == null || value.isEmpty
                          ? AppLocalizations.of(context)!.requiredField
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _bankIbanNumberController,
                      label: AppLocalizations.of(context)!.bankIbanNumber,
                      icon: Icons.credit_card_outlined,
                      isLtr: true,
                      enabled: !_isSavingBankDetails,
                      validator: (value) => value == null || value.isEmpty
                          ? AppLocalizations.of(context)!.requiredField
                          : null,
                    ),
                  ],
                ),
              ),
            )
          else if (!hasBankDetails)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  AppLocalizations.of(context)!.noBankDetails,
                  style: const TextStyle(fontSize: 14, color: Colors.black45),
                ),
              ),
            )
          else
            Builder(
              builder: (context) {
                final fields = <_FieldData>[];
                if (p.bankFullName != null && p.bankFullName!.isNotEmpty) {
                  fields.add(
                    _FieldData(
                      label: AppLocalizations.of(context)!.bankFullName,
                      value: p.bankFullName!,
                      icon: Icons.person_outline,
                    ),
                  );
                }
                if (p.bankName != null && p.bankName!.isNotEmpty) {
                  fields.add(
                    _FieldData(
                      label: AppLocalizations.of(context)!.bankName,
                      value: p.bankName!,
                      icon: Icons.account_balance,
                    ),
                  );
                }
                if (p.bankAccountNumber != null &&
                    p.bankAccountNumber!.isNotEmpty) {
                  fields.add(
                    _FieldData(
                      label: AppLocalizations.of(context)!.bankAccountNumber,
                      value: p.bankAccountNumber!,
                      icon: Icons.numbers_outlined,
                      forceLtr: true,
                    ),
                  );
                }
                if (p.bankIbanNumber != null && p.bankIbanNumber!.isNotEmpty) {
                  fields.add(
                    _FieldData(
                      label: AppLocalizations.of(context)!.bankIbanNumber,
                      value: p.bankIbanNumber!,
                      icon: Icons.credit_card_outlined,
                      forceLtr: true,
                    ),
                  );
                }

                return Column(
                  children: fields.asMap().entries.map((entry) {
                    final isLast = entry.key == fields.length - 1;
                    return Column(
                      children: [
                        _buildFieldRow(entry.value),
                        if (!isLast)
                          const Divider(
                            height: 1,
                            color: Color(0xFFEEF1F4),
                            indent: 20,
                            endIndent: 20,
                          ),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.buttonBlueDark.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.water_drop_outlined,
                    color: AppColors.buttonBlueDark,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.productDetails,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEF1F4)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (product.image != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      product.image!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey.shade100,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.product,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.black38,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Directionality.of(context) == TextDirection.ltr
                            ? product.name
                            : product.nameAr ?? product.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isLtr = false,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      cursorColor: AppColors.buttonBlueDark,
      textDirection: isLtr ? TextDirection.ltr : null,
      decoration: InputDecoration(
        labelText: label,

        labelStyle: TextStyle(color: AppColors.buttonBlueDark),
        prefixIcon: Icon(icon, size: 20, color: AppColors.buttonBlueDark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.buttonBlueDark),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildFullPageError() {
    log(_error.toString());
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.buttonBlueDark,
            padding: const EdgeInsetsDirectional.fromSTEB(16, 60, 16, 20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.myAccount,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context)!.yourPersonalInformation,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 38),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(color: AppColors.buttonBlueDark),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.error_outline_rounded,
                            size: 40,
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error ??
                              AppLocalizations.of(context)!.somethingWentWrong,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _fetchProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonBlueDark,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                          ),
                          child: Text(AppLocalizations.of(context)!.tryAgain),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String first, String last) {
    final f = first.isNotEmpty ? first[0].toUpperCase() : '';
    final l = last.isNotEmpty ? last[0].toUpperCase() : '';
    return '$f$l';
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  String _formatDate(DateTime dt) {
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat.yMMMd(locale).format(dt);
  }
}

class _FieldData {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  final bool forceLtr;

  _FieldData({
    required this.label,
    required this.value,
    required this.icon,
    this.forceLtr = false,
  }) : valueColor = null;
}
