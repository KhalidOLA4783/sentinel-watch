class SystemStats {
  final int totalLogs;
  final int totalFailedLogins;
  final int uniqueIps;
  final int flaggedLogs;
  final int recentActivityCount;

  const SystemStats({
    required this.totalLogs,
    required this.totalFailedLogins,
    required this.uniqueIps,
    required this.flaggedLogs,
    required this.recentActivityCount,
  });

  factory SystemStats.fromJson(Map<String, dynamic> json) {
    return SystemStats(
      totalLogs: json['total_logs'] as int? ?? 0,
      totalFailedLogins: json['total_failed_logins'] as int? ?? 0,
      uniqueIps: json['unique_ips'] as int? ?? 0,
      flaggedLogs: json['flagged_logs'] as int? ?? 0,
      recentActivityCount: json['recent_activity_count'] as int? ?? 0,
    );
  }

  factory SystemStats.empty() {
    return const SystemStats(
      totalLogs: 0,
      totalFailedLogins: 0,
      uniqueIps: 0,
      flaggedLogs: 0,
      recentActivityCount: 0,
    );
  }
}
