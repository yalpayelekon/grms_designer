class ProjectSettings {
  String projectName;
  int socketTimeoutMs;
  bool autoSave;
  int autoSaveIntervalMinutes;

  ProjectSettings({
    this.projectName = 'Default Project',
    this.socketTimeoutMs = 15000,
    this.autoSave = true,
    this.autoSaveIntervalMinutes = 5,
  });

  ProjectSettings copyWith({
    String? projectName,
    int? socketTimeoutMs,
    bool? autoSave,
    int? autoSaveIntervalMinutes,
  }) {
    return ProjectSettings(
      projectName: projectName ?? this.projectName,
      socketTimeoutMs: socketTimeoutMs ?? this.socketTimeoutMs,
      autoSave: autoSave ?? this.autoSave,
      autoSaveIntervalMinutes:
          autoSaveIntervalMinutes ?? this.autoSaveIntervalMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectName': projectName,
      'socketTimeoutMs': socketTimeoutMs,
      'autoSave': autoSave,
      'autoSaveIntervalMinutes': autoSaveIntervalMinutes,
    };
  }

  factory ProjectSettings.fromJson(Map<String, dynamic> json) {
    return ProjectSettings(
      projectName: json['projectName'] as String? ?? 'Default Project',
      socketTimeoutMs: json['socketTimeoutMs'] as int? ?? 15000,
      autoSave: json['autoSave'] as bool? ?? true,
      autoSaveIntervalMinutes: json['autoSaveIntervalMinutes'] as int? ?? 5,
    );
  }
}
