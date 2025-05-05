class ProjectSettings {
  String projectName;
  int socketTimeoutMs;
  bool autoSave;
  int autoSaveIntervalMinutes;
  int commandTimeoutMs;
  int heartbeatIntervalSeconds;
  int maxCommandRetries;
  int maxConcurrentCommandsPerRouter;
  int commandHistorySize;

  ProjectSettings({
    this.projectName = 'Default Project',
    this.socketTimeoutMs = 15000,
    this.autoSave = true,
    this.autoSaveIntervalMinutes = 5,
    this.commandTimeoutMs = 10000, // 10 seconds
    this.heartbeatIntervalSeconds = 30, // 30 seconds
    this.maxCommandRetries = 3,
    this.maxConcurrentCommandsPerRouter = 5,
    this.commandHistorySize = 100,
  });

  ProjectSettings copyWith({
    String? projectName,
    int? socketTimeoutMs,
    bool? autoSave,
    int? autoSaveIntervalMinutes,
    int? commandTimeoutMs,
    int? heartbeatIntervalSeconds,
    int? maxCommandRetries,
    int? maxConcurrentCommandsPerRouter,
    int? commandHistorySize,
  }) {
    return ProjectSettings(
      projectName: projectName ?? this.projectName,
      socketTimeoutMs: socketTimeoutMs ?? this.socketTimeoutMs,
      autoSave: autoSave ?? this.autoSave,
      autoSaveIntervalMinutes:
          autoSaveIntervalMinutes ?? this.autoSaveIntervalMinutes,
      commandTimeoutMs: commandTimeoutMs ?? this.commandTimeoutMs,
      heartbeatIntervalSeconds:
          heartbeatIntervalSeconds ?? this.heartbeatIntervalSeconds,
      maxCommandRetries: maxCommandRetries ?? this.maxCommandRetries,
      maxConcurrentCommandsPerRouter:
          maxConcurrentCommandsPerRouter ?? this.maxConcurrentCommandsPerRouter,
      commandHistorySize: commandHistorySize ?? this.commandHistorySize,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectName': projectName,
      'socketTimeoutMs': socketTimeoutMs,
      'autoSave': autoSave,
      'autoSaveIntervalMinutes': autoSaveIntervalMinutes,
      'commandTimeoutMs': commandTimeoutMs,
      'heartbeatIntervalSeconds': heartbeatIntervalSeconds,
      'maxCommandRetries': maxCommandRetries,
      'maxConcurrentCommandsPerRouter': maxConcurrentCommandsPerRouter,
      'commandHistorySize': commandHistorySize,
    };
  }

  factory ProjectSettings.fromJson(Map<String, dynamic> json) {
    return ProjectSettings(
      projectName: json['projectName'] as String? ?? 'Default Project',
      socketTimeoutMs: json['socketTimeoutMs'] as int? ?? 15000,
      autoSave: json['autoSave'] as bool? ?? true,
      autoSaveIntervalMinutes: json['autoSaveIntervalMinutes'] as int? ?? 5,
      commandTimeoutMs: json['commandTimeoutMs'] as int? ?? 10000,
      heartbeatIntervalSeconds: json['heartbeatIntervalSeconds'] as int? ?? 30,
      maxCommandRetries: json['maxCommandRetries'] as int? ?? 3,
      maxConcurrentCommandsPerRouter:
          json['maxConcurrentCommandsPerRouter'] as int? ?? 5,
      commandHistorySize: json['commandHistorySize'] as int? ?? 100,
    );
  }
}
