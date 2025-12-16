import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/note.dart';

class DBHelper {
  static const _dbName = 'app.db';
  static const _dbVersion = 1;
  static Database? _db;
  static const notesTable = 'notes';

  static Future<Database> _open() async {
    if (_db != null) return _db!;
    
    try {
      print('[DB] Получаем путь к директории документов...');
      final docs = await getApplicationDocumentsDirectory();
      print('[DB] Директория документов: ${docs.path}');
      
      final dbPath = p.join(docs.path, _dbName);
      print('[DB] Полный путь к БД: $dbPath');
      
      _db = await openDatabase(
        dbPath,
        version: _dbVersion,
        onCreate: (db, version) async {
          print('[DB] Создание таблицы notes, версия: $version');
          try {
            await db.execute('''
              CREATE TABLE $notesTable(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                body TEXT NOT NULL,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL
              );
            ''');
            await db.execute(
                'CREATE INDEX idx_notes_created_at ON $notesTable(created_at DESC);');
            print('[DB] Таблица успешно создана');
          } catch (e) {
            print('[DB] Ошибка при создании таблицы: $e');
            rethrow;
          }
        },
        onUpgrade: (db, oldV, newV) async {
          print('[DB] Обновление БД с версии $oldV на $newV');
        },
      );
      
      print('[DB] База данных успешно открыта');
      
      // Проверяем существование таблицы
      final tables = await _db!.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$notesTable'");
      print('[DB] Существующие таблицы: $tables');
      
    } catch (e, stackTrace) {
      print('[DB] Критическая ошибка при открытии БД: $e');
      print('[DB] Stack trace: $stackTrace');
      rethrow;
    }
    
    return _db!;
  }

  // CREATE
  static Future<int> insertNote(Note note) async {
    try {
      print('[DB] Вставка заметки: ${note.title}');
      final db = await _open();
      final id = await db.insert(
        notesTable, 
        note.toMap(), 
        conflictAlgorithm: ConflictAlgorithm.abort
      );
      print('[DB] Заметка добавлена с ID: $id');
      return id;
    } catch (e, stackTrace) {
      print('[DB] Ошибка при вставке заметки: $e');
      print('[DB] Stack trace: $stackTrace');
      rethrow;
    }
  }

  // READ all
  static Future<List<Note>> fetchNotes() async {
    try {
      print('[DB] Загрузка всех заметок...');
      final db = await _open();
      final rows = await db.query(notesTable, orderBy: 'created_at DESC');
      print('[DB] Загружено заметок: ${rows.length}');
      return rows.map((m) => Note.fromMap(m)).toList();
    } catch (e, stackTrace) {
      print('[DB] Ошибка при загрузке заметок: $e');
      print('[DB] Stack trace: $stackTrace');
      rethrow;
    }
  }

  // UPDATE
  static Future<int> updateNote(Note note) async {
    try {
      print('[DB] Обновление заметки ID: ${note.id}');
      final db = await _open();
      final count = await db.update(
        notesTable,
        note.toMap(),
        where: 'id = ?',
        whereArgs: [note.id],
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      print('[DB] Обновлено строк: $count');
      return count;
    } catch (e, stackTrace) {
      print('[DB] Ошибка при обновлении заметки: $e');
      print('[DB] Stack trace: $stackTrace');
      rethrow;
    }
  }

  // DELETE
  static Future<int> deleteNote(int id) async {
    try {
      print('[DB] Удаление заметки ID: $id');
      final db = await _open();
      final count = await db.delete(
        notesTable, 
        where: 'id = ?', 
        whereArgs: [id]
      );
      print('[DB] Удалено строк: $count');
      return count;
    } catch (e, stackTrace) {
      print('[DB] Ошибка при удалении заметки: $e');
      print('[DB] Stack trace: $stackTrace');
      rethrow;
    }
  }
}