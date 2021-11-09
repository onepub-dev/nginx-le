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

  String rootDir;

  var possibleCerts = <PossibleCert>[];

  MockCertbotPaths(
      {required this.hostname,
      required this.domain,
      required this.tld,
      required this.wildcard,
      required this.settingsFilename,
      required this.possibleCerts,
      this.production = false,
      required this.rootDir});
  void wire() {
    throwOnMissingStub(this); // , (invocation) => buildException(invocation));
    Environment().certbotRootPath = rootDir;

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

    if (!exists(_mockPath(CertbotPaths().wwwPathToAcquire))) {
      createDir(_mockPath(CertbotPaths().wwwPathToAcquire), recursive: true);
    }
    if (!exists(_mockPath(CertbotPaths().wwwPathToOperating))) {
      createDir(_mockPath(CertbotPaths().wwwPathToOperating), recursive: true);
    }

    if (!exists(_mockPath(CertbotPaths().nginxCertPath))) {
      createDir(_mockPath(CertbotPaths().nginxCertPath), recursive: true);
    }

    when(() => cloudFlareSettings)
        .thenReturn(_mockPath(CertbotPaths().cloudFlareSettings));
    when(() => wwwPathToAcquire)
        .thenReturn(_mockPath(CertbotPaths().wwwPathToAcquire));

    when(() => wwwPathLive).thenReturn(_mockPath(CertbotPaths().wwwPathLive));

    when(() => wwwPathToOperating)
        .thenReturn(_mockPath(CertbotPaths().wwwPathToOperating));

    for (var possibleCert in possibleCerts) {
      mockPossibleCertPath(possibleCert);
    }

    when(() => wwwPathToAcquire)
        .thenReturn(_mockPath(CertbotPaths().wwwPathToAcquire));

    when(() => wwwPathLive).thenReturn(_mockPath(CertbotPaths().wwwPathLive));

    when(() => wwwPathToOperating)
        .thenReturn(_mockPath(CertbotPaths().wwwPathToOperating));

    when(() => fullchainFile).thenReturn(CertbotPaths().fullchainFile);
    when(() => certificateFile).thenReturn(CertbotPaths().certificateFile);
    when(() => privateKeyFile).thenReturn(CertbotPaths().privateKeyFile);

    when(() => logFilename).thenReturn(CertbotPaths().logFilename);

    when(() => letsEncryptRootPath)
        .thenReturn(CertbotPaths().letsEncryptRootPath);

    when(() => letsEncryptLogPath)
        .thenReturn(CertbotPaths().letsEncryptLogPath);

    when(() => letsEncryptWorkPath)
        .thenReturn(CertbotPaths().letsEncryptWorkPath);

    when(() => letsEncryptConfigPath)
        .thenReturn(CertbotPaths().letsEncryptConfigPath);

    when(() => letsEncryptLivePath)
        .thenReturn(CertbotPaths().letsEncryptLivePath);

    when(() => nginxCertPath)
        .thenReturn(_mockPath(CertbotPaths().nginxCertPath));
  }

  void _wireEnvironment(String settingFileName) {
    /// emails to mail hog which is started by a critical_test pre-hook.
    Environment().smtpServer = 'localhost';
    Environment().smtpServerPort = 1025;
    Environment().emailaddress = 'test@noojee.com.au';

    final settingsPath = truepath('test', 'config', settingFileName);
    final settings = SettingsYaml.load(pathToSettings: settingsPath);
    Environment().authProvider = settings['AUTH_PROVIDER'] as String?;
    Environment().authProviderToken =
        settings[AuthProvider.authProviderToken] as String?;
    Environment().authProviderUsername =
        settings[AuthProvider.authProviderUsername] as String?;
    Environment().authProviderEmailAddress =
        settings[AuthProvider.authProviderEmailAddress] as String?;

    Environment().hostname = hostname;
    Environment().domain = domain;
    Environment().tld = tld;
    Environment().domainWildcard = wildcard;

    Environment().production = production;
  }

  String _mockPath(String path) {
    if (path.startsWith(rootPath)) {
      path = path.substring(1);
    }
    final result = join(rootDir, path);
    return result;
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

    when(() => privateKeyPath(rootPathHost)).thenReturn(_privateKeyPathHost);

    when(() => certificatePathRoot(possibleCert.hostname, possibleCert.domain,
        wildcard: possibleCert.wildcard)).thenReturn(rootPathHost);

    when(() => fullChainPath(rootPathHost)).thenReturn(_fullChainPathHost);
  }
}
