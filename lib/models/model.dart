import 'package:meta/meta.dart';

@immutable
abstract class Model {
  final String id;

  Model(this.id);

  Map<String, dynamic> toJson();
}
