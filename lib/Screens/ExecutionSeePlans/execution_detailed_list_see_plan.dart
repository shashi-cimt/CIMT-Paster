  import 'package:canimage/Screens/ExecutionSeePlans/execution_see_plans.dart';
  import 'package:flutter/cupertino.dart';
  import 'package:flutter/material.dart';
  import '../../Hive_Database/execution_seeplan_location_db.dart';
import '../../Model/see_plan_model.dart';
import '../../Repository/execution_balance_count_change_repository.dart';
  import '../../generated/l10n.dart';
  import '../../utils/fonts.dart';
  import '../landing/landing_screen.dart';
import 'execution_map_pointer.dart';
import 'execution_map_screen.dart';
import 'execution_sub_map_screen.dart';

  class DetailedListSeePlansScreen extends StatefulWidget {
    final List<LocationItem>? locations;
    List<ArtworkData>? artworkList; // Accept village artworks data
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
      required this.flag
    });

    @override
    State<DetailedListSeePlansScreen> createState() => _DetailedListSeePlansScreenState();
  }

  class _DetailedListSeePlansScreenState extends State<DetailedListSeePlansScreen> {


    Future<bool> _onWillPop() async {
      if(widget.flag == "6"){
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SeePlanScreen(changeLanguage: widget.changeLanguage,)),
        );
      }else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SubMapScreen(planCode: '', VillageCode: '', ServerID: '', changeLanguage: widget.changeLanguage, height:"", width: "", villageName: "", brand: "", tensil: '', artworkId: "",)),
        );
      }
      return false;
    }

    @override
    Widget build(BuildContext context) {
      final theme = Theme.of(context);
      final cs = theme.colorScheme;

      return WillPopScope(
        onWillPop: _onWillPop,
        child: SafeArea(
          child: Scaffold(
            backgroundColor: theme.colorScheme.surface,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Font.primaryColor,
              title: Text(
                S.of(context).planDetails,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    letterSpacing: 1,
                    fontFamily: "Roboto"
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                onPressed: () {
                  if(widget.flag == "6"){
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SeePlanScreen(changeLanguage: widget.changeLanguage,)),
                    );
                  }else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SubMapScreen(
                        planCode: '',
                        VillageCode: '',
                        ServerID: '',
                        changeLanguage: widget.changeLanguage,
                        height:"",
                        width: "",
                        villageName: "",
                        brand: "", tensil: '',
                        artworkId: "",
                      )),
                    );
                  }

                },
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.home, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LandingScreen(changeLanguage: widget.changeLanguage)),
                    );
                  },
                ),
              ],
            ),
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Font.pureWhiteColor, Font.pureWhiteColor, Font.pureWhiteColor],
                ),
              ),
              child: Column(
                children: [
                  // Top card with Village Name, District Name, CD Block Name, Total Prints & Balance Prints
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: _TopCard(data: {
                      'villageName': widget.villageName.toString(),
                      'districtName': widget.districtName.toString(),
                      'cdBlockName': widget.cdBlockName.toString(),
                      'totalPrints': widget.totalPrints.toString(),
                      'balancePrints': widget.balancePrints.toString(),
                    }),
                  ),

                  // Main content list (ListView)
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                      itemCount: widget.artworkList!.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final item = widget.artworkList![i];
                        // print(item.artworkId);
                        // print("item.artworkId");
                        // print(item.artworkName);
                        return FutureBuilder<int>(
                           // error1  key: ValueKey('artwork_${item.artworkId}_${item.planServerId.toString()}'),
                            key: ValueKey('artwork_${item.planServerId.toString()}'),
                          future: PlanCountChangeHiveRepository().getArtworkOfflineCount(
                            item.planServerId.toString(),
                            item.planCode,
                            item.villageCode,
                            item.artworkId,
                          ),
                          builder: (context, offlineSnapshot) {
                            int artworkOfflineCount = offlineSnapshot.data ?? 0;
                            int originalBalance = item.balance ?? 0;

                            // Calculate display balance for this specific artwork
                            int displayBalance = originalBalance - artworkOfflineCount;

                            // Ensure balance doesn't go negative
                            displayBalance = displayBalance < 0 ? 0 : displayBalance;
                            if (displayBalance <= 0) {
                              return SizedBox.shrink(); // Hides the card
                            }
                        return Card(
                          color: Font.pureWhiteColor,
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: cs.outlineVariant),
                          ),
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          child: InkWell(
                            // // onTap: (){
                            // //   Navigator.push(
                            // //     context,
                            // //     MaterialPageRoute(builder: (context) => MapScreen(
                            // //       planCode: item.planCode.toString(),
                            // //       VillageCode: item.villageCode.toString(),
                            // //       ServerID: item.planServerId.toString(),
                            // //       changeLanguage: widget.changeLanguage,
                            // //       height:item.height, width: item.width,
                            // //       villageName: widget.villageName,
                            // //       brand: item.artworkName,
                            // //       tensil: widget.cdBlockName,
                            // //       artworkId: item.artworkId,
                            // //     ),
                            // //     ),
                            // //   );
                            // // },
                            // onTap: () {
                            //   final pointers = widget.locations
                            //       ?.map(
                            //         (e) => MapPointerData(
                            //       planServerId: item.planServerId.toString(),
                            //       locateId: e.locateId ?? "",
                            //       latitude: double.tryParse(e.latitude ?? "0") ?? 0.0,
                            //       longitude: double.tryParse(e.longitude ?? "0") ?? 0.0,
                            //       artworkName: item.artworkName,
                            //     ),
                            //   )
                            //       .toList();
                            //
                            //   Navigator.push(
                            //     context,
                            //     MaterialPageRoute(
                            //       builder: (context) => MapScreenpointer(
                            //         planCode: item.planCode.toString(),
                            //         VillageCode: item.villageCode.toString(),
                            //         ServerID: item.planServerId.toString(),
                            //         changeLanguage: widget.changeLanguage,
                            //         height: item.height,
                            //         width: item.width,
                            //         villageName: widget.villageName,
                            //         brand: item.artworkName,
                            //         tensil: widget.cdBlockName,
                            //         artworkId: item.artworkId,
                            //
                            //         // Pass pointers
                            //         pointers: pointers,
                            //       ),
                            //     ),
                            //   );
                            // },
                            onTap: () {
                              final pointers = widget.locations
                                  ?.where((e) =>
                              (e.locateId?.trim().isNotEmpty ?? false) &&
                                  (e.latitude?.trim().isNotEmpty ?? false) &&
                                  (e.longitude?.trim().isNotEmpty ?? false))
                                  .map(
                                    (e) => MapPointerData(
                                  planServerId: item.planServerId.toString(),
                                  locateId: e.locateId!,
                                  latitude: double.tryParse(e.latitude!) ?? 0.0,
                                  longitude: double.tryParse(e.longitude!) ?? 0.0,
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
                                      planCode: item.planCode.toString(),
                                      VillageCode: item.villageCode.toString(),
                                      ServerID: item.planServerId.toString(),
                                      changeLanguage: widget.changeLanguage,
                                      height: item.height,
                                      width: item.width,
                                      villageName: widget.villageName,
                                      brand: item.artworkName,
                                      tensil: widget.cdBlockName,
                                      artworkId: item.artworkId,
                                    ),
                                  ),
                                );
                              } else {
                                // Pointer available -> Open pointer map
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MapScreenpointer(
                                      planCode: item.planCode.toString(),
                                      VillageCode: item.villageCode.toString(),
                                      ServerID: item.planServerId.toString(),
                                      changeLanguage: widget.changeLanguage,
                                      height: item.height,
                                      width: item.width,
                                      villageName: widget.villageName,
                                      brand: item.artworkName,
                                      tensil: widget.cdBlockName,
                                      artworkId: item.artworkId,
                                      pointers: pointers,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 14, left: 14, right: 14, bottom: 5),
                                  child: Row(
                                    children: [
                                      // Image on the left side (small size)
                                      Container(
                                        width: 70,
                                        height: 70,
                                        margin: const EdgeInsets.only(right: 12),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.rectangle,
                                          border: Border.all(color: Colors.grey.shade300),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: _buildImageWidget(item.artworkUrl),
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              //item.planServerId.toString(),
                                              item.artworkName.toString(),
                                              maxLines: 10,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: Font.neutralDarkColor,
                                                  fontSize: 12,
                                                  fontFamily: "Roboto"
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            _MetaRow(label: S.of(context).width, value: item.height.toString()),
                                            _MetaRow(label: S.of(context).height, value: item.width.toString()),
                                            _MetaRow(label: S.of(context).balancePrints, value: '${displayBalance.toString()}'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned.fill(
                                  right: 0,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Container(
                                      width: 30,
                                      height: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Font.primaryColor,
                                        borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(16),
                                          bottomRight: Radius.circular(16),
                                        ),
                                      ),
                                      child: Icon(Icons.arrow_circle_right_rounded, size: 22, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                        );
                      }
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    Widget _buildImageWidget(String? artworkUrl) {
      // Check if URL is null or empty
      if (artworkUrl == null || artworkUrl.isEmpty) {
        return _buildPlaceholderIcon();
      }

      // Clean up the URL - remove double slashes and decode spaces
      String cleanUrl = artworkUrl
          .replaceAll(RegExp(r'(?<!:)//+'), '/') // Replace double+ slashes (except after :)
          .replaceAll('%20', ' '); // Decode spaces back

      // print('Original URL: $artworkUrl');
      // print('Cleaned URL: $cleanUrl');

      return Image.network(
        cleanUrl,
        fit: BoxFit.cover,
        width: 70,
        height: 70,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;

          return Container(
            width: 70,
            height: 70,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Font.primaryLightColor),
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // print('Failed to load image: $cleanUrl');
          // print('Error: $error');
          return _buildPlaceholderIcon();
        },
      );
    }

    Widget _buildPlaceholderIcon() {
      return Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.image_not_supported,
          size: 30,
          color: Font.primaryColor.withOpacity(0.2),
        ),
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
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context).planDetails,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Font.neutralDarkColor,
                ),
              ),
              const SizedBox(height: 12),
              _MetaRow(label: S.of(context).villageNameMap, value: data['villageName'] ?? 'N/A'),
              _MetaRow(label: S.of(context).districtName, value: data['districtName'] ?? 'N/A'),
              _MetaRow(label: S.of(context).cdBlockName, value: data['cdBlockName'] ?? 'N/A'),
              _MetaRow(label: S.of(context).totalPrints, value: data['totalPrints'] ?? '0'),
              _MetaRow(label: S.of(context).balancePrints, value: data['balancePrints'] ?? '0'),
            ],
          ),
        ),
      );
    }
  }


  class _MetaRow extends StatelessWidget {
    const _MetaRow({required this.label, required this.value});

    final String label;
    final String value;

    @override
    Widget build(BuildContext context) {
      final theme = Theme.of(context);
      final cs = theme.colorScheme;

      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: Font.neutralDarkColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    fontFamily: "Roboto"
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 25),
                child: Text(
                  value,
                  maxLines: 10,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 11,
                      fontFamily: "Roboto"
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

