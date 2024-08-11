import 'package:todolistfullstack/Screens/DB.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TaskItem> tasks = [];
  int completedTasks = 0;
  final TextEditingController _controller = TextEditingController(); // Controller for the input field
  TaskItem? _selectedTask; // Track the task being edited

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final loadedTasks = await DatabaseHelper().getTasks();
      setState(() {
        tasks = loadedTasks;
        completedTasks = tasks.where((task) => task.isCompleted).length;
      });
      print('Tasks loaded successfully: $tasks');
    } catch (e) {
      print('Error loading tasks: $e');
    }
  }

  Future<void> _addOrUpdateTask() async {
    if (_controller.text.isNotEmpty) {
      try {
        if (_selectedTask != null) {
          _selectedTask!.description = _controller.text;
          await DatabaseHelper().updateTask(_selectedTask!);
          print('Task updated: ${_selectedTask!.description}');
          _selectedTask = null;
        } else {
          final newTask = TaskItem(description: _controller.text);
          await DatabaseHelper().addTask(newTask);
          print('Task added: ${newTask.description}');
        }
        _controller.clear();
        _loadTasks();
      } catch (e) {
        print('Error adding/updating task: $e');
      }
    }
  }
  Future<void> _printAllTasks() async {
    try {
      final tasks = await DatabaseHelper().getTasks();
      tasks.forEach((task) {
        print('Task ID: ${task.id}, Description: ${task.description}, Completed: ${task.isCompleted}');
      });
    } catch (e) {
      print('Error retrieving tasks: $e');
    }
  }

  Future<void> _deleteTask(int id) async {
    try {
      await DatabaseHelper().deleteTask(id);
      print('Task marked as deleted: $id');
      _loadTasks();
    } catch (e) {
      print('Error deleting task: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with completed tasks count
            Card(
              color: Color(0xFF1E1E1E),
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Todo Done',
                        style: GoogleFonts.oswald(
                          fontSize: 29,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '$completedTasks/${tasks.length}',
                      style: GoogleFonts.poppins(
                        fontSize: 48,
                        color: Color(0xFFFF5A3C),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Input field to add or edit a task
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller, // Attach the controller to the input field
                    decoration: InputDecoration(
                      hintText: 'Write your next task',
                      hintStyle: TextStyle(color: Colors.black54,fontSize: 20,fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      setState(() {
                        if (_selectedTask != null) {
                          // Update the selected task
                          _selectedTask!.description = _controller.text;
                          _selectedTask = null;
                          setState(() {
                            _addOrUpdateTask();
                            _printAllTasks();
                          });
                          // Clear the selected task after updating
                        } else {
                          // Add a new task
                          tasks.add(TaskItem(description: _controller.text));
                        }
                        _controller.clear(); // Clear the input field after adding or updating the task
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF5A3C), // Orange button color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  ),
                  child: Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),

            SizedBox(height: 20),

            // List of tasks
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return TaskCard(
                    task: task,
                    onCompleted: (isChecked) {
                      setState(() {
                        task.isCompleted = isChecked;
                        completedTasks = tasks.where((task) => task.isCompleted).length;
                      });
                    },
                    onDelete: () {
                      setState(() {
                        tasks.removeAt(index);
                        completedTasks = tasks.where((task) => task.isCompleted).length;
                        _deleteTask(task.id!);
                      });
                    },
                    onEdit: () {
                      setState(() {
                        _selectedTask = task;
                        _controller.text = task.description; // Set the selected task text in the input field
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskItem {
  int? id;
  String description;
  bool isCompleted;

  TaskItem({this.id, required this.description, this.isCompleted = false});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }
}

class TaskCard extends StatelessWidget {
  final TaskItem task;
  final ValueChanged<bool> onCompleted;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  TaskCard({
    required this.task,
    required this.onCompleted,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0xFF1E1E1E),
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (bool? value) {
            onCompleted(value!);
          },
          activeColor: Color(0xFFFF5A3C),
          checkColor: Colors.white,
        ),
        title: GestureDetector(
          onTap: onEdit,
          child: Text(
            task.description,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
