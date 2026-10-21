class AuthenticationUser {
  /// `userId` de Roble: el `sub` del token y el `_owner` de sus filas.
  String? id;
  final String email;
  final String name;
  final String password;

  AuthenticationUser({
    this.id,
    required this.email,
    required this.name,
    required this.password,
  });

  factory AuthenticationUser.fromJson(Map<String, dynamic> json) {
    return AuthenticationUser(
      id: json['id']?.toString(),
      email: json['email'],
      name: json['name'],
      password: json['password'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email, 'name': name, 'password': password};
  }
}
