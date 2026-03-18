import 'package:flutter/foundation.dart';
import 'package:app_wallet_app/common/AppCache.dart';
import 'package:app_wallet_app/common/sql_helper.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';

/// 앱 데이터 초기화 및 앱별 조작(열기·삭제·고정·그룹 변경) 비즈니스 로직을 담당하는 싱글톤 클래스.
///
/// 작업 순서:
///   1. [instance]              - 싱글톤 인스턴스 반환 (앱 전체에서 하나만 존재)
///   2. [initIntrnAppInfo]      - 앱 시작 시 전체/분류별 캐시 데이터를 메모리에 로딩
///       └ [getCachedApplications] - AppCache + SQLHelper 를 조합하여 화면용 데이터 생성
///           └ [getListCachedApplication] - Map 리스트에서 CachedApplication 목록만 추출
///   3. [openApp]               - 앱 실행 + [changeOpenStatus] 호출하여 사용 이력 기록
///   4. [changeOpenStatus]      - DB 에 앱 사용 횟수·기간 업데이트 후 메모리 정렬
///   5. [deleteApp]             - DB 에서 앱 삭제 + 메모리 목록에서도 제거
///   6. [fixingApp]             - 앱 고정/해제 토글 (DB + 메모리 동기화)
///   7. [changeGroup]           - 앱 그룹 변경 (DB + 메모리 동기화)
///   8. [showConfirmationDialog]- 앱 롱프레스 시 그룹변경·고정·삭제 다이얼로그 표시
class CommonHelper {
  List<Map<String, dynamic>> appDataWithAll = [];
  List<Map<String, dynamic>> appDataWithMine = [];
  List<Map<String, dynamic>> appDataWithUser = [];
  List<Map<String, dynamic>> appDataWithInst = [];
  List<Map<String, dynamic>> appDataWithSys = [];

  /// "나의 앱" 목록 변경 시 증가. PageMyApps 가 이를 구독하여 갱신.
  static final ValueNotifier<int> myAppsVersion = ValueNotifier(0);

  static CommonHelper? _instance;
  CommonHelper._();
  /// 싱글톤 인스턴스를 반환. 최초 호출 시 인스턴스를 생성하고 이후에는 동일 인스턴스 재사용.
  static CommonHelper get instance {
    return _instance ??= CommonHelper._();
  }

  /// Map 리스트에서 'cached_application' 키에 해당하는 [CachedApplication] 목록만 추출하여 반환.
  /// [getCachedApplications] 가 생성한 Map 목록을 단순 [CachedApplication] 목록으로 변환할 때 사용.
  Future<List<CachedApplication>> getListCachedApplication(
    List<Map<String, dynamic>> appData,
  ) async {
    List<CachedApplication> tmpAllApps = [];

    for (var _item in appData) {
      tmpAllApps.add(_item["cached_application"]);
    }
    return tmpAllApps;
  }

  /// AppCache(캐시) 와 SQLHelper(분류 데이터) 를 조합하여 화면 표시용 앱 목록 생성.
  ///
  /// 작업 순서:
  ///   1. [AppCache.getCachedApps] 로 전체 설치 앱 캐시 목록 조회
  ///   2. packageName 을 키로 Map 생성 (O(1) 빠른 조회 목적)
  ///   3. [SQLHelper.initIntrnAppListData] 로 pKind/pUserGroup 기준 분류 데이터 생성
  ///   4. 분류 데이터 각 항목에 캐시 앱 정보(아이콘 등) 병합하여 최종 목록 구성
  ///   5. 메모리 정리 후 결과 반환
  ///
  /// - pKind: 'A'=전체, 'U'=사용자, 'I'=기관, 'S'=시스템
  /// - pUserGroup: 세부 그룹 코드 (빈 문자열이면 전체)
  Future<List<Map<String, dynamic>>> getCachedApplications(
    String pKind,
    String pUserGroup,
  ) async {
    List<Map<String, dynamic>> appDataWithApplication = [];

    List<CachedApplication> allApps = await AppCache.getCachedApps();

    // Convert allApps to a Map for quick lookup
    Map<String, CachedApplication> allAppsMap = {};
    for (var app in allApps) {
      allAppsMap[app.packageName] = app;
    }

    List<dynamic> appData;

    // 파일 목록을 LIST방식으로 생성하는 비동기 작업
    appData = await SQLHelper.initIntrnAppListData(pKind, pUserGroup, allApps);

    for (var _itemImmutable in appData) {
      Map<String, dynamic> appDataMap = Map.from(
        _itemImmutable,
      ); // _itemImmutable을 변경 가능한 Map으로 변환

      // Now we look up the app in the map, which is an O(1) operation
      var app = allAppsMap[appDataMap["package_name"]];
      if (app != null) {
        // 이제 _item은 변경 가능하므로, 아래 코드는 오류를 발생시키지 않습니다.
        appDataMap["cached_application"] = app;
        appDataWithApplication.add(appDataMap);
      }
    }

    allApps = [];
    appData = [];
    allAppsMap = {};

    return appDataWithApplication;
  }

