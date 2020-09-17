import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import 'model.dart';

@immutable
class DataStoreItemChange<T extends Model> extends Equatable {
  final String uuid;
  final String type;
  final String itemClass;
  final T item;

  DataStoreItemChange(this.uuid, this.type, this.itemClass, this.item);

  @override
  List<Object> get props => [uuid, type, itemClass, item];
}
