import 'package:html/parser.dart' as dom;
import 'package:http/http.dart' as http;
import 'package:scheduling/src/constants/types.dart';
import 'package:scheduling/src/utilities/parse.dart';

class SkyAPI {
  SkyAPI._();

  static final SkyAPI _instance = SkyAPI._();

  static SkyAPI get instance => _instance;

  Future<double?> getRainChance({
    required GameField? gameField,
    required DateTime? date,
  }) async {
    if (gameField==null || date==null) return null;

    final skyUri = Uri.parse(
      'https://darksky.net/details/'
      '${gameField.lat},${gameField.lng}'
      '/${date.year}-${date.month}-${date.day}'
      '/us12/es',
    );
    final response = await http.get(skyUri).timeout(const Duration(minutes: 1));
    final document = dom.parse(response.body);
    final element = document.querySelector('.precipAccum .val .num');
    final result = Parse.toDouble(element?.text);

    return result;
  }
}
