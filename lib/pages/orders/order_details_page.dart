import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:rahiq_driver/data/api/api_client.dart';
import 'package:rahiq_driver/data/api/driver/driver_orders_api.dart';
import 'package:rahiq_driver/data/models/driver/driver_order.dart';
import 'package:rahiq_driver/pages/orders/normal_sub_order_details_page.dart';
import 'package:rahiq_driver/utils/colors.dart';
import 'package:rahiq_driver/l10n/app_localizations.dart';

class OrderDetailsPage extends StatefulWidget {
  final DriverOrder order;

  const OrderDetailsPage({super.key, required this.order});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  late DriverOrdersApi _api;
  bool _isLoading = true;
  String? _error;
  List<dynamic> _subOrders = [];

  @override
  void initState() {
    super.initState();
    _api = DriverOrdersApi(ApiClient());
    _fetchSubOrders();
  }

  Future<void> _fetchSubOrders() async {
    try {
      final response = await _api.getNormalOrderSubOrders(widget.order.id);
      setState(() {
        _subOrders = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(
            context,
          )!.orderNumber(widget.order.id.split('-').first.toUpperCase()),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((widget.order.latitude ?? 0.0) != 0.0 &&
                      (widget.order.longitude ?? 0.0) != 0.0)
                    _buildMapArea(
                      context,
                      widget.order.latitude ?? 0.0,
                      widget.order.longitude ?? 0.0,
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_error != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            color: Colors.red.withOpacity(0.1),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        _buildInfoCard(context),
                        const SizedBox(height: 16),
                        if (_subOrders.isNotEmpty) _buildSubOrdersSection(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMapArea(BuildContext context, double lat, double lng) {
    final height = MediaQuery.of(context).size.height * 0.65;
    final target = LatLng(lat, lng);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: target, zoom: 15),
            markers: {
              Marker(markerId: const MarkerId('destination'), position: target),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
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
              label: Text(
                AppLocalizations.of(context)?.getDirections ?? 'Get Directions',
              ),
              backgroundColor: AppColors.buttonBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.orderInfo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.buttonBlue,
              ),
            ),
            const Divider(),
            _buildDetailRow(
              Icons.info,
              AppLocalizations.of(context)!.status,
              widget.order.status ?? 'N/A',
            ),
            _buildDetailRow(
              Icons.payment,
              AppLocalizations.of(context)!.paymentLabel,
              widget.order.paymentMethod ?? 'N/A',
            ),
            if (widget.order.totalAmount != null)
              _buildDetailRow(
                Icons.monetization_on,
                AppLocalizations.of(context)!.totalLabel,
                '\$${widget.order.totalAmount}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            AppLocalizations.of(context)!.subOrdersLabel,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        ..._subOrders.map((subOrder) {
          final product = subOrder['product'] ?? {};
          final subId = subOrder['id']?.toString() ?? '';

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NormalSubOrderDetailsPage(
                    order: widget.order,
                    subOrder: subOrder,
                  ),
                ),
              ).then((shouldRefresh) {
                if (shouldRefresh == true) {
                  _fetchSubOrders();
                }
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.transparent, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.subOrderNumber(
                            subOrder['subOrderNumber']?.toString() ??
                                (subId.length > 8 ? subId.substring(0, 8) : subId),
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.buttonBlueDark,
                          ),
                        ),
                        const Divider(),
                        if (subOrder['deliveryNotes'] != null &&
                            subOrder['deliveryNotes'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.note_alt_outlined,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)!.notes(
                                      subOrder['deliveryNotes'].toString(),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (subOrder['assignedDate'] != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context)!.assigned(
                                    _formatDate(subOrder['assignedDate']),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            if (product['image'] != null &&
                                product['image'].toString().isNotEmpty)
                              Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey.withValues(alpha: 0.1),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image.network(
                                  product['image'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.inventory_2_outlined,
                                        color: Colors.grey,
                                      ),
                                ),
                              )
                            else
                              Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey.withValues(alpha: 0.1),
                                ),
                                child: const Icon(
                                  Icons.inventory_2_outlined,
                                  color: Colors.grey,
                                ),
                              ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product['name'] ??
                                        AppLocalizations.of(context)!.product,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    AppLocalizations.of(context)!.qty(
                                      subOrder['quantity']?.toString() ?? '1',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.buttonBlueDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr.toString()).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr.toString().length > 10
          ? dateStr.toString().substring(0, 10)
          : dateStr.toString();
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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
