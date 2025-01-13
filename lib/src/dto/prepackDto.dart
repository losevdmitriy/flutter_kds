class PrepackDto {
  final int id;
  final String name;

  PrepackDto({
    required this.id,
    required this.name,
  });

  factory PrepackDto.fromJson(Map<String, dynamic> json) {
    return PrepackDto(id: json['id'] as int, name: json['name'] as String);
  }
}
