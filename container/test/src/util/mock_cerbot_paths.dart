import 'package:mocktail/mocktail.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

class PossibleCert {
  PossibleCert(this.hostname, this.domain, {required this.wildcard});

  String hostname;
  String domain;
  bool wildcard;

  @override
  String toString() {
    if (hostname.isEmpty) {
      return '$domain wildcard: $wildcard';
    } else {
      return '${Certificate.buildFQDN(hostname, domain)} wildcard: $wildcard';
    }
  }
}

class MockCertbotPaths extends Mock implements CertbotPaths {
  MockCertbotPaths({
    required this.hostname,
    required this.domain,
    required this.tld,
    required this.wildcard,
    required this.settingsFilename,
    required this.possibleCerts,
    required this.rootDir,
    this.production = false,
  });

  String hostname;
  String domain;
  String? tld;
  bool wildcard;
  bool production;
  String settingsFilename;

  String rootDir;

  List<PossibleCert> possibleCerts = <PossibleCert>[];

  // void wire() {
  //   throwOnMissingStub(this); // , (invocation) => buildException(invocation));
  //   Environment().certbotRootPath = rootDir;

  //   _wirePaths();
  //   _wireEnvironment(settingsFilename);

  //   _setMock();
  // }

  // void _wirePaths() {
  //   if (!exists(Environment().certbotRootPath)) {
  //     createDir(Environment().certbotRootPath, recursive: true);
  //   }

  //   if (!exists(CertbotPaths().letsEncryptConfigPath)) {
  //     createDir(CertbotPaths().letsEncryptConfigPath, recursive: true);
  //   }

  //   if (!exists(CertbotPaths().letsEncryptLivePath)) {
  //     createDir(CertbotPaths().letsEncryptLivePath, recursive: true);
  //   }

  //   if (!exists(_mockPath(CertbotPaths().wwwPathToAcquire))) {
  //     createDir(_mockPath(CertbotPaths().wwwPathToAcquire), recursive: true);
  //   }
  //   if (!exists(_mockPath(CertbotPaths().wwwPathToOperating))) {
  //     createDir(_mockPath(CertbotPaths().wwwPathToOperating),
  //recursive: true);
  //   }

  //   if (!exists(_mockPath(CertbotPaths().nginxCertPath))) {
  //     createDir(_mockPath(CertbotPaths().nginxCertPath), recursive: true);
  //   }

  //   when(() => cloudFlareSettings)
  //       .thenReturn(_mockPath(CertbotPaths().cloudFlareSettings));
  //   when(() => wwwPathToAcquire)
  //       .thenReturn(_mockPath(CertbotPaths().wwwPathToAcquire));

  //   when(() => wwwPathLive).thenReturn(_mockPath(CertbotPaths()
  // .wwwPathLive));

  //   when(() => wwwPathToOperating)
  //       .thenReturn(_mockPath(CertbotPaths().wwwPathToOperating));

  //   possibleCerts.forEach(mockPossibleCertPath);

  //   when(() => wwwPathToAcquire)
  //       .thenReturn(_mockPath(CertbotPaths().wwwPathToAcquire));

  //   when(() => wwwPathLive).thenReturn(_mockPath(CertbotPaths()
  // .wwwPathLive));

  //   when(() => wwwPathToOperating)
  //       .thenReturn(_mockPath(CertbotPaths().wwwPathToOperating));

  //   when(() => fullchainFile).thenReturn(CertbotPaths().fullchainFile);
  //   when(() => certificateFile).thenReturn(CertbotPaths().certificateFile);
  //   when(() => privateKeyFile).thenReturn(CertbotPaths().privateKeyFile);

  //   when(() => logFilename).thenReturn(CertbotPaths().logFilename);

  //   when(() => letsEncryptRootPath)
  //       .thenReturn(CertbotPaths().letsEncryptRootPath);

  //   when(() => letsEncryptLogPath)
  //       .thenReturn(CertbotPaths().letsEncryptLogPath);

  //   when(() => letsEncryptWorkPath)
  //       .thenReturn(CertbotPaths().letsEncryptWorkPath);

  //   when(() => letsEncryptConfigPath)
  //       .thenReturn(CertbotPaths().letsEncryptConfigPath);

  //   when(() => letsEncryptLivePath)
  //       .thenReturn(CertbotPaths().letsEncryptLivePath);

  //   when(() => nginxCertPath)
  //       .thenReturn(_mockPath(CertbotPaths().nginxCertPath));
  //   when(() => certificatePathRoot(hostname, domain, wildcard: wildcard))
  //       .thenReturn(_mockPath(CertbotPaths().nginxCertPath));
  // }

  // String _mockPath(String path) {
  //   if (path.startsWith(rootPath)) {
  //     // ignore: parameter_assignments
  //     path = path.substring(1);
  //   }
  //   final result = join(rootDir, path);
  //   return result;
  // }

  // void _setMock() {
  //   CertbotPaths.setMock(this);
  // }

  // void mockPossibleCertPath(PossibleCert possibleCert) {
  //   print('Creating mocks for: $possibleCert');

  //   final rootPathHost = CertbotPaths().certificatePathRoot(
  //       possibleCert.hostname, possibleCert.domain,
  //       wildcard: possibleCert.wildcard);

  //   final _fullChainPathHost = CertbotPaths().fullChainPath(rootPathHost);

  //   final _nginxFullChainPath =
  //       CertbotPaths().fullChainPath(CertbotPaths().nginxCertPath);

  //   final _privateKeyPathHost = CertbotPaths().privateKeyPath(rootPathHost);

  //   // when(privateKeyPath(_mockPath(rootPathHost)))
  //   //     .thenReturn(_mockPath(_privateKeyPathHost));

  //   // when(privateKeyPath(_mockPath(rootPathWildcard)))
  //   //     .thenReturn(_mockPath(_privateKeyPathWildcard));

  //   when(() => certificatePathRoot(hostname, domain, wildcard: false))
  //       .thenReturn(_mockPath(rootPathHost));

  //   // when(certificatePathRoot(hostname, domain, wildcard: true))
  //   //     .thenReturn(_mockPath(rootPathWildcard));

  //   // when(certificatePathRoot('*', domain, wildcard: true))
  //   //     .thenReturn(_mockPath(rootPathWildcard));

  //   // /etc/nginx/certs/
  //   when(() => fullChainPath(_mockPath(CertbotPaths().nginxCertPath)))
  //       .thenReturn(_mockPath(_nginxFullChainPath));

  //   when(() => fullChainPath(_mockPath(rootPathHost)))
  //       .thenReturn(_mockPath(_fullChainPathHost));

  //   // when(() => fullChainPath(_mockPath(rootPathWildcard)))
  //   //     .thenReturn(_mockPath(_fullChainPathWildcard));

  //   when(() => privateKeyPath(rootPathHost)).thenReturn(_privateKeyPathHost);

  //   when(() => certificatePathRoot(possibleCert.hostname,
  // possibleCert.domain,
  //       wildcard: possibleCert.wildcard)).thenReturn(rootPathHost);

  //   when(() => fullChainPath(rootPathHost)).thenReturn(_fullChainPathHost);
  // }
}
