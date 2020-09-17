import 'package:amplify_datastore/models/todo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class TodoWidget extends StatelessWidget {
  final Todo todo;

  const TodoWidget({Key key, @required this.todo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Id: ${todo.id}'),
        Text('Name: ${todo.name}'),
        Text('Description: ${todo.description}'),
      ],
    );
  }
}
