import 'package:nginx_le_container/src/commands/internal/logs.dart';

/// In container entry point to run nginx
/// The cli logs command calls this command which does the 
/// actual tailing of logs
/// within the container.
void main(List<String> args) {
  logs(args);
}
