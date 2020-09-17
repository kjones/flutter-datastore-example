part of 'sign_in_bloc.dart';

abstract class SignInEvent extends Equatable {
  const SignInEvent();
}

class SignInUsernameChanged extends SignInEvent {
  SignInUsernameChanged(String username) : username = username.trim();

  final username;

  @override
  List<Object> get props => [username];
}

class SignInPasswordChanged extends SignInEvent {
  SignInPasswordChanged(String password) : password = password.trim();
  final password;

  @override
  List<Object> get props => [password];
}

class SignInEmailChanged extends SignInEvent {
  SignInEmailChanged(String email) : email = email.trim();

  final email;

  @override
  List<Object> get props => [email];
}

class SignInConfirmationCodeChanged extends SignInEvent {
  SignInConfirmationCodeChanged(String confirmationCode)
      : confirmationCode = confirmationCode.trim();

  final confirmationCode;

  @override
  List<Object> get props => [confirmationCode];
}

class SignInSubmitted extends SignInEvent {
  const SignInSubmitted();

  @override
  List<Object> get props => [];
}

class SignUpSubmitted extends SignInEvent {
  const SignUpSubmitted();

  @override
  List<Object> get props => [];
}

class ChangeSignInMode extends SignInEvent {
  const ChangeSignInMode(this.mode);

  final SignInMode mode;

  @override
  List<Object> get props => [mode];
}

class ConfirmationCodeSubmitted extends SignInEvent {
  const ConfirmationCodeSubmitted();

  @override
  List<Object> get props => [];
}

class ResendConfirmationCode extends SignInEvent {
  const ResendConfirmationCode();

  @override
  List<Object> get props => [];
}
