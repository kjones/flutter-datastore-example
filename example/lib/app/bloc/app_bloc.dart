import 'dart:async';

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_core/amplify_core.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';

part 'app_event.dart';
part 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc({this.authCognito}) : super(const AppState.unknown()) {
    _authEventSubscription = authCognito.events.events
        .receiveBroadcastStream(1)
        .startWith({'eventName': 'Kickstart'}).listen(_authenticationEvent);
  }

  final AmplifyAuthCognito authCognito;
  StreamSubscription _authEventSubscription;

  @override
  Future<void> close() {
    _authEventSubscription?.cancel();
    return super.close();
  }

  @override
  Stream<AppState> mapEventToState(AppEvent event) async* {
    if (event is AuthStatusChanged) {
      yield await _mapCurrentAmplifyAuthStateToAppState();
    }
  }

  Future<AppState> _mapCurrentAmplifyAuthStateToAppState() async {
    try {
      final authState = await Amplify.Auth.fetchAuthSession();
      if (authState.isSignedIn) {
        final authUser = await Amplify.Auth.getCurrentUser();
        return AppState.authenticated(
            userId: authUser.userId, username: authUser.username);
      }
    } catch (ex) {
      // Ignored. fetchAuthSession throws instead of returning isSignedIn=false.
      print(ex);
    }
    return const AppState.unauthenticated();
  }

  void _authenticationEvent(dynamic msg) {
    print('EventName: ${msg['eventName']}');
    add(AuthStatusChanged());
  }
}
