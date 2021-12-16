import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:tony_flutter/service/ably_service.dart';
import 'package:tony_flutter/view/dashboard.dart';

GetIt getIt = GetIt.instance;

void main() {
  getIt.registerSingletonAsync<AblyService>(() => AblyService.init());
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tony Robin Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xffFF5416),
        accentColor: Color(0xffFF5416),
        scaffoldBackgroundColor: Color(0xff292831),
        appBarTheme: AppBarTheme(
          elevation: 0.0,
        ),
        textTheme: TextTheme(
          bodyText1: TextStyle(color: Colors.white),
          bodyText2: TextStyle(color: Colors.white),
        ),
      ),
      home: DashboardView(),
    );
  }
}
