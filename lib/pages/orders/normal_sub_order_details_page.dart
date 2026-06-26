import 'package:flutter/material.dart';
import 'package:rahiq_driver/data/models/driver/driver_order.dart';
import 'package:rahiq_driver/pages/shared/proof_submission_page.dart';
import 'package:rahiq_driver/utils/colors.dart';
import 'package:rahiq_driver/l10n/app_localizations.dart';

class NormalSubOrderDetailsPage extends StatelessWidget {
  final DriverOrder order;
  final dynamic subOrder;

  const NormalSubOrderDetailsPage({
    super.key,
    required this.order,
    required this.subOrder,
  });

  @override
  Widget build(BuildContext context) {
    final subId = subOrder['id']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.subOrderNumber(
            subOrder['subOrderNumber']?.toString() ??
                subId.substring(0, subId.length > 8 ? 8 : subId.length),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(context),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final customer = subOrder['customerDetails'] ?? {};
                        final address =
                            subOrder['deliveryAddress'] ??
                            customer['address'] ??
                            order.deliveryAddress;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProofSubmissionPage(
                              isAutoOrder: false,
                              orderId: order.id,
                              subOrders: [subId],
                              singleCustomerData: {
                                'firstName':
                                    customer['firstName'] ?? order.customerName,
                                'lastName': customer['lastName'] ?? '',
                                'phoneNumber':
                                    customer['phoneNumber'] ??
                                    order.customerPhone,
                                'address': address,
                              },
                              initialMosqueFrontImage:
                                  subOrder['mosqueFrontImage'],
                              initialMosqueInsideImage:
                                  subOrder['mosqueInsideImage'],
                            ),
                          ),
                        ).then((_) {
                          Navigator.pop(context, true);
                        });
                      },
                      icon: const Icon(Icons.upload_file),
                      label: Text(
                        AppLocalizations.of(
                          context,
                        )!.uploadMediaToSupportDeliveryCompletion,
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
              subOrder['status']?.toString() ?? order.status ?? 'N/A',
            ),
            if (subOrder['numberOfSubOrders'] != null)
              _buildDetailRow(
                Icons.format_list_numbered,
                AppLocalizations.of(context)!.subOrdersLabel,
                subOrder['numberOfSubOrders'].toString(),
              ),
            _buildDetailRow(
              Icons.payment,
              AppLocalizations.of(context)!.paymentLabel,
              subOrder['paymentMethod']?.toString() ??
                  order.paymentMethod ??
                  'N/A',
            ),
            if (order.totalAmount != null)
              _buildDetailRow(
                Icons.monetization_on,
                AppLocalizations.of(context)!.totalLabel,
                '\$${order.totalAmount}',
              ),
            if (subOrder['deliveryNotes'] != null &&
                subOrder['deliveryNotes'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note_alt, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(
                          context,
                        )!.notes(subOrder['deliveryNotes'].toString()),
                        style: const TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.black87,
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
