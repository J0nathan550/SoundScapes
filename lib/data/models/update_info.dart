/// A newer release found on GitHub, ready to offer to the user. The asset
/// is an .apk on Android and a portable .zip build on Windows — see
/// [UpdateService.fetchLatestIfNewer].
class UpdateInfo {
  final String version;
  final String assetDownloadUrl;
  final int assetSizeBytes;
  final String releaseUrl;

  const UpdateInfo({
    required this.version,
    required this.assetDownloadUrl,
    required this.assetSizeBytes,
    required this.releaseUrl,
  });
}
