class Equipment {
  final String id;
  final String name;
  final String? model;
  final String? serialNumber;
  final String equipmentType;
  final String status;
  final String? locationDetail;
  final String? manufacturer;
  final String? qrCode;
  final String systemId;

  Equipment({
    required this.id,
    required this.name,
    this.model,
    this.serialNumber,
    required this.equipmentType,
    required this.status,
    this.locationDetail,
    this.manufacturer,
    this.qrCode,
    required this.systemId,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'],
      name: json['name'],
      model: json['model'],
      serialNumber: json['serial_number'],
      equipmentType: json['equipment_type'],
      status: json['status'],
      locationDetail: json['location_detail'],
      manufacturer: json['manufacturer'],
      qrCode: json['qr_code'],
      systemId: json['system_id'],
    );
  }

  String get statusText {
    switch (status) {
      case 'active': return 'Aktif';
      case 'maintenance': return 'Bakimda';
      case 'inactive': return 'Devre Disi';
      default: return status;
    }
  }
}
