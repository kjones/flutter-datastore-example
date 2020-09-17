import 'dart:math';

import 'package:amplify_datastore/amplify_datastore.dart';
import 'package:amplify_datastore/models/todo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lorem/flutter_lorem.dart';

import '../todo.dart';

class TodoPage extends StatelessWidget {
  static Route route() {
    return MaterialPageRoute<void>(builder: (_) => TodoPage());
  }

  final random = Random();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TodoBloc>(
      create: (context) => TodoBloc(
          amplifyDataStore: RepositoryProvider.of<AmplifyDataStore>(context))
        ..add(StartLoading()),
      child: BlocBuilder<TodoBloc, TodoState>(
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            title: Text('Todos'),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.note_add),
                onPressed: () {
                  final name = 'todo-${100 + random.nextInt(899)}';
                  final description = lorem(words: 10, paragraphs: 1);
                  final newTodo = Todo(name: name, description: description);
                  context.bloc<TodoBloc>().add(TodoCreated(newTodo));
                },
              ),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () =>
                    context.bloc<TodoBloc>().add(DataStoreRefresh()),
              ),
              IconButton(
                icon: Icon(Icons.clear),
                onPressed: () => context.bloc<TodoBloc>().add(DataStoreClear()),
              ),
            ],
          ),
          body: BlocBuilder<TodoBloc, TodoState>(
            builder: (context, state) {
              if (state is TodoStateInitial) {
                return Center(child: CircularProgressIndicator());
              }
              if (state is TodoStateLoaded) {
                return ListView.builder(
                  itemBuilder: (context, position) {
                    final todo = state.todos[position];
                    return Dismissible(
                      background: Container(color: Colors.red),
                      key: Key(todo.id),
                      onDismissed: (direction) {
                        BlocProvider.of<TodoBloc>(context)
                            .add(TodoDeleted(todo.id));
                        Scaffold.of(context).showSnackBar(
                            SnackBar(content: Text("${todo.id} dismissed")));
                      },
                      child: _todoRow(todo, context, state, position),
                    );
                  },
                  itemCount: state.todos.length,
                );
              }
              return Center(
                child: Text("Unknown State"),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _todoRow(
      Todo todo, BuildContext context, TodoStateLoaded state, int position) {
    return Column(
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 8.0),
              child: TodoWidget(todo: state.todos[position]),
            ),
          ],
        ),
        Divider(
          height: 2.0,
          color: Colors.grey,
        )
      ],
    );
  }
}
