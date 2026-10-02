class SecurityAlert {
  final int id;
  final DateTime timestamp;
  final String alertType;
  final String severity;
  final String sourceIp;
  final String? targetUser;
  final String description;
  final String? details;
  final double? anomalyScore;
  final String status;
  final int? logId;

  const SecurityAlert({
    required this.id,
    required this.timestamp,
    required this.alertType,
    required this.severity,
    required this.sourceIp,
    this.targetUser,
    required this.description,
    this.details,
    this.anomalyScore,
    required this.status,
    this.logId,
  });

  factory SecurityAlert.fromJson(Map<String, dynamic> json) {
    return SecurityAlert(
      id: json['id'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      alertType: json['alert_type'] as String? ?? 'UNKNOWN',
      severity: json['severity'] as String? ?? 'MEDIUM',
      sourceIp: json['source_ip'] as String? ?? '0.0.0.0',
      targetUser: json['target_user'] as String?,
      description: json['description'] as String? ?? '',
      details: json['details'] as String?,
      anomalyScore: (json['anomaly_score'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'PENDING',
      logId: json['log_id'] as int?,
    );
  }

  bool get isCritical => severity.toUpperCase() == 'CRITICAL';
  bool get isHigh => severity.toUpperCase() == 'HIGH';
  bool get isPending => status.toUpperCase() == 'PENDING';
}
