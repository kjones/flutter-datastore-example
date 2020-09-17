import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import 'model.dart';

@immutable
class ModelMetadata extends Equatable implements Model {
  final String id;
  final bool deleted;
  final int version;
  final DateTime lastChangedAt;

  ModelMetadata(this.id, this.deleted, this.version, this.lastChangedAt);

  ModelMetadata.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        deleted = json['_deleted'] ?? false,
        version = json['_version'] ?? 0,
        lastChangedAt =
            DateTime.fromMillisecondsSinceEpoch(json['_lastChangedAt']);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        '_deleted': deleted,
        '_version': version,
        '_lastChangedAt': lastChangedAt.millisecondsSinceEpoch,
      };

  @override
  List<Object> get props => [id, deleted, version, lastChangedAt];
}
