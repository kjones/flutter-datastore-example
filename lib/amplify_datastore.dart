import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

import 'models/data_store_item_change.dart';
import 'models/model.dart';
import 'models/model_metadata.dart';
import 'models/todo.dart';

class AmplifyDataStore {
  static const androidTodoClass =
      'com.amplifyframework.datastore.generated.model.Todo';
  static const androidModelMetadataClass =
      'com.amplifyframework.datastore.appsync.ModelMetadata';

  static const iosTodoClass = 'Todo';
  static const iosModelMetadataClass = 'ModelMetadata';

  final _channel = MethodChannel('com.kjones.amplify_datastore/amplify');
  final _dataStoreEvents =
      EventChannel('com.kjones.amplify_datastore/dataStoreEvents');

  Future<String> platformVersion() async =>
      await _channel.invokeMethod<String>('getPlatformVersion');

  Future<bool> dataStoreClear() async =>
      await _channel.invokeMethod<bool>('dataStoreClear');

  Future<T> dataStoreSave<T extends Model>(T item) async {
    var eventChannelName = await _channel.invokeMethod<String>('dataStoreSave',
        {'itemClass': T.toString(), 'item': json.encode(item.toJson())});
    final eventChannel = EventChannel(eventChannelName);
    return eventChannel.receiveBroadcastStream().single.then(
        (item) => _toDataStoreModel(item['itemClass'], item['item']) as T);
  }

  Future<bool> dataStoreDelete<T extends Model>({@required String id}) async {
    var eventChannelName = await _channel.invokeMethod<String>(
        'dataStoreDelete', {'itemClass': T.toString(), 'id': id});
    final eventChannel = EventChannel(eventChannelName);
    return eventChannel.receiveBroadcastStream().cast<bool>().single;
  }

  Future<List<T>> dataStoreQuery<T extends Model>() async {
    final eventChannelName = await _channel
        .invokeMethod<String>('dataStoreQuery', {'itemClass': T.toString()});
    final eventChannel = EventChannel(eventChannelName);
    return eventChannel
        .receiveBroadcastStream()
        .cast<List<dynamic>>()
        .single
        .then((list) => list
            .map((item) =>
                _toDataStoreModel(item['itemClass'], item['item']) as T)
            .toList());
  }

  Stream<DataStoreItemChange<Model>> dataStoreEvents() async* {
    await for (final event in _dataStoreEvents.receiveBroadcastStream()) {
      final item = _toDataStoreModel(event['itemClass'], event['item']);
      if (item != null) {
        yield DataStoreItemChange(
            event['uuid'], event['type'], event['itemClass'], item);
      }
    }
  }

  static Model _toDataStoreModel(String itemClass, String itemJson) {
    var decodedJson = json.decode(itemJson);
    switch (itemClass) {
      case androidTodoClass:
      case iosTodoClass:
        return Todo.fromJson(decodedJson);
      case androidModelMetadataClass:
      case iosModelMetadataClass:
        return ModelMetadata.fromJson(decodedJson);
    }
    return null;
  }
}
