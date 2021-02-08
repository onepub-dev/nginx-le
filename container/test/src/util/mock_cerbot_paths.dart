import 'package:dcli/dcli.dart';
import 'package:mockito/mockito.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:settings_yaml/settings_yaml.dart';

import 'acquisition_manager_test.dart';

class MockCertbotPaths extends Mock implements CertbotPaths {
  void wirePaths() {
    if (!exists(mockPath(CertbotPaths().WWW_PATH_ACQUIRE))) {
      createDir(mockPath(CertbotPaths().WWW_PATH_ACQUIRE), recursive: true);
    }
    if (!exists(mockPath(CertbotPaths().WWW_PATH_OPERATING))) {
      createDir(mockPath(CertbotPaths().WWW_PATH_OPERATING), recursive: true);
    }

    if (!exists(mockPath(CertbotPaths().nginxCertPath))) {
      createDir(mockPath(CertbotPaths().nginxCertPath), recursive: true);
    }

    when(WWW_PATH_ACQUIRE)
        .thenReturn(mockPath(CertbotPaths().WWW_PATH_ACQUIRE));

    when(WWW_PATH_LIVE).thenReturn(mockPath(CertbotPaths().WWW_PATH_LIVE));

    when(WWW_PATH_OPERATING)
        .thenReturn(mockPath(CertbotPaths().WWW_PATH_OPERATING));

    var rootPath = CertbotPaths()
        .certificatePathRoot(hostname, domain, wildcard: wildcard);

    var _fullChainPath = CertbotPaths().fullChainPath(rootPath);

    

    var _privateKeyPath = CertbotPaths().privateKeyPath(rootPath);

    when(privateKeyPath(mockPath(rootPath)))
        .thenReturn(mockPath(_privateKeyPath));

    when(WWW_PATH_ACQUIRE)
        .thenReturn(mockPath(CertbotPaths().WWW_PATH_ACQUIRE));

    when(WWW_PATH_LIVE).thenReturn(mockPath(CertbotPaths().WWW_PATH_LIVE));

    when(WWW_PATH_OPERATING)
        .thenReturn(mockPath(CertbotPaths().WWW_PATH_OPERATING));

    when(CERTIFICATE_FILE).thenReturn(CertbotPaths().CERTIFICATE_FILE);

    when(letsEncryptRootPath)
        .thenReturn(mockPath(CertbotPaths().letsEncryptRootPath));

    when(letsEncryptLogPath)
        .thenReturn(mockPath(CertbotPaths().letsEncryptLogPath));

    when(letsEncryptWorkPath)
        .thenReturn(mockPath(CertbotPaths().letsEncryptWorkPath));

    when(letsEncryptConfigPath)
        .thenReturn(mockPath(CertbotPaths().letsEncryptConfigPath));

    when(letsEncryptLivePath)
        .thenReturn(mockPath(CertbotPaths().letsEncryptLivePath));

    when(nginxCertPath).thenReturn(mockPath(CertbotPaths().nginxCertPath));

    when(certificatePathRoot(hostname, domain, wildcard: wildcard))
        .thenReturn(mockPath(rootPath));

    when(fullChainPath(mockPath(rootPath)))
        .thenReturn(mockPath(_fullChainPath));
  }

  void wireEnvironment() {
    final settingsPath = truepath('test', 'src', 'util', 'settings.yaml');
    final settings = SettingsYaml.load(pathToSettings: settingsPath);
    Environment().authProvider = 'clourdflare';
    env[AuthProvider.AUTH_PROVIDER_TOKEN] =
        settings[AuthProvider.AUTH_PROVIDER_TOKEN] as String;
    env[AuthProvider.AUTH_PROVIDER_EMAIL_ADDRESS] =
        settings[AuthProvider.AUTH_PROVIDER_EMAIL_ADDRESS] as String;

    Environment().certbotRootPath = mockPath('/etc/letsencrypt');

    Environment().hostname = hostname;
    Environment().domain = domain;
    Environment().tld = tld;
    Environment().domainWildcard = wildcard;

    Environment().authProvider = 'cloudflare';
    Environment().production = production;
  }

  String mockPath(String path) {
    if (path.startsWith('/')) {
      path = path.substring(1);
    }
    return join('/tmp', path);
  }

  void setMock() {
    CertbotPaths.setMock(this);
  }
}
