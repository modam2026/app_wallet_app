# 커서를 이 노트북에 설치한 후 현재 프로젝트를 수정하면서 여기에 적은 대화 내용을 파일로 전부 받아 낼 수 있나?

# 대화 요약 및 수정 사항 (app_wallet_app)

이 문서는 Cursor 에이전트와의 대화에서 다룬 주제와 실제로 적용한 코드 수정 사항을 정리한 요약입니다.

---

## 1. 주제별 요약

### 1.1 앱 구동 시 프레임 드롭 / 초기화 최적화

- **문제**: `Skipped XXX frames`, 메인 스레드에서 무거운 작업으로 인한 끊김.
- **대응**: `main.dart`에서 `runApp` 전에 실행되던 **앱 캐시 초기화**(`AppCache.cacheAllApps()` / `updateCacheOnAppChange()`)를 제거.
- **결과**: 앱을 먼저 띄우고, 화면에서 실제로 캐시가 필요할 때만 비동기로 로딩하도록 변경.

### 1.2 앱 캐시(AppCache) – “없으면 만들고, 있으면 재사용”

- **동작**: `AppCache.getCachedApps()` 내부에서 `SharedPreferences`에 `cached_apps`가 없을 때만 `cacheAllApps()` 호출.
- **의미**: 캐시는 이미 “없으면 만들고, 있으면 건드리지 않음” 구조로 동작 중.

### 1.3 나의 앱 리스트 DB – “없을 때만 기본 앱 등록”

- **조건**: `SQLHelper.hasMyApps()`로 `tbl_my_application_info`에 데이터가 있는지 확인.
- **로직**: `hasMyApps == false`일 때만 카카오톡, YouTube, 네이버지도 등 기본 앱을 DB에 한 번 등록.
- **제거**: `DicService.isDataInit` 플래그 제거 → 조건은 **DB에 데이터가 있는지 여부만** 사용.

### 1.4 전체 앱 리스트에서 “나의 앱”으로 추가 시 DB에 안 들어가던 문제

- **원인**: `SQLHelper.addMyIntrnAppInfo()`가 `commonHelper.appDataWithAll`만 보고 INSERT하는데, `appDataWithAll`이 비어 있는 경우가 많았음.
- **대응**: `CommonHelper.initIntrnAppInfo()`에서 **전체 앱**도 로딩하도록 `appDataWithAll = await getCachedApplications("A", "");` 추가.
- **추가**: `MgrAppWebPage._initInternalAppInfo()`에서 `await commonHelper.initIntrnAppInfo()`로 완료될 때까지 기다리도록 수정.

### 1.5 나의 앱 리스트가 재실행 후 비어 보이던 문제 (is_first_input)

- **원인**: `getMyAppsFromDB()`가 `WHERE is_first_input = 0` 조건으로만 조회하고, `updateMyIntrnAppStts(1)`로 전부 1로 바꿔서 다음 실행 시 조회 결과가 0건이 됨.
- **대응**:
  - `getMyAppsFromDB()`에서 **`WHERE is_first_input = 0` 조건 제거** → 테이블에 있는 모든 “나의 앱” 행 조회.
  - `PageMyUserDef`에서 `updateMyIntrnAppStts(0/1)` 호출 제거.

### 1.6 나의 앱 리스트가 매번 비어 보이던 문제 (appDataWithAll / appDataWithMine)

- **원인**: 재실행 후 `appDataWithAll`이 비어 있으면 DB에서 읽은 행을 `appDataWithAll`과 조인할 수 없어 리스트가 0개로 나옴. 또한 `appDataWithMine`을 매번 비우지 않아 setState 시 중복 누적.
- **대응**:
  - `_getInstalledApplications()` 시작 시 `commonHelper.appDataWithMine.clear()` 호출.
  - `appDataWithAll.isEmpty`일 때만 `getCachedApplications("A", "")`로 전체 앱 캐시 로딩.
  - 위와 함께 `getMyAppsFromDB()` 조건 제거로 재실행 후에도 리스트가 유지되도록 함.

### 1.7 ... 버튼(ellipsis) 누를 때마다 리스트가 늘어나던 문제

