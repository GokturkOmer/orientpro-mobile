class SensorDefinition {
  final int id;
  final int unitId;
  final int registerAddress;
  final String? equipmentId;
  final String name;
  final String sensorType;
  final String unit;
  final double scaleFactor;
  final double offset;
  final double? alarmMin;
  final double? warningMin;
  final double? warningMax;
  final double? alarmMax;
  final int pollingInterval;
  final bool isActive;

  SensorDefinition({
    required this.id,
    required this.unitId,
    required this.registerAddress,
    this.equipmentId,
    required this.name,
    required this.sensorType,
    required this.unit,
    this.scaleFactor = 1.0,
    this.offset = 0.0,
    this.alarmMin,
    this.warningMin,
    this.warningMax,
    this.alarmMax,
    this.pollingInterval = 5,
    this.isActive = true,
  });

  factory SensorDefinition.fromJson(Map<String, dynamic> json) {
    return SensorDefinition(
      id: json['id'],
      unitId: json['unit_id'],
      registerAddress: json['register_address'],
      equipmentId: json['equipment_id'],
      name: json['name'],
      sensorType: json['sensor_type'],
      unit: json['unit'] ?? '',
      scaleFactor: (json['scale_factor'] ?? 1.0).toDouble(),
      offset: (json['offset'] ?? 0.0).toDouble(),
      alarmMin: json['alarm_min']?.toDouble(),
      warningMin: json['warning_min']?.toDouble(),
      warningMax: json['warning_max']?.toDouble(),
      alarmMax: json['alarm_max']?.toDouble(),
      pollingInterval: json['polling_interval'] ?? 5,
      isActive: json['is_active'] ?? true,
    );
  }
}

class SensorReading {
  final int sensorId;
  final DateTime timestamp;
  final int rawValue;
  final double value;
  final String quality;

  SensorReading({
    required this.sensorId,
    required this.timestamp,
    required this.rawValue,
    required this.value,
    this.quality = 'good',
  });

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      sensorId: json['sensor_id'],
      timestamp: DateTime.parse(json['timestamp']),
      rawValue: json['raw_value'],
      value: (json['value']).toDouble(),
      quality: json['quality'] ?? 'good',
    );
  }
}

class SensorLatestValue {
  final int sensorId;
  final String sensorName;
  final String sensorType;
  final String unit;
  final double value;
  final int rawValue;
  final String quality;
  final DateTime timestamp;
  final String? equipmentId;
  final String alarmStatus;

  SensorLatestValue({
    required this.sensorId,
    required this.sensorName,
    required this.sensorType,
    required this.unit,
    required this.value,
    required this.rawValue,
    this.quality = 'good',
    required this.timestamp,
    this.equipmentId,
    this.alarmStatus = 'normal',
  });

  factory SensorLatestValue.fromJson(Map<String, dynamic> json) {
    return SensorLatestValue(
      sensorId: json['sensor_id'],
      sensorName: json['sensor_name'],
      sensorType: json['sensor_type'],
      unit: json['unit'] ?? '',
      value: (json['value']).toDouble(),
      rawValue: json['raw_value'],
      quality: json['quality'] ?? 'good',
      timestamp: DateTime.parse(json['timestamp']),
      equipmentId: json['equipment_id'],
      alarmStatus: json['alarm_status'] ?? 'normal',
    );
  }
}

class AlarmEvent {
  final int id;
  final int sensorId;
  final String? equipmentId;
  final String severity;
  final String status;
  final String message;
  final double? triggerValue;
  final double? thresholdValue;
  final DateTime triggeredAt;
  final DateTime? acknowledgedAt;
  final String? acknowledgedBy;
  final DateTime? clearedAt;

  AlarmEvent({
    required this.id,
    required this.sensorId,
    this.equipmentId,
    required this.severity,
    required this.status,
    required this.message,
    this.triggerValue,
    this.thresholdValue,
    required this.triggeredAt,
    this.acknowledgedAt,
    this.acknowledgedBy,
    this.clearedAt,
  });

  factory AlarmEvent.fromJson(Map<String, dynamic> json) {
    return AlarmEvent(
      id: json['id'],
      sensorId: json['sensor_id'],
      equipmentId: json['equipment_id'],
      severity: json['severity'],
      status: json['status'],
      message: json['message'],
      triggerValue: json['trigger_value']?.toDouble(),
      thresholdValue: json['threshold_value']?.toDouble(),
      triggeredAt: DateTime.parse(json['triggered_at']),
      acknowledgedAt: json['acknowledged_at'] != null ? DateTime.parse(json['acknowledged_at']) : null,
      acknowledgedBy: json['acknowledged_by'],
      clearedAt: json['cleared_at'] != null ? DateTime.parse(json['cleared_at']) : null,
    );
  }
}

class AlarmStats {
  final int totalActive;
  final int totalAcknowledged;
  final int totalClearedToday;
  final Map<String, int> bySeverity;

  AlarmStats({
    required this.totalActive,
    required this.totalAcknowledged,
    required this.totalClearedToday,
    required this.bySeverity,
  });

  factory AlarmStats.fromJson(Map<String, dynamic> json) {
    return AlarmStats(
      totalActive: json['total_active'] ?? 0,
      totalAcknowledged: json['total_acknowledged'] ?? 0,
      totalClearedToday: json['total_cleared_today'] ?? 0,
      bySeverity: Map<String, int>.from(json['by_severity'] ?? {}),
    );
  }
}
