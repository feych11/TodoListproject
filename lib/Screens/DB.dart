import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:todolistfullstack/Screens/HomeScreen.dart';

class UserItem {
  int? id;
  String username;
  String password;
  String email;

  UserItem({this.id, required this.username, required this.password, required this.email});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'email': email,
    };
  }
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'user_database.db');
    return openDatabase(
      path,
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT, password TEXT, email TEXT)",
        );
      },
      version: 1,
    );
  }


  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT,
        isCompleted INTEGER
      )
    ''');
  }

  Future<int> addTask(TaskItem task) async {
    Database db = await database;
    return await db.insert('tasks', task.toMap());
  }

  Future<List<TaskItem>> getTasks() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tasks');

    return List.generate(maps.length, (i) {
      return TaskItem(
        id: maps[i]['id'],
        description: maps[i]['description'],
        isCompleted: maps[i]['isCompleted'] == 1,
      );
    });
  }

  Future<int> updateTask(TaskItem task) async {
    Database db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    Database db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Method to add a new user to the database
  Future<void> addUser(UserItem user) async {
    final db = await database;
    await db.insert(
      'users', // Assuming you have a users table
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('User added: ${user.username}');
  }

  // Optional: Method to retrieve all users
  Future<List<UserItem>> getUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users');

    return List.generate(maps.length, (i) {
      return UserItem(
        id: maps[i]['id'],
        username: maps[i]['username'],
        password: maps[i]['password'],
        email: maps[i]['email'],
      );
    });
  }

  Future<bool> validateUser(String email, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    return maps.isNotEmpty;
  }

}
