import 'package:flutter/widgets.dart';
import 'package:scheduling/src/constants/types.dart';

@immutable
abstract class Parse {
  static T? as<T>(dynamic value) {
    if (value is T) {
      return value;
    } else {
      return null;
    }
  }

  static String? toStr(dynamic value) {
    if (value is String) {
      return _toTrim(value);
    } else if (value!=null) {
      return _toTrim(value.toString());
    } else {
      return null;
    }
  }

  static int? toInt(dynamic value) {
    if (value is int) {
      return value;
    } else if (value is double) {
      return value.toInt();
    } else if (value!=null) {
      return int.tryParse(Parse.toStr(value) ?? '');
    } else {
      return null;
    }
  }

  static double? toDouble(dynamic value) {
    if (value is double) {
      return value;
    } else if (value is int) {
      return value.toDouble();
    } else if (value!=null) {
      return double.tryParse(Parse.toStr(value) ?? '');
    } else {
      return null;
    }
  }

  static bool? toBool(dynamic value) {
    if (value is bool) {
      return value;
    } else if (value==0 || value==1) {
      return value==1;
    } else {
      return null;
    }
  }

  static Map? toMap(dynamic value) {
    return Parse.as<Map>(value);
  }

  static List<Map>? toMapList(dynamic values) {
    if (values is List<Map>) {
      values.removeWhere((value) => value.isEmpty);
      return values;
    } else if (values is List) {
      if (values.isNotEmpty) {
        final result = <Map>[];

        for (final value in values) {
          if (value is Map && value.isNotEmpty) {
            result.add(value);
          }
        }

        return result;
      } else {
        return <Map>[];
      }
    } else {
      return null;
    }
  }

  static DateTime? toDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    } else if (value is String && value!='0000-00-00 00:00:00') {
      return DateTime.tryParse(Parse.toStr(value) ?? '');
    } else {
      return null;
    }
  }

  static String? toReadableDate(dynamic value, [String separator = '/']) {
    final date = Parse.toDateTime(value);
    if (date is DateTime) {
      return [
        date.day,
        date.month,
        date.year,
      ].join(separator);
    } else {
      return null;
    }
  }

  static GameField? toGameField(dynamic value) {
    if (value is GameField) {
      return value;
    } else if (value is int) {
      try {
        return GameField.values[value];
      } catch (_) {
        return null;
      }
    } else {
      return null;
    }
  }

  static final _rSpaces = RegExp(r'(?!(\r\n|\n))([\s]+)', multiLine: true);

  static String? _toTrim(dynamic value) {
    return Parse.as<String>(value)?.replaceAll(_rSpaces, ' ').trim();
  }
}
