import 'package:flutter/material.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart'; // 로컬용 비활성화. 스토어 배포 시 복구
import 'package:app_wallet_app/common/dic_service.dart';
import 'package:app_wallet_app/sub/drawer_callback.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app_wallet_app/common/sql_helper.dart';

/// 그룹 관리 전용 Drawer(우측 패널) 페이지.
///
/// 작업 순서:
///   1. 그룹명 직접 입력 또는 선택 버튼으로 기존 그룹 선택 (전체 제외)
///   2. [추가] 버튼: tbl_group_info에 신규 생성 (group_code='A', app_order=최대값+1)
///   3. [삭제] 버튼: 사용자 정의 그룹(group_code='A')만, 앱 없을 때 삭제
///   4. [사용여부] 버튼: 해당 그룹의 use_yn Y↔N 토글 (라벨: 사용안함/사용함)
///   5. [onItemSelected] 콜백으로 부모 화면 갱신
class DrawerPageGrp extends StatefulWidget {
  final CustomDrawerCallback? onItemSelected;
  final List<GroupItem>? groupList;
  final int openKey;

  const DrawerPageGrp({
    Key? key,
    this.onItemSelected,
    this.groupList,
    this.openKey = 0,
  }) : super(key: key);

  @override
  State<DrawerPageGrp> createState() => _DrawerPageGrpState();
}

class _DrawerPageGrpState extends State<DrawerPageGrp> {
  final TextEditingController classController = TextEditingController();
  late FocusNode _groupNameFocusNode;
  String? _selectedGroupUseYn;
  String? _selectedGroupMyAppYn;

  /// 그룹 관리 전용 목록. "전체" 제외.
  List<GroupItem> get _menuGroupList =>
      (widget.groupList != null && widget.groupList!.isNotEmpty)
      ? widget.groupList!.where((item) => item.codeName != '전체').toList()
      : [];

  /// 상단 정렬된 목록: 사용자 정의 그룹+my_app_yn Y → 상단, 그 안에서 사용자 정의 먼저
  List<GroupItem> get _sortedMenuGroupList {
    final list = List<GroupItem>.from(_menuGroupList);
    bool isTop(GroupItem g) => g.code == 'A' || g.myAppYn == 'Y';
    list.sort((a, b) {
      final aTop = isTop(a);
      final bTop = isTop(b);
      if (aTop != bTop) return aTop ? -1 : 1;
      if (aTop) {
        final aUser = a.code == 'A';
        final bUser = b.code == 'A';
        if (aUser != bUser) return aUser ? -1 : 1;
      }
      return a.order.compareTo(b.order);
    });
    return list;
  }

  @override
  void initState() {
    super.initState();
    _groupNameFocusNode = FocusNode();
    _groupNameFocusNode.addListener(_onGroupNameFocusChange);
  }

  void _onGroupNameFocusChange() {
    if (!_groupNameFocusNode.hasFocus) {
      final name = classController.text.trim();
      if (name.isNotEmpty) {
        SQLHelper.getGroupInfoByName(name).then((info) {
          if (mounted && info != null) {
            setState(() {
              _selectedGroupUseYn =
                  info['use_yn']?.toString().toUpperCase() ?? 'Y';
              _selectedGroupMyAppYn =
                  (info['my_app_yn']?.toString() ?? 'N').toUpperCase();
            });
          } else if (mounted && info == null) {
            setState(() {
              _selectedGroupUseYn = 'Y';
              _selectedGroupMyAppYn = null;
            });
          }
        });
      } else {
        setState(() {
          _selectedGroupUseYn = null;
          _selectedGroupMyAppYn = null;
        });
      }
    }
  }

  @override
  void didUpdateWidget(DrawerPageGrp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.openKey != widget.openKey) {
      setState(() {
        _selectedGroupUseYn = null;
        _selectedGroupMyAppYn = null;
      });
    }
  }

  @override
  void dispose() {
    _groupNameFocusNode.removeListener(_onGroupNameFocusChange);
    _groupNameFocusNode.dispose();
    classController.dispose();
    super.dispose();
  }

  String get _useStatusLabel {
    if (_selectedGroupUseYn == null) return '사용여부';
    final u = _selectedGroupUseYn!.toUpperCase();
    return u == 'Y' ? '사용안함' : '사용함';
  }

  /// my_app_yn 에 따른 나의 앱 토글 버튼 라벨
  String get _myAppStatusLabel {
    if (_selectedGroupMyAppYn == null) return '나의 앱 사용';
    final y = _selectedGroupMyAppYn!.toUpperCase();
    return y == 'N' ? '나의 앱 사용함' : '나의 앱 사용 안함';
  }

  bool get _isUsed => _selectedGroupUseYn?.toUpperCase() == 'N';

  @override
  Widget build(BuildContext context) {
    return Consumer<DicService>(
      builder: (context, dicService, child) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 250,
                      height: 50,
                      child: Center(
                        child: Text(
                          "그룹 관리",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      height: 30,
                      child: Container(margin: EdgeInsets.fromLTRB(0, 5, 0, 0)),
                    ),
                  ],
                ),
                SizedBox(width: 100, height: 10),
                Container(
                  margin: EdgeInsets.only(left: 10),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 8,
                        backgroundColor: Colors.red,
                        child: Text(
                          '1',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      SizedBox(width: 10),
                      SizedBox(
                        width: 230,
                        child: Text(
                          "그룹명",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 200,
                      height: 40,
                      margin: EdgeInsets.symmetric(horizontal: 10.0),
                      child: TextField(
                        style: TextStyle(fontSize: 16.0),
                        controller: classController,
                        focusNode: _groupNameFocusNode,
                        decoration: InputDecoration(
                          hintText: "그룹명을 입력하거나 선택하세요",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    if (_menuGroupList.isNotEmpty)
                      PopupMenuButton<GroupItem>(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [Icon(Icons.arrow_drop_down), Text("선택")],
                          ),
                        ),
                        itemBuilder: (context) => _sortedMenuGroupList
                            .map(
                              (g) => PopupMenuItem<GroupItem>(
                                value: g,
                                child: Text(
                                  g.codeName,
                                  style: TextStyle(
                                    color: g.code == 'A'
                                        ? Colors.red
                                        : g.myAppYn == 'Y'
                                            ? Colors.blue
                                            : null,
                                    fontWeight:
                                        (g.code == 'A' || g.myAppYn == 'Y')
                                            ? FontWeight.w600
                                            : null,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onSelected: (GroupItem item) async {
                          classController.text = item.codeName;
                          final info = await SQLHelper.getGroupInfoByName(
                            item.codeName,
                          );
                          if (mounted) {
                            setState(() {
                              _selectedGroupUseYn =
                                  info?['use_yn']?.toString().toUpperCase() ??
                                  'Y';
                              _selectedGroupMyAppYn =
                                  (info?['my_app_yn']?.toString() ?? 'N')
                                      .toUpperCase();
                            });
                          }
                        },
                      ),
                  ],
                ),
                SizedBox(width: 100, height: 20),
                _buildMyAppRegisterButton(dicService),
                _buildAddButton(dicService),
                _buildDeleteButton(dicService),
                _buildUseStatusButton(dicService),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMyAppRegisterButton(DicService dicService) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      width: MediaQuery.of(context).size.width - 32,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueGrey.shade600,
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
          surfaceTintColor: Colors.transparent,
        ),
        onPressed: () async {
          final strGroupName = classController.text.trim();
          if (strGroupName.isEmpty) {
            dicService.showCheckItems("그룹명");
            return;
          }
          final existing = await SQLHelper.getGroupInfoByName(strGroupName);
          if (existing == null) {
            dicService.showCheckItems("해당 그룹");
            return;
          }
          final currentYn =
              (existing['my_app_yn']?.toString() ?? 'N').toUpperCase();
          final newYn = currentYn == 'Y' ? 'N' : 'Y';
          final affected =
              await SQLHelper.updateGroupMyAppYn(strGroupName, newYn);
          if (affected > 0 && mounted) {
            setState(() => _selectedGroupMyAppYn = newYn);
            if (!context.mounted) return;
            Navigator.pop(context);
            widget.onItemSelected?.call();
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_to_home_screen, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _myAppStatusLabel,
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(DicService dicService) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      width: MediaQuery.of(context).size.width - 32,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueGrey,
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
          surfaceTintColor: Colors.transparent,
        ),
        onPressed: () async {
          final strGroupName = classController.text.trim();
          if (strGroupName.isEmpty) {
            dicService.showCheckItems("그룹명");
            return;
          }
          final existing = await SQLHelper.getGroupInfoByName(strGroupName);
          if (existing != null) {
            dicService.showExistStatus(strGroupName);
            return;
          }
          await SQLHelper.createUserGroup(strGroupName);
          classController.clear();
          setState(() {
            _selectedGroupUseYn = null;
            _selectedGroupMyAppYn = null;
          });
          if (!context.mounted) return;
          Navigator.pop(context);
          widget.onItemSelected?.call();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icons/done-svgrepo-com.svg',
              width: 24,
              height: 24,
              color: Colors.white,
            ),
            SizedBox(width: 8),
            Text('추가', style: TextStyle(fontSize: 18, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteButton(DicService dicService) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      width: MediaQuery.of(context).size.width - 32,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueGrey.shade700,
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
          surfaceTintColor: Colors.transparent,
        ),
        onPressed: () async {
          final strGroupName = classController.text.trim();
          if (strGroupName.isEmpty) {
            dicService.showCheckItems("그룹명");
            return;
          }
          final result = await SQLHelper.deleteUserGroup(strGroupName);
          if (!mounted) return;
          if (result == 'ok') {
            classController.clear();
            setState(() {
              _selectedGroupUseYn = null;
              _selectedGroupMyAppYn = null;
            });
            Navigator.pop(context);
            widget.onItemSelected?.call();
            return;
          }
          if (result == 'not_found') {
            dicService.showCheckItems("해당 그룹");
          } else if (result == 'not_user_group') {
            dicService.showCheckItems("사용자 정의 그룹(A)만 삭제 가능");
          } else if (result == 'has_apps') {
            dicService.showCheckItems("그룹에 앱이 있으면 삭제할 수 없습니다");
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text('삭제', style: TextStyle(fontSize: 18, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildUseStatusButton(DicService dicService) {
    final btnColor = _isUsed ? Colors.white : Colors.blueGrey;
    final contentColor = _isUsed ? Colors.black87 : Colors.white;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      width: MediaQuery.of(context).size.width - 32,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: btnColor,
          foregroundColor: contentColor,
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
          surfaceTintColor: Colors.transparent,
        ),
        onPressed: () async {
          final strGroupName = classController.text.trim();
          if (strGroupName.isEmpty) {
            dicService.showCheckItems("그룹명");
            return;
          }
          final affected = await SQLHelper.toggleGroupUseYn(strGroupName);
          if (affected == 0) {
            dicService.showCheckItems("해당 그룹");
            return;
          }
          setState(() {
            final u = _selectedGroupUseYn?.toUpperCase() ?? 'Y';
            _selectedGroupUseYn = u == 'Y' ? 'N' : 'Y';
          });
          if (!context.mounted) return;
          Navigator.pop(context);
          widget.onItemSelected?.call();
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isUsed ? Icons.check : Icons.toggle_on,
              color: contentColor,
              size: 24,
            ),
            SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _useStatusLabel,
                  style: TextStyle(fontSize: 18, color: contentColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
