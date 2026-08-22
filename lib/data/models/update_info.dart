/// A newer release found on GitHub, ready to offer to the user.
class UpdateInfo {
  final String version;
  final String apkDownloadUrl;
  final int apkSizeBytes;
  final String releaseUrl;

  const UpdateInfo({
    required this.version,
    required this.apkDownloadUrl,
    required this.apkSizeBytes,
    required this.releaseUrl,
  });
}
