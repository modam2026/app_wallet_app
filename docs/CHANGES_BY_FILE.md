# (질문) 여기 파일들은 수정되거나 새로 만들어진 파일인데 이 파일들의 이름과 변경내역을 받을 수 있나?

# 파일별 변경 내역

이번 대화에서 **수정되거나 새로 만들어진 파일**의 이름과 변경 내용을 정리했습니다.

---

## 1. CHAT_SUMMARY.md (신규)

- **경로**: `docs/CHAT_SUMMARY.md`
- **변경**: 신규 생성 (+94줄)
- **내용**: 대화 주제별 요약, 수정 파일 목록, 테이블/캐시 정리, 참고 사항을 담은 요약 문서.

---

## 2. proguard-rules.pro (신규)

- **경로**: `android/app/proguard-rules.pro`
- **변경**: 신규 생성 (+11줄)
- **내용**:
  - R8 릴리즈 빌드 시 `sql_conn`(jTDS) 관련 Missing class 경고 제거.
  - `-dontwarn` 규칙 추가: jcifs.Config, jcifs.smb.*, org.ietf.jgss.* (GSSContext, GSSCredential, GSSException, GSSManager, GSSName, Oid).

---

## 3. sql_helper.dart (수정)

- **경로**: `lib/common/sql_helper.dart`
- **변경**: +14줄, -1줄
- **내용**:
  - **추가**: `hasMyApps()` — `tbl_my_application_info`의 행 개수를 세어, 데이터가 있으면 true, 없으면 false 반환.
  - **수정**: `getMyAppsFromDB()` — `WHERE is_first_input = 0` 조건 제거. 테이블에 있는 모든 “나의 앱” 행을 조회하도록 변경.

---

## 4. android/build.gradle (수정) — 플러그인

- **경로**: `plugins/device_apps/android/build.gradle`, `plugins/sql_conn/android/build.gradle`
- **변경**: 각 +1줄, -1줄
- **내용**:
  - **device_apps**: `compileSdkVersion` 30 → 33 (android:attr/lStar 등 리소스 호환).
  - **sql_conn**: `compileSdkVersion` 30 → 33.

---

## 5. MgrAppWebPage.dart (수정)

- **경로**: `lib/sub/MgrAppWebPage.dart`
- **변경**: +2줄, -2줄
- **내용**:
  - `_initInternalAppInfo()`에서 `commonHelper.initIntrnAppInfo()` 호출 시 **await** 추가.
  - 앱 시작 시 전체 앱/분류별 캐시(`appDataWithAll` 등)가 로딩 완료된 뒤에 화면이 갱신되도록 변경.

---

## 6. PageMyUserDef.dart (수정)

- **경로**: `lib/sub/PageMyUserDef.dart`
- **변경**: +10줄, -10줄 (리팩터링)
- **내용**:
  - **제거**: `DicService` import 및 사용. `isDataInit` 대신 `hasMyApps()`만 사용.
  - **추가**: `_getInstalledApplications()` 시작 시 `commonHelper.appDataWithMine.clear()`.
  - **추가**: `appDataWithAll.isEmpty`일 때 `getCachedApplications("A", "")`로 전체 앱 캐시 로딩.
  - **제거**: 기본 앱 등록 시 `updateMyIntrnAppStts(0)` 호출.
  - **제거**: `app_data.isNotEmpty`일 때 `updateMyIntrnAppStts(1)` 호출.
  - **결과**: 리스트 중복 방지, 재실행 후에도 “나의 앱 리스트” 유지, ... 버튼 눌러도 개수 불어나지 않음.

---

## 7. main.dart (수정)

- **경로**: `lib/main.dart`
- **변경**: -9줄
- **내용**:
  - **제거**: `import 'package:app_wallet_app/common/AppCache.dart';`
  - **제거**: `runApp` 전 실행되던 다음 블록 전부.
    - `if (!(await AppCache.isAllAppsCached())) { await AppCache.cacheAllApps(); } else { await AppCache.updateCacheOnAppChange(); }`
  - **결과**: 앱 구동 시 메인 스레드에서 무거운 캐시 초기화를 하지 않음 → 프레임 드롭 완화.

---

## 8. AppCache.dart (수정)

- **경로**: `lib/common/AppCache.dart`
- **변경**: +5줄
- **내용**:
  - `getCachedApps()` 내부 상단에 지연 초기화 추가.
  - `SharedPreferences`에서 `keyCachedApps` 값을 읽었을 때 **null이면** `return await cacheAllApps();` 호출 후 반환.
  - **결과**: 캐시가 없을 때만 한 번 생성하고, 있으면 기존 데이터만 반환.

---

## 9. common_helper.dart (수정)

- **경로**: `lib/common/common_helper.dart`
- **변경**: +3줄
- **내용**:
  - `initIntrnAppInfo()` 맨 앞에 한 줄 추가:  
    `appDataWithAll = await getCachedApplications("A", "");`
  - **결과**: 앱 시작 시 “전체 앱” 목록도 메모리에 로딩 → 전체 앱 리스트에서 + 버튼으로 추가 시 `addMyIntrnAppInfo()`가 정상 동작.

---

## 10. dic_service.dart (수정)

- **경로**: `lib/common/dic_service.dart`
- **변경**: -1줄
- **내용**:
  - **제거**: `bool isDataInit = false;` 필드.
  - **결과**: “나의 앱 리스트” 초기화 여부는 DB `hasMyApps()`만으로 판단하므로 해당 플래그 불필요.

---

## 요약 표 (이미지 기준 라인 수와 대응)

| 파일명 | 추가 | 삭제 | 구분 |
|--------|------|------|------|
| CHAT_SUMMARY.md | 94 | 0 | 신규 |
| proguard-rules.pro | 11 | 0 | 신규 |
| sql_helper.dart | 14 | 1 | 수정 |
| android/build.gradle | 1 | 1 | 수정 (플러그인 2곳) |
| MgrAppWebPage.dart | 2 | 2 | 수정 |
| PageMyUserDef.dart | 10 | 10 | 수정 |
| main.dart | 0 | 9 | 수정 |
| AppCache.dart | 5 | 0 | 수정 |
| common_helper.dart | 3 | 0 | 수정 |
| dic_service.dart | 0 | 1 | 수정 |

---

## 12. google_mobile_ads — 플러그인/예제 분석 오류 해결

- **경로**: `plugins/google_mobile_ads/pubspec.yaml`, `plugins/google_mobile_ads/` 및 `example/`
- **변경**:
  - **pubspec.yaml**: `dev_dependencies`에서 **e2e: ^0.7.0** 제거. (e2e는 null safety 미지원·deprecated라 현재 SDK에서 pub get 실패 방지.)
  - **plugins/google_mobile_ads**에서 `flutter pub get` 실행 → mockito, build_runner 등 dev_dependencies 설치.
  - **plugins/google_mobile_ads/example**에서 `flutter pub get` 실행 → 예제 패키지가 `path: ../` 로 플러그인을 인식하도록 의존성 해결.
- **내용**: 기존 수정(flutter_keyboard_visibility, device_apps 예제)과 동일하게, 워크스페이스 루트가 앱일 때 플러그인·예제의 import/분석 오류를 없애기 위함. 예제는 `package:google_mobile_ads` 유지, 테스트는 플러그인 폴더에서 pub get으로 mockito 등 해결.

이 문서는 `docs/CHAT_SUMMARY.md`와 함께 두면, 어떤 파일을 왜 바꿨는지 추적할 때 도움이 됩니다.
