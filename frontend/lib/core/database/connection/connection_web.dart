import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:sqlite3/wasm.dart';

QueryExecutor connect() {
  return LazyDatabase(() async {
    const isPreview = bool.fromEnvironment('WEB_DEMO_MODE');
    if (!isPreview) {
      throw StateError(
        'Web finans veritabanı yalnızca WEB_DEMO_MODE=true ile açılabilir.',
      );
    }
    // Preview verisi bilerek oturumluk tutulur. Doğrudan ana iş parçacığında
    // in-memory SQLite açmak, worker/OPFS/IndexedDB izin ve protokol farklarını
    // devreden çıkarır; web önizlemesi hiçbir koşulda kalıcı finans verisi
    // saklamaz.
    final sqlite3 = await WasmSqlite3.loadFromUrl(
      Uri.parse('sqlite3.wasm?v=sqlite3-2.9.4'),
    );
    sqlite3.registerVirtualFileSystem(
      InMemoryFileSystem(),
      makeDefault: true,
    );
    return WasmDatabase.inMemory(sqlite3);
  });
}
