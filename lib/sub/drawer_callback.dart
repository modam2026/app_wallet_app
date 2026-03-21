typedef CustomDrawerCallback = void Function();

/// Drawer 그룹 선택 팝업에서 사용하는 불변 데이터 모델 클래스.
///
/// 작업 순서:
///   1. [MgrAppWebPage] 에서 기본 그룹 목록(매일/매주/매월 등)을 상수로 생성
///   2. [SQLHelper.getDistinctAppUserGroups] 로 DB 에서 읽은 그룹 목록을 동적으로 생성
///   3. [DrawerPageGrp] 의 팝업 메뉴에 전달되어 그룹 선택 UI 항목으로 표시
///   - [code]     : DB 에 저장되는 그룹 코드 (예: 'd', 'U11')
///   - [codeName] : 화면에 표시되는 그룹명 (예: '매일', '금융')
///   - [order]    : tbl_group_info.app_order (PageMyApps 앱 필터링 시 app_order 매칭용)
///   - [myAppYn]  : 'Y' 이면 나의 앱 탭에 표시되는 그룹 (선택 팝업에서 빨간색)
/// 그룹 선택용: 프로그램에서는 [code], UI에는 [codeName] 표시
class GroupItem {
  final String code;
  final String codeName;
  final int order;
  final String? myAppYn;
  const GroupItem(this.code, this.codeName, [this.order = 1, this.myAppYn]);
}
