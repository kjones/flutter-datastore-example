import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_core/amplify_core.dart';
import 'package:amplify_datastore/amplify_datastore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import './amplifyconfiguration.dart';
import 'app/app.dart';

class AmplifyRepositories {
  final Amplify amplify;
  final AmplifyDataStore amplifyDataStore;
  final AmplifyAuthCognito amplifyAuthCognito;

  AmplifyRepositories(
      {this.amplify, this.amplifyDataStore, this.amplifyAuthCognito});
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var amplifyRepositories = await _configureAmplify();
  runApp(Main(amplifyRepositories: amplifyRepositories));
}

Future<AmplifyRepositories> _configureAmplify() async {
  final delayFuture = Future.delayed(Duration(seconds: 3));

  final amplify = Amplify();
  final amplifyDataStore = AmplifyDataStore();

  final auth = AmplifyAuthCognito();
  amplify.addPlugin(authPlugins: [auth]);
  final configFuture = amplify.configure(amplifyconfig);

  await delayFuture;
  await configFuture;

  Future.wait([delayFuture, configFuture]).timeout(Duration(seconds: 5));

  return AmplifyRepositories(
      amplify: amplify,
      amplifyDataStore: amplifyDataStore,
      amplifyAuthCognito: auth);
}

class Main extends StatelessWidget {
  const Main({Key key, @required this.amplifyRepositories}) : super(key: key);
  final AmplifyRepositories amplifyRepositories;

  @override
  Widget build(BuildContext context) => MultiRepositoryProvider(
        providers: [
          RepositoryProvider(
            create: (context) => amplifyRepositories.amplify,
          ),
          RepositoryProvider(
            create: (context) => amplifyRepositories.amplifyDataStore,
          ),
          RepositoryProvider(
            create: (context) => amplifyRepositories.amplifyAuthCognito,
          ),
        ],
        child: BlocProvider(
          create: (context) =>
              AppBloc(authCognito: context.repository<AmplifyAuthCognito>()),
          child: AppView(),
        ),
      );
}
