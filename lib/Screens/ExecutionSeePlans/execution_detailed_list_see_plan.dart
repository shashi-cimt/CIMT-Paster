import 'package:flutter/material.dart';
import '../../Hive_Database/execution_seeplan_location_db.dart';
import '../../Repository/execution_balance_count_change_repository.dart';
import '../../generated/l10n.dart';
import '../../utils/fonts.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/can_image_loader.dart';
import 'execution_map_pointer.dart';
import 'execution_map_screen.dart';
import 'execution_see_plans.dart';

class DetailedListSeePlansScreen extends StatefulWidget {
  final List<LocationItem>? locations;
  List<ArtworkData>? artworkList;
  String? villageName;
  String? districtName;
  String? cdBlockName;
  int? totalPrints;
  int? balancePrints;
  String? planCode;
  String? VillageCode;
  String? ServerID;
  final Function(String) changeLanguage;
  String? flag;
  String? projectId;

  DetailedListSeePlansScreen({
    super.key,
    required this.ServerID,
    this.artworkList,
    this.villageName,
    this.locations,
    this.districtName,
    this.cdBlockName,
    this.totalPrints,
    this.balancePrints,
    required this.planCode,
    required this.VillageCode,
    required this.changeLanguage,
    required this.flag,
    this.projectId,
  });

  @override
  State<DetailedListSeePlansScreen> createState() =>
      _DetailedListSeePlansScreenState();
}

