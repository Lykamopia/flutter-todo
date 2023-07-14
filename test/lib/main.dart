import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(TodoApp());
}

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Todo',
      theme: ThemeData(
        primaryColor: Color(0xFFab47bc),
        colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Color(0xFFba68c8)),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => TodoListScreen()),
      );
    });

    return Scaffold(
      body: Center(
        child: FlutterLogo(
          size: 200,
        ),
      ),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
 late SharedPreferences sharedPreferences;
  List<TodoTask> todoTasks = [];
  List<TodoTask> filteredTasks = [];
  TaskFilter filter = TaskFilter.all;

  @override
  void initState() {
    super.initState();
    initSharedPreferences();
  }

  Future<void> initSharedPreferences() async {
    
  sharedPreferences = await SharedPreferences.getInstance();
  loadTasks();
    sharedPreferences = await SharedPreferences.getInstance();
    loadTasks();
  }

  void loadTasks() {
    setState(() {
      todoTasks = TodoTask.fromSharedPreferences(sharedPreferences);
      applyFilter();
    });
  }

  void applyFilter() {
    switch (filter) {
      case TaskFilter.all:
        filteredTasks = todoTasks;
        break;
      case TaskFilter.done:
        filteredTasks = todoTasks.where((task) => task.isDone).toList();
        break;
      case TaskFilter.undone:
        filteredTasks = todoTasks.where((task) => !task.isDone).toList();
        break;
      case TaskFilter.progress:
        filteredTasks = todoTasks.where((task) => !task.isDone && !task.isCancelled).toList();
        break;
      case TaskFilter.cancel:
        filteredTasks = todoTasks.where((task) => task.isCancelled).toList();
        break;
    }
  }

  void addTask(String description) {
    setState(() {
      final newTask = TodoTask(description: description);
      todoTasks.add(newTask);
      sharedPreferences.setStringList('tasks', TodoTask.toSharedPreferences(todoTasks));
      applyFilter();
    });
  }

  void updateTask(TodoTask task) {
    setState(() {
      task.toggleDone();
      sharedPreferences.setStringList('tasks', TodoTask.toSharedPreferences(todoTasks));
      applyFilter();
    });
  }

  void cancelTask(TodoTask task) {
    setState(() {
      task.cancel();
      sharedPreferences.setStringList('tasks', TodoTask.toSharedPreferences(todoTasks));
      applyFilter();
    });
  }

  void deleteTask(TodoTask task) {
    setState(() {
      todoTasks.remove(task);
      sharedPreferences.setStringList('tasks', TodoTask.toSharedPreferences(todoTasks));
      applyFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Todo'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Enter a task',
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        addTask(value);
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    if (TodoTask.isNotEmptyString()) {
                      addTask(TodoTask.defaultTaskDescription);
                    }
                  },
                ),
              ],
            ),
          ),
          _buildFilterBar(),
          Expanded(
            child: ListView.builder(
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                final task = filteredTasks[index];
                return _buildTaskItem(task);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(TodoTask task) {
    return ListTile(
      title: Text(task.description),
      leading: Checkbox(
        value: task.isDone,
        onChanged: (value) => updateTask(task),
      ),
      trailing: IconButton(
        icon: Icon(Icons.delete),
        onPressed: () => deleteTask(task),
      ),
      onTap: () => cancelTask(task),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildFilterButton(TaskFilter.all),
          _buildFilterButton(TaskFilter.done),
          _buildFilterButton(TaskFilter.undone),
          _buildFilterButton(TaskFilter.progress),
          _buildFilterButton(TaskFilter.cancel),
        ],
      ),
    );
  }

  Widget _buildFilterButton(TaskFilter buttonFilter) {
    final isSelected = filter == buttonFilter;
    final buttonText = buttonFilter == TaskFilter.all
        ? 'All'
        : buttonFilter == TaskFilter.done
            ? 'Done'
            : buttonFilter == TaskFilter.undone
                ? 'Undone'
                : buttonFilter == TaskFilter.progress
                    ? 'In Progress'
                    : 'Cancelled';

    return ElevatedButton(
      onPressed: () {
        setState(() {
          filter = buttonFilter;
          applyFilter();
        });
      },
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (isSelected) {
              return Theme.of(context).colorScheme.secondary;
            }
              return Theme.of(context).colorScheme.primary; 
          },
        ),
      ),
      child: Text(
        buttonText,
        style: TextStyle(
          color: isSelected ? Colors.white : null,
        ),
      ),
    );
  }
}

enum TaskFilter {
  all,
  done,
  undone,
  progress,
  cancel,
}

class TodoTask {
  final String description;
  bool isDone;
  bool isCancelled;

  TodoTask({
    required this.description,
    this.isDone = false,
    this.isCancelled = false,
  });

  void toggleDone() {
    isDone = !isDone;
  }

  void cancel() {
    isCancelled = !isCancelled;
  }

  static String defaultTaskDescription = 'New Task';

  static bool isNotEmptyString() {
    return defaultTaskDescription.trim().isNotEmpty;
  }

  static List<TodoTask> fromSharedPreferences(SharedPreferences sharedPreferences) {
    final tasks = sharedPreferences.getStringList('tasks');
    return tasks != null
        ? tasks.map((task) {
            final taskData = task.split('::');
            return TodoTask(
              description: taskData[0],
              isDone: taskData[1] == 'true',
              isCancelled: taskData[2] == 'true',
            );
          }).toList()
        : [];
  }

  static List<String> toSharedPreferences(List<TodoTask> tasks) {
    return tasks.map((task) {
      return '${task.description}::${task.isDone}::${task.isCancelled}';
    }).toList();
  }
}
