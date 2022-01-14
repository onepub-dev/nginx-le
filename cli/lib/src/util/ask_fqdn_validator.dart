import 'package:dcli/dcli.dart';
import 'package:validators2/validators.dart';

class AskFQDNOrLocalhost extends AskValidator {
  const AskFQDNOrLocalhost();
  @override
  String validate(String line) {
    // ignore: parameter_assignments
    line = line.trim().toLowerCase();

    if (!isFQDN(line) && line != 'localhost') {
      throw AskValidatorException(red('Invalid FQDN $line.'));
    }
    return line;
  }
}
