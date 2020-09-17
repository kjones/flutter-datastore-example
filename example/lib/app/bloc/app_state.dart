part of 'app_bloc.dart';

class AppState extends Equatable {
  const AppState._({this.isSignedIn = false, this.userId, this.username});

  final bool isSignedIn;
  final String userId;
  final String username;

  const AppState.unknown() : this._();

  const AppState.unauthenticated() : this._(isSignedIn: false);

  const AppState.authenticated({String userId, String username})
      : this._(isSignedIn: true, userId: userId, username: username);

  @override
  List<Object> get props => [isSignedIn, userId, username];
}