  /// 앱 시작 시 전체 및 분류별 앱 데이터를 메모리(appDataWith*)에 로딩.
  ///
  /// 작업 순서:
  ///   1. getCachedApplications("A") → appDataWithAll  (전체 앱, 나의 앱/전체 앱 공통)
  ///   2. getCachedApplications("U") → appDataWithUser (사용자 앱)
  ///   3. getCachedApplications("I") → appDataWithInst (구글·삼성 등 기관 앱)
  ///   4. getCachedApplications("S") → appDataWithSys  (시스템 앱)
  Future<int> initIntrnAppInfo() async {
    // 전체 앱 기준 데이터 (나의 앱/전체 앱 공통으로 사용)
    appDataWithAll = await getCachedApplications("A", "");
    // 분류별 데이터 (화면별 리스트용)
    appDataWithUser = await getCachedApplications("U", "");
    appDataWithInst = await getCachedApplications("I", "");
    appDataWithSys = await getCachedApplications("S", "");

    return 0;
  }

  /// 앱을 실행하고 사용 이력(사용 횟수·기간)을 DB 에 기록.
  ///
  /// 작업 순서:
  ///   1. [changeOpenStatus] 호출하여 DB 사용 이력 업데이트 및 메모리 정렬
  ///   2. DeviceApps.openApp 으로 해당 앱 실행
  Future<int> openApp(CachedApplication app) async {
    changeOpenStatus(app);
    await DeviceApps.openApp(app.packageName);
    return 0;
  }

  /// "나의 앱" 목록에 앱을 추가. DB 삽입 후 appDataWithMine 메모리 캐시에도 반영.
  ///
  /// 작업 순서:
  ///   1. [SQLHelper.addMyIntrnAppInfo] 호출
  ///   2. 신규 삽입 시 반환된 Map 을 appDataWithMine 에 추가 후 정렬
  ///   3. [myAppsVersion] 증가하여 "나의 앱" 탭 갱신 트리거
  Future<void> addApp(CachedApplication app, String pType) async {
    final newMap =
        await SQLHelper.addMyIntrnAppInfo(app.appName, app.packageName, pType);
    if (newMap == null) return;

    appDataWithMine.add(newMap);
    appDataWithMine.sort((a, b) {
      final fixedCmp = b['is_fixed_app'].compareTo(a['is_fixed_app']);
      if (fixedCmp != 0) return fixedCmp;
      final periodCmp =
          a['app_use_period'].compareTo(b['app_use_period']);
      return periodCmp != 0
          ? periodCmp
          : b['app_num'].compareTo(a['app_num']);
    });
    myAppsVersion.value++;
  }

  /// "나의 앱" 목록에서 특정 앱을 DB 와 메모리 모두에서 삭제.
  ///
  /// 작업 순서:
  ///   1. [SQLHelper.deleteMyIntrnAppInfo] 로 DB 에서 해당 앱 레코드 삭제
  ///   2. appDataWithMine 에서 해당 앱 인덱스 탐색 후 메모리 목록에서도 제거
  ///   3. [myAppsVersion] 증가하여 "나의 앱" 탭 갱신 트리거
  void deleteApp(CachedApplication appWithIcon) {
    SQLHelper.deleteMyIntrnAppInfo(
      appWithIcon.appName,
      appWithIcon.packageName,
    );

    final indexToRemove = appDataWithMine.indexWhere(
      (app) =>
          app["cached_application"].packageName == appWithIcon.packageName,
    );
    if (indexToRemove != -1) {
      appDataWithMine.removeAt(indexToRemove);
      myAppsVersion.value++;
    }
  }

