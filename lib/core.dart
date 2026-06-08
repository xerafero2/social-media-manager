import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// --- MODELS ---
class Account {
  final int? id;
  final String platform;
  final String username;
  final String password;
  final int isDeleted;
  final int updatedAt;
  final String? totpKey;
  final String? customIconPath;

  Account({
    this.id,
    required this.platform,
    required this.username,
    required this.password,
    this.isDeleted = 0,
    required this.updatedAt,
    this.totpKey,
    this.customIconPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'platform': platform,
      'username': username,
      'password': EncryptionService.encrypt(password),
      'isDeleted': isDeleted,
      'updatedAt': updatedAt,
      'totpKey': totpKey,
      'customIconPath': customIconPath,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      platform: map['platform'],
      username: map['username'],
      password: EncryptionService.decrypt(map['password']),
      isDeleted: map['isDeleted'],
      updatedAt: map['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      totpKey: map['totpKey'],
      customIconPath: map['customIconPath'],
    );
  }
}

// --- SERVICES ---
class EncryptionService {
  static final _key = enc.Key.fromUtf8('c39812b1a9c8b74c4a6a5d4e3f2a1b9c');
  static final _iv = enc.IV.fromLength(16);
  static final _encrypter = enc.Encrypter(enc.AES(_key));

  static String encrypt(String text) {
    return _encrypter.encrypt(text, iv: _iv).base64;
  }

  static String decrypt(String base64) {
    try {
      return _encrypter.decrypt64(base64, iv: _iv);
    } catch (e) {
      return "ERROR";
    }
  }
}

class SecurityService {
  static final LocalAuthentication auth = LocalAuthentication();
  static Future<bool> authenticateUser() async {
    try {
      final canAuthenticate = await auth.canCheckBiometrics || await auth.isDeviceSupported();
      if (!canAuthenticate) return true;
      return await auth.authenticate(
        localizedReason: 'Please authenticate to access your vault',
        options: const AuthenticationOptions(stickyAuth: true),
      );
    } catch (e) {
      return false;
    }
  }
}

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;
  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('accounts_v4.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        platform TEXT NOT NULL,
        username TEXT NOT NULL,
        password TEXT NOT NULL,
        isDeleted INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        totpKey TEXT,
        customIconPath TEXT
      )
    ''');
  }

  Future<int> insert(Account account) async {
    final db = await instance.database;
    return await db.insert('accounts', account.toMap());
  }

  Future<List<Account>> getAllAccounts() async {
    final db = await instance.database;
    final maps = await db.query('accounts');
    return maps.map((map) => Account.fromMap(map)).toList();
  }

  Future<int> update(Account account) async {
    final db = await instance.database;
    return db.update('accounts', account.toMap(), where: 'id = ?', whereArgs: [account.id]);
  }

  Future<int> deletePermanent(int id) async {
    final db = await instance.database;
    return await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }
}

class DataService {
  static Future<void> exportToClipboard(List<Account> accounts) async {
    List<Map<String, dynamic>> data = accounts.map((a) => {
      'platform': a.platform, 'username': a.username, 'password': a.password,
      'isDeleted': a.isDeleted, 'updatedAt': a.updatedAt,
      'totpKey': a.totpKey, 'customIconPath': a.customIconPath
    }).toList();
    
    String jsonString = jsonEncode(data);
    String encryptedData = EncryptionService.encrypt(jsonString);
    await Clipboard.setData(ClipboardData(text: "SMM_BACKUP::$encryptedData"));
  }

  static Future<bool> importFromClipboard() async {
    try {
      ClipboardData? data = await Clipboard.getData('text/plain');
      if (data == null || data.text == null || !data.text!.startsWith("SMM_BACKUP::")) return false;
      
      String decryptedJson = EncryptionService.decrypt(data.text!.replaceFirst("SMM_BACKUP::", ""));
      List<dynamic> parsed = jsonDecode(decryptedJson);
      
      for (var item in parsed) {
        await DatabaseService.instance.insert(Account(
          platform: item['platform'] ?? 'Unknown',
          username: item['username'] ?? '',
          password: item['password'] ?? '',
          isDeleted: item['isDeleted'] ?? 0,
          updatedAt: item['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch,
          totpKey: item['totpKey'],
          customIconPath: item['customIconPath'],
        ));
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}

// --- PROVIDERS ---
final sortProvider = StateProvider<bool>((ref) => true); // True: Newest, False: Oldest
final accountsProvider = StateNotifierProvider<AccountNotifier, List<Account>>((ref) {
  return AccountNotifier();
});

class AccountNotifier extends StateNotifier<List<Account>> {
  AccountNotifier() : super([]) { loadAccounts(); }

  Future<void> loadAccounts() async {
    state = await DatabaseService.instance.getAllAccounts();
  }

  Future<void> addAccount(Account account) async {
    await DatabaseService.instance.insert(account);
    await loadAccounts();
  }
  
  Future<void> updateAccount(Account account) async {
    await DatabaseService.instance.update(account);
    await loadAccounts();
  }

  Future<void> moveToTrash(Account account) async {
    await updateAccount(Account(
      id: account.id, platform: account.platform, username: account.username, 
      password: account.password, isDeleted: 1, updatedAt: DateTime.now().millisecondsSinceEpoch,
      totpKey: account.totpKey, customIconPath: account.customIconPath
    ));
  }

  Future<void> restore(Account account) async {
    await updateAccount(Account(
      id: account.id, platform: account.platform, username: account.username, 
      password: account.password, isDeleted: 0, updatedAt: DateTime.now().millisecondsSinceEpoch,
      totpKey: account.totpKey, customIconPath: account.customIconPath
    ));
  }

  Future<void> deletePermanent(int id) async {
    await DatabaseService.instance.deletePermanent(id);
    await loadAccounts();
  }
}
