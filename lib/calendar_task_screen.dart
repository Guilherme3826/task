import 'package:flutter/material.dart';
import 'task_model.dart';

class CalendarTaskScreen extends StatefulWidget {
  const CalendarTaskScreen({super.key});

  @override
  State<CalendarTaskScreen> createState() => _CalendarTaskScreenState();
}

class _CalendarTaskScreenState extends State<CalendarTaskScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Task> _allTasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await TaskRepository.getTasks();
    setState(() {
      _allTasks = tasks;
    });
  }

  List<Task> get _filteredAndSortedTasks {
    List<Task> filtered = _allTasks.where((task) {
      return task.date.year == _selectedDate.year &&
          task.date.month == _selectedDate.month &&
          task.date.day == _selectedDate.day;
    }).toList();

    filtered.sort((a, b) {
      if (a.isCompleted == b.isCompleted) {
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
      return a.isCompleted ? 1 : -1;
    });

    return filtered;
  }

  Future<void> _addTask(String title) async {
    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      date: _selectedDate,
    );
    await TaskRepository.insertTask(newTask);
    await _loadTasks();
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    task.isCompleted = !task.isCompleted;
    await TaskRepository.updateTask(task);
    await _loadTasks();
  }

  Future<void> _removeTask(Task task) async {
    await TaskRepository.deleteTask(task.id);
    await _loadTasks();
  }

  void _showAddTaskDialog() {
    final TextEditingController titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D2D44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Nova Tarefa',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: titleController,
            style: const TextStyle(color: Colors.white),
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Digite o nome da tarefa',
              hintStyle: TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF4ECDC4)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFFF6B6B)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),
              ),
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  _addTask(titleController.text.trim());
                  Navigator.pop(context);
                }
              },
              child: const Text(
                'Adicionar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksToDisplay = _filteredAndSortedTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Calendário e Tarefas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D44),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Color(0xFFFF6B6B),
                  onPrimary: Colors.white,
                  surface: Color(0xFF2D2D44),
                  onSurface: Colors.white,
                ),
              ),
              child: CalendarDatePicker(
                initialDate: _selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                onDateChanged: (newDate) {
                  setState(() {
                    _selectedDate = newDate;
                  });
                },
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: tasksToDisplay.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhuma tarefa para este dia.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: tasksToDisplay.length,
                      itemBuilder: (context, index) {
                        final task = tasksToDisplay[index];
                        return Card(
                          color: task.isCompleted
                              ? const Color(0xFF1E1E2C)
                              : const Color(0xFF3A3A5A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: task.isCompleted
                                  ? Colors.transparent
                                  : const Color(0xFF4ECDC4).withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          margin: const EdgeInsets.only(bottom: 12.0),
                          child: ListTile(
                            leading: Checkbox(
                              value: task.isCompleted,
                              activeColor: const Color(0xFFFF6B6B),
                              checkColor: Colors.white,
                              side: const BorderSide(
                                color: Color(0xFF4ECDC4),
                                width: 2,
                              ),
                              onChanged: (value) => _toggleTaskCompletion(task),
                            ),
                            title: Text(
                              task.title,
                              style: TextStyle(
                                color: task.isCompleted
                                    ? Colors.grey
                                    : Colors.white,
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                fontWeight: task.isCompleted
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.grey,
                              ),
                              onPressed: () => _removeTask(task),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: const Color(0xFFFF6B6B),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}
