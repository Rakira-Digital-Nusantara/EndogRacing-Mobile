/// Model data User yang merepresentasikan response dari Laravel.
///
/// Ketika Laravel mengembalikan data user (misal dari GET /api/me),
/// response JSON-nya akan dikonversi ke class ini.
///
/// Contoh response Laravel:
/// ```json
/// {
///   "id": 1,
///   "name": "Ridho",
///   "email": "ridho@example.com"
/// }
/// ```
class UserModel {
  final int id;
  final String usrLoginname;
  final String usrRolecode;
  final String empCode;
  final String? foto;

  UserModel({
    required this.id,
    required this.usrLoginname,
    required this.usrRolecode,
    required this.empCode,
    this.foto,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      usrLoginname: json['usr_loginname'] as String,
      usrRolecode: json['usr_rolecode'] as String,
      empCode: json['emp_code'] as String,
      foto: json['foto'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usr_loginname': usrLoginname,
      'usr_rolecode': usrRolecode,
      'emp_code': empCode,
      'foto': foto,
    };
  }
}
