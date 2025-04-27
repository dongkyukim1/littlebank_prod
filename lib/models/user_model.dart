class UserModel {
  final String id;
  final String nickname;
  final String password;
  final int? age;
  final double? allowance;
  final String? parent;

  UserModel({
    required this.id,
    required this.nickname,
    required this.password,
    this.age,
    this.allowance,
    this.parent,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      nickname: json['nickname'],
      password: json['password'],
      age: json['age'],
      allowance: json['allowance'],
      parent: json['parent'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'password': password,
      'age': age,
      'allowance': allowance,
      'parent': parent,
    };
  }
} 