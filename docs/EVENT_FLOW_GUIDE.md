# 이벤트 흐름 및 작업 순서 가이드

> 저장소: modam2026/app_wallet_app  
> 작성일: 2026-03-12

---

## 1. 폰 화면에서 앱 아이콘 클릭 (앱 최초 실행)

### 전체 흐름도

```
폰 화면 앱 아이콘 클릭
        │
        ▼
[Android OS]
  앱 프로세스 시작
        │
        ▼
[main.dart] main()
  ① WidgetsFlutterBinding.ensureInitialized()
  ② DicService 를 ChangeNotifierProvider 로 등록
  ③ runApp(MyApp)
        │
        ▼
[main.dart] MyApp.build()
  ④ MaterialApp 생성
  ⑤ home: MgrAppWebPage() 설정
        │
        ▼
[MgrAppWebPage.dart] MgrAppWebPage (StatefulWidget)
  ⑥ _MgrAppWebPageState.initState() 실행
        │
        ├─ ⑦ TabController 생성 (탭 3개: 나의앱·전체앱·웹)
        ├─ ⑧ 탭 변경 리스너 등록 (_onTabChanged)
        ├─ ⑨ 1초 Timer 시작 (AppBar 시계 갱신용)
        ├─ ⑩ _initAsync() 호출
        │       └─ _initInternalAppInfo() 호출
        │               │
        │               ▼
        │       [common_helper.dart] CommonHelper.initIntrnAppInfo()
        │         ⑪ getCachedApplications("A") → appDataWithAll
        │         ⑫ getCachedApplications("U") → appDataWithUser
        │         ⑬ getCachedApplications("I") → appDataWithInst
        │         ⑭ getCachedApplications("S") → appDataWithSys
        │               │
        │               ▼
        │       getCachedApplications() 내부 작업:
        │         ⑮ AppCache.getCachedApps() 호출
        │               │
        │               ▼
        │         [AppCache.dart]
        │           - SharedPreferences 에서 'cached_apps' 조회
        │           - 캐시 없으면(최초 실행) → DeviceApps.getInstalledApplications()
        │             로 폰의 전체 설치 앱 목록 읽기 → base64 아이콘 인코딩
        │             → SharedPreferences 에 JSON 저장 (cacheAllApps)
        │           - 캐시 있으면 → JSON 역직렬화하여 CachedApplication 목록 반환
        │               │
        │               ▼
        │         ⑯ SQLHelper.initIntrnAppListData() 호출
        │               │
        │               ▼
        │         [sql_helper.dart]
        │           - 캐시 앱 목록을 순회하며 makeIntrnAppListData() 로
        │             패키지명 분석 → 앱 분류(그룹) 코드 결정
        │           - pKind 에 맞는 앱만 필터링하여 Map 목록 반환
        │               │
        │               ▼
        │         ⑰ 분류 데이터 + 캐시 앱 정보 병합
        │           (appDataMap["cached_application"] = app)
        │               │
        │               ▼
        │         ⑱ setState() → 화면 재빌드
        │
        └─ ⑲ _loadGroupNamesForTab(0) 호출
                └─ SQLHelper.getDistinctAppUserGroups()
                   → DB 에서 그룹 코드 목록 조회
                   → _groupListForDrawer 에 셋팅
                        │
                        ▼
        ⑳ MgrAppWebPage.build()
           - AppBar: 날짜/시간 표시
           - TabBar: 나의앱 / 전체앱 / 웹
           - TabBarView:
               └─ TabMyAppPage (나의 앱 탭)
               └─ TabAllAppPage (전체 앱 탭)
               └─ TabWebPage (웹 탭)
           - endDrawer: DrawerPageGrp / DrawerPage
```

---

### 단계별 설명

| 단계 | 클래스/파일 | 설명 |
|---|---|---|
| ① | `main.dart` | Flutter 엔진과 위젯 바인딩 초기화. async main 사용을 위해 필수 |
| ② | `main.dart` | `DicService`(알림·콜백 상태 관리) 를 앱 전체에서 사용할 수 있도록 Provider 등록 |
| ③~⑤ | `main.dart` | `MaterialApp` 생성 후 첫 화면으로 `MgrAppWebPage` 지정 |
| ⑥ | `MgrAppWebPage` | StatefulWidget 의 `initState` 진입 - 모든 초기화의 시작점 |
| ⑦~⑨ | `MgrAppWebPage` | 탭 컨트롤러, 이벤트 리스너, 1초 타이머 초기화 |
| ⑩ | `MgrAppWebPage` | 비동기 앱 데이터 초기화 시작 |
| ⑪~⑭ | `CommonHelper` | 전체/분류별 앱 데이터를 메모리에 로딩 (A=전체, U=사용자, I=기관, S=시스템) |
| ⑮ | `AppCache` | SharedPreferences 캐시 조회. **최초 실행**이면 폰의 전체 앱을 직접 읽어 캐시 생성 |
| ⑯ | `SQLHelper` | 캐시 앱 목록을 패키지명 분석으로 그룹 분류 (금융/SNS/구글 등) |
| ⑰ | `CommonHelper` | 분류 데이터에 아이콘 등 캐시 정보를 합쳐 화면용 최종 데이터 구성 |
| ⑱ | `MgrAppWebPage` | `setState` 로 화면 재빌드 |
| ⑲ | `MgrAppWebPage` | DB 에서 그룹 코드 목록 조회 → Drawer 팝업 메뉴 항목 셋팅 |
| ⑳ | `MgrAppWebPage` | 최종 화면 렌더링 (AppBar + TabBar + 탭 화면들) |

---

### 최초 실행 vs 재실행 차이

```
최초 실행 (앱 설치 후 처음):
  SharedPreferences 캐시 없음
    → DeviceApps.getInstalledApplications() 로 폰 전체 앱 스캔 (시간 소요)
    → base64 아이콘 인코딩
    → SharedPreferences 에 저장
    → 이후 재실행 시에는 캐시에서 빠르게 로딩

재실행:
  SharedPreferences 캐시 있음
    → JSON 역직렬화만으로 빠르게 앱 목록 로딩
```

---

## 2. "그룹관리" 버튼 클릭

### 전체 흐름도

```
AppBar 우측 상단 "그룹관리" 버튼 클릭
        │
        ▼
[MgrAppWebPage.dart] 버튼 onPressed:
  ① setState(() { _isGroupDrawer = true; })
     → _isGroupDrawer 플래그를 true 로 설정 (그룹관리 Drawer 표시 구분용)
  ② Scaffold.of(context).openEndDrawer()
     → 우측 endDrawer 패널 열기
        │
        ▼
[MgrAppWebPage.dart] endDrawer 빌드:
  ③ _isGroupDrawer == true 이므로
     DrawerPageGrp 위젯 표시
       - onItemSelected: refreshThisPage (완료 후 콜백)
       - groupList: _groupListForDrawer (DB 에서 읽어온 그룹 목록)
        │
        ▼
[DrawerPageGrp.dart] DrawerPageGrp.initState()
  ④ 초기 상태 설정 (텍스트 컨트롤러 초기화)
        │
        ▼
[DrawerPageGrp.dart] DrawerPageGrp.build()
  ⑤ _menuGroupList getter 실행
     → widget.groupList 를 팝업 메뉴 항목으로 변환
     → 그룹 없으면 빈 목록
        │
        ▼
  ⑥ UI 표시:
     ┌─────────────────────────────┐
     │  그룹 관리                    │
     │  ① 그룹명  [선택 ▼]          │
     │  ② 사이트명 [입력]            │
     │  ③ 사이트URL [입력]           │
     │  [     추가     ]            │
     └─────────────────────────────┘

사용자가 그룹 선택 → 사이트명 입력 → URL 입력 → "추가" 버튼 클릭
        │
        ▼
[DrawerPageGrp.dart] 추가 버튼 onPressed:
  ⑦ strTagCtrl = strSeletedClass (선택된 그룹 코드 사용)
  ⑧ SQLWebHelper.chkCaption(strWebUrlCtrl) 호출
     → tbl_web_info 에서 동일 URL 존재 여부 확인
        │
        ├─ URL 형식 불일치 → DicService.showCheckUrl() (토스트 메시지)
        ├─ 그룹 미선택  → DicService.showCheckItems("그룹명") (토스트 메시지)
        ├─ 사이트명 비어있음 → DicService.showCheckItems("사이트명") (토스트 메시지)
        ├─ URL 비어있음 → DicService.showCheckItems("사이트URL") (토스트 메시지)
        ├─ URL 중복 → DicService.showExistStatus() (토스트 메시지)
        │
        └─ 이상 없음:
              ⑨ SQLWebHelper.createWebInfo(caption, webUrl, tag) 호출
                 → tbl_web_info 에 INSERT
                        │
                        ▼
              ⑩ captionController.text = "" (입력창 초기화)
              ⑪ Navigator.pop(context) → Drawer 닫기
              ⑫ onItemSelected() 콜백 호출
                        │
                        ▼
              [MgrAppWebPage.dart] refreshThisPage()
              ⑬ DicService.callbackStatus = true
              ⑭ DicService.callNotifyListeners()
                        │
                        ▼
              [TabWebPage.dart] build() 에서
              ⑮ callbackStatus == true 감지
                 → refreshWebUrls() 호출
                 → SQLWebHelper.getWebInfos() 로 DB 재조회
                 → _captions 갱신
                 → setState() → 웹 탭 화면 재빌드
```

