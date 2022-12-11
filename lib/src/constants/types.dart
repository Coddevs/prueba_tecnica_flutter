import 'package:flutter/services.dart';

enum GameField {
  optionA(39.7127, -75.0057),
  optionB(39.7128, -75.0058),
  optionC(39.7129, -75.0059);

  const GameField(this.lat, this.lng);

  final double lat;
  final double lng;

  String toReadable([
    TextCapitalization textCapitalization = TextCapitalization.words,
  ]) {
    switch (this) {
      case GameField.optionA:
        return _parse('A', textCapitalization);
      case GameField.optionB:
        return _parse('B', textCapitalization);
      case GameField.optionC:
        return _parse('C', textCapitalization);
      default:
        return '';
    }
  }

  String _parse(String char, TextCapitalization textCapitalization) {
    switch (textCapitalization) {
      case TextCapitalization.words:
        return 'Cancha ${char.toUpperCase()}';
      case TextCapitalization.sentences:
        return 'Cancha ${char.toUpperCase()}';
      case TextCapitalization.characters:
        return 'CANCHA ${char.toUpperCase()}';
      case TextCapitalization.none:
        return 'cancha ${char.toUpperCase()}';
      default:
        return '';
    }
  }
}