  /// 앱 고정/해제를 토글. DB 와 메모리(appDataWithMine) 를 동기화.
  ///
  /// 작업 순서:
  ///   1. [SQLHelper.fixMyIntrnAppInfo] 로 DB 의 is_fixed_app 값 0↔1 토글
  ///   2. appDataWithMine 에서 해당 앱 탐색 후 메모리 상의 is_fixed_app 값도 토글
  ///   3. 정렬 후 [myAppsVersion] 증가하여 "나의 앱" 탭 갱신 (고정 앱이 상단에 표시)
  void fixingApp(CachedApplication appWithIcon) {
    SQLHelper.fixMyIntrnAppInfo(appWithIcon.appName, appWithIcon.packageName);

    int indexToFix = appDataWithMine.indexWhere(
      (app) => app["cached_application"].packageName == appWithIcon.packageName,
    );

    if (indexToFix != -1) {
      if (appDataWithMine[indexToFix]["is_fixed_app"] == 0) {
        appDataWithMine[indexToFix]["is_fixed_app"] = 1;
      } else {
        appDataWithMine[indexToFix]["is_fixed_app"] = 0;
      }

      appDataWithMine.sort((a, b) {
        final fixedCmp = b['is_fixed_app'].compareTo(a['is_fixed_app']);
        if (fixedCmp != 0) return fixedCmp;
        final periodCmp =
            a['app_use_period'].compareTo(b['app_use_period']);
        return periodCmp != 0
            ? periodCmp
            : b['app_num'].compareTo(a['app_num']);
      });
      myAppsVersion.value++;
    }
  }

  /// 앱의 그룹 분류를 변경. DB 와 메모리(appDataWithMine) 를 동기화.
  ///
  /// 작업 순서:
  ///   1. [SQLHelper.changeMyGroupInfo] 로 DB 의 app_order·app_kind·app_user_group 업데이트
  ///   2. appDataWithMine 에서 해당 앱 탐색 후 메모리 상의 그룹 정보도 업데이트
  void changeGroup(
    CachedApplication appWithIcon,
    String pAppOrder,
    String pAppKind,
    String pAppUserGroup,
  ) async {
    await SQLHelper.changeMyGroupInfo(
      appWithIcon.appName,
      appWithIcon.packageName,
      pAppOrder,
      pAppKind,
      pAppUserGroup,
    );

    int indexToChange = appDataWithMine.indexWhere(
      (app) => app["cached_application"].packageName == appWithIcon.packageName,
    );

    if (indexToChange != -1) {
      appDataWithMine[indexToChange]["app_order"] = pAppOrder;
      appDataWithMine[indexToChange]["app_kind"] = pAppKind;
      appDataWithMine[indexToChange]["app_user_group"] = pAppUserGroup;
      myAppsVersion.value++;
    }
  }

