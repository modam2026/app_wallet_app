import 'dart:convert';
import 'package:app_wallet_app/common/AppCache.dart';
import 'package:app_wallet_app/common/DataSearch.dart';
import 'package:app_wallet_app/common/common_helper.dart';
import 'package:app_wallet_app/common/sql_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// "전체 앱" 탭에서 그룹별로 설치된 앱을 표시하는 단일 동적 페이지.
///
/// 작업 순서:
///   1. [initState]   - [groupCode] / [appOrder] 기준으로 [_appsFuture] 초기화
///   2. [_loadApps]   - appDataWithAll 이 비어있으면 로딩 후 groupCode·app_order 로 필터
///   3. "전체"(A, appOrder 1) → 전체 표시 / 사용자 정의(A, appOrder>1) → 나의 앱 DB 필터 / 그 외 → app_kind+app_order 매칭
///   4. [build]       - FutureBuilder 로 ListView 렌더링, 각 앱에 나의 앱 추가/삭제 버튼
///   5. [didUpdateWidget] - groupCode·appOrder 변경 시 목록 갱신
class PageAllApps extends StatefulWidget {
  /// tbl_group_info.group_code 와 동일한 값 (예: "A", "G", "M", "B", "C" …)
  final String groupCode;

  /// 화면 AppBar 에 표시할 그룹명
  final String groupName;

  /// tbl_group_info.app_order - 은행/카드/증권 등 동일 group_code 내 구분용
  final int appOrder;

  const PageAllApps({
    Key? key,
    required this.groupCode,
    required this.groupName,
    this.appOrder = 1,
  }) : super(key: key);

  @override
  State<PageAllApps> createState() => _PageAllAppsState();
}

class _PageAllAppsState extends State<PageAllApps> {
  List<CachedApplication> _searchApps = [];
  final CommonHelper _helper = CommonHelper.instance;
  late Future<List<CachedApplication>> _appsFuture;
  bool _showGroupName = false;
  final Map<String, String> _appGroupNames = {};

  @override
  void initState() {
    super.initState();
    _appsFuture = _loadApps();
  }

  @override
  void didUpdateWidget(PageAllApps oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupCode != widget.groupCode ||
        oldWidget.appOrder != widget.appOrder) {
      setState(() {
        _appsFuture = _loadApps();
      });
    }
  }

  /// appDataWithAll 에서 groupCode·app_order 기준으로 필터링 후 앱 목록 반환.
  /// - "전체"(A, appOrder 1) → 전체 표시
  /// - 사용자 정의 그룹(A, appOrder > 1) → 나의 앱 DB에서 해당 그룹 앱만 표시
  /// - 기본 그룹(B, C, G 등) → app_kind + app_order 매칭
  Future<List<CachedApplication>> _loadApps() async {
    if (_helper.appDataWithAll.isEmpty) {
      _helper.appDataWithAll =
          await _helper.getCachedApplications('A', '');
    }

    final groups = await SQLHelper.getAllGroupList();
    final groupMap = <String, String>{};
    for (var g in groups) {
      final key = '${g['group_code']}_${g['app_order']}';
      groupMap[key] = g['group_name']?.toString() ?? '';
    }

    _appGroupNames.clear();

    // 사용자 정의 그룹(groupCode A, appOrder > 1): 나의 앱 DB에서 해당 그룹 앱만 표시
    final bool isUserDefinedGroup =
        widget.groupCode == "A" && widget.appOrder > 1;

    if (isUserDefinedGroup) {
      final myApps = await SQLHelper.getMyAppsFromDB();
      final packageNames = myApps
          .where((m) =>
              (m["app_kind"]?.toString() ?? "") == "A" &&
              m["app_order"].toString() == widget.appOrder.toString())
          .map((m) => m["package_name"] as String)
          .toSet();

      final result = <CachedApplication>[];
      for (var item in _helper.appDataWithAll) {
        final pkg = item["package_name"] as String?;
        if (pkg != null && packageNames.contains(pkg)) {
          result.add(item["cached_application"]);
          _appGroupNames[pkg] = widget.groupName;
        }
      }
      return result;
    }

    // "전체"(A, appOrder 1) 또는 기본 그룹(B, C, G 등): appDataWithAll에서 필터
    final List<CachedApplication> result = [];
    for (var item in _helper.appDataWithAll) {
      final bool matched =
          (widget.groupCode == "A" && widget.appOrder == 1) ||
          (item["app_kind"] == widget.groupCode &&
              item["app_order"].toString() == widget.appOrder.toString());
      if (matched) {
        final app = item["cached_application"];
        final pkg = item["package_name"] as String?;
        result.add(app);
        if (pkg != null) {
          final key =
              '${item["app_kind"]}_${item["app_order"]}';
          _appGroupNames[pkg] =
              groupMap[key] ?? widget.groupName;
        }
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_special, size: 22, color: Colors.amber[700]),
            const SizedBox(width: 8),
            Text(
              widget.groupName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: widget.groupCode == "A"
            ? [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _showGroupName,
                        onChanged: (v) =>
                            setState(() => _showGroupName = v ?? false),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _showGroupName = !_showGroupName),
                      child: Text(
                        '그룹보기',
                        style: TextStyle(fontSize: 14, color: Colors.black),
                      ),
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      icon: const Icon(Icons.search),
                      padding: const EdgeInsets.fromLTRB(0, 0, 26, 0),
                      onPressed: () => showSearch(
                        context: context,
                        delegate: DataSearch(_searchApps),
                      ),
                    ),
                  ],
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
            return Center(
              child: Text('${widget.groupName} 앱이 없습니다.'),
            );
          }

          return ListView.separated(
            itemCount: apps.length,
            separatorBuilder: (_, __) => Divider(
              color: Colors.grey[350],
              height: 1,
              thickness: 1.0,
            ),
            itemBuilder: (context, index) {
              final app = apps[index];
              final icon = MemoryImage(base64Decode(app.icon));
              return FutureBuilder<bool>(
                future: SQLHelper.isAppInDatabase(
                  app.appName,
                  app.packageName,
                ),
                builder: (context, dbSnapshot) {
                  if (dbSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const ListTile(
                      leading: SizedBox(
                        width: 50,
                        height: 50,
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                    );
                  }
                  if (dbSnapshot.hasError) {
                    return ListTile(
                      title: Text(app.appName),
                      subtitle: const Text('오류'),
                    );
                  }
                  final isInDb = dbSnapshot.data ?? false;
                  return ListTile(
                    leading: Image(
                      image: icon,
                      width: 50,
                      height: 50,
                    ),
                    title: Text(app.appName),
                    subtitle: _showGroupName
                        ? Text(
                            _appGroupNames[app.packageName] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          )
                        : null,
                    trailing: IconButton(
                      icon: Icon(
                        isInDb
                            ? CupertinoIcons.minus_circled
                            : CupertinoIcons.add_circled_solid,
                      ),
                      onPressed: () async {
                        if (isInDb) {
                          await SQLHelper.deleteMyIntrnAppInfo(
                            app.appName,
                            app.packageName,
                          );
                          _helper.deleteApp(app);
                        } else {
                          await _helper.addApp(app, "All");
                        }
                        setState(() {});
                      },
                    ),
                    onTap: () async {
                      await _helper.openApp(app);
                      setState(() {});
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
