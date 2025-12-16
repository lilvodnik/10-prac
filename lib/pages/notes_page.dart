import 'package:flutter/material.dart';
import '../data/db_helper.dart';
import '../models/note.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  late Future<List<Note>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = DBHelper.fetchNotes();
    });
  }

  Future<void> _createDialog() async {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _EditDialog(
        titleCtrl: titleCtrl, 
        bodyCtrl: bodyCtrl, 
        title: 'Новая заметка'
      ),
    );
    
    if (ok == true) {
      try {
        final now = DateTime.now();
        final note = Note(
          title: titleCtrl.text.trim(), 
          body: bodyCtrl.text.trim(), 
          createdAt: now, 
          updatedAt: now
        );
        
        print('[UI] Сохранение заметки: ${note.title}');
        await DBHelper.insertNote(note);
        _reload();
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заметка сохранена'))
        );
      } catch (e, stackTrace) {
        print('[UI] Ошибка при сохранении заметки: $e');
        print('[UI] Stack trace: $stackTrace');
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: $e'),
            backgroundColor: Colors.red,
          )
        );
      }
    }
  }

  Future<void> _editDialog(Note n) async {
    final titleCtrl = TextEditingController(text: n.title);
    final bodyCtrl = TextEditingController(text: n.body);
    
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _EditDialog(
        titleCtrl: titleCtrl, 
        bodyCtrl: bodyCtrl, 
        title: 'Редактировать'
      ),
    );
    
    if (ok == true) {
      try {
        final updated = n.copyWith(
          title: titleCtrl.text.trim(),
          body: bodyCtrl.text.trim(),
          updatedAt: DateTime.now(),
        );
        
        print('[UI] Обновление заметки ID: ${updated.id}');
        await DBHelper.updateNote(updated);
        _reload();
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заметка обновлена'))
        );
      } catch (e, stackTrace) {
        print('[UI] Ошибка при обновлении заметки: $e');
        print('[UI] Stack trace: $stackTrace');
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка обновления: $e'),
            backgroundColor: Colors.red,
          )
        );
      }
    }
  }

  Future<void> _delete(Note n) async {
    try {
      print('[UI] Удаление заметки ID: ${n.id}');
      await DBHelper.deleteNote(n.id!);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Удалено'))
      );
      
      _reload();
    } catch (e, stackTrace) {
      print('[UI] Ошибка при удалении заметки: $e');
      print('[UI] Stack trace: $stackTrace');
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка удаления: $e'),
          backgroundColor: Colors.red,
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes SQLite')),
      floatingActionButton: FloatingActionButton(
        onPressed: _createDialog,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Note>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            print('[UI] Ошибка FutureBuilder: ${snap.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text('Ошибка загрузки'),
                  Text(
                    '${snap.error}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _reload,
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }
          
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final notes = snap.data!;
          
          if (notes.isEmpty) {
            return const Center(child: Text('Пока нет заметок. Нажмите +'));
          }
          
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: notes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final n = notes[i];
              return Dismissible(
                key: ValueKey(n.id),
                background: Container(
                  color: Theme.of(context).colorScheme.error.withOpacity(.1),
                ),
                onDismissed: (_) => _delete(n),
                child: Card(
                  child: ListTile(
                    title: Text(
                      n.title.isEmpty ? '(без названия)' : n.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      n.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _editDialog(n),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _delete(n),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EditDialog extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController bodyCtrl;
  final String title;

  const _EditDialog({
    required this.titleCtrl,
    required this.bodyCtrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleCtrl,
            decoration: const InputDecoration(labelText: 'Заголовок'),
          ),
          TextField(
            controller: bodyCtrl,
            decoration: const InputDecoration(labelText: 'Текст'),
            maxLines: 4,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}