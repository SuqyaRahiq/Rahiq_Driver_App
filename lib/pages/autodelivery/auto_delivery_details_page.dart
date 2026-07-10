import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:rahiq_driver/data/models/driver/driver_auto_delivery.dart';
import 'package:rahiq_driver/pages/shared/proof_submission_page.dart';
import 'package:rahiq_driver/utils/colors.dart';
import 'package:rahiq_driver/l10n/app_localizations.dart';

class AutoDeliveryDetailsPage extends StatelessWidget {
  final DriverAutoDelivery item;

  const AutoDeliveryDetailsPage({super.key, required this.item});

  double _getLatitude() {
    return item.deliveryLocation?.mosque?.latitude ?? 0.0;
  }

  double _getLongitude() {
    return item.deliveryLocation?.mosque?.longitude ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final lat = _getLatitude();
    final lng = _getLongitude();
    final hasLocation = lat != 0.0 && lng != 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
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
                                    AppLocalizations.of(context)!.orderDetails,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.viewAndManageAssignedOrders,
                                    style: const TextStyle(
                                      fontSize: 12,
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
            Container(
              decoration: const BoxDecoration(color: AppColors.buttonBlueDark),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 120,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasLocation) _buildMapArea(context, lat, lng),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoCard(context),
                          const SizedBox(height: 24),
                          // Confirm order button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProofSubmissionPage(
                                      orderId: item.id,
                                      isAutoOrder: false,
                                      isAutoDelivery: true,
                                      subOrders: const [],
                                    ),
                                  ),
                                ).then((_) => Navigator.pop(context, true));
                              },
                              icon: const Icon(
                                Icons.check_circle_outline,
                                size: 20,
                              ),
                              label: Text(
                                AppLocalizations.of(context)!.completeOrder,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.buttonBlueDark,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapArea(BuildContext context, double lat, double lng) {
    final height = MediaQuery.of(context).size.height * 0.4;
    final target = LatLng(lat, lng);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: target, zoom: 15),
              markers: {
                Marker(
                  markerId: const MarkerId('destination'),
                  position: target,
                ),
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
          ),
          PositionedDirectional(
            bottom: 16,
            end: 16,
            child: FloatingActionButton.extended(
              onPressed: () async {
                final url =
                    'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  );
                }
              },
              icon: const Icon(Icons.directions),
              label: Text(AppLocalizations.of(context)!.getDirections),
              backgroundColor: AppColors.buttonBlueDark,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final campaignName = isArabic
        ? (item.deliveryLocation?.campaign?.titleAr ??
              item.deliveryLocation?.campaign?.title)
        : item.deliveryLocation?.campaign?.title;
    final cityName = isArabic
        ? (item.deliveryLocation?.city?.nameAr ??
              item.deliveryLocation?.city?.name)
        : item.deliveryLocation?.city?.name;
    final mosqueName = isArabic
        ? (item.deliveryLocation?.mosque?.nameAr ??
              item.deliveryLocation?.mosque?.name)
        : item.deliveryLocation?.mosque?.name;
    final address = item.deliveryLocation?.mosque?.address;
    final productName = isArabic
        ? (item.product?.nameAr ?? item.product?.name)
        : item.product?.name;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEFF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.orderInfo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFEAEFF2)),
            ),

            if (mosqueName != null)
              _buildDetailRow(
                Icons.mosque_outlined,
                AppLocalizations.of(context)!.locationLabel,
                mosqueName,
              ),
            if (campaignName != null)
              _buildDetailRow(
                Icons.campaign_outlined,
                AppLocalizations.of(context)!.typeCampaign,
                campaignName,
              ),
            if (cityName != null)
              _buildDetailRow(
                Icons.location_city_outlined,
                AppLocalizations.of(context)!.cityLabel,
                cityName,
              ),
            if (productName != null)
              _buildDetailRow(
                Icons.inventory_2_outlined,
                AppLocalizations.of(context)!.product,
                productName,
              ),

            if (item.quantity != null)
              _buildDetailRow(
                Icons.format_list_numbered,
                AppLocalizations.of(context)!.totalPackagesLabel,
                item.quantity.toString(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