- **원인**: 다이얼로그에서 `setState()` → FutureBuilder 재실행 → `_getInstalledApplications()`가 다시 호출되면서 `appDataWithMine`에 **clear 없이** 계속 add만 해서 중복 증가.
- **대응**: `_getInstalledApplications()` 맨 앞에서 `commonHelper.appDataWithMine.clear()` 호출하여 매번 새로 구성.

### 1.8 flutter install vs flutter run / DB 유지

- **flutter install**: 로그에 `Uninstalling old version...`이 뜨면 기존 앱(및 내부 DB·캐시)이 삭제된 뒤 새로 설치됨 → “나의 앱 리스트” 데이터도 삭제됨.
- **flutter run** (같은 빌드 타입·같은 서명): 기존 앱 위에 덮어쓰기 → DB·캐시 유지.
- **Play 스토어 업데이트**: 같은 패키지·같은 서명으로만 업데이트되므로 **uninstall 없음** → 고객이 등록한 “나의 앱 리스트”는 유지됨.

### 1.9 릴리즈 빌드 에러 (R8 / device_apps 리소스)

- **R8 Missing classes**: `sql_conn` 플러그인의 jTDS 관련 클래스(jcifs, org.ietf.jgss 등)가 없어서 발생. `android/app/proguard-rules.pro`에 `-dontwarn` 규칙 추가로 해결.
- **android:attr/lStar not found**: `device_apps` 플러그인 `compileSdkVersion`을 30 → 33으로 상향.

---

## 2. 수정한 파일 목록 및 변경 요약

| 파일 | 변경 요약 |
|------|------------|
| `lib/main.dart` | `runApp` 전 `AppCache.isAllAppsCached()` / `cacheAllApps()` / `updateCacheOnAppChange()` 호출 제거. `AppCache` import 제거. |
| `lib/common/AppCache.dart` | `getCachedApps()` 내부에서 `cached_apps`가 null일 때 `cacheAllApps()` 호출하도록 지연 초기화 추가. |
| `lib/common/dic_service.dart` | `isDataInit` 필드 제거. |
| `lib/common/common_helper.dart` | `initIntrnAppInfo()`에서 `appDataWithAll = await getCachedApplications("A", "");` 추가. |
| `lib/common/sql_helper.dart` | `hasMyApps()` 추가. `getMyAppsFromDB()`에서 `WHERE is_first_input = 0` 조건 제거. |
| `lib/sub/PageMyUserDef.dart` | `DicService` 제거, `hasMyApps()`만 사용. `appDataWithMine.clear()` 및 `appDataWithAll` 비어 있을 때 로딩 추가. `updateMyIntrnAppStts` 호출 제거. 기본 앱 등록 시 `updateMyIntrnAppStts(0)` 제거. |
| `lib/sub/MgrAppWebPage.dart` | `_initInternalAppInfo()`에서 `await commonHelper.initIntrnAppInfo()` 사용. |
| `android/app/proguard-rules.pro` | 신규 생성. jcifs / org.ietf.jgss 관련 `-dontwarn` 규칙 추가. |
| `plugins/device_apps/android/build.gradle` | `compileSdkVersion` 30 → 33. |
| `plugins/sql_conn/android/build.gradle` | `compileSdkVersion` 30 → 33. |

---

## 3. 테이블/캐시 정리

- **DB 파일**: `db_app_management.db` (sqflite, 앱 내부 저장소)
- **테이블**: `tbl_my_application_info` — “나의 앱 리스트” 저장.
- **캐시 키**: SharedPreferences `cached_apps` — 설치 앱 목록(아이콘 base64 등) 캐시.

---

## 4. 참고

- “나의 앱 리스트”는 **앱을 삭제(uninstall)하면** 내부 저장소와 함께 사라집니다. 데이터를 재설치 후에도 유지하려면 서버/클라우드 동기화 등 별도 설계가 필요합니다.
- 에뮬레이터에서만 테스트할 때는 같은 AVD, 같은 `flutter run`(또는 같은 서명의 설치)로 반복 실행하면 DB가 유지됩니다.