---

### 단계별 설명

| 단계 | 클래스/파일 | 설명 |
|---|---|---|
| ① | `MgrAppWebPage` | `_isGroupDrawer = true` 로 Drawer 종류 구분 (그룹관리 vs 웹등록) |
| ② | `MgrAppWebPage` | `openEndDrawer()` 로 우측 패널(Drawer) 오픈 |
| ③ | `MgrAppWebPage` | `_isGroupDrawer` 플래그에 따라 `DrawerPageGrp` 또는 `DrawerPage` 표시 결정 |
| ④ | `DrawerPageGrp` | Drawer 위젯 초기화 |
| ⑤ | `DrawerPageGrp` | `_groupListForDrawer` (DB 에서 읽어온 그룹 목록) 를 팝업 메뉴 항목으로 변환 |
| ⑥ | `DrawerPageGrp` | 그룹명 선택 → 사이트명 → URL 순서로 입력하는 UI 렌더링 |
| ⑦ | `DrawerPageGrp` | 선택된 그룹 코드를 tag 값으로 사용 (예: 'd'=매일, 'U11'=금융) |
| ⑧ | `SQLWebHelper` | `tbl_web_info` 에서 동일 URL 중복 여부 확인 |
| ⑨ | `SQLWebHelper` | `tbl_web_info` 에 신규 웹사이트 INSERT |
| ⑩~⑪ | `DrawerPageGrp` | 입력창 초기화 후 Drawer 닫기 |
| ⑫ | `DrawerPageGrp` | `onItemSelected` 콜백 호출 → 부모(`MgrAppWebPage`)에 작업 완료 알림 |
| ⑬~⑭ | `MgrAppWebPage` | `DicService` 의 callbackStatus 를 true 로 설정하고 리스너들에게 알림 |
| ⑮ | `TabWebPage` | `DicService` 변경 감지 → `refreshWebUrls()` → DB 재조회 → 화면 갱신 |

---

### "웹등록" 버튼과의 차이점

```
그룹관리 버튼 클릭:
  _isGroupDrawer = true
  → DrawerPageGrp 표시
  → DB 그룹 코드(_groupListForDrawer)를 팝업 메뉴로 선택
  → tbl_web_info 에 그룹 코드 포함하여 저장

웹등록 버튼 클릭:
  _isGroupDrawer = false
  → DrawerPage 표시
  → 고정된 목록(매일/매주/매월/가끔/게임)을 팝업 메뉴로 선택
  → tbl_web_info 에 태그 코드(d/w/m/e/g)로 저장
```

---

## 3. 두 이벤트의 공통 데이터 흐름

```
[SharedPreferences]          [SQLite: webinfo.db]       [SQLite: db_app_management.db]
  cached_apps                  tbl_web_info               tbl_my_application_info
       │                            │                              │
       │ AppCache                   │ SQLWebHelper                 │ SQLHelper
       │ getCachedApps()            │ getWebInfos()                │ getMyAppsFromDB()
       │ cacheAllApps()             │ createWebInfo()              │ addMyIntrnAppInfo()
       ▼                            ▼                              ▼
  [CommonHelper]              [TabWebPage]               [TabMyAppPage / TabAllAppPage]
  appDataWithAll/Mine/etc      _captions 목록              각 분류별 앱 목록
       │                            │                              │
       └────────────────────────────┴──────────────────────────────┘
                                    │
                              [DicService]
                           callbackStatus / notifyListeners
                                    │
                              [MgrAppWebPage]
                              화면 전체 갱신
```
