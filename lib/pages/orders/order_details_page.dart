import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:rahiq_driver/data/api/api_client.dart';
import 'package:rahiq_driver/data/api/driver/driver_orders_api.dart';
import 'package:rahiq_driver/data/models/driver/driver_order.dart';
import 'package:rahiq_driver/pages/shared/proof_submission_page.dart';
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
  List<String> _subOrders = [];
  bool _isMultiSelectMode = false;
  final Set<String> _selectedSubOrders = {};

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
                        if (_isMultiSelectMode && _selectedSubOrders.isNotEmpty)
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProofSubmissionPage(
                                      isAutoOrder: false,
                                      orderId: widget.order.id,
                                      subOrders: _selectedSubOrders.toList(),
                                      singleCustomerData: null,
                                    ),
                                  ),
                                ).then((_) {
                                  // Clear multiselect state when returning
                                  setState(() {
                                    _isMultiSelectMode = false;
                                    _selectedSubOrders.clear();
                                  });
                                });
                              },
                              icon: const Icon(Icons.upload_file),
                              label: Text(
                                _selectedSubOrders.length == 1
                                    ? AppLocalizations.of(
                                        context,
                                      )!.completeOrder
                                    : AppLocalizations.of(
                                        context,
                                      )!.completeSelectedOrders,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.buttonBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.subOrdersLabel,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.buttonBlue,
                  ),
                ),
                if (_isMultiSelectMode)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isMultiSelectMode = false;
                        _selectedSubOrders.clear();
                      });
                    },
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),
              ],
            ),
            const Divider(),
            ..._subOrders.map((subId) {
              final isSelected = _selectedSubOrders.contains(subId);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onLongPress: () {
                  if (_subOrders.length > 1) {
                    setState(() {
                      _isMultiSelectMode = true;
                      _selectedSubOrders.add(subId);
                    });
                  }
                },
                onTap: () {
                  if (_isMultiSelectMode) {
                    setState(() {
                      if (isSelected) {
                        _selectedSubOrders.remove(subId);
                        if (_selectedSubOrders.isEmpty) {
                          _isMultiSelectMode = false;
                        }
                      } else {
                        _selectedSubOrders.add(subId);
                      }
                    });
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProofSubmissionPage(
                          isAutoOrder: false,
                          orderId: widget.order.id,
                          subOrders: [subId],
                          singleCustomerData: {
                            'firstName': widget.order.customerName,
                            'lastName': '',
                            'phoneNumber': widget.order.customerPhone,
                            'address': widget.order.deliveryAddress,
                          },
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: AppColors.buttonBlue, width: 2)
                        : Border.all(color: Colors.transparent, width: 2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          subId,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      if (!_isMultiSelectMode)
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey,
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
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
