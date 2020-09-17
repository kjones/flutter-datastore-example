import 'package:amplify_datastore_example/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../home/home.dart';
import '../../sign_in/sign_in.dart';
import '../app.dart';

class AppView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  NavigatorState get _navigator => _navigatorKey.currentState;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      builder: (context, child) => BlocListener<AppBloc, AppState>(
        listener: (context, state) {
          if (state.isSignedIn) {
            _navigator.pushAndRemoveUntil(HomePage.route(), (route) => false);
          } else {
            _navigator.pushAndRemoveUntil(SignInPage.route(), (route) => false);
          }
        },
        child: child,
      ),
      onGenerateRoute: (_) => SplashScreen.route(),
    );
  }
}
