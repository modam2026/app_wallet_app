typedef CustomDrawerCallback = void Function();

/// 그룹 선택용: 프로그램에서는 [code], UI에는 [codeName] 표시
class GroupItem {
  final String code;
  final String codeName;
  const GroupItem(this.code, this.codeName);
}
