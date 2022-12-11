// ignore_for_file: library_private_types_in_public_api

import 'package:scheduling/src/constants/types.dart';
import 'package:scheduling/src/providers/local_db.dart';
import 'package:scheduling/src/utilities/parse.dart';

class Petition implements Adapterdb<Petition, Map<String, dynamic>> {
  const Petition({
    this.key,
    this.userName = '',
    this.gameField,
    this.date,
    this.rain,
  });

  @override
  final String? key;

  final String userName;
  final GameField? gameField;
  final DateTime? date;
  final double? rain;

  Petition copyWith({
    String? key,
    String? userName,
    GameField? gameField,
    DateTime? date,
    double? rain,
  }) {
    return Petition(
      key: key ?? this.key,
      userName: userName ?? this.userName,
      gameField: gameField ?? this.gameField,
      date: date ?? this.date,
      rain: rain ?? this.rain,
    );
  }

  @override
  Petition fromMap(String? key, Map<String, dynamic> map) {
    const def = Petition();
    return Petition(
      key: key,
      userName: Parse.toStr(map[fields.userName]) ?? def.userName,
      gameField: Parse.toGameField(map[fields.gameField]) ?? def.gameField,
      date: Parse.toDateTime(map[fields.date]) ?? def.date,
      rain: Parse.toDouble(map[fields.rain]) ?? def.rain,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      fields.userName: userName,
      fields.gameField: gameField?.index,
      fields.date: date.toString(),
      fields.rain: rain,
    };
  }

  static _Fields fields = _Fields.instance;
}

class _Fields {
  _Fields._();

  static final _Fields _instance = _Fields._();

  static _Fields get instance => _instance;

  String get userName => 'user_name';
  String get gameField => 'game_field';
  String get date => 'date';
  String get rain => 'rain';
}
