class SecurityUtils {
  // قائمة النطاقات الموثوقة (Trusted Domains)
  static final List<String> _trustedDomains = [
    'firebasestorage.googleapis.com',
    'somaliapps.com',
    'github.com',
    'raw.githubusercontent.com',
    'r2.dev',
  ];

  // التحقق من أمان الرابط
  static bool isUrlSafe(String url) {
    try {
      final uri = Uri.parse(url);

      // 1. التأكد من أن البروتوكول هو HTTPS
      if (uri.scheme != 'https') {
        return false;
      }

      // 2. التأكد من أن النطاق موجود في القائمة الموثوقة
      bool isTrusted = _trustedDomains.any(
        (domain) => uri.host.endsWith(domain),
      );

      return isTrusted;
    } catch (e) {
      return false;
    }
  }
}
