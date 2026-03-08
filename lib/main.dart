import 'package:app_wallet_app/common/dic_service.dart';
import 'package:app_wallet_app/sub/MgrAppWebPage.dart';
import 'package:flutter/material.dart';
//import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // main 함수에서 async 사용하기 위함
  //await Firebase.initializeApp(); // firebase 앱 시작
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => DicService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MODAM TECH',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      // ignore: unrelated_type_equality_checks
      //home: user == null ? LoginPage() : WebListMgrPage(),
      home: MgrAppWebPage(),
    );
  }
}
