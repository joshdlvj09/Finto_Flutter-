// Usuario local de la app. La contrasena nunca se guarda en texto plano.
class AppUser {
  final int? id;
  final String name;
  final String email;
  final String passwordHash;
  final String salt;

  const AppUser({
    this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.salt,
  });

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  String get initials => name
      .trim()
      .split(RegExp(r'\s+'))
      .take(2)
      .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
      .join();

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'email': email,
        'password_hash': passwordHash,
        'salt': salt,
      };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        id: map['id'] as int?,
        name: map['name'] as String,
        email: map['email'] as String,
        passwordHash: map['password_hash'] as String,
        salt: map['salt'] as String,
      );

  AppUser copyWith({String? passwordHash, String? salt}) => AppUser(
        id: id,
        name: name,
        email: email,
        passwordHash: passwordHash ?? this.passwordHash,
        salt: salt ?? this.salt,
      );
}
