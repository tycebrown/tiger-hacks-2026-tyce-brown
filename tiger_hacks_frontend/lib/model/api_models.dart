import 'package:tiger_hacks_frontend/model/user.dart';

class LoginRequest {
  const LoginRequest({required this.username, required this.password});

  final String username;
  final String password;

  Map<String, dynamic> toJson() => {'username': username, 'password': password};
}

class LoginResponse {
  const LoginResponse({required this.user, required this.token});

  final User user;
  final String token;

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
    user: User.fromJson(json['user'] as Map<String, dynamic>),
    token: json['token'] as String,
  );
}

class MeasureModelData {
  MeasureModelData({
    DateTime? timestamp,
    this.bpSysPressure,
    this.bpDiaPressure,
    this.heartRate,
    this.respiratoryRate,
    this.temperature,
    this.bloodOx,
  }) : timestamp = timestamp ?? DateTime.now().toUtc();

  final DateTime timestamp;
  final int? bpSysPressure;
  final int? bpDiaPressure;
  final int? heartRate;
  final int? respiratoryRate;
  final int? temperature;
  final int? bloodOx;

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'bp_sys_pressure': bpSysPressure,
    'bp_dia_pressure': bpDiaPressure,
    'heart_rate': heartRate,
    'respiratory_rate': respiratoryRate,
    'temperature': temperature,
    'blood_ox': bloodOx,
  };
}

class MeasureQueryParams {
  const MeasureQueryParams({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  Map<String, String> toQueryParameters() => {
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
  };
}

class MeasureModel extends MeasureModelData {
  MeasureModel({
    required this.id,
    required super.timestamp,
    super.bpSysPressure,
    super.bpDiaPressure,
    super.heartRate,
    super.respiratoryRate,
    super.temperature,
    super.bloodOx,
  });

  final int id;

  factory MeasureModel.fromJson(Map<String, dynamic> json) => MeasureModel(
    id: json['id'] as int,
    timestamp: DateTime.parse(json['timestamp'] as String),
    bpSysPressure: json['bp_sys_pressure'] as int?,
    bpDiaPressure: json['bp_dia_pressure'] as int?,
    heartRate: json['heart_rate'] as int?,
    respiratoryRate: json['respiratory_rate'] as int?,
    temperature: json['temperature'] as int?,
    bloodOx: json['blood_ox'] as int?,
  );
}

class SharepointModel {
  const SharepointModel({
    required this.id,
    required this.individualId,
    required this.caretakerId,
  });

  final int id;
  final int individualId;
  final int caretakerId;

  factory SharepointModel.fromJson(Map<String, dynamic> json) =>
      SharepointModel(
        id: json['id'] as int,
        individualId: json['individual_id'] as int,
        caretakerId: json['caretaker_id'] as int,
      );
}

class SharedUserModel {
  const SharedUserModel({
    required this.sharepointId,
    required this.individualId,
    required this.caretakerId,
    required this.username,
    required this.role,
  });

  final int sharepointId;
  final int individualId;
  final int caretakerId;
  final String username;
  final UserRole role;

  factory SharedUserModel.fromJson(Map<String, dynamic> json) =>
      SharedUserModel(
        sharepointId: json['sharepoint_id'] as int,
        individualId: json['individual_id'] as int,
        caretakerId: json['caretaker_id'] as int,
        username: json['username'] as String,
        role: UserRole.values.byName(json['role'] as String),
      );
}
