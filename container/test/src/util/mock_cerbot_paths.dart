import 'package:dcli/dcli.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:settings_yaml/settings_yaml.dart';

class PossibleCert {
  String hostname;
  String domain;
  bool wildcard;

  PossibleCert(this.hostname, this.domain, {required this.wildcard});

  @override
  String toString() => '$hostname.$domain wildcard: $wildcard';
}

class MockCertbotPaths extends Mock implements CertbotPaths {
  String hostname;
  String domain;
  String? tld;
  bool wildcard;
  bool production;
  String settingsFilename;

  var possibleCerts = <PossibleCert>[];

  MockCertbotPaths(
      {required this.hostname,
      required this.domain,
      required this.tld,
      required this.wildcard,
      required this.settingsFilename,
      required this.possibleCerts,
      this.production = false});
  void wire() {
    throwOnMissingStub(this); // , (invocation) => buildException(invocation));
    Environment().certbotRootPath = _mockPath('/etc/letsencrypt');

    _wirePaths();
    _wireEnvironment(settingsFilename);

    _setMock();
  }

  void _wirePaths() {
    if (!exists(Environment().certbotRootPath)) {
      createDir(Environment().certbotRootPath, recursive: true);
    }

    if (!exists(CertbotPaths().letsEncryptConfigPath)) {
      createDir(CertbotPaths().letsEncryptConfigPath, recursive: true);
    }

    if (!exists(CertbotPaths().letsEncryptLivePath)) {
      createDir(CertbotPaths().letsEncryptLivePath, recursive: true);
    }

    if (!exists(_mockPath(CertbotPaths().WWW_PATH_ACQUIRE))) {
      createDir(_mockPath(CertbotPaths().WWW_PATH_ACQUIRE), recursive: true);
    }
    if (!exists(_mockPath(CertbotPaths().WWW_PATH_OPERATING))) {
      createDir(_mockPath(CertbotPaths().WWW_PATH_OPERATING), recursive: true);
    }

    if (!exists(_mockPath(CertbotPaths().nginxCertPath))) {
      createDir(_mockPath(CertbotPaths().nginxCertPath), recursive: true);
    }

    when(() => CLOUD_FLARE_SETTINGS)
        .thenReturn(_mockPath(CertbotPaths().CLOUD_FLARE_SETTINGS));
    when(() => WWW_PATH_ACQUIRE)
        .thenReturn(_mockPath(CertbotPaths().WWW_PATH_ACQUIRE));

    when(() => WWW_PATH_LIVE)
        .thenReturn(_mockPath(CertbotPaths().WWW_PATH_LIVE));

    when(() => WWW_PATH_OPERATING)
        .thenReturn(_mockPath(CertbotPaths().WWW_PATH_OPERATING));

    for (var possibleCert in possibleCerts) {
      mockPossibleCertPath(possibleCert);
    }

    when(() => WWW_PATH_ACQUIRE)
        .thenReturn(_mockPath(CertbotPaths().WWW_PATH_ACQUIRE));

    when(() => WWW_PATH_LIVE)
        .thenReturn(_mockPath(CertbotPaths().WWW_PATH_LIVE));

    when(() => WWW_PATH_OPERATING)
        .thenReturn(_mockPath(CertbotPaths().WWW_PATH_OPERATING));

    when(() => FULLCHAIN_FILE).thenReturn(CertbotPaths().FULLCHAIN_FILE);
    when(() => CERTIFICATE_FILE).thenReturn(CertbotPaths().CERTIFICATE_FILE);
    when(() => PRIVATE_KEY_FILE).thenReturn(CertbotPaths().PRIVATE_KEY_FILE);

    when(() => LOG_FILE_NAME).thenReturn(CertbotPaths().LOG_FILE_NAME);

    when(() => letsEncryptRootPath)
        .thenReturn(_mockPath(CertbotPaths().letsEncryptRootPath));

    when(() => letsEncryptLogPath)
        .thenReturn(_mockPath(CertbotPaths().letsEncryptLogPath));

    when(() => letsEncryptWorkPath)
        .thenReturn(_mockPath(CertbotPaths().letsEncryptWorkPath));

    when(() => letsEncryptConfigPath)
        .thenReturn(_mockPath(CertbotPaths().letsEncryptConfigPath));

    when(() => letsEncryptLivePath)
        .thenReturn(_mockPath(CertbotPaths().letsEncryptLivePath));

    when(() => nginxCertPath)
        .thenReturn(_mockPath(CertbotPaths().nginxCertPath));
  }

  void _wireEnvironment(String settingFileName) {
    /// emails to mail hog which is started by a critical_test pre-hook.
    Environment().smtpServer = 'localhost';
    Environment().smtpServerPort = 1025;

    final settingsPath = truepath('test', 'config', settingFileName);
    final settings = SettingsYaml.load(pathToSettings: settingsPath);
    Environment().authProvider = settings['AUTH_PROVIDER'] as String?;
    Environment().authProviderToken =
        settings[AuthProvider.AUTH_PROVIDER_TOKEN] as String?;
    Environment().authProviderUsername =
        settings[AuthProvider.AUTH_PROVIDER_USERNAME] as String?;
    Environment().authProviderEmailAddress =
        settings[AuthProvider.AUTH_PROVIDER_EMAIL_ADDRESS] as String?;

    Environment().hostname = hostname;
    Environment().domain = domain;
    Environment().tld = tld;
    Environment().domainWildcard = wildcard;

    Environment().production = production;
  }

  String _mockPath(String path) {
    if (path.startsWith('/tmp')) return path;
    if (path.startsWith('/')) {
      path = path.substring(1);
    }

    return join('/tmp', path);
  }

  void _setMock() {
    CertbotPaths.setMock(this);
  }

  void mockPossibleCertPath(PossibleCert possibleCert) {
    print('Creating mocks for: $possibleCert');

    var rootPathHost = CertbotPaths().certificatePathRoot(
        possibleCert.hostname, possibleCert.domain,
        wildcard: possibleCert.wildcard);

    var _fullChainPathHost = CertbotPaths().fullChainPath(rootPathHost);

    var _privateKeyPathHost = CertbotPaths().privateKeyPath(rootPathHost);

    // when(privateKeyPath(_mockPath(rootPathHost)))
    //     .thenReturn(_mockPath(_privateKeyPathHost));

    // when(privateKeyPath(_mockPath(rootPathWildcard)))
    //     .thenReturn(_mockPath(_privateKeyPathWildcard));

    // when(certificatePathRoot(hostname, domain, wildcard: false))
    //     .thenReturn(_mockPath(rootPathHost));

    // when(certificatePathRoot(hostname, domain, wildcard: true))
    //     .thenReturn(_mockPath(rootPathWildcard));

    // when(certificatePathRoot('*', domain, wildcard: true))
    //     .thenReturn(_mockPath(rootPathWildcard));

    // when(fullChainPath(_mockPath(rootPathHost)))
    //     .thenReturn(_mockPath(_fullChainPathHost));

    // when(fullChainPath(_mockPath(rootPathWildcard)))
    //     .thenReturn(_mockPath(_fullChainPathWildcard));

    when(() => privateKeyPath(_mockPath(rootPathHost)))
        .thenReturn(_mockPath(_privateKeyPathHost));

    when(() => certificatePathRoot(possibleCert.hostname, possibleCert.domain,
        wildcard: possibleCert.wildcard)).thenReturn(_mockPath(rootPathHost));

    when(() => fullChainPath(_mockPath(rootPathHost)))
        .thenReturn(_mockPath(_fullChainPathHost));
  }
}
