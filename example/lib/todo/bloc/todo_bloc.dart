import 'dart:async';

import 'package:amplify_datastore/amplify_datastore.dart';
import 'package:amplify_datastore/models/todo.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';

part 'todo_event.dart';
part 'todo_state.dart';

class TodoBloc extends Bloc<TodoEvent, TodoState> {
  TodoBloc({@required AmplifyDataStore amplifyDataStore})
      : _amplifyDataStore = amplifyDataStore,
        super(TodoStateInitial());

  final AmplifyDataStore _amplifyDataStore;
  StreamSubscription _todoStreamSubscription;

  @override
  Stream<TodoState> mapEventToState(TodoEvent event) async* {
    switch (event.runtimeType) {
      case StartLoading:
        _subscribeToDataStoreTodoChangeEvents();
        continue LoadCurrentTodos;

      LoadCurrentTodos:
      case TodoItemChanged:
      case DataStoreRefresh:
        yield* _loadCurrentTodos();
        break;

      case TodoCreated:
        yield* _saveTodo(state, event);
        break;

      case TodoDeleted:
        yield* _deleteTodo(state, event);
        break;

      case DataStoreClear:
        yield* _dataStoreClear();
        break;
    }
  }

  @override
  Future<void> close() {
    print('Close TodoBloc');
    _todoStreamSubscription?.cancel();
    _todoStreamSubscription = null;
    return super.close();
  }

  void _subscribeToDataStoreTodoChangeEvents() async {
    _todoStreamSubscription = _amplifyDataStore
        .dataStoreEvents()
        .where((event) => event.item is Todo)
        .debounceTime(Duration(milliseconds: 500))
        .listen((change) => add(TodoItemChanged()));
  }

  Stream<TodoState> _dataStoreClear() async* {
    await _amplifyDataStore.dataStoreClear();
    yield TodoStateLoaded([]);
  }

  Stream<TodoState> _loadCurrentTodos() async* {
    final todos = await _amplifyDataStore.dataStoreQuery<Todo>();
    yield TodoStateLoaded(todos);
  }

  Stream<TodoState> _saveTodo(TodoStateLoaded state, TodoCreated event) async* {
    final updatedTodos = [...state.todos, event.todo];
    await _amplifyDataStore.dataStoreSave<Todo>(event.todo);
    yield TodoStateLoaded(updatedTodos);
  }

  Stream<TodoState> _deleteTodo(
      TodoStateLoaded state, TodoDeleted event) async* {
    await _amplifyDataStore.dataStoreDelete<Todo>(id: event.id);
    final updatedTodos =
        state.todos.where((todo) => todo.id != event.id).toList();
    yield TodoStateLoaded(updatedTodos);
  }

  @override
  void onChange(Change<TodoState> change) {
    print(change);
    super.onChange(change);
  }

  @override
  void onTransition(Transition<TodoEvent, TodoState> transition) {
    print(transition);
    super.onTransition(transition);
  }
}
