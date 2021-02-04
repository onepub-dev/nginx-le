import 'package:nginx_le_container/src/util/acquisition_manager.dart';
import 'package:test/test.dart';

void main() {
  test('acquisition manager ...', () async {
    expect(AcquisitionManager.inAcquisitionMode, equals(false));

    AcquisitionManager.enterAcquisitionMode();
    expect(AcquisitionManager.inAcquisitionMode, equals(true));

    AcquisitionManager.leaveAcquistionMode();
    expect(AcquisitionManager.inAcquisitionMode, equals(true));

    AcquisitionManager.enterAcquisitionMode();
    expect(AcquisitionManager.inAcquisitionMode, equals(true));

    AcquisitionManager.leaveAcquistionMode();
    expect(AcquisitionManager.inAcquisitionMode, equals(true));
  });
}
