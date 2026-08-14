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
  final String name;
  final String email;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
  });

  /// Membuat UserModel dari JSON (Map).
  /// Dipanggil saat menerima response dari API Laravel.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  /// Mengubah UserModel ke JSON (Map).
  /// Berguna jika perlu mengirim data user ke API.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}
