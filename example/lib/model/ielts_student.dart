import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ielts_student.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class IeltsStudent {
  final int? coreUserId;
  final String? fullName;
  final String? avatar;
  final String? birthday;

  // For trial lesson
  int? id;
  String? token;

  IeltsStudent({
    this.coreUserId,
    this.fullName,
    this.avatar,
    this.birthday,
    this.id,
    this.token,
  });

  String get getBirthday {
    final date = DateFormat('yyyy-MM-dd').parse(birthday!);
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String get heroTag => 'ielts_student_${coreUserId ?? fullName ?? hashCode}';

  factory IeltsStudent.fromJson(Map<String, dynamic> json) =>
      _$IeltsStudentFromJson(json);

  Map<String, dynamic> toJson() => _$IeltsStudentToJson(this);
}
