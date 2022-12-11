// ignore_for_file: library_private_types_in_public_api, unnecessary_overrides

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

export 'package:sembast/sembast.dart' show SortOrder;

enum LocalDirectory {
  current,
  documents,
  temporary,
  support;

  Future<String> getPath() async {
    switch (this) {
      case current:
        return Directory.current.path;
      case documents:
        return (await getApplicationDocumentsDirectory()).path;
      case temporary:
        return (await getTemporaryDirectory()).path;
      case support:
        return (await getApplicationSupportDirectory()).path;
      default:
        throw _InitialErrorType.unknownError;
    }
  }
}

@immutable
abstract class Adapterdb<AT, MT extends Map> {
  final _KT? key = null as _KT;

  AT fromMap(_KT? key, MT map) {
    assert(
      true,
      '[super.fromMap($_KT, $MT) => $AT], this should not be called.',
    );
    return null as AT;
  }

  MT toMap() {
    assert(true, '[super.toMap() => $MT], this should not be called.');
    return null as MT;
  }
}

abstract class Localdb<AT extends Adapterdb<AT, MT>, MT extends Map>
  with ChangeNotifier, DiagnosticableTreeMixin {
  Localdb({
    required LocalDirectory directory,
    required String? folderName,
    required String database,
    required int version,
    required AT adapter,
    required MT raw,
  }) :
    assert(adapter is! List, '[adapter] must not be a [List].'),
    assert(raw is! List && raw.isEmpty, '[raw] must be an empty [Map].'),
    assert(version>0, 'The database version must be valid.'),
    assert(
      _rFilename.hasMatch(database),
      'The database filename must be valid.',
    ),
    assert(
      folderName==null || _rFilename.hasMatch(folderName),
      'The database folder name must be valid.',
    ),
    _atInstance = adapter,
    _version = version,
    _databaseName = '$database.db',
    _folderName = folderName ?? '',
    _directory = directory;

  String get folderName => _folderName;

  String get databaseName => _databaseName;

  int get version => _version;

  bool get isInitilized => _database!=null;

  bool get isProcessing {
    assert(isInitilized, 'The database must be initialized.');
    return _isProcessing;
  }

  AT? get first {
    assert(isInitilized, 'The database must be initialized.');
    return _firstValue;
  }

  int get length {
    assert(isInitilized, 'The database must be initialized.');
    return _length;
  }

  int get total {
    assert(isInitilized, 'The database must be initialized.');
    return _total;
  }

  Future<void> initialize({OnVersionChangedFunction? onVersionChanged}) async {
    if (isInitilized) return;

    var dbFilePath = '';
    var dbFileExists = false;

    try {
      final isMobile = Platform.isAndroid || Platform.isIOS;
      final separator = Platform.pathSeparator;
      final dbParentPath = await _directory.getPath();
      final dbDirectory = isMobile
                        ? Directory(dbParentPath)
                        : _folderName.isEmpty
                          ? Directory(dbParentPath)
                          : Directory(dbParentPath + separator + _folderName);
      dbFilePath = dbDirectory.path + separator + _databaseName;
      dbFileExists = await File(dbFilePath).exists();

      final dbDirExists = await dbDirectory.exists();
      if (!dbDirExists) await dbDirectory.create(recursive: true);

      _database = await databaseFactoryIo.openDatabase(
        dbFilePath,
        version: _version,
        onVersionChanged: onVersionChanged,
      );
      await _setFirst(true, init: true);
      await _setLength();
      await _updateTotal(init: true);
      return;
    } catch (error) {
      if (error.toString().contains('Invalid codec signature')) {
        throw _InitialErrorType.signatureError;
      } else if (!dbFileExists) {
        try {
          await File(dbFilePath).delete();
        } catch (_) {}
        throw _InitialErrorType.creationError;
      } else {
        throw _InitialErrorType.readingError;
      }
    }
  }

  Future<List<_KT>> getKeys() async {
    assert(isInitilized, 'The database must be initialized.');
    return await _mainStoreRef.findKeys(_database!);
  }

  Future<List<AT>> set(List<AT> values, {bool notify = true}) async {
    assert(isInitilized, 'The database must be initialized.');
    if (_isProcessing || values.isEmpty) {
      return [];
    } else {
      if (notify) _setProcessing(true);

      final addedAndUpdated = <AT>[];
      final listOfAdditions = <AT>[];
      final existingKeys = await getKeys();

      for (final value in values) {
        final exists = existingKeys.contains(value.key);
        final isSet = await _set(value, exists);
        if (isSet) addedAndUpdated.add(value);
        if (isSet && !exists) listOfAdditions.add(value);
      }

      if (listOfAdditions.isNotEmpty && _firstValue==null) {
        final firstAddedKey = listOfAdditions.first.key;
        if (firstAddedKey!=null) {
          final addedRecordRef = _mainStoreRef.record(firstAddedKey);
          final addedSnapshot = await addedRecordRef.getSnapshot(_database!);
          await _setFirst(_firstValue==null, first: addedSnapshot);
        }
      }
      await _setLength();
      await _updateTotal(added: listOfAdditions.length);

      if (notify) _setProcessing(false);

      return addedAndUpdated;
    }
  }

  Future<AT?> get(_KT? key) async {
    assert(isInitilized, 'The database must be initialized.');

    final result = await _read(key);

    if (key==null || result==null) {
      return null;
    } else {
      return _atInstance.fromMap(key, result);
    }
  }

  Future<List<AT>> search({
    int? currentPage,
    int? perPage,
    List<SortOrder>? sortList,
    required bool Function(AT adapter) where,
  }) async {
    assert(isInitilized, 'The database must be initialized.');
    assert(
      (currentPage==null && perPage==null)
      || ((currentPage ?? 0)>0 && (perPage ?? 0)>0),
      (() {
        if (currentPage!=null && perPage==null) {
          return
            'If you want the whole result without '
            'pagination, then [currentPage] must be null.';
        } else if (currentPage==null && perPage!=null) {
          return
            'If you want the whole result without '
            'pagination, then [perPage] must be null.';
        } else if ((currentPage ?? 0)<=0) {
          return '[currentPage] must be greater than 0.';
        } else if ((perPage ?? 0)<=0) {
          return '[perPage] must be greater than 0.';
        } else {
          return 'Unknown error.';
        }
      })(),
    );

    final result = await _mainStoreRef.find(
      _database!,
      finder: Finder(
        limit: perPage,
        offset: currentPage!=null && perPage!=null
                ? perPage * (currentPage - 1)
                : null,
        sortOrders: sortList,
        filter: Filter.custom((snapshot) {
          if (where(_atInstance.fromMap(snapshot.key, snapshot.value))) {
            return true;
          } else {
            return false;
          }
        }),
      ),
    );

    return result.map((s) => _atInstance.fromMap(s.key, s.value)).toList();
  }

  Future<bool> remove(_KT? key, {bool notify = true}) async {
    assert(isInitilized, 'The database must be initialized.');
    if (_isProcessing || key==null) {
      return false;
    } else {
      if (notify) _setProcessing(true);

      final result = await _delete(key);

      if (notify) _setProcessing(false);

      return result;
    }
  }

  Future<List<_KT>> removeAll({
    bool first = true,
    bool notify = true,
  }) async {
    assert(isInitilized, 'The database must be initialized.');
    if (_isProcessing) {
      return [];
    } else {
      if (notify) _setProcessing(true);

      final result = <_KT>[];
      final firstKey = _firstValue?.key;
      final keys = await getKeys();

      for (final key in keys) {
        if (!first && firstKey!=null && key.contains(firstKey)) continue;
        final isDeleted = await _delete(key);
        if (isDeleted) result.add(key);
      }

      if (notify) _setProcessing(false);

      return result;
    }
  }

  @override
  void notifyListeners() => super.notifyListeners();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<String>('folderName', folderName));
    properties.add(DiagnosticsProperty<String>('databaseName', databaseName));
    properties.add(DiagnosticsProperty<int>('version', version));
    properties.add(DiagnosticsProperty<bool>('isInitilized', isInitilized));
    properties.add(DiagnosticsProperty<bool>('isProcessing', isProcessing));
    properties.add(DiagnosticsProperty<AT>('first', first));
    properties.add(DiagnosticsProperty<int>('length', length));
    properties.add(DiagnosticsProperty<int>('total', total));
  }

  @override
  void dispose() {
    _database?.close();
    super.dispose();
  }

  final LocalDirectory _directory;
  final String _folderName;
  final String _databaseName;
  final int _version;
  final AT _atInstance;

  final _mainStoreRef = StoreRef<_KT, MT>.main();
  final _firstRecordRef = StoreRef<int, _KT>('first').record(0);
  final _totalRecordRef = StoreRef<int, int>('total').record(0);

  Database? _database;
  AT? _firstValue;
  var _isProcessing = false;
  var _length = -1;
  var _total = -1;

  void _setProcessing(bool value) {
    final notify = value!=_isProcessing;
    _isProcessing = value;
    if (notify) super.notifyListeners();
  }

  Future<void> _setFirst(
    bool condition, {
    bool init = false,
    bool update = false,
    RecordSnapshot<_KT, MT>? first,
  }) async {
    assert(
      (() {
        if (init==true) {
          if (update==false && first==null) {
            return true;
          } else {
            return false;
          }
        } else if (update==true) {
          if (init==false && first==null) {
            return true;
          } else {
            return false;
          }
        } else if (first!=null) {
          if (init==false && update==false) {
            return true;
          } else {
            return false;
          }
        } else {
          return true;
        }
      })(),
      '[init], [update] and [first] must be compatible.',
    );
    if (condition) {
      if (init) {
        final firstKey = await _firstRecordRef.get(_database!);
        final retrieved = await _read(firstKey);
        if (firstKey==null || retrieved==null) {
          _firstValue = null;
          await _firstRecordRef.add(_database!, '');
        } else {
          _firstValue = _atInstance.fromMap(firstKey, retrieved);
        }
      } else if (update && _firstValue!=null) {
        final current = await _read(_firstValue!.key);
        _firstValue = current==null
                      ? null
                      : _atInstance.fromMap(_firstValue!.key, current);
      } else if (first!=null) {
        final updated = await _firstRecordRef.update(_database!, first.key);
        _firstValue = updated==null
                      ? null
                      : _atInstance.fromMap(first.key, first.value);
      } else {
        final found = await _mainStoreRef.findFirst(_database!);
        final updated = found==null
                        ? null
                        : await _firstRecordRef.update(_database!, found.key);
        _firstValue = found==null || updated==null
                      ? null
                      : _atInstance.fromMap(found.key, found.value);
      }
    }
  }

  Future<void> _setLength() async {
    _length = (await _mainStoreRef.findKeys(_database!)).length;
  }

  Future<void> _updateTotal({int added = 1, bool init = false}) async {
    if (init || _total==-1) {
      final retrieved = await _totalRecordRef.get(_database!);
      if (retrieved==null) {
        await _totalRecordRef.add(_database!, _total = 0);
      } else {
        _total = retrieved;
      }
    } else {
      _total = await _totalRecordRef.update(_database!, _total + added) ?? -1;
    }
  }

  Future<bool> _set(AT value, bool exists) async {
    try {
      if (value.key==null) {
        return false;
      } else {
        if (!exists) {
          return _create(value);
        } else {
          return _update(value);
        }
      }
    } catch (error) {
      return false;
    }
  }

  Future<bool> _create(AT value) async {
    try {
      final key = value.key;
      if (key==null) {
        return false;
      } else {
        final recordRef = _mainStoreRef.record(key);
        final isCreated = await recordRef.add(_database!, value.toMap());
        if (isCreated!=null) {
          return true;
        } else {
          return false;
        }
      }
    } catch (error) {
      return false;
    }
  }

  Future<MT?> _read(_KT? key) async {
    try {
      if (key==null) {
        return null;
      } else {
        final recordRef = _mainStoreRef.record(key);
        final rawValue = await recordRef.get(_database!);
        return rawValue;
      }
    } catch (error) {
      return null;
    }
  }

  Future<bool> _update(AT value) async {
    try {
      final key = value.key;
      if (key==null) {
        return false;
      } else {
        final recordRef = _mainStoreRef.record(key);
        final isUpdated = await recordRef.update(_database!, value.toMap());
        if (isUpdated!=null) {
          await _setFirst(_firstValue?.key==key, update: true);
          return true;
        } else {
          return false;
        }
      }
    } catch (error) {
      return false;
    }
  }

  Future<bool> _delete(_KT key) async {
    try {
      final recordRef = _mainStoreRef.record(key);
      final isDeleted = await recordRef.delete(_database!);
      if (isDeleted!=null) {
        await _setFirst(_firstValue?.key==key);
        await _setLength();
        return true;
      } else {
        return false;
      }
    } catch (error) {
      return false;
    }
  }
}

typedef _KT = String;

final _rFilename = RegExp(r'^[0-9a-zA-Z_]+$');

enum _InitialErrorType {
  creationError,
  readingError,
  signatureError,
  unknownError;

  @override
  String toString() {
    switch (this) {
      case _InitialErrorType.creationError:
        return 'CREATION_ERROR';
      case _InitialErrorType.readingError:
        return 'READING_ERROR';
      case _InitialErrorType.signatureError:
        return 'SIGNATURE_ERROR';
      default:
        return 'UNKNOWN_ERROR';
    }
  }
}
