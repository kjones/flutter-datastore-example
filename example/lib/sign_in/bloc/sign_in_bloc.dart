import 'dart:async';

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_auth_plugin_interface/amplify_auth_plugin_interface.dart';
import 'package:amplify_core/amplify_core.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'sign_in_event.dart';

part 'sign_in_state.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  SignInBloc() : super(SignInState());

  @override
  Stream<SignInState> mapEventToState(SignInEvent event) async* {
    if (event is SignInUsernameChanged) {
      yield* _mapUsernameChangedToState(event, state);
    } else if (event is SignInPasswordChanged) {
      yield* _mapPasswordChangedToState(event, state);
    } else if (event is SignInEmailChanged) {
      yield* _mapEmailChangedToState(event, state);
    } else if (event is SignInConfirmationCodeChanged) {
      yield* _mapConfirmationCodeChangedToState(event, state);
    } else if (event is SignInSubmitted) {
      yield* _mapSignInSubmittedToState(event, state);
    } else if (event is SignUpSubmitted) {
      yield* _mapSignUpSubmittedToState(event, state);
    } else if (event is ConfirmationCodeSubmitted) {
      yield* _mapConfirmationCodeSubmittedToState(event, state);
    } else if (event is ResendConfirmationCode) {
      yield* _mapResendConfirmationCodeToState(event, state);
    } else if (event is ChangeSignInMode) {
      yield* _mapChangeSignInModeToState(event, state);
    }
  }

  static Stream<SignInState> _mapUsernameChangedToState(
      SignInUsernameChanged event, SignInState state) async* {
    var stateWithUpdatedUsername = state.copyWith(
      username: event.username,
      usernameError: _validateUsername(event.username),
    );
    yield _stateWithUpdatedFormStatus(stateWithUpdatedUsername);
  }

  static Stream<SignInState> _mapPasswordChangedToState(
      SignInPasswordChanged event, SignInState state) async* {
    var stateWithUpdatedPassword = state.copyWith(
      password: event.password,
      passwordError: _validatePassword(event.password),
    );
    yield _stateWithUpdatedFormStatus(stateWithUpdatedPassword);
  }

  static Stream<SignInState> _mapEmailChangedToState(
      SignInEmailChanged event, SignInState state) async* {
    final stateWithUpdatedEmail = state.copyWith(
      email: event.email,
      emailError: _validateEmail(event.email),
    );
    yield _stateWithUpdatedFormStatus(stateWithUpdatedEmail);
  }

  static Stream<SignInState> _mapConfirmationCodeChangedToState(
      SignInConfirmationCodeChanged event, SignInState state) async* {
    final stateWithUpdatedConfirmationCode =
        state.copyWith(confirmationCode: event.confirmationCode);
    yield _stateWithUpdatedFormStatus(stateWithUpdatedConfirmationCode);
  }

  static Stream<SignInState> _mapSignInSubmittedToState(
      SignInSubmitted event, SignInState state) async* {
    if (state.formStatus.isNotValid) {
      return;
    }

    yield state.copyWith(formStatus: FormStatus.submissionInProgress);

    try {
      final signInResult = await Amplify.Auth.signIn(
          username: state.username, password: state.password);
      if (signInResult.isSignedIn) {
        yield state.copyWith(formStatus: FormStatus.initial);
      } else {
        // iOS gives zero clues to what happened when signInResult.isSignedIn == false
        // For now, going to assume that when a login fails without throwing an exception
        // that this means "USER_NOT_CONFIRMED" like below.
        yield state.copyWith(
            formStatus: FormStatus.initial, mode: SignInMode.confirmSignUp);
      }
    } on AuthError catch (ex) {
      if (ex.exceptionList
          .any((exEntry) => exEntry.exception == "USER_NOT_CONFIRMED")) {
        yield state.copyWith(
            formStatus: FormStatus.initial, mode: SignInMode.confirmSignUp);
      } else {
        yield state.copyWith(
            formStatus: FormStatus.initial,
            error: ex.cause,
            exceptions: _toExceptionList(ex));
      }
    }
  }

  static Stream<SignInState> _mapSignUpSubmittedToState(
      SignUpSubmitted event, SignInState state) async* {
    if (state.formStatus.isNotValid) {
      return;
    }

    yield state.copyWith(formStatus: FormStatus.submissionInProgress);

    try {
      final signUpOptions =
          CognitoSignUpOptions(userAttributes: {"email": state.email});
      final signUpResult = await Amplify.Auth.signUp(
          username: state.username,
          password: state.password,
          options: signUpOptions);
      switch (signUpResult.nextStep.signUpStep) {
        case "CONFIRM_SIGN_UP_STEP":
          yield state.copyWith(
              formStatus: FormStatus.initial, mode: SignInMode.confirmSignUp);
          break;
        default:
          yield state.copyWith(formStatus: FormStatus.initial);
          break;
      }
    } on AuthError catch (ex) {
      yield state.copyWith(
          formStatus: FormStatus.initial,
          error: ex.cause,
          exceptions: _toExceptionList(ex));
    }
  }

  static Stream<SignInState> _mapConfirmationCodeSubmittedToState(
      ConfirmationCodeSubmitted event, SignInState state) async* {
    if (state.formStatus.isNotValid) {
      return;
    }

    yield state.copyWith(formStatus: FormStatus.submissionInProgress);

    try {
      final signUpResult = await Amplify.Auth.confirmSignUp(
          username: state.username, confirmationCode: state.confirmationCode);

      switch (signUpResult.nextStep.signUpStep) {
        case "CONFIRM_SIGN_UP_STEP":
          yield state.copyWith(
              formStatus: FormStatus.initial, mode: SignInMode.confirmSignUp);
          break;
        case "DONE":
          final signInState = state.copyWith(
              formStatus: FormStatus.valid, mode: SignInMode.signIn);
          yield* _mapSignInSubmittedToState(SignInSubmitted(), signInState);
          break;
        default:
          yield state.copyWith(formStatus: FormStatus.initial);
          break;
      }
    } on AuthError catch (ex) {
      yield state.copyWith(
          formStatus: FormStatus.initial,
          error: ex.cause,
          exceptions: _toExceptionList(ex));
    }
  }

  static Stream<SignInState> _mapResendConfirmationCodeToState(
      ResendConfirmationCode event, SignInState state) async* {
    yield state.copyWith(formStatus: FormStatus.submissionInProgress);

    try {
      final resendSignUpCodeResult =
          await Amplify.Auth.resendSignUpCode(username: state.username);
      if (resendSignUpCodeResult.codeDeliveryDetails != null) {
        yield state.copyWith(formStatus: FormStatus.initial);
      }
    } on AuthError catch (ex) {
      yield state.copyWith(
          formStatus: FormStatus.initial,
          error: ex.cause,
          exceptions: _toExceptionList(ex));
    }
  }

  static Stream<SignInState> _mapChangeSignInModeToState(
      ChangeSignInMode event, SignInState state) async* {
    if (state.mode != event.mode) {
      yield state.copyWith(mode: event.mode);
    }
  }

  static SignInState _stateWithUpdatedFormStatus(SignInState state) =>
      state.copyWith(
          formStatus:
              _isValidFormInput(state) ? FormStatus.valid : FormStatus.invalid);

  static bool _isValidFormInput(SignInState state) =>
      _validateUsername(state.username) == null &&
      _validatePassword(state.password) == null &&
      (state.mode != SignInMode.signUp ||
          _validateEmail(state.email) == null) &&
      (state.mode != SignInMode.confirmSignUp ||
          _validateConfirmationCode(state.confirmationCode) == null);

  static String _validateUsername(String username) =>
      username?.isNotEmpty == true ? null : "Username is empty";

  static String _validatePassword(String password) =>
      _validatePasswordIsNotEmpty(password) ??
      _validatePasswordMeetsMinimumLength(password);

  static String _validatePasswordIsNotEmpty(String password) =>
      password?.isNotEmpty == true ? null : "Password is empty";

  static String _validatePasswordMeetsMinimumLength(String password) =>
      password.length >= 6 ? null : "Password too short";

  static String _validateEmail(String email) {
    if (email == null) {
      return "Email is empty";
    }

    bool emailValid = RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);
    return emailValid ? null : "Invalid email address format";
  }

  static String _validateConfirmationCode(String confirmationCode) =>
      confirmationCode?.isNotEmpty == true
          ? null
          : "Confirmation code is empty";

  static List<String> _toExceptionList(AuthError ex) => ex.exceptionList
      .where((element) => element.exception != "PLATFORM_EXCEPTIONS")
      .map((e) => e.exception + " - " + e.detail.toString())
      .toList();
}
