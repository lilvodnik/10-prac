#10 практика
<img width="795" height="628" alt="Снимок экрана 2025-12-16 в 4 13 01 AM" src="https://github.com/user-attachments/assets/ccbf5b34-99f6-4354-8ba4-a53e9a33dd19" />
страница с пустым списком
<img width="802" height="626" alt="Снимок экрана 2025-12-16 в 4 13 24 AM" src="https://github.com/user-attachments/assets/043ec64d-14ab-47a8-87f0-f80df0359bbd" />
<img width="799" height="626" alt="Снимок экрана 2025-12-16 в 4 13 31 AM" src="https://github.com/user-attachments/assets/8b869c30-1529-49fb-968f-1d4631a9b3e8" />
добавление заметки
<img width="788" height="626" alt="Снимок экрана 2025-12-16 в 4 13 43 AM" src="https://github.com/user-attachments/assets/6961d4f1-e3c9-4621-9b9d-d72af53320d0" />
обновление заметки
<img width="800" height="616" alt="Снимок экрана 2025-12-16 в 4 13 53 AM" src="https://github.com/user-attachments/assets/f246f9c0-46b2-4ad6-a879-fa94a854047e" />
удаление заметки

Файл app.db хранится в песочнице приложения
Путь в коде:```
final docs = await getApplicationDocumentsDirectory();
final dbPath = p.join(docs.path, _dbName);
getApplicationDocumentsDirectory() ```

Создание таблицы:```
CREATE TABLE notes(
  id INTEGER PRIMARY KEY AUTOINCREMENT, - id заметки
  title TEXT NOT NULL, - заголовок заметки
  body TEXT NOT NULL, - текст заметки
  created_at INTEGER NOT NULL, - время создание
  updated_at INTEGER NOT NULL - время обновления 
);```

Индексы заметок:```
CREATE INDEX idx_notes_created_at ON notes(created_at DESC);```
Индекс нужен для ускорения поиска заметки и для сортировки по новизне, чтобы новые заметки были вверху списка

CRUD
C - Create```
static Future<int> insertNote(Note note) async {
  final db = await _open();
  return db.insert(notesTable, note.toMap());
}```

Преобразовываем объект Note в Map с помощью toMap(), затем с помощью db.insert() делаем sql запрос и возвращаем ID записи

R - Read```
static Future<List<Note>> fetchNotes() async {
  final db = await _open();
  final rows = await db.query(
    notesTable, 
    orderBy: 'created_at DESC' 
  );
  return rows.map((m) => Note.fromMap(m)).toList();
}```

db.query() выполняет: SELECT * FROM notes ORDER BY created_at DESC
Преобразовываем каждую строку из Map в объект Note через fromMap()

U - Update```
static Future<int> updateNote(Note note) async {
  final db = await _open();
  return db.update(
    notesTable,
    note.toMap(),
    where: 'id = ?',          
    whereArgs: [note.id],     
  );
}```
Вызывем db.update для обновления, преобразовываем обьект note.toMap(), и заменяем нужную строчку  where: 'id = ?'


D - Delete```
static Future<int> deleteNote(int id) async {
  final db = await _open();
  return db.delete(
    notesTable, 
    where: 'id = ?', 
    whereArgs: [id]
  );
}```
Вызываем db.delete для удаления, и удаляем нужную строчку where: 'id = ?'

