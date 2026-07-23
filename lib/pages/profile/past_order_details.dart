import 'package:flutter/material.dart';
import 'package:rahiq_driver/data/models/driver/driver_profile.dart';
import 'package:rahiq_driver/data/models/driver/normal_sub_order.dart';
import 'package:rahiq_driver/data/storage/auth_storage.dart';
import 'package:rahiq_driver/l10n/app_localizations.dart';
import 'package:rahiq_driver/utils/colors.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:video_player/video_player.dart';

class PastOrderDetailsPage extends StatefulWidget {
  final NormalSubOrder order;

  const PastOrderDetailsPage({super.key, required this.order});

  @override
  State<PastOrderDetailsPage> createState() => _PastOrderDetailsPageState();
}

class _PastOrderDetailsPageState extends State<PastOrderDetailsPage> {
  DriverProfile? driver;
  @override
  void initState() {
    driver = AuthStorage.getUserData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final bool isAr = Directionality.of(context) == TextDirection.rtl;
    final order = widget.order;

    final String locationName = isAr
        ? (order.location?['nameAr'] ?? order.location?['name'] ?? '')
        : (order.location?['name'] ?? '');

    final String cityName = isAr
        ? (order.city?['nameAr'] ?? order.city?['name'] ?? '')
        : (order.city?['name'] ?? '');

    final String customerName = [
      order.customerDetails?.firstName,
      order.customerDetails?.lastName,
    ].where((e) => e != null && e.isNotEmpty).join(' ').trim();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.orderDetails,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 38),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── Rounded body ───────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                Container(height: 50, color: AppColors.buttonBlueDark),
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSection(
                            title: isAr ? 'معلومات المنتج' : 'Product Info',
                            child: Row(
                              children: [
                                if (order.product?.image != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: order.product!.image!,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          Shimmer.fromColors(
                                            baseColor: Colors.grey[300]!,
                                            highlightColor: Colors.grey[100]!,
                                            child: Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.white,
                                            ),
                                          ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                            width: 80,
                                            height: 80,
                                            color: Colors.grey[200],
                                            child: const Icon(
                                              Icons.image_not_supported,
                                              color: Colors.grey,
                                            ),
                                          ),
                                    ),
                                  ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isAr
                                            ? (order.product?.nameAr ??
                                                  order.product?.name ??
                                                  '')
                                            : (order.product?.name ?? ''),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${isAr ? 'الكمية' : 'Quantity'}: ${order.quantity ?? 0}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (customerName.isNotEmpty ||
                              order.customerDetails?.phoneNumber != null &&
                                  driver?.canViewContact == true)
                            _buildSection(
                              title: isAr
                                  ? 'تفاصيل العميل'
                                  : 'Customer Details',
                              child: Column(
                                children: [
                                  if (customerName.isNotEmpty)
                                    _buildDetailRow(
                                      isPhoneNumber: false,
                                      title: isAr ? 'الاسم' : 'Name',
                                      value: customerName,
                                    ),
                                  if (order.customerDetails?.phoneNumber !=
                                      null)
                                    _buildDetailRow(
                                      isPhoneNumber: true,
                                      title: isAr ? 'رقم الهاتف' : 'Phone',
                                      value:
                                          '${order.customerDetails?.countryCode ?? ''}${order.customerDetails!.phoneNumber}',
                                    ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),
                          if (locationName.isNotEmpty || cityName.isNotEmpty)
                            _buildSection(
                              title: isAr ? 'الموقع' : 'Location',
                              child: Column(
                                children: [
                                  if (locationName.isNotEmpty)
                                    _buildDetailRow(
                                      isPhoneNumber: false,
                                      title: isAr ? 'الاسم' : 'Name',
                                      value: locationName,
                                    ),
                                  if (cityName.isNotEmpty)
                                    _buildDetailRow(
                                      isPhoneNumber: false,
                                      title: isAr ? 'المدينة' : 'City',
                                      value: cityName,
                                    ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),
                          _buildSection(
                            title: isAr ? 'الجدول الزمني' : 'Timeline',
                            child: Column(
                              children: [
                                if (order.assignedDate != null)
                                  _buildDetailRow(
                                    isPhoneNumber: false,
                                    title: isAr
                                        ? 'تاريخ التعيين'
                                        : 'Assigned Date',
                                    value: _formatDate(
                                      order.assignedDate!,
                                      context,
                                    ),
                                  ),
                                if (order.deliveredAt != null)
                                  _buildDetailRow(
                                    isPhoneNumber: false,
                                    title: isAr
                                        ? 'تاريخ التوصيل'
                                        : 'Delivered At',
                                    value: _formatDate(
                                      order.deliveredAt!,
                                      context,
                                    ),
                                  ),
                                _buildDetailRow(
                                  isPhoneNumber: false,
                                  title: isAr ? 'الحالة' : 'Status',
                                  value: _getLocalizedStatus(
                                    context,
                                    order.status ?? ' ',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDeliveryProofs(isAr),
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

  String _getLocalizedStatus(BuildContext context, String? status) {
    final stat = status!.toLowerCase();
    if (stat == "confirmed") {
      return AppLocalizations.of(context)!.confirmedStat;
    } else if (stat == "delivered") {
      return AppLocalizations.of(context)!.delivered;
    } else {
      return status;
    }
  }

  String _formatDate(String isoDate, BuildContext context) {
    final date = DateTime.tryParse(isoDate)?.toLocal();
    if (date == null) return isoDate;
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat('MMM d, yyyy - h:mm a', locale).format(date);
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.buttonBlueDark,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required String title,
    required String value,
    required bool isPhoneNumber,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          isPhoneNumber
              ? Text(
                  textDirection: TextDirection.ltr,
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.end,
                )
              : Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.end,
                ),
        ],
      ),
    );
  }

  Widget _buildDeliveryProofs(bool isAr) {
    final order = widget.order;
    List<Widget> proofItems = [];

    if (order.mosqueFrontImage != null && order.mosqueFrontImage!.isNotEmpty) {
      proofItems.add(
        _buildSmallProofCard(
          isAr ? 'صورة الواجهة' : 'Front Image',
          order.mosqueFrontImage!,
          false,
        ),
      );
    }
    if (order.mosqueInsideImage != null &&
        order.mosqueInsideImage!.isNotEmpty) {
      proofItems.add(
        _buildSmallProofCard(
          isAr ? 'صورة من الداخل' : 'Inside Image',
          order.mosqueInsideImage!,
          false,
        ),
      );
    }
    if (order.packagesImage != null && order.packagesImage!.isNotEmpty) {
      proofItems.add(
        _buildSmallProofCard(
          isAr ? 'صورة الطرود' : 'Packages Image',
          order.packagesImage!,
          false,
        ),
      );
    }
    if (order.deliveryVideo != null && order.deliveryVideo!.isNotEmpty) {
      proofItems.add(
        _buildSmallProofCard(
          isAr ? 'فيديو التوصيل' : 'Delivery Video',
          order.deliveryVideo!,
          true,
        ),
      );
    }

    if (proofItems.isEmpty) return const SizedBox.shrink();

    return _buildSection(
      title: isAr ? 'إثبات التسليم' : 'Proof of Delivery',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(7, (index) {
          if (index.isOdd) {
            return const SizedBox(width: 8.0);
          }
          int itemIndex = index ~/ 2;
          if (itemIndex < proofItems.length) {
            return Expanded(child: proofItems[itemIndex]);
          } else {
            return const Expanded(child: SizedBox.shrink());
          }
        }),
      ),
    );
  }

  Widget _buildSmallProofCard(String title, String url, bool isVideo) {
    return GestureDetector(
      onTap: () {
        if (isVideo) {
          _showVideoPreview(url);
        } else {
          _showImagePreview(url);
        }
      },
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (!isVideo)
                    CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover, // Fit cover looks better for proofs
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  else
                    Container(
                      color: Colors.black12,
                      child: const Icon(
                        Icons.videocam,
                        size: 32,
                        color: Colors.grey,
                      ),
                    ),
                  if (isVideo)
                    const Center(
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.black54,
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showVideoPreview(String url) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _VideoPlayerWidget(url: url),
              PositionedDirectional(
                top: 40,
                start: 20,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showImagePreview(String url) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              InteractiveViewer(
                child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
              ),
              PositionedDirectional(
                top: 40,
                start: 20,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  final String url;
  const _VideoPlayerWidget({required this.url});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize()
          .then((_) {
            setState(() {});
            _controller.play();
          })
          .catchError((e) {
            setState(() {
              _isError = true;
            });
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return const Center(
        child: Text(
          "Failed to load video",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    if (!_controller.value.isInitialized) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[800]!,
        highlightColor: Colors.grey[700]!,
        child: Container(color: Colors.black),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            VideoPlayer(_controller),
            VideoProgressIndicator(_controller, allowScrubbing: true),
            GestureDetector(
              onTap: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
              child: Center(
                child: Icon(
                  _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 50,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
