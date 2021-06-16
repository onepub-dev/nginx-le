import 'package:dcli/dcli.dart';

void verbose(String Function() getMessage) => Settings().verbose(getMessage());