  /// 앱 실행 시 DB 사용 이력을 업데이트하고 메모리 목록을 재정렬.
  ///
  /// 작업 순서:
  ///   1. [SQLHelper.changeOpenStatusInfo] 로 DB의 app_num·app_opening·use_period_at 업데이트
  ///      및 전체 앱의 app_use_period(사용 경과일) 재계산
  ///   2. 반환된 전체 앱 목록으로 appDataWithMine 의 app_num·app_use_period·is_fixed_app 갱신
  ///   3. [SQLHelper.selectNumStatusInfo] 로 현재 앱의 최신 app_num 조회
  ///   4. appDataWithMine 에 해당 앱이 없으면 → [SQLHelper.addMyIntrnAppInfo] 로 신규 추가
  ///   5. appDataWithMine 을 is_fixed_app > app_use_period > app_num 순으로 정렬
  void changeOpenStatus(CachedApplication appWithIcon) async {
    final appData = await SQLHelper.changeOpenStatusInfo(
      appWithIcon.appName,
      appWithIcon.packageName,
    );

    for (var _item in appData) {
      int indexToPeriod = appDataWithMine.indexWhere(
        (app) => app["cached_application"].packageName == _item["package_name"],
      );

      if (indexToPeriod != -1) {
        appDataWithMine[indexToPeriod]["app_num"] = _item["app_num"];
        appDataWithMine[indexToPeriod]["app_use_period"] =
            _item["app_use_period"];
        appDataWithMine[indexToPeriod]["is_fixed_app"] = _item["is_fixed_app"];
      }
    }

    int iNum = await SQLHelper.selectNumStatusInfo(
      appWithIcon.appName,
      appWithIcon.packageName,
    );

    int indexToChange = appDataWithMine.indexWhere(
      (app) => app["cached_application"].packageName == appWithIcon.packageName,
    );

    if (indexToChange != -1) {
      appDataWithMine[indexToChange]["app_num"] = iNum;
      appDataWithMine[indexToChange]["app_opening"] = 1;
    } else {
      final newMap = await SQLHelper.addMyIntrnAppInfo(
        appWithIcon.appName,
        appWithIcon.packageName,
        "OPN",
      );
      if (newMap != null) {
        newMap["app_opening"] = 1;
        appDataWithMine.add(newMap);
      }
    }

    appDataWithMine.sort((a, b) {
      // Compare 'is_fixed_app' first
      int isFixedAppComparison = b['is_fixed_app'].compareTo(a['is_fixed_app']);

      // If 'is_fixed_app' values are equal, compare 'app_use_period'
      if (isFixedAppComparison == 0) {
        // Compare 'app_use_period'
        int usePeriodComparison = a['app_use_period'].compareTo(
          b['app_use_period'],
        );

        // If 'app_use_period' values are equal, compare 'num'
        if (usePeriodComparison == 0) {
          // Compare 'num'
          return b['app_num'].compareTo(a['app_num']);
        }

        return usePeriodComparison;
      }

      return isFixedAppComparison;
    });
    myAppsVersion.value++;
  }