class _DetailedListSeePlansScreenState
    extends State<DetailedListSeePlansScreen> {
  Future<bool> _onWillPop() async {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: SafeArea(
        top: false,
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F6F8),
          appBar: CommonAppBar(
            title: S.of(context).planDetails,
            actions: const [CommonHomeButton()],
          ),
          body: Column(
            children: [
              // Top card with Village Name, District Name, CD Block Name, Total Prints & Balance Prints
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                child: _TopCard(
                  data: {
                    'villageName': widget.villageName?.toString() ?? 'N/A',
                    'districtName': widget.districtName?.toString() ?? 'N/A',
                    'cdBlockName': widget.cdBlockName?.toString() ?? 'N/A',
                    'totalPrints': widget.totalPrints?.toString() ?? '0',
                    'balancePrints': widget.balancePrints?.toString() ?? '0',
                  },
                ),
              ),

              // Main content list (ListView)
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
                  itemCount: widget.artworkList?.length ?? 0,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final item = widget.artworkList![i];

                    return FutureBuilder<int>(
                      key: ValueKey('artwork_${item.planServerId.toString()}'),
                      future: PlanCountChangeHiveRepository()
                          .getArtworkOfflineCount(
                            item.planServerId.toString(),
                            item.planCode,
                            item.villageCode,
                            item.artworkId,
                          ),
                      builder: (context, offlineSnapshot) {
                        int artworkOfflineCount = offlineSnapshot.data ?? 0;
                        int originalBalance = item.balance ?? 0;

                        // Calculate display balance for this specific artwork
                        int displayBalance =
                            originalBalance - artworkOfflineCount;

                        // Ensure balance doesn't go negative
                        displayBalance = displayBalance < 0
                            ? 0
                            : displayBalance;
                        if (displayBalance <= 0) {
                          return const SizedBox.shrink(); // Hides the card
                        }

                        return Card(
                          color: Font.pureWhiteColor,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          child: InkWell(
                            onTap: () {
                              final pointers = widget.locations
                                  ?.where(
                                    (e) =>
                                        e.locateId.trim().isNotEmpty &&
                                        e.latitude.trim().isNotEmpty &&
                                        e.longitude.trim().isNotEmpty,
                                  )
                                  .map(
                                    (e) => MapPointerData(
                                      planServerId: item.planServerId
                                          .toString(),
                                      locateId: e.locateId,
                                      latitude:
                                          double.tryParse(e.latitude) ?? 0.0,
                                      longitude:
                                          double.tryParse(e.longitude) ?? 0.0,
                                      artworkName: item.artworkName,
                                    ),
                                  )
                                  .toList();

                              if (pointers == null || pointers.isEmpty) {
                                // No pointer available -> Open normal map
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MapScreen(
                                      planCode: item.planCode,
                                      VillageCode: item.villageCode,
                                      ServerID: item.planServerId.toString(),
                                      changeLanguage: widget.changeLanguage,
                                      height: item.height,
                                      width: item.width,
                                      villageName: widget.villageName,
                                      brand: item.artworkName,
                                      tensil: widget.cdBlockName,
                                      artworkId: item.artworkId,
                                      projectId: item.projectId ?? widget.projectId,
                                    ),
                                  ),
                                );
                              } else {
                                // Pointer available -> Open pointer map
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MapScreenpointer(
                                      planCode: item.planCode,
                                      VillageCode: item.villageCode,
                                      ServerID: item.planServerId.toString(),
                                      changeLanguage: widget.changeLanguage,
                                      height: item.height,
                                      width: item.width,
                                      villageName: widget.villageName,
                                      brand: item.artworkName,
                                      tensil: widget.cdBlockName,
                                      artworkId: item.artworkId,
                                      pointers: pointers,
                                      projectId: item.projectId ?? widget.projectId,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    children: [
                                      // Image on the left side
                                      Container(
                                        width: 76,
                                        height: 76,
                                        margin: const EdgeInsets.only(
                                          right: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child: _buildImageWidget(
                                            item.artworkUrl,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                right: 34,
                                              ),
                                              child: Text(
                                                item.artworkName,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          Font.neutralDarkColor,
                                                      fontSize: 14.5,
                                                      fontFamily: "Roboto",
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            _MetaRow(
                                              label: S.of(context).width,
                                              value: item.width.toString(),
                                              rightPadding: 34,
                                            ),
                                            _MetaRow(
                                              label: S.of(context).height,
                                              value: item.height.toString(),
                                              rightPadding: 34,
                                            ),
                                            _MetaRow(
                                              label: S
                                                  .of(context)
                                                  .balancePrints,
                                              value: displayBalance.toString(),
                                              rightPadding: 34,
                                              isBoldValue: true,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Right side blue action bar
                                Positioned.fill(
                                  right: 0,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Container(
                                      width: 34,
                                      height: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Font.primaryColor,
                                        borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(14),
                                          bottomRight: Radius.circular(14),
                                        ),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget(String? artworkUrl) {
    if (artworkUrl == null || artworkUrl.trim().isEmpty) {
      return _buildPlaceholderIcon();
    }

    String cleanUrl = artworkUrl
        .replaceAll(RegExp(r'(?<!:)//+'), '/')
        .replaceAll('%20', ' ');

    return Image.network(
      cleanUrl,
      fit: BoxFit.cover,
      width: 76,
      height: 76,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;

        return const Center(
          child: CanImageSpinner(size: 22),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholderIcon();
      },
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.image_outlined, size: 28, color: Colors.grey.shade400),
    );
  }
}

class _TopCard extends StatelessWidget {
  final Map<String, String> data;
  const _TopCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: Font.pureWhiteColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context).planDetails,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: Font.neutralDarkColor,
              ),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 10),
            _MetaRow(
              label: S.of(context).villageNameMap,
              value: data['villageName'] ?? 'N/A',
            ),
            _MetaRow(
              label: S.of(context).districtName,
              value: data['districtName'] ?? 'N/A',
            ),
            _MetaRow(
              label: S.of(context).cdBlockName,
              value: data['cdBlockName'] ?? 'N/A',
            ),
            _MetaRow(
              label: S.of(context).totalPrints,
              value: data['totalPrints'] ?? '0',
            ),
            _MetaRow(
              label: S.of(context).balancePrints,
              value: data['balancePrints'] ?? '0',
              isBoldValue: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
    this.rightPadding = 0,
    this.isBoldValue = false,
  });

  final String label;
  final String value;
  final double rightPadding;
  final bool isBoldValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Font.neutralDarkColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                fontFamily: "Roboto",
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Padding(
              padding: EdgeInsets.only(right: rightPadding),
              child: Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isBoldValue ? Font.primaryColor : cs.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: isBoldValue ? FontWeight.w700 : FontWeight.w500,
                  fontFamily: "Roboto",
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
