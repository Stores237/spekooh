/// A paper's scanned file saved to on-device storage for offline access.
/// [relativeFilePath] is a key into [OfflineFileStore], not an absolute
/// path — [OfflinePapersStore] resolves the real path when something
/// needs to actually open the file.
class OfflinePaper {
  const OfflinePaper({
    required this.paperId,
    required this.title,
    required this.subtitle,
    required this.relativeFilePath,
    required this.savedAt,
  });

  final int paperId;
  final String title;
  final String subtitle;
  final String relativeFilePath;
  final DateTime savedAt;

  Map<String, dynamic> toJson() => {
        'paperId': paperId,
        'title': title,
        'subtitle': subtitle,
        'relativeFilePath': relativeFilePath,
        'savedAt': savedAt.toIso8601String(),
      };

  factory OfflinePaper.fromJson(Map<String, dynamic> json) => OfflinePaper(
        paperId: json['paperId'] as int,
        title: json['title'] as String,
        subtitle: json['subtitle'] as String,
        relativeFilePath: json['relativeFilePath'] as String,
        savedAt: DateTime.parse(json['savedAt'] as String),
      );
}
