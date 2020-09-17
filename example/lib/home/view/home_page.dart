import 'package:amplify_datastore_example/todo/todo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../todo/todo.dart';
import '../home.dart';

enum MenuItem { signOut }

class HomePage extends StatelessWidget {
  static Route route() {
    return MaterialPageRoute<void>(builder: (_) => HomePage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeBloc>(
      create: (context) => HomeBloc(),
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            title: Text('Home'),
            actions: [
              PopupMenuButton<MenuItem>(
                onSelected: (value) =>
                    BlocProvider.of<HomeBloc>(context).add(SignOutEvent()),
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<MenuItem>(
                    value: MenuItem.signOut,
                    child: Text("Sign Out"),
                  ),
                ],
              ),
            ],
          ),
          body: Padding(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 40),
            child: HomeView(),
          ),
        ),
      ),
    );
  }
}

class HomeView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Expanded(
          child: Column(
            children: [
              RaisedButton(
                child: const Text('DataStore Demo'),
                onPressed: () => Navigator.of(context).push(TodoPage.route()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
