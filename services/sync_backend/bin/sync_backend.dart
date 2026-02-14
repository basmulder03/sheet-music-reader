import 'dart:io';

import 'package:sync_backend/sync_backend.dart';

Future<void> main(List<String> args) async {
  final host = Platform.environment['SYNC_BACKEND_HOST'] ?? '0.0.0.0';
  final portValue = Platform.environment['SYNC_BACKEND_PORT'] ?? '9090';
  final port = int.tryParse(portValue) ?? 9090;
  final dataDir = Platform.environment['SYNC_BACKEND_DATA_DIR'] ?? './data';
  final token = Platform.environment['SYNC_BACKEND_API_TOKEN'] ?? 'dev-token';

  final server = SyncBackendServer(
    dataDirectoryPath: dataDir,
    apiToken: token,
  );

  await server.start(host: host, port: port);

  ProcessSignal.sigint.watch().listen((_) async {
    await server.stop();
    exit(0);
  });
  ProcessSignal.sigterm.watch().listen((_) async {
    await server.stop();
    exit(0);
  });
}
