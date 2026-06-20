import 'package:flutter/material.dart';
import 'package:rahiq_driver/l10n/app_localizations.dart';
import 'package:rahiq_driver/utils/colors.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                // ── Header ──────────────────────────
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
                            0,
                            16,
                            12,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.dashboard,
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
                                  )!.welcomeToTheDriverDashboard,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // ── Rounded white body ────────────────────────────────────
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
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),

                          // ── Dummy Stats ───────────────────────────────
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  title: l10n.orders,
                                  value: "24",
                                  icon: Icons.list_alt,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildStatCard(
                                  title: l10n.autoOrders,
                                  value: "12",
                                  icon: Icons.autorenew,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  title: l10n.pending,
                                  value: "5",
                                  icon: Icons.pending_actions,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildStatCard(
                                  title: l10n.delivered,
                                  value: "84",
                                  icon: Icons.check_circle_outline,
                                  color: AppColors.buttonBlueDark,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 150,
                          ), // bottom padding for nav bar
                        ],
                      ),
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

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEFF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
