class Equipment {
  final String id;
  final String name;
  final String? model;
  final String? serialNumber;
  final String category;
  final String subcategory;
  final String status;
  final String? locationDetail;
  final String? manufacturer;
  final String? qrCode;
  final String? roomNumber;
  final String? zone;
  final String? criticality;
  final int? maintenanceIntervalDays;
  final String? lastMaintenanceDate;
  final String? photoUrl;
  final String systemId;
  Equipment({required this.id, required this.name, this.model, this.serialNumber, required this.category, required this.subcategory, required this.status, this.locationDetail, this.manufacturer, this.qrCode, this.roomNumber, this.zone, this.criticality, this.maintenanceIntervalDays, this.lastMaintenanceDate, this.photoUrl, required this.systemId});
  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(id: json['id'], name: json['name'], model: json['model'], serialNumber: json['serial_number'], category: json['category'], subcategory: json['subcategory'], status: json['status'], locationDetail: json['location_detail'], manufacturer: json['manufacturer'], qrCode: json['qr_code'], roomNumber: json['room_number'], zone: json['zone'], criticality: json['criticality'], maintenanceIntervalDays: json['maintenance_interval_days'], lastMaintenanceDate: json['last_maintenance_date'], photoUrl: json['photo_url'], systemId: json['system_id']);
  }
  String get statusText { switch (status) { case 'active': return 'Aktif'; case 'maintenance': return 'Bakimda'; case 'inactive': return 'Devre Dışı'; default: return status; } }
  String get categoryText { const map = {'HVAC': 'Iklimlendirme', 'ELEKTRIK': 'Elektrik', 'TESISAT': 'Tesisat', 'KAPI_KILIT': 'Kapi/Kilit', 'MOBILYA': 'Mobilya', 'ELEKTRONIK': 'Elektronik', 'HAVUZ_SPA': 'Havuz/SPA', 'ASANSOR': 'Asansor', 'BOYA_TADILAT': 'Boya/Tadilat'}; return map[category] ?? category; }
  String get criticalityText { switch (criticality) { case 'critical': return 'Kritik'; case 'high': return 'Yuksek'; case 'normal': return 'Normal'; case 'low': return 'Dusuk'; default: return 'Normal'; } }
}
