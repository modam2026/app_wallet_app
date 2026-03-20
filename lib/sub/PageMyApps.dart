import 'dart:convert';
import 'package:app_wallet_app/common/AppCache.dart';
import 'package:app_wallet_app/common/DataSearch.dart';
import 'package:app_wallet_app/common/common_helper.dart';
import 'package:app_wallet_app/common/sql_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 나의 앱 탭에서 그룹별로 앱을 표시하는 단일 동적 페이지.
///
/// 작업 순서:
///   1. [initState]   - [groupCode] / [isFirst] 를 기반으로 [_appsFuture] 초기화
///   2. [_loadApps]   - isFirst 이거나 appDataWithMine 이 비어있으면 DB 초기화 수행
///   3. groupCode "A" → 전체 표시 / 그 외 → app_kind == groupCode 로 필터링
///   4. [build]       - FutureBuilder 로 ListView 렌더링
///   5. 그룹 변경 다이얼로그 → [showConfirmationDialog] 호출 후 setState
class PageMyApps extends StatefulWidget {
  /// tbl_group_info.group_code 와 동일한 값 (예: "A", "G", "M", "B", "C" …)
  final String groupCode;
  final int appOrder;

  /// 화면 AppBar 에 표시할 그룹명
  final String groupName;

  /// true 이면 DB 에서 appDataWithMine 을 새로 로딩(첫 페이지용)
  final bool isFirst;

  const PageMyApps({
    Key? key,
    required this.groupCode,
    required this.appOrder,
    required this.groupName,
    this.isFirst = false,
  }) : super(key: key);

  @override
  State<PageMyApps> createState() => _PageMyAppsState();
}

class _PageMyAppsState extends State<PageMyApps> {
  List<CachedApplication> _searchApps = [];
  final CommonHelper _helper = CommonHelper.instance;
  late Future<List<CachedApplication>> _appsFuture;

  /// 동시 _initAppData 호출 방지. 여러 PageMyApps 가 동시에 빌드되면
  /// appDataWithMine 이 비어있는 상태에서 중복 초기화가 발생함.
  static Future<void>? _initAppDataFuture;

  @override
  void initState() {
    super.initState();
    _appsFuture = _loadApps();
    CommonHelper.myAppsVersion.addListener(_onMyAppsChanged);
  }

  void _onMyAppsChanged() {
    if (mounted) {
      setState(() {
        _appsFuture = _loadApps();
      });
    }
  }

