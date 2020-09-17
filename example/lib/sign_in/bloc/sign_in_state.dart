part of 'sign_in_bloc.dart';

enum FormStatus { initial, valid, invalid, submissionInProgress }

extension FormStatusExtensions on FormStatus {
  bool get isValid => this == FormStatus.valid;
  bool get isNotValid => !this.isValid;

  bool get isSubmissionInProgress => this == FormStatus.submissionInProgress;
}

enum SignInMode { signIn, signUp, confirmSignUp }

class SignInState extends Equatable {
  const SignInState(
      {this.formStatus,
      this.mode = SignInMode.signIn,
      this.username,
      this.usernameError,
      this.password,
      this.passwordError,
      this.email,
      this.emailError,
      this.confirmationCode,
      this.error,
      this.exceptions});

  final FormStatus formStatus;
  final SignInMode mode;
  final String username;
  final String usernameError;
  final String password;
  final String passwordError;
  final String email;
  final String emailError;
  final String confirmationCode;
  final String error;
  final List<String> exceptions;

  SignInState copyWith(
          {FormStatus formStatus,
          SignInMode mode,
          String username,
          String usernameError,
          String password,
          String passwordError,
          String email,
          String emailError,
          String confirmationCode,
          String error,
          List<String> exceptions}) =>
      SignInState(
          formStatus: formStatus ?? this.formStatus,
          mode: mode ?? this.mode,
          username: username ?? this.username,
          usernameError:
              formStatus.isValid ? null : (usernameError ?? this.usernameError),
          password: password ?? this.password,
          passwordError:
              formStatus.isValid ? null : (passwordError ?? this.passwordError),
          email: email ?? this.email,
          emailError:
              formStatus.isValid ? null : (emailError ?? this.emailError),
          confirmationCode: confirmationCode ?? this.confirmationCode,
          error: error,
          exceptions: exceptions);

  @override
  List<Object> get props => [
        formStatus,
        mode,
        username,
        usernameError,
        password,
        passwordError,
        email,
        emailError,
        confirmationCode,
        error,
        exceptions
      ];
}
