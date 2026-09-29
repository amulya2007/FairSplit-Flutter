import 'package:sqflite/sqflite.dart';

Future<void> configureDatabaseFactory() async {}

String databaseFilePath(String nativePath) => nativePath;

DatabaseFactory get configuredDatabaseFactory => databaseFactory;