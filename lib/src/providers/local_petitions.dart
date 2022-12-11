import 'package:scheduling/src/models/petition.dart';
import 'package:scheduling/src/providers/local_db.dart';

export 'package:scheduling/src/models/petition.dart' show Petition;

class LocalPetitions extends Localdb<Petition, Map<String, dynamic>> {
  LocalPetitions() : super(
    directory: LocalDirectory.temporary,
    folderName: 'scheduling',
    database: 'petitions',
    version: 1,
    adapter: const Petition(),
    raw: <String, dynamic>{},
  );
}
