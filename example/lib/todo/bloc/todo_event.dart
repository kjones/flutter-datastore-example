part of 'todo_bloc.dart';

abstract class TodoEvent extends Equatable {
  const TodoEvent();

  @override
  List<Object> get props => [];
}

class StartLoading extends TodoEvent {}

class TodoItemChanged extends TodoEvent {}

class TodoCreated extends TodoEvent {
  final Todo todo;

  TodoCreated(this.todo);

  @override
  List<Object> get props => [todo];
}

class TodoDeleted extends TodoEvent {
  final String id;

  TodoDeleted(this.id);

  @override
  List<Object> get props => [id];
}

class DataStoreClear extends TodoEvent {}

class DataStoreRefresh extends TodoEvent {}
