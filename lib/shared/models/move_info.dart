/// Battle data of one move, from `GET /move/{name}`.
class MoveInfo {
  const MoveInfo({
    required this.type,
    this.power,
    this.accuracy,
    this.pp,
    this.damageClass = '',
  });

  factory MoveInfo.fromJson(Map<String, dynamic> json) {
    return MoveInfo(
      type: (json['type'] as Map<String, dynamic>?)?['name'] as String? ??
          'normal',
      power: json['power'] as int?,
      accuracy: json['accuracy'] as int?,
      pp: json['pp'] as int?,
      damageClass:
          (json['damage_class'] as Map<String, dynamic>?)?['name'] as String? ??
              '',
    );
  }

  final String type;
  final int? power;
  final int? accuracy;
  final int? pp;

  /// `physical`, `special` or `status`.
  final String damageClass;
}
