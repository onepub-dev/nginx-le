import 'package:dshell/dshell.dart';
import 'package:validators/validators.dart';

class AskFQDNOrLocalhost extends AskValidator {
  const AskFQDNOrLocalhost();
  @override
  String validate(String line) {
    line = line.trim().toLowerCase();

    if (!isFQDN(line) && line != 'localhost') {
      throw AskValidatorException(red('Invalid FQDN.'));
    }
    return line;
  }
}