  /// 앱 아이콘 롱프레스 시 그룹변경·고정·삭제 옵션 다이얼로그를 표시.
  ///
  /// 작업 순서:
  ///   1. tbl_group_info 에서 그룹 목록 조회 (다른 콤보박스와 동일한 소스)
  ///   2. showDialog 로 AlertDialog 표시 (StatefulBuilder 로 드롭다운 상태 관리)
  ///   3. "그룹 변경" 버튼 → 선택한 그룹명을 코드로 변환 후 [changeGroup] 호출
  ///   4. "앱 고정/풀기" 버튼 → [fixingApp] 호출 (is_fixed_app 0↔1 토글)
  ///   5. "앱 삭제" 버튼 → [deleteApp] 호출 (DB + 메모리 삭제)
  ///   6. 각 버튼 처리 후 [notifyStateChanged] 콜백으로 부모 위젯 화면 갱신
  Future<void> showConfirmationDialog(
    CachedApplication appWithIcon,
    BuildContext context,
    VoidCallback notifyStateChanged,
  ) async {
    final groups = await SQLHelper.getAllGroupList();
    final List<String> pageList = groups
        .map((g) => g['group_name'] as String? ?? '')
        .where((n) => n.isNotEmpty)
        .toList();
    final List<String> displayList =
        pageList.isEmpty ? ['전체'] : pageList;

    String dropdownValue = displayList.first;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            titlePadding: EdgeInsets.all(0),
            title: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('   + 변경사항 ', style: TextStyle(fontSize: 20)),
                      CloseButton(onPressed: () => Navigator.of(context).pop()),
                    ],
                  ),
                ),
                Divider(color: Colors.blueGrey),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        "그룹",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: Theme.of(context).primaryColor,
                            width: 1.0,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: dropdownValue,
                            icon: Icon(Icons.arrow_downward),
                            iconSize: 24,
                            elevation: 16,
                            onChanged: (String? newValue) {
                              setState(() {
                                dropdownValue = newValue ?? '전체';
                              });
                            },
                            items: displayList
                                .map<DropdownMenuItem<String>>(
                                  (String value) => DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(
                          backgroundColor: Colors.white38, // 버튼의 배경색을 변경
                          padding: EdgeInsets.symmetric(vertical: 10),
                        ).copyWith(
                          foregroundColor: WidgetStateProperty.all<Color>(
                            Colors.black87,
                          ), // 버튼의 텍스트 및 아이콘 색상을 변경
                        ),
                    child: Text("그룹 변경", style: TextStyle(fontSize: 18)),
                    onPressed: () async {
                      String strAppOrder = "";
                      String strAppKind = "";
                      String strAppUserGroup = "";

                      // tbl_group_info 에서 선택한 그룹명으로 조회 (app_order 사용)
                      final groupInfo =
                          await SQLHelper.getGroupInfoByName(
                            dropdownValue,
                          );

                      if (groupInfo != null) {
                        strAppOrder =
                            groupInfo['app_order']?.toString() ?? "";
                        strAppKind =
                            groupInfo['group_code']?.toString() ?? "";
                        strAppUserGroup =
                            strAppKind + strAppOrder.padLeft(2, '0');
                      }

                      changeGroup(
                        appWithIcon,
                        strAppOrder,
                        strAppKind,
                        strAppUserGroup,
                      );
                      notifyStateChanged(); // state를 변경했음을 알림
                      // 그룹 변경 완료 후 현재 BottomSheet(다이얼로그)를 닫고 이전 화면으로 복귀
                      Navigator.pop(context);
                    },
                  ),
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(
                          backgroundColor: Colors.white54, // 버튼의 배경색을 변경
                          padding: EdgeInsets.symmetric(vertical: 10),
                        ).copyWith(
                          foregroundColor: WidgetStateProperty.all<Color>(
                            Colors.black87,
                          ), // 버튼의 텍스트 및 아이콘 색상을 변경
                        ),
                    child: appWithIcon.isFixedApp == '1'
                        ? Text("앱 풀기", style: TextStyle(fontSize: 18))
                        : Text("앱 고정", style: TextStyle(fontSize: 18)),
                    onPressed: () async {
                      fixingApp(appWithIcon);
                      notifyStateChanged(); // state를 변경했음을 알림
                      // 앱 고정/풀기 완료 후 현재 BottomSheet(다이얼로그)를 닫고 이전 화면으로 복귀
                      Navigator.pop(context);
                    },
                  ),
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(
                          backgroundColor: Colors.white60, // 버튼의 배경색을 변경
                          padding: EdgeInsets.symmetric(vertical: 10),
                        ).copyWith(
                          foregroundColor: WidgetStateProperty.all<Color>(
                            Colors.black87,
                          ), // 버튼의 텍스트 및 아이콘 색상을 변경
                        ),
                    child: Text("앱 삭제", style: TextStyle(fontSize: 18)),
                    onPressed: () async {
                      deleteApp(appWithIcon);
                      notifyStateChanged(); // state를 변경했음을 알림
                      // 앱 삭제 완료 후 현재 BottomSheet(다이얼로그)를 닫고 이전 화면으로 복귀
                      Navigator.pop(context);
                    },
                  ),
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.vpn_key, size: 22),
                    label: Text(
                      "로그인 정보",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.indigo.shade800,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      if (!context.mounted) return;
                      Navigator.of(context).pop(); // 변경사항 다이얼로그 닫기
                      await showLoginInfoDialogForWeb(
                        context,
                        packageName: appWithIcon.packageName,
                        appWebName: appWithIcon.appName,
                      );
                    },
                  ),
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(
                          backgroundColor: Colors.white70, // 버튼의 배경색을 변경
                          padding: EdgeInsets.symmetric(vertical: 10),
                        ).copyWith(
                          foregroundColor: WidgetStateProperty.all<Color>(
                            Colors.black87,
                          ), // 버튼의 텍스트 및 아이콘 색상을 변경
                        ),
                    child: Text("닫기", style: TextStyle(fontSize: 18)),
                    onPressed: () async {
                      // 아무 작업 없이 현재 BottomSheet(다이얼로그)를 닫고 이전 화면으로 복귀
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
          );
        },
      ),
    );

    notifyStateChanged(); // state를 변경했음을 알림
  }

  /// 웹 사이트별 로그인 정보(아이디/비밀번호 등) 관리 다이얼로그를 표시.
  Future<void> showLoginInfoDialogForWeb(
    BuildContext context, {
    required String packageName,
    required String appWebName,
  }) async {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => _LoginInfoDialog(
        webUrl: packageName,
        appWebName: appWebName,
      ),
    );
  }
}

