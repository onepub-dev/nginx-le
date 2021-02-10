import 'package:dcli/dcli.dart';
import 'package:mockito/mockito.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:settings_yaml/settings_yaml.dart';

import 'acquisition_manager_test.dart';

class MockCertbotPaths extends Mock implements CertbotPaths {
  void wire() {
    Environment().certbotRootPath = _mockPath('/etc/letsencrypt');

    _wirePaths();
    _wireEnvironment();

    _setMock();
  }

  void _wirePaths() {
    if (!exists(_mockPath(CertbotPaths().WWW_PATH_ACQUIRE))) {
      createDir(_mockPath(CertbotPaths().WWW_PATH_ACQUIRE), recursive: true);
    }
    if (!exists(_mockPath(CertbotPaths().WWW_PATH_OPERATING))) {
      createDir(_mockPath(CertbotPaths().WWW_PATH_OPERATING), recursive: true);
    }

    if (!exists(_mockPath(CertbotPaths().nginxCertPath))) {
      createDir(_mockPath(CertbotPaths().nginxCertPath), recursive: true);
    }

    when(WWW_PATH_ACQUIRE)
        .thenReturn(_mockPath(CertbotPaths().WWW_PATH_ACQUIRE));

    when(WWW_PATH_LIVE).thenReturn(_mockPath(CertbotPaths().WWW_PATH_LIVE));

    when(WWW_PATH_OPERATING)
        .thenReturn(_mockPath(CertbotPaths().WWW_PATH_OPERATING));

    var rootPathHost =
        CertbotPaths().certificatePathRoot(hostname, domain, wildcard: false);

    var rootPathWildcard =
        CertbotPaths().certificatePathRoot('*', domain, wildcard: true);

    var _fullChainPathHost = CertbotPaths().fullChainPath(rootPathHost);
    var _fullChainPathWildcard = CertbotPaths().fullChainPath(rootPathWildcard);

    var _privateKeyPathHost = CertbotPaths().privateKeyPath(rootPathHost);

    var _privateKeyPathWildcard =
        CertbotPaths().privateKeyPath(rootPathWildcard);

    when(privateKeyPath(_mockPath(rootPathHost)))
        .thenReturn(_mockPath(_privateKeyPathHost));

    when(privateKeyPath(_mockPath(rootPathWildcard)))
        .thenReturn(_mockPath(_privateKeyPathWildcard));

    when(WWW_PATH_ACQUIRE)
        .thenReturn(_mockPath(CertbotPaths().WWW_PATH_ACQUIRE));

    when(WWW_PATH_LIVE).thenReturn(_mockPath(CertbotPaths().WWW_PATH_LIVE));

    when(WWW_PATH_OPERATING)
        .thenReturn(_mockPath(CertbotPaths().WWW_PATH_OPERATING));

    when(FULLCHAIN_FILE).thenReturn(CertbotPaths().FULLCHAIN_FILE);
    when(CERTIFICATE_FILE).thenReturn(CertbotPaths().CERTIFICATE_FILE);
    when(PRIVATE_KEY_FILE).thenReturn(CertbotPaths().PRIVATE_KEY_FILE);

    when(letsEncryptRootPath)
        .thenReturn(_mockPath(CertbotPaths().letsEncryptRootPath));

    when(letsEncryptLogPath)
        .thenReturn(_mockPath(CertbotPaths().letsEncryptLogPath));

    when(letsEncryptWorkPath)
        .thenReturn(_mockPath(CertbotPaths().letsEncryptWorkPath));

    when(letsEncryptConfigPath)
        .thenReturn(_mockPath(CertbotPaths().letsEncryptConfigPath));

    when(letsEncryptLivePath)
        .thenReturn(_mockPath(CertbotPaths().letsEncryptLivePath));

    when(nginxCertPath).thenReturn(_mockPath(CertbotPaths().nginxCertPath));

    when(certificatePathRoot(hostname, domain, wildcard: false))
        .thenReturn(_mockPath(rootPathHost));

    when(certificatePathRoot('*', domain, wildcard: true))
        .thenReturn(_mockPath(rootPathWildcard));

    when(fullChainPath(_mockPath(rootPathHost)))
        .thenReturn(_mockPath(_fullChainPathHost));

    when(fullChainPath(_mockPath(rootPathWildcard)))
        .thenReturn(_mockPath(_fullChainPathWildcard));
  }

  void _wireEnvironment() {
    final settingsPath = truepath('test', 'src', 'util', 'settings.yaml');
    final settings = SettingsYaml.load(pathToSettings: settingsPath);
    Environment().authProvider = 'clourdflare';
    env[AuthProvider.AUTH_PROVIDER_TOKEN] =
        settings[AuthProvider.AUTH_PROVIDER_TOKEN] as String;
    env[AuthProvider.AUTH_PROVIDER_EMAIL_ADDRESS] =
        settings[AuthProvider.AUTH_PROVIDER_EMAIL_ADDRESS] as String;

    Environment().hostname = hostname;
    Environment().domain = domain;
    Environment().tld = tld;
    Environment().domainWildcard = wildcard;

    Environment().authProvider = 'cloudflare';
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
}
