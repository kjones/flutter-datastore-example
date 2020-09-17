import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import 'model.dart';

final _uuid = Uuid();

@immutable
class Todo extends Equatable implements Model {
  final String id;
  final String name;
  final String description;

  Todo({id, @required this.name, @required this.description})
      : id = id ?? _uuid.v4();

  Todo.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        description = json['description'];

  @override
  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'description': description};

  @override
  List<Object> get props => [id, name, description];
}