/// 로그인 정보(아이디/비밀번호/메모) 저장·조회 다이얼로그.
class _LoginInfoDialog extends StatefulWidget {
  const _LoginInfoDialog({
    required this.webUrl,
    required this.appWebName,
  });

  final String webUrl;
  final String appWebName;

  @override
  State<_LoginInfoDialog> createState() => _LoginInfoDialogState();
}

class _LoginInfoDialogState extends State<_LoginInfoDialog> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    final list =
        await SQLHelper.getAppWebLoginInfos(widget.webUrl);
    if (mounted) {
      setState(() {
        _items = list;
        _loading = false;
      });
    }
  }

  Future<void> _showAddEditDialog({Map<String, dynamic>? item}) async {
    final isEdit = item != null;
    final usernameController =
        TextEditingController(text: item?['username']?.toString() ?? '');
    final passwordController =
        TextEditingController(text: item?['password']?.toString() ?? '');
    final memoController =
        TextEditingController(text: item?['memo']?.toString() ?? '');

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? '로그인 정보 수정' : '로그인 정보 추가'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: '아이디/이메일',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.none,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: 12),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                textCapitalization: TextCapitalization.none,
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: 12),
              TextField(
                controller: memoController,
                decoration: InputDecoration(
                  labelText: '메모 (선택)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              final username = usernameController.text.trim();
              final password = passwordController.text.trim();
              final memo = memoController.text.trim();
              await SQLHelper.saveAppWebLoginInfo(
                id: isEdit ? item['id'] as int? : null,
                webUrl: widget.webUrl,
                appWebName: widget.appWebName,
                username: username.isEmpty ? null : username,
                password: password.isEmpty ? null : password,
                memo: memo.isEmpty ? null : memo,
              );
              if (ctx.mounted) Navigator.of(ctx).pop();
              _loadItems();
            },
            child: Text('저장'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> item) async {
    final username = item['username']?.toString() ?? '(없음)';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('삭제 확인'),
        content: Text(
          '아이디 "$username" 로그인 정보를 삭제할까요?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed == true && item['id'] != null) {
      await SQLHelper.deleteAppWebLoginInfo(item['id'] as int);
      _loadItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('로그인 정보 - ${widget.appWebName}'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'URL: ${widget.webUrl}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            SizedBox(height: 16),
            if (_loading)
              Center(child: CircularProgressIndicator())
            else if (_items.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  '저장된 로그인 정보가 없습니다.\n"추가" 버튼으로 저장하세요.',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _items.length,
                  itemBuilder: (ctx, i) {
                    final it = _items[i];
                    final username = it['username']?.toString() ?? '(없음)';
                    final hasPw =
                        (it['password']?.toString() ?? '').isNotEmpty;
                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(username),
                        subtitle: hasPw
                            ? Text('비밀번호 ****')
                            : it['memo']?.toString().isNotEmpty == true
                                ? Text(it['memo'] as String)
                                : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, size: 20),
                              onPressed: () => _showAddEditDialog(item: it),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, size: 20),
                              onPressed: () => _confirmDelete(it),
                            ),
                          ],
                        ),
                        onTap: () => _showAddEditDialog(item: it),
                      ),
                    );
                  },
                ),
              ),
            SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _showAddEditDialog(),
              icon: Icon(Icons.add),
              label: Text('추가'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('닫기'),
        ),
      ],
    );
  }
}
