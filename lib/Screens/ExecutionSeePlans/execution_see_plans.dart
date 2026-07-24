import 'package:canimage/Screens/landing/landing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../Hive_Database/execution_seeplan_db.dart';
import '../../Provider/can_image_provider.dart';
import '../../Repository/execution_image_upload_repository.dart';
import '../../Repository/execution_balance_count_change_repository.dart';
import '../../generated/l10n.dart';
import '../../utils/fonts.dart';
import '../../utils/textStyle.dart';
import 'execution_detailed_list_see_plan.dart';

final currentScreenProvider = StateProvider<String>((ref) => 'plans');
final offlineCountRefreshProvider = StateProvider<int>((ref) => 0);

class SeePlanScreen extends ConsumerStatefulWidget {
  final Function(String) changeLanguage;

  SeePlanScreen({super.key, required this.changeLanguage});
  @override
  _SeePlanScreenState createState() => _SeePlanScreenState();
}

class _SeePlanScreenState extends ConsumerState<SeePlanScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  ValueNotifier<double> progressNotifier = ValueNotifier<double>(0);
  bool _hasStartedRefresh = false;  // Track if refresh has started

  String _searchQuery = '';
  final Map<String, bool> _expandedGroups = {};
  final Map<String, int> _offlineCountCache = {};
  Map<String, Map<String, dynamic>>? _processedGroupedPlans;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _offlineCountCache.clear();
    });
  }



  Future<void> _refreshPlans() async {
    // Mark the start of the refresh process
    setState(() {
      _hasStartedRefresh = true;
    });

    try {
      final uploadRepository = ExecutionImageUploadHiveRepository();
      final pendingUploads = await uploadRepository.getAllMetadata();

      if (pendingUploads.isNotEmpty) {
        // Reset the state before showing dialog
        setState(() {
          _hasStartedRefresh = false;
          progressNotifier.value = 0;
        });

        if (mounted) {
          _showPendingSyncDialog(pendingUploads.length);
        }
        return;
      }

      ref.read(isRefreshingProvider.notifier).state = true;

      // Simulate the refresh process with progress updates
      for (int i = 0; i <= 10; i++) {
        await Future.delayed(Duration(milliseconds: 200));
        progressNotifier.value = i * 10.0;
      }

      // Refresh plans and handle progress updates
      await ref.refresh(reloadPlansProvider(true).future);

      // Simulate finishing the refresh process
      progressNotifier.value = 100.0;

      // Simulate the loading completion and reset button
      await Future.delayed(Duration(milliseconds: 500));  // Wait a little before resetting
      setState(() {
        _hasStartedRefresh = false;  // Reset the state back to reload
        progressNotifier.value = 0;  // Reset progress
      });

      await PlanCountChangeHiveRepository().clearAllOfflineCounts();
      ref.read(offlineCountRefreshProvider.notifier).state++;
      _offlineCountCache.clear();
      _processedGroupedPlans = null;

      if (mounted) {
        Navigator.of(context).popUntil((route) =>
        route.isFirst ||
            route.settings.name == '/see_plan' ||
            ModalRoute.of(context) == route
        );
      }

      final plansAsyncValue = ref.read(plansProvider);

      plansAsyncValue.when(
        data: (refreshedPlans) {
          if (refreshedPlans == "null" || refreshedPlans.isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.orange,
                  content: Text(S.of(context).noDataFound, style: TextStyle(fontFamily: "Roboto")),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.green,
                  content: Text(S.of(context).planSuccess, style: TextStyle(fontFamily: "Roboto")),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        },
        loading: () {},
        error: (error, stackTrace) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${S.of(context).failedPlan}: $error', style: TextStyle(fontFamily: "Roboto")),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
        },
      );
    } catch (e) {
      // Reset state on error as well
      setState(() {
        _hasStartedRefresh = false;
        progressNotifier.value = 0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${S.of(context).failedPlan}: $e', style: TextStyle(fontFamily: "Roboto")),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        ref.read(isRefreshingProvider.notifier).state = false;
      }
    }
  }
  void _showPendingSyncDialog(int pendingCount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.cloud_upload, color: Colors.orange[700], size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  S.of(context).pendingUploads,
                  style: TextStyle(
                    fontFamily: "Roboto",
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${S.of(context).youhave} $pendingCount ${S.of(context).pendingSynced}',
                style: TextStyle(
                  fontFamily: "Roboto",
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        S.of(context).pleaseSyncAllPending,
                        style: TextStyle(
                          fontFamily: "Roboto",
                          fontSize: 13,
                          color: Colors.orange[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                S.of(context).ok,
                style: TextStyle(
                  fontFamily: "Roboto",
                  color: Font.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onGroupRowClickNew(List<PlanItem> groupPlans, int totalBalance) async {
    List<ArtworkData> artworkList = groupPlans.map((plan) => ArtworkData(
      artworkId: plan.artworkId,
      artworkName: plan.artworkName,
      height: int.tryParse(plan.height) ?? 0,
      width: int.tryParse(plan.width) ?? 0,
      sqft: int.tryParse(plan.sqft) ?? 0,
      artworkUrl: plan.artworkUrl,
      planServerId: plan.planServerId,
      planCode: plan.planCode,
      villageCode: plan.villageCode,
      balance: plan.noOfBalance,
    )).toList();

    Map<int, ArtworkData> uniqueArtworks = {};
    for (var artwork in artworkList) {
      //uniqueArtworks[artwork.artworkId] = artwork;
      uniqueArtworks[artwork.planServerId] = artwork;

    }

    final filteredArtworks = uniqueArtworks.values.toList();
    final firstPlan = groupPlans[0];
    int totalPrints = groupPlans.fold(0, (sum, plan) => sum + (plan.noOfPrints ?? 0));

    final isRefreshing = ref.read(isRefreshingProvider);
    int offlineCount = await PlanCountChangeHiveRepository().getOfflineCountForGroup(
      firstPlan.planCode,
      firstPlan.villageCode,
      firstPlan.villageName,
      firstPlan.tehsil,
    );

    int displayBalance = isRefreshing ? totalBalance : totalBalance - offlineCount;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetailedListSeePlansScreen(
        artworkList: filteredArtworks,
        villageName: firstPlan.villageName,
        districtName: firstPlan.districtName,
        cdBlockName: firstPlan.tehsil,
        totalPrints: totalPrints,
        balancePrints: displayBalance,
        planCode: firstPlan.planCode,
        VillageCode: firstPlan.villageCode,
        ServerID: firstPlan.planServerId.toString(),
        locations: firstPlan.locations,
        changeLanguage: widget.changeLanguage,
        flag: '6',
      )),
    );

    _offlineCountCache.clear();
    _processedGroupedPlans = null;
    ref.read(offlineCountRefreshProvider.notifier).state++;
    setState(() {});
  }

  Future<bool> _onWillPop() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LandingScreen(changeLanguage: widget.changeLanguage)),
    );
    return false;
  }

  Future<int> _getCachedOfflineCount(String groupKey, PlanItem firstPlan) async {
    if (_offlineCountCache.containsKey(groupKey)) {
      return _offlineCountCache[groupKey]!;
    }

    final count = await PlanCountChangeHiveRepository().getOfflineCountForGroup(
      firstPlan.planCode,
      firstPlan.villageCode,
      firstPlan.villageName,
      firstPlan.tehsil,
    );

    _offlineCountCache[groupKey] = count;
    return count;
  }

  Map<String, Map<String, dynamic>> _processPlansData(List<PlanItem> plans) {
    final projectPlanGroups = <String, Map<String, dynamic>>{};

    for (var plan in plans) {
      final projectPlanKey = '${plan.projectName}_${plan.planCode}';

      if (!projectPlanGroups.containsKey(projectPlanKey)) {
        projectPlanGroups[projectPlanKey] = {
          'projectName': plan.projectName,
          'planCode': plan.planCode,
          'villageGroups': <String, Map<String, dynamic>>{},
          'totalBalance': 0,
        };
      }

      final villageKey = '${plan.planCode}_${plan.villageCode}_${plan.villageName}_${plan.tehsil}';

      if (!projectPlanGroups[projectPlanKey]!['villageGroups'].containsKey(villageKey)) {
        projectPlanGroups[projectPlanKey]!['villageGroups'][villageKey] = {
          'plans': <PlanItem>[],
          'totalBalance': 0,
          'artworkIds': <int>{},
        };
      }

      projectPlanGroups[projectPlanKey]!['villageGroups'][villageKey]['plans'].add(plan);
      projectPlanGroups[projectPlanKey]!['villageGroups'][villageKey]['totalBalance'] += (plan.noOfBalance ?? 0);
      projectPlanGroups[projectPlanKey]!['villageGroups'][villageKey]['artworkIds'].add(plan.artworkId);
      projectPlanGroups[projectPlanKey]!['totalBalance'] += (plan.noOfBalance ?? 0);
    }

    projectPlanGroups.removeWhere((key, group) => (group['totalBalance'] as int) <= 0);
    return projectPlanGroups;
  }

  // SEARCH FILTER - Only show matching villages
  Map<String, Map<String, dynamic>> _applySearchFilter(
      Map<String, Map<String, dynamic>> groupedPlans, String query) {
    if (query.isEmpty) return groupedPlans;

    final lowercaseQuery = query.toLowerCase();
    Map<String, Map<String, dynamic>> result = {};

    for (var entry in groupedPlans.entries) {
      final projectPlanKey = entry.key;
      final projectPlanData = entry.value;
      final projectName = (projectPlanData['projectName'] as String).toLowerCase();
      final planCode = (projectPlanData['planCode'] as String).toLowerCase();
      final allVillageGroups = projectPlanData['villageGroups'] as Map<String, Map<String, dynamic>>;

      // Check if project/plan name matches search
      final projectPlanMatches = projectName.contains(lowercaseQuery) || planCode.contains(lowercaseQuery);

      if (projectPlanMatches) {
        // Show ALL villages if project/plan matches
        result[projectPlanKey] = projectPlanData;
      } else {
        // Filter villages that match search
        Map<String, Map<String, dynamic>> matchingVillages = {};
        int totalFilteredBalance = 0;

        for (var villageEntry in allVillageGroups.entries) {
          final villageKey = villageEntry.key;
          final villageData = villageEntry.value;
          final groupPlans = villageData['plans'] as List<PlanItem>;

          // Check if this village matches search
          final villageMatches = groupPlans.any((plan) =>
          (plan.villageCode?.toLowerCase().contains(lowercaseQuery) ?? false) ||
              (plan.villageName?.toLowerCase().contains(lowercaseQuery) ?? false) ||
              (plan.tehsil?.toLowerCase().contains(lowercaseQuery) ?? false));

          if (villageMatches) {
            matchingVillages[villageKey] = villageData;
            totalFilteredBalance += villageData['totalBalance'] as int;
          }
        }

        // Only include this project-plan if it has matching villages
        if (matchingVillages.isNotEmpty) {
          result[projectPlanKey] = {
            'projectName': projectPlanData['projectName'],
            'planCode': projectPlanData['planCode'],
            'villageGroups': matchingVillages,
            'totalBalance': totalFilteredBalance,
          };
        }
      }
    }

    return result;
  }

  Widget _buildHierarchicalList(Map<String, Map<String, dynamic>> displayPlans) {
    final projectPlanKeys = displayPlans.keys.toList();
    double screenWidth = MediaQuery.of(context).size.width;
    bool isTablet = screenWidth > 600;

    return ListView.builder(
      controller: _scrollController,
      itemCount: projectPlanKeys.length,
      itemBuilder: (context, index) {
        final projectPlanKey = projectPlanKeys[index];
        final projectPlanData = displayPlans[projectPlanKey]!;
        final projectName = projectPlanData['projectName'] as String;
        final planCode = projectPlanData['planCode'] as String;
        final villageGroups = projectPlanData['villageGroups'] as Map<String, Map<String, dynamic>>;
        final totalBalance = projectPlanData['totalBalance'] as int;

        final isExpanded = _expandedGroups[projectPlanKey] ?? true;

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              // PROJECT + PLAN HEADER
              InkWell(
                onTap: () {
                  setState(() {
                    _expandedGroups[projectPlanKey] = !isExpanded;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: Font.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(8),
                      bottom: isExpanded ? Radius.zero : Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                        color: Font.primaryColor,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$projectName - $planCode',
                              style: TextStyle(
                                fontFamily: "Roboto",
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Font.primaryColor,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${villageGroups.length} ${S.of(context).villages} • ${S.of(context).balance}: $totalBalance',
                              style: TextStyle(
                                fontFamily: "Roboto",
                                fontSize: 11,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // VILLAGE TABLE - WITHOUT PLAN CODE
              if (isExpanded)
                Column(
                  children: [
                    // Header
                    Container(
                      color: Font.primaryColor,
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 20 : 12,
                        vertical: isTablet ? 12 : 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 14, child: Text(S.of(context).villageCode, style: TextstyleGlobal.tableHeaderTextStyle)),
                          Expanded(flex: 35, child: Text(S.of(context).villageNameMap, style: TextstyleGlobal.tableHeaderTextStyle, textAlign: TextAlign.center)),
                          Expanded(flex: 25, child: Text(S.of(context).tehsil, style: TextstyleGlobal.tableHeaderTextStyle, textAlign: TextAlign.center)),
                          Expanded(flex: 20, child: Text(S.of(context).balance, style: TextstyleGlobal.tableHeaderTextStyle, textAlign: TextAlign.center)),
                        ],
                      ),
                    ),

                    // Rows
                    ...villageGroups.entries.map((villageEntry) {
                      final villageKey = villageEntry.key;
                      final villageData = villageEntry.value;
                      final groupPlans = villageData['plans'] as List<PlanItem>;
                      final totalBalance = villageData['totalBalance'] as int;
                      final firstPlan = groupPlans[0];
                      final villageIndex = villageGroups.keys.toList().indexOf(villageKey);

                      return InkWell(
                        onTap: () => _onGroupRowClickNew(groupPlans, totalBalance),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
                            color: villageIndex % 2 == 0 ? Colors.white : Colors.grey[50],
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 20 : 12,
                            vertical: isTablet ? 14 : 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 14,
                                child: Text(
                                  firstPlan.villageCode,
                                  style: TextstyleGlobal.bodyTextStyleSeeplan,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 10,
                                ),
                              ),
                              Expanded(
                                flex: 35,
                                child: Text(
                                  firstPlan.villageName,
                                  style: TextstyleGlobal.bodyTextStyleSeeplan,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 10,
                                ),
                              ),
                              Expanded(
                                flex: 25,
                                child: Text(
                                  firstPlan.tehsil,
                                  style: TextstyleGlobal.bodyTextStyleSeeplan,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 10,
                                ),
                              ),
                              Expanded(
                                flex: 20,
                                child: Consumer(
                                  builder: (context, ref, child) {
                                    ref.watch(offlineCountRefreshProvider);
                                    final isRefreshing = ref.watch(isRefreshingProvider);

                                    return FutureBuilder<int>(
                                      key: ValueKey('${villageKey}_${ref.watch(offlineCountRefreshProvider)}_$isRefreshing'),
                                      future: _getCachedOfflineCount(villageKey, firstPlan),
                                      builder: (context, snapshot) {
                                        int offlineCount = snapshot.data ?? 0;
                                        int displayBalance = totalBalance - offlineCount;

                                        if (isRefreshing && displayBalance <= 0) {
                                          return SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          );
                                        }

                                        return Text(
                                          '$displayBalance',
                                          style: TextstyleGlobal.bodyTextStyleSeeplan.copyWith(
                                            color: Font.neutralDarkColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plansState = ref.watch(plansProvider);
    final isRefreshing = ref.watch(isRefreshingProvider);
    final offlineCountRefresh = ref.watch(offlineCountRefreshProvider);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Font.primaryColor,
            title: Text(
              S.of(context).plan,
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  letterSpacing: 1,
                  fontFamily: "Roboto"),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LandingScreen(changeLanguage: widget.changeLanguage)),
                );
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
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 45,
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.search_sharp, color: Font.primaryLightColor),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                icon: Icon(Icons.clear, color: Font.primaryLightColor),
                                onPressed: _clearSearch,
                              )
                                  : null,
                              hintText: S.of(context).search,
                              hintStyle: TextStyle(fontSize: 12, color: Colors.grey[600], fontFamily: "Roboto"),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Font.primaryLightColor, width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                              ),
                            ),
                            style: TextStyle(fontSize: 14, fontFamily: "Roboto"),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      GestureDetector(
                        onTap: _hasStartedRefresh || isRefreshing ? null : _refreshPlans,  // Disable when refreshing or already started
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: _hasStartedRefresh || isRefreshing ? Colors.grey : Font.primaryColor,  // Disable button after clicking
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ValueListenableBuilder<double>(
                                valueListenable: progressNotifier,
                                builder: (context, progress, child) {
                                  return _hasStartedRefresh
                                      ? Row(
                                    children: [
                                      SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          value: progress / 100,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Loading ${progress.toInt()}%',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                          fontFamily: "Roboto",
                                        ),
                                      ),
                                    ],
                                  )
                                      : Row(
                                    children: [
                                      Text(
                                        'Reload',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                          fontFamily: "Roboto",
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: plansState.when(
                    data: (plans) {
                      if (_processedGroupedPlans == null) {
                        _processedGroupedPlans = _processPlansData(plans);
                      }

                      return FutureBuilder<Map<String, Map<String, dynamic>>>(
                        key: ValueKey('${_processedGroupedPlans!.length}_${offlineCountRefresh}_${isRefreshing}_$_searchQuery'),
                        future: _filterGroupsWithDisplayBalance(_processedGroupedPlans!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                '${S.of(context).error}: ${snapshot.error}',
                                style: TextStyle(color: Colors.red, fontFamily: "Roboto"),
                              ),
                            );
                          }

                          final balanceFilteredPlans = snapshot.data ?? {};
                          final searchFilteredPlans = _applySearchFilter(balanceFilteredPlans, _searchQuery);

                          if (searchFilteredPlans.isEmpty && _searchQuery.isNotEmpty) {
                            return _buildNoResultsWidget();
                          }

                          if (searchFilteredPlans.isEmpty) {
                            return _buildNoPlansWidget();
                          }

                          return Column(
                            children: [
                              if (_searchQuery.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          '${S.of(context).showing} ${searchFilteredPlans.length} ${S.of(context).results}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontFamily: "Roboto",
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Expanded(child: _buildHierarchicalList(searchFilteredPlans)),
                            ],
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, stack) => _buildErrorWidget(e),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<Map<String, Map<String, dynamic>>> _filterGroupsWithDisplayBalance(
      Map<String, Map<String, dynamic>> groupedPlans) async {
    Map<String, Map<String, dynamic>> filteredGroups = {};

    for (var entry in groupedPlans.entries) {
      final projectPlanKey = entry.key;
      final projectPlanData = entry.value;
      final villageGroups = projectPlanData['villageGroups'] as Map<String, Map<String, dynamic>>;

      int totalDisplayBalance = 0;
      Map<String, Map<String, dynamic>> filteredVillageGroups = {};

      for (var villageEntry in villageGroups.entries) {
        final villageKey = villageEntry.key;
        final villageData = villageEntry.value;
        final totalBalance = villageData['totalBalance'] as int;
        final groupPlans = villageData['plans'] as List<PlanItem>;
        final firstPlan = groupPlans[0];

        if (totalBalance <= 0) continue;

        int offlineCount = await _getCachedOfflineCount(villageKey, firstPlan);
        int displayBalance = totalBalance - offlineCount;

        if (displayBalance > 0) {
          filteredVillageGroups[villageKey] = villageData;
          totalDisplayBalance += displayBalance;
        }
      }

      if (totalDisplayBalance > 0) {
        filteredGroups[projectPlanKey] = {
          'projectName': projectPlanData['projectName'],
          'planCode': projectPlanData['planCode'],
          'villageGroups': filteredVillageGroups,
          'totalBalance': totalDisplayBalance,
        };
      }
    }

    return filteredGroups;
  }

  Widget _buildNoResultsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            '${S.of(context).noPlanFound} "${_searchQuery}"',
            style: TextStyle(fontSize: 16, color: Colors.grey[600], fontFamily: "Roboto"),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPlansWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(S.of(context).noPlanFound, style: TextStyle(fontSize: 16, color: Colors.grey[600], fontFamily: "Roboto")),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _processedGroupedPlans = null;
                _offlineCountCache.clear();
              });
              ref.invalidate(plansProvider);
            },
            icon: Icon(Icons.refresh, color: Colors.white),
            label: Text(S.of(context).retry, style: TextStyle(color: Colors.white, fontFamily: "Roboto")),
            style: ElevatedButton.styleFrom(
              backgroundColor: Font.primaryColor,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(Object e) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[600]),
            SizedBox(height: 24),
            Text(S.of(context).error, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, fontFamily: "Roboto")),
            SizedBox(height: 12),
            Text(e.toString(), style: TextStyle(fontSize: 14, fontFamily: "Roboto"), textAlign: TextAlign.center),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _processedGroupedPlans = null;
                  _offlineCountCache.clear();
                });
                ref.invalidate(plansProvider);
              },
              icon: Icon(Icons.refresh, color: Colors.white),
              label: Text(S.of(context).retry, style: TextStyle(color: Colors.white, fontFamily: "Roboto")),
              style: ElevatedButton.styleFrom(
                backgroundColor: Font.primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ArtworkData {
  final int planServerId;
  final String planCode;
  final String villageCode;
  final int artworkId;
  final String artworkName;
  final int height;
  final int width;
  final int sqft;
  final String artworkUrl;
  final dynamic balance;
  ArtworkData({
    required this.planServerId,
    required this.planCode,
    required this.villageCode,
    required this.artworkId,
    required this.artworkName,
    required this.height,
    required this.width,
    required this.sqft,
    required this.artworkUrl,
    required this.balance,
  });
}