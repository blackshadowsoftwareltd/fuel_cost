import 'dart:async';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/fuel_entry.dart';

class DatabaseService {
  static Isar? _isar;
  static Completer<Isar>? _completer;

  static Future<Isar> get database async {
    if (_isar != null && _isar!.isOpen) return _isar!;

    // Prevent multiple concurrent Isar.open() calls
    if (_completer != null) return _completer!.future;

    _completer = Completer<Isar>();
    try {
      final dir = await getApplicationDocumentsDirectory();
      final instance = Isar.getInstance() ??
          await Isar.open(
            [FuelEntrySchema],
            directory: dir.path,
          );
      _isar = instance;
      _completer!.complete(instance);
      return instance;
    } catch (e) {
      _completer!.completeError(e);
      rethrow;
    } finally {
      _completer = null;
    }
  }

  static Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}
