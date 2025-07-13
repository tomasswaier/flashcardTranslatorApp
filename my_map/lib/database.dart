library;

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DictionaryDatabase{
  static Database? _db;
  static final DictionaryDatabase instance=DictionaryDatabase._constructor() ;
  static String _dictionaryTableName="dictionary";
  DictionaryDatabase._constructor();

  Future<Database> get database async{
    if(_db!=null)
      return _db!;

    _db=await createInstance();
    return _db!;
  }

  Future<Database> createInstance() async {
    try {
      final database = await openDatabase(
        join(await getDatabasesPath(), 'dictionary.db'),
        version: 3,
        onCreate: (db, version) {
          return db.execute(
            'CREATE TABLE dictionary(id INTEGER PRIMARY KEY, originalWord TEXT,translatedWord TEXT,isKnown INTEGER)',
          );
        },
      );
      print('Database opened successfully');
      return database;
    }
    catch(e) {
      print('Error opening db : $e');
      rethrow;
    }
  }


  void insertWord(Map<String,Object> dict) async{
    final db = await database;
    await db.insert(
      _dictionaryTableName,
      dict,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  // A method that retrieves all the dogs from the dogs table.
  Future<List<Map<String,Object?>>> getDictionary() async {
    // Get a reference to the database.
    final db = await database;

    final List<Map<String, Object?>> wordMap= await db.query(_dictionaryTableName);
    //return [
    //  for (final {'id': id as int, 'originalWord': originalWord as String, 'translatedWord': translatedWord as String} in wordMap)
    //
    //];
    return wordMap;
  }
  //prob useless
  Future<List<Map<String, Object?>>> getNotKnownWords() async {
    final db = await database;

    final List<Map<String, Object?>> wordMap = await db.query(_dictionaryTableName);

    // Filter and map only the not-known words
    return [
      for (final map in wordMap)
        if (map['isKnown'] == false || map['isKnown'] == 0)
          {
            'id': map['id'],
            'originalWord': map['originalWord'],
            'translatedWord': map['translatedWord'],
            'isKnown': 0,
          }
    ];
  }
  Future<void> markAsKnown(Map<String, Object?> entry) async {
    // Validate input
    if (entry['id'] == null) {
      return; // ✅ return nothing for Future<void>
    }

    // Get a reference to the database.
    final db = await database;

    // Perform the update
    await db.update(
      _dictionaryTableName,
      {'id':entry['id'],'originalWord':entry['originalWord'],'translatedWord':entry['translatedWord'],'isKnown':1},
      where: 'id = ?',
      whereArgs: [entry['id']],
    );
  }

  Future<void> removeWord(int id) async {
    // Get a reference to the database.
    final db = await database;

    // Remove the Dog from the database.
    await db.delete(
      _dictionaryTableName,
      // Use a `where` clause to delete a specific dog.
      where: 'id = ?',
      // Pass the Dog's id as a whereArg to prevent SQL injection.
      whereArgs: [id],
    );
  }

}
class Dictionary{
  final int id;
  final String originalWord;
  final String translatedWord;
  final int isKnown;

  Dictionary({
    required this.id ,
    required this.originalWord,
    required this.translatedWord,
    required this.isKnown
  });

  Map<String,Object?> toMap() {
    return {
      'id': id,
      'originalWord': originalWord,
      'translatedWord': translatedWord,
      'isKnown':isKnown
    };
  }

  @override
  String toString() {
    return 'Dictionary{id: $id, originalWord: $originalWord, translatedWord: $translatedWord isKnown: $isKnown}';
  }
}
