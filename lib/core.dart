import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// --- PROVIDERS ---
final languageProvider = StateProvider<String>((ref) => "Bahasa Indonesia");
enum SortType { newest, oldest, az, za }
final sortProvider = StateProvider<SortType>((ref) => SortType.newest);

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
    this.id, required this.platform, required this.username, required this.password,
    this.isDeleted = 0, required this.updatedAt, this.totpKey, this.customIconPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id, 'platform': platform, 'username': username,
      'password': EncryptionService.encrypt(password), 'isDeleted': isDeleted,
      'updatedAt': updatedAt, 'totpKey': totpKey, 'customIconPath': customIconPath,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'], platform: map['platform'], username: map['username'],
      password: EncryptionService.decrypt(map['password']), isDeleted: map['isDeleted'],
      updatedAt: map['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      totpKey: map['totpKey'], customIconPath: map['customIconPath'],
    );
  }
}

class EncryptionService {
  static final _key = enc.Key.fromUtf8('c39812b1a9c8b74c4a6a5d4e3f2a1b9c');
  static final _iv = enc.IV.fromLength(16);
  static final _encrypter = enc.Encrypter(enc.AES(_key));
  static String encrypt(String text) => _encrypter.encrypt(text, iv: _iv).base64;
  static String decrypt(String base64) {
    try { return _encrypter.decrypt64(base64, iv: _iv); } catch (e) { return "ERROR"; }
  }
}

class SecurityService {
  static final LocalAuthentication auth = LocalAuthentication();
  static Future<bool> authenticateUser() async {
    try {
      final can = await auth.canCheckBiometrics || await auth.isDeviceSupported();
      if (!can) return true;
      return await auth.authenticate(localizedReason: 'Otentikasi diperlukan', options: const AuthenticationOptions(stickyAuth: true));
    } catch (e) { return false; }
  }
}

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;
  DatabaseService._init();
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await openDatabase(join(await getDatabasesPath(), 'accounts_v5.db'), version: 1, onCreate: (db, v) async {
      await db.execute('CREATE TABLE accounts (id INTEGER PRIMARY KEY AUTOINCREMENT, platform TEXT, username TEXT, password TEXT, isDeleted INTEGER, updatedAt INTEGER, totpKey TEXT, customIconPath TEXT)');
    });
    return _database!;
  }
  Future<int> insert(Account a) async => (await instance.database).insert('accounts', a.toMap());
  Future<List<Account>> getAll() async => (await (await instance.database).query('accounts')).map((m) => Account.fromMap(m)).toList();
  Future<int> update(Account a) async => (await instance.database).update('accounts', a.toMap(), where: 'id = ?', whereArgs: [a.id]);
  Future<int> delete(int id) async => (await instance.database).delete('accounts', where: 'id = ?', whereArgs: [id]);
}

class DataService {
  static Future<void> exportToClipboard(List<Account> accounts) async {
    List<Map<String, dynamic>> data = accounts.map((a) => a.toMap()).toList();
    await Clipboard.setData(ClipboardData(text: "SMM_BACKUP::${EncryptionService.encrypt(jsonEncode(data))}"));
  }
  static Future<bool> importFromClipboard() async {
    try {
      ClipboardData? data = await Clipboard.getData('text/plain');
      if (data == null || !data.text!.startsWith("SMM_BACKUP::")) return false;
      List<dynamic> parsed = jsonDecode(EncryptionService.decrypt(data.text!.replaceFirst("SMM_BACKUP::", "")));
      for (var item in parsed) { await DatabaseService.instance.insert(Account.fromMap(item)); }
      return true;
    } catch (e) { return false; }
  }
}

class AccountNotifier extends StateNotifier<List<Account>> {
  AccountNotifier() : super([]) { load(); }
  Future<void> load() async { state = await DatabaseService.instance.getAll(); }
  Future<void> add(Account a) async { await DatabaseService.instance.insert(a); await load(); }
  Future<void> edit(Account a) async { await DatabaseService.instance.update(a); await load(); }
  Future<void> toTrash(Account a) async { await edit(Account(id: a.id, platform: a.platform, username: a.username, password: a.password, isDeleted: 1, updatedAt: DateTime.now().millisecondsSinceEpoch, totpKey: a.totpKey, customIconPath: a.customIconPath)); }
  Future<void> restore(Account a) async { await edit(Account(id: a.id, platform: a.platform, username: a.username, password: a.password, isDeleted: 0, updatedAt: DateTime.now().millisecondsSinceEpoch, totpKey: a.totpKey, customIconPath: a.customIconPath)); }
  Future<void> permDelete(int id) async { await DatabaseService.instance.delete(id); await load(); }
}
final accountsProvider = StateNotifierProvider<AccountNotifier, List<Account>>((ref) => AccountNotifier());
