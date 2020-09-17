part of 'todo_bloc.dart';

abstract class TodoState extends Equatable {
  const TodoState();

  List<Object> get props => [];
}

class TodoStateInitial extends TodoState {}

class TodoStateLoaded extends TodoState {
  final List<Todo> todos;

  const TodoStateLoaded(this.todos);

  @override
  List<Object> get props => [todos];

  @override
  String toString() => 'TodoStateLoaded {todos: ${todos.length}}';
}
