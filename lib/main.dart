import 'package:PixPe/provider/aoi_provider.dart';
import 'package:PixPe/provider/api_provider.dart';
import 'package:PixPe/provider/profile_provider.dart';
import 'package:PixPe/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MultiProvider(providers: [ChangeNotifierProvider(create: (_)=>ApiProvider()),
  ChangeNotifierProvider(create: (_)=>ProfileProvider()),
    ChangeNotifierProvider(create: (_)=>AoiProvider())
  ],
  child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: SplashScreen()
    );
  }
}