  @override
  void dispose() {
    CommonHelper.myAppsVersion.removeListener(_onMyAppsChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(PageMyApps oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupCode != widget.groupCode ||
        oldWidget.appOrder != widget.appOrder) {
      setState(() {
        _appsFuture = _loadApps();
      });
    }
  }

  /// DB 초기화(필요시) 후 groupCode 기준으로 앱 목록 반환.
  Future<List<CachedApplication>> _loadApps() async {
    if (widget.isFirst || _helper.appDataWithMine.isEmpty) {
      await _initAppData();
    }

    final List<CachedApplication> result = [];
    for (var myApp in _helper.appDataWithMine) {
      // "전체"(groupCode=A, appOrder=1)만 전체 표시. 사용자 정의 그룹(A, appOrder>1)은 필터링
      final bool matched =
          (widget.groupCode == "A" && widget.appOrder == 1) ||
          (myApp["app_order"].toString() == widget.appOrder.toString() &&
              myApp["app_kind"] == widget.groupCode);
      if (matched) {
        final CachedApplication app = myApp["cached_application"];
        app.appNum = myApp['app_num'].toString();
        app.isOpening = myApp['app_opening'].toString();
        app.appUsePeriod = myApp['app_use_period'].toString();
        app.isFixedApp = myApp['is_fixed_app'].toString();
        result.add(app);
      }
    }
    return result;
  }

  /// appDataWithMine 을 DB 에서 새로 로딩하고 정렬.
  /// 여러 PageMyApps 가 동시에 빌드될 때 중복 초기화를 방지하기 위해
  /// static Future 로 한 번만 실행되도록 직렬화.
  Future<void> _initAppData() async {
    if (_initAppDataFuture != null) {
      await _initAppDataFuture;
      return;
    }
    _initAppDataFuture = _doInitAppData();
    await _initAppDataFuture;
  }

  Future<void> _doInitAppData() async {
    _helper.appDataWithMine.clear();

    if (_helper.appDataWithAll.isEmpty) {
      _helper.appDataWithAll = await _helper.getCachedApplications("A", "");
    }

    final hasMyApps = await SQLHelper.hasMyApps();
    if (!hasMyApps) {
      await SQLHelper.addMyIntrnAppInfo("카카오톡", "com.kakao.talk", "OPN");
      await SQLHelper.addMyIntrnAppInfo(
        "YouTube",
        "com.google.android.youtube",
        "OPN",
      );
      await SQLHelper.addMyIntrnAppInfo("네이버지도", "com.nhn.android.nmap", "OPN");
    }

    final appData = await SQLHelper.getMyAppsFromDB();
    for (var item in appData) {
      final matched = _helper.appDataWithAll
          .where((a) => a["package_name"] == item["package_name"])
          .toList();
      if (matched.isEmpty) continue;

      final Map<String, dynamic> rsltApp = matched[0];
      rsltApp["app_num"] = item["app_num"];
      rsltApp["app_order"] = item["app_order"];
      rsltApp["app_kind"] = item["app_kind"];
      rsltApp["app_user_group"] = item["app_user_group"];
      rsltApp["app_opening"] = item["app_opening"];
      rsltApp["app_use_period"] = item["app_use_period"];
      rsltApp["is_fixed_app"] = item["is_fixed_app"];
      _helper.appDataWithMine.add(rsltApp);
    }

    _helper.appDataWithMine.sort((a, b) {
      final int fixedCmp = b['is_fixed_app'].compareTo(a['is_fixed_app']);
      if (fixedCmp != 0) return fixedCmp;
      final int periodCmp = a['app_use_period'].compareTo(b['app_use_period']);
      return periodCmp != 0 ? periodCmp : b['app_num'].compareTo(a['app_num']);
    });
  }

  void _showDialog(CachedApplication app) {
    _helper.showConfirmationDialog(app, context, () => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        actions: widget.groupCode == "A"
            ? [
                IconButton(
                  icon: const Icon(Icons.search),
                  padding: const EdgeInsets.fromLTRB(0, 0, 26, 0),
                  onPressed: () => showSearch(
                    context: context,
                    delegate: DataSearch(_searchApps),
                  ),
                ),
              ]
            : null,
      ),
      body: FutureBuilder<List<CachedApplication>>(
        future: _appsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: SelectableText.rich(
                TextSpan(
                  text: 'An error occurred!',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }
          final apps = snapshot.data ?? [];
          _searchApps = List.from(apps);

          if (apps.isEmpty) {
            return Center(child: Text('${widget.groupName} 앱이 없습니다.'));
          }

          return ListView.separated(
            itemCount: apps.length,
            separatorBuilder: (_, __) =>
                Divider(color: Colors.grey[350], height: 1, thickness: 1.0),
            itemBuilder: (context, index) {
              final app = apps[index];
              final icon = MemoryImage(base64Decode(app.icon));
              return ListTile(
                tileColor: app.isFixedApp == '1'
                    ? const Color.fromARGB(255, 227, 227, 235)
                    : null,
                leading: Image(image: icon, width: 50, height: 50),
                title: Text(app.appName),
                trailing: IconButton(
                  icon: const Icon(CupertinoIcons.ellipsis_vertical),
                  onPressed: () => _showDialog(app),
                ),
                onTap: () async {
                  await _helper.openApp(app);
                  setState(() {});
                },
              );
            },
          );
        },
      ),
    );
  }
}
