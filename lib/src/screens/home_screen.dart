import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:scheduling/src/providers/local_db.dart';
import 'package:scheduling/src/providers/local_petitions.dart';
import 'package:scheduling/src/screens/petition_screen.dart';
import 'package:scheduling/src/utilities/functions.dart';
import 'package:scheduling/src/utilities/parse.dart';
import 'package:scheduling/src/widgets/custom_stateful.dart';
import 'package:scheduling/src/widgets/future_widget.dart';
import 'package:uuid/uuid.dart';

@immutable
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.provider,
  });

  final LocalPetitions? provider;

  @override
  State createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  final _stateController = StateController();

  var _initialData = <Petition>[];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendamiento de canchas'),
        centerTitle: true,
      ),
      body: CustomStateful(
        controller: _stateController,
        builder: (context) {
          return FutureWidget<List<Petition>>(
            future: Future(() async {
              if (widget.provider!=null) {
                await Future.delayed(const Duration(seconds: 1));
                return widget.provider!.search(
                  sortList: [
                    SortOrder(Petition.fields.date, true, true),
                    SortOrder(Petition.fields.gameField, true, true),
                  ],
                  where: (petition) => true,
                );
              } else {
                return [];
              }
            }),
            setState: _stateController.repaint,
            initialData: () => _initialData,
            computeWhere: () => _initialData.isEmpty,
            onDataChanged: (data) => _initialData = data,
            builder: (context, indicator, errorView, petitions) {
              if (indicator!=null) return Center(child: indicator);
              if (errorView!=null) return Center(child: errorView);
              if (petitions?.isEmpty ?? true) {
                return Center(
                  key: const Key('empty_petitions'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.5),
                    child: Text(
                      'No se ha reservado ninguna cancha, \r\n'
                      'para comenzar presione el botón inferior.',
                      style: textTheme.headline6,
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.only(
                  top: 25.0,
                  bottom: 75.0,
                ),
                itemCount: petitions?.length ?? 0,
                separatorBuilder: (context, _) => const Divider(),
                itemBuilder: (context, index) {
                  final petition = (petitions ?? [])[index];
                  final userName = petition.userName;
                  final gameField = petition.gameField;
                  final date = Parse.toReadableDate(petition.date) ?? '';
                  final rain = petition.rain;
                  final rValidDate = RegExp(r'[0-9]{1,2}/[0-9]{1,2}/[0-9]{1,}');
                  return ListTile(
                    leading: const Icon(Icons.sports_tennis),
                    title: Text(
                      [
                        if (gameField!=null) gameField.toReadable(),
                        if (rValidDate.hasMatch(date)) 'día $date',
                        if (userName.isNotEmpty) 'usuario $userName',
                      ].join(', '),
                    ),
                    subtitle: Text(
                      rain==null
                          ? 'Probabilidad de lluvia desconocida'
                          : '${(rain * 100).toStringAsFixed(2)}% '
                            'de probabilidad de lluvia',
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_forever,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        _showModal(
                          context: context,
                          onYes: () async {
                            await Functions.showPause(
                              context: context,
                              future: (context) async {
                                await widget.provider?.remove(petition.key);
                                _stateController.repaint(_initialData.clear);
                              },
                              onSuccess: () {
                                final gameField = petition.gameField;
                                const none = TextCapitalization.none;
                                final date = petition.date;
                                Functions.showSnackBar(
                                  context: context,
                                  duration: const Duration(seconds: 10),
                                  content: Text(
                                    'Se ha eliminado la reservación '
                                    'del día ${Parse.toReadableDate(date)} '
                                    'en la ${gameField?.toReadable(none)}.',
                                  ),
                                );
                              },
                            );
                          },
                          onNot: () {},
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('Reservar'),
        heroTag: const Key('hero_to_reserve'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                return PetitionScreen(
                  petition: Petition(key: const Uuid().v4()),
                  onSaved: (petition) {
                    final gameField = petition.gameField;
                    final date = petition.date;
                    Functions.showSnackBar(
                      context: context,
                      content: Text(
                        'Se ha reservado la '
                        '${gameField?.toReadable(TextCapitalization.none)} '
                        'para el día ${Parse.toReadableDate(date)}.',
                      ),
                    );
                    _stateController.repaint(_initialData.clear);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _stateController.dispose();
    super.dispose();
  }
}

void _showModal({
  required BuildContext context,
  required VoidCallback onYes,
  required VoidCallback onNot,
}) {
  showModalBottomSheet(
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          vertical: 25.0,
          horizontal: 12.5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 300.0,
              child: Text(
                '¿Deseas eliminar la reservación?',
                textAlign: TextAlign.center,
                style: theme.textTheme.headline4?.copyWith(
                  fontSize: theme.textTheme.headline5?.fontSize,
                ),
              ),
            ),
            const SizedBox(height: 15.0),
            SizedBox(
              width: 300.0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.5),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        child: const Text('Si'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          SchedulerBinding.instance.addPostFrameCallback((_) {
                            onYes.call();
                          });
                        },
                      ),
                      const SizedBox(width: 12.5),
                      ElevatedButton(
                        child: const Text('No'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          SchedulerBinding.instance.addPostFrameCallback((_) {
                            onNot.call();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15.0),
          ],
        ),
      );
    },
  );
}
