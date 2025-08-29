import 'package:totp_generator/totp_generator.dart';

class TotpService {
  String generateTotp(String secret, int interval) {
    final totp = TOTPGenerator();
    return totp.generateTOTP(
      secret: secret,
      encoding: 'base32',
      algorithm: HashAlgorithm.sha1,
      interval: interval,
    );
  }

  int getRemainingSeconds(int interval) {
    final now = DateTime.now();
    final secondsSinceEpoch = now.millisecondsSinceEpoch ~/ 1000;
    return interval - (secondsSinceEpoch % interval);
  }
}
