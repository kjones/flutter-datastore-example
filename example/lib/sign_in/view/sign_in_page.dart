// import 'dart:async';

// import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
// import 'package:amplify_core/amplify_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../sign_in.dart';

class SignInPage extends StatelessWidget {
  static Route route() {
    return MaterialPageRoute<void>(builder: (_) => SignInPage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SignInBloc>(
      create: (context) => SignInBloc(),
      child: Scaffold(
        appBar: AppBar(
          title: _appBarTitle(),
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 40),
          child: BlocBuilder<SignInBloc, SignInState>(
            builder: (context, state) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _signInView(),
                if (state.error != null) Text(state.error),
                if (state.exceptions?.isNotEmpty ?? false)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: state.exceptions.map((ex) => Text(ex)).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BlocBuilder<SignInBloc, SignInState> _appBarTitle() =>
      BlocBuilder<SignInBloc, SignInState>(
        buildWhen: (previous, current) => previous.mode != current.mode,
        builder: (context, state) {
          switch (state.mode) {
            case SignInMode.signIn:
              return Text('Sign In');
            case SignInMode.signUp:
              return Text('Sign Up');
            case SignInMode.confirmSignUp:
              return Text('Confirm Sign Up');
          }
          return Text('Invalid sign in mode: ${state.mode}');
        },
      );

  Widget _signInView() =>
      BlocBuilder<SignInBloc, SignInState>(builder: (context, state) {
        switch (state.mode) {
          case SignInMode.signIn:
            return _showSignIn();
          case SignInMode.signUp:
            return _showSignUp();
          case SignInMode.confirmSignUp:
            return _showSignUpConfirmation();
        }
        return Text('Invalid sign in mode: ${state.mode}');
      });

  Widget _showSignIn() => Expanded(
        child: Column(
          children: [
            const Padding(padding: EdgeInsets.all(6.0)),
            _usernameInput(),
            const Padding(padding: EdgeInsets.all(6.0)),
            _passwordInput(),
            const Padding(padding: EdgeInsets.all(6.0)),
            _signInButton(),
            const Padding(padding: EdgeInsets.all(6.0)),
            _needAnAccountButton(),
          ],
        ),
      );

  Widget _showSignUp() => Expanded(
        child: Column(
          children: [
            const Padding(padding: EdgeInsets.all(6.0)),
            _usernameInput(),
            const Padding(padding: EdgeInsets.all(6.0)),
            _passwordInput(),
            const Padding(padding: EdgeInsets.all(6.0)),
            _emailInput(),
            const Padding(padding: EdgeInsets.all(6.0)),
            _signUpButton(),
            const Padding(padding: EdgeInsets.all(6.0)),
            _alreadyHaveAnAccountButton(),
          ],
        ),
      );

  Widget _showSignUpConfirmation() => Expanded(
        child: Column(
          children: [
            const Padding(padding: EdgeInsets.all(6.0)),
            _confirmationText(),
            const Padding(padding: EdgeInsets.all(6.0)),
            _confirmationCodeInput(),
            const Padding(padding: EdgeInsets.all(6.0)),
            _confirmSignUpButton(),
            const Padding(padding: EdgeInsets.all(6.0)),
            _resendConfirmationCodeButton(),
          ],
        ),
      );

  Widget _usernameInput() => BlocBuilder<SignInBloc, SignInState>(
        builder: (context, state) => TextField(
          key: const Key('SignInForm_UsernameInput'),
          onChanged: (username) =>
              context.bloc<SignInBloc>().add(SignInUsernameChanged(username)),
          decoration: InputDecoration(
            labelText: 'username',
            errorText: state.formStatus == FormStatus.valid
                ? null
                : state.usernameError,
          ),
        ),
      );

  Widget _confirmationText() => BlocBuilder<SignInBloc, SignInState>(
        builder: (context, state) => Text(
            "A confirmation code was sent to the email address associated with user ${state.username}."),
        key: const Key('SignInForm_UsernameText'),
      );

  Widget _passwordInput() => BlocBuilder<SignInBloc, SignInState>(
        builder: (context, state) => TextField(
          key: const Key('SignInForm_PasswordInput'),
          onChanged: (password) =>
              context.bloc<SignInBloc>().add(SignInPasswordChanged(password)),
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'password',
            errorText: state.passwordError,
          ),
        ),
      );

  Widget _emailInput() => BlocBuilder<SignInBloc, SignInState>(
        builder: (context, state) => Visibility(
          visible: state.mode == SignInMode.signUp,
          child: TextField(
            key: const Key('SignInForm_EmailInput'),
            onChanged: (email) =>
                context.bloc<SignInBloc>().add(SignInEmailChanged(email)),
            decoration: InputDecoration(
              labelText: 'email',
              errorText: state.formStatus == FormStatus.valid
                  ? null
                  : state.emailError,
            ),
          ),
        ),
      );

  Widget _confirmationCodeInput() => BlocBuilder<SignInBloc, SignInState>(
        builder: (context, state) => TextField(
          key: const Key('SignInForm_ConfirmationCodeInput'),
          onChanged: (username) => context
              .bloc<SignInBloc>()
              .add(SignInConfirmationCodeChanged(username)),
          decoration: InputDecoration(
            labelText: 'confirmation code',
          ),
        ),
      );

  Widget _signInButton() => BlocBuilder<SignInBloc, SignInState>(
        builder: (context, state) => state.formStatus.isSubmissionInProgress
            ? const CircularProgressIndicator()
            : RaisedButton(
                key: const Key('SignInForm_SignInButton'),
                child: const Text('Sign In'),
                onPressed: state.formStatus.isValid
                    ? () {
                        FocusScope.of(context).unfocus();
                        context.bloc<SignInBloc>().add(const SignInSubmitted());
                      }
                    : null,
              ),
      );

  Widget _signUpButton() => BlocBuilder<SignInBloc, SignInState>(
        builder: (context, state) => state.formStatus.isSubmissionInProgress
            ? const CircularProgressIndicator()
            : RaisedButton(
                key: const Key('SignInForm_SignUpButton'),
                child: const Text('Sign Up'),
                onPressed: state.formStatus.isValid
                    ? () {
                        FocusScope.of(context).unfocus();
                        context.bloc<SignInBloc>().add(const SignUpSubmitted());
                      }
                    : null,
              ),
      );

  Widget _confirmSignUpButton() => BlocBuilder<SignInBloc, SignInState>(
        builder: (context, state) => state.formStatus.isSubmissionInProgress
            ? const CircularProgressIndicator()
            : RaisedButton(
                key: const Key('SignInForm_ConfirmSignUpButton'),
                child: const Text('Confirm'),
                onPressed: state.formStatus.isValid
                    ? () {
                        FocusScope.of(context).unfocus();
                        context
                            .bloc<SignInBloc>()
                            .add(const ConfirmationCodeSubmitted());
                      }
                    : null,
              ),
      );

  Widget _needAnAccountButton() => BlocBuilder<SignInBloc, SignInState>(
        builder: (context, state) => Visibility(
          visible: !state.formStatus.isSubmissionInProgress,
          child: OutlineButton(
            key: const Key('SignInForm_NeedAnAccountButton'),
            child: const Text('Need an account? Sign up'),
            onPressed: () {
              FocusScope.of(context).unfocus();
              context
                  .bloc<SignInBloc>()
                  .add(const ChangeSignInMode(SignInMode.signUp));
            },
          ),
        ),
      );

  Widget _alreadyHaveAnAccountButton() => BlocBuilder<SignInBloc, SignInState>(
        builder: (context, state) => Visibility(
          visible: !state.formStatus.isSubmissionInProgress,
          child: OutlineButton(
            key: const Key('SignInForm_AlreadyHaveAnAccountButton'),
            child: const Text('Already have an account? Sign in'),
            onPressed: () {
              FocusScope.of(context).unfocus();
              context
                  .bloc<SignInBloc>()
                  .add(const ChangeSignInMode(SignInMode.signIn));
            },
          ),
        ),
      );

  Widget _resendConfirmationCodeButton() =>
      BlocBuilder<SignInBloc, SignInState>(
        builder: (context, state) => Visibility(
          visible: !state.formStatus.isSubmissionInProgress,
          child: OutlineButton(
            key: const Key('SignInForm_ResendConfirmationCodeButton'),
            child: const Text('Resend confirmation code'),
            onPressed: () {
              FocusScope.of(context).unfocus();
              context.bloc<SignInBloc>().add(const ResendConfirmationCode());
            },
          ),
        ),
      );
}
