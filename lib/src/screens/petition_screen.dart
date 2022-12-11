import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:scheduling/src/constants/types.dart';
import 'package:scheduling/src/providers/local_petitions.dart';
import 'package:scheduling/src/providers/sky_api.dart';
import 'package:scheduling/src/utilities/functions.dart';
import 'package:scheduling/src/utilities/parse.dart';
import 'package:scheduling/src/widgets/custom_stateful.dart';

class PetitionScreen extends StatefulWidget {
  const PetitionScreen({
    super.key,
    required this.petition,
    required this.onSaved,
  });

  final Petition petition;
  final ValueSetter<Petition> onSaved;

  @override
  State createState() => _PetitionScreenState();
}
class _PetitionScreenState extends State<PetitionScreen> {
  final _scrollController = ScrollController();
  final _stateController = StateController();
  final _dateTextController = TextEditingController();
  final _userNameFocusNode = FocusNode();
  final _gameFieldFocusNode = FocusNode();
  final _dateFocusNode = _AlwaysDisabledFocusNode();

  String _userNameValue = '';
  GameField? _gameFieldValue;
  DateTime? _dateValue;
  double? _rainValue;

  FocusNode? _nextFocus;

  Future<void> _showRainChance(FormState? form) async {
    await Functions.showPause(
      context: context,
      future: (context) async {
        _rainValue = await SkyAPI.instance.getRainChance(
          gameField: _gameFieldValue,
          date: _dateValue,
        );
      },
    );

    if (_rainValue!=null) form?.validate();
    _stateController.repaint(() {});
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final now = DateTime.now();
    final form = Form.of(context);

    _dateValue = await showDatePicker(
      context: context,
      initialDate: _dateValue ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );

    if (_dateValue!=null) {
      _dateTextController.text = Parse.toReadableDate(_dateValue) ?? '';
      await _showRainChance(form);
    }
  }

  Future<void> _save(BuildContext context) async {
    final form = Form.of(context);
    final navigator = Navigator.of(context);

    _nextFocus = null;

    if (form?.validate() ?? false) {
      form?.save();
      if (_rainValue==null) {
        await _showRainChance(form);
      } else {
        final value = widget.petition.copyWith(
          userName: _userNameValue,
          gameField: _gameFieldValue,
          date: _dateValue,
          rain: _rainValue,
        );
        final fieldPetitions = await context.read<LocalPetitions>().search(
          where: (petition) {
            final isGameField = petition.gameField==_gameFieldValue;
            final isPetitionDate = petition.date==_dateValue;
            return isGameField && isPetitionDate;
          },
        );

        if (fieldPetitions.length>=3) {
          Functions.showSnackBar(
            context: context,
            content: Text(
              'Se alcanzó el máximo de reserva para la '
              '${_gameFieldValue?.toReadable(TextCapitalization.none)} '
              'en el día ${Parse.toReadableDate(_dateValue)}.',
            ),
          );
        } else {
          await Functions.showPause(
            context: context,
            future: (context) async {
              await context.read<LocalPetitions>().set([value]);
              await Future.delayed(const Duration(seconds: 1));
            },
          );
          navigator.pop();
          widget.onSaved(value);
        }
      }
    } else {
      /* if (_nextFocus!=null) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          _scrollController.jumpTo(
            _scrollController.offset
            - _nextFocus!.offset.dy.abs()
            - 85.0,
          );
        });
      } */
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reserve su cancha'),
      ),
      body: Center(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 7.5),
          child: Form(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12.5),
                TextFormField(
                  key: const Key('user_name'),
                  focusNode: _userNameFocusNode,
                  initialValue: widget.petition.userName,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'^[\s]+')),
                    FilteringTextInputFormatter.deny(
                      RegExp(r'(?!(\r\n|\n))([\s]+)', multiLine: true),
                      replacementString: ' ',
                    ),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Nombre de usuario',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final userName = value ?? '';
                    if (userName.isEmpty) {
                      _nextFocus ??= _userNameFocusNode;
                      return 'Este campo es obligatorio.';
                    } else {
                      return null;
                    }
                  },
                  onSaved: (value) => _userNameValue = value ?? '',
                ),
                const SizedBox(height: 12.5),
                Builder(
                  builder: (context) {
                    return DropdownButtonFormField<GameField>(
                      value: _gameFieldValue,
                      focusNode: _gameFieldFocusNode,
                      items: GameField.values.map((gameField) {
                        return DropdownMenuItem(
                          value: gameField,
                          child: Text(gameField.toReadable()),
                        );
                      }).toList(),
                      decoration: const InputDecoration(
                        labelText: 'Cancha',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value==null) {
                          _nextFocus ??= _gameFieldFocusNode;
                          return 'Este campo es obligatorio.';
                        } else {
                          return null;
                        }
                      },
                      onChanged: (value) async {
                        _gameFieldValue = value;
                        await _showRainChance(Form.of(context));
                      },
                      onSaved: (value) => _gameFieldValue = value,
                    );
                  },
                ),
                const SizedBox(height: 12.5),
                CustomStateful(
                  controller: _stateController,
                  builder: (context) {
                    return TextFormField(
                      focusNode: _dateFocusNode,
                      controller: _dateTextController,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'^[\s]+')),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Fecha',
                        border: const OutlineInputBorder(),
                        suffixIcon: const Icon(Icons.navigate_next),
                        helperText: _rainValue!=null
                                  ? '${(_rainValue! *100).toStringAsFixed(2)}% '
                                    'de probabilidad de lluvia '
                                    'para el día elegido.'
                                  : null,
                      ),
                      validator: (value) {
                        if (_dateValue==null) {
                          _nextFocus ??= _dateFocusNode;
                          return 'Este campo es obligatorio.';
                        } else {
                          return null;
                        }
                      },
                      onTap: () => _showDatePicker(context),
                    );
                  },
                ),
                const SizedBox(height: 12.5),
                Builder(
                  builder: (context) {
                    return Hero(
                      tag: const Key('hero_to_reserve'),
                      child: ElevatedButton(
                        child: const Text('Reservar'),
                        onPressed: () => _save(context),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12.5),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _stateController.dispose();
    _dateTextController.dispose();
    _userNameFocusNode.dispose();
    _gameFieldFocusNode.dispose();
    _dateFocusNode.dispose();
    super.dispose();
  }
}

class _AlwaysDisabledFocusNode extends FocusNode {
  @override
  bool get hasFocus => false;
}
