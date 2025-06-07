class UserModel {
  String? status;
  String? message;
  UserData? data;

  UserModel({this.status, this.message, this.data});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null ? UserData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class UserData {
  User? user;
  String? token;

  UserData({this.user, this.token});

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (user != null) data['user'] = user!.toJson();
    if (token != null) data['token'] = token;
    return data;
  }
}

class User {
  int? id;
  String? username;
  String? email;
  String? currentPassword;
  String? newPassword;
  String? confirmNewPassword;
  String? profilePicture;
  bool? role;
  String? createdAt;
  String? updatedAt;

  User({
    this.id,
    this.username,
    this.email,
    this.currentPassword,
    this.newPassword,
    this.confirmNewPassword,
    this.profilePicture,
    this.role,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['userID'] ?? json['id'],
      username: json['username'],
      email: json['email'],
      profilePicture: json['profilePicture'],
      role: json['role'] is bool ? json['role'] : json['role'] == 1,
      createdAt: json['created_at'] ?? json['createdAt'],
      updatedAt: json['updated_at'] ?? json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) data['userID'] = id;
    if (username != null) data['username'] = username;
    if (email != null) data['email'] = email;
    if (currentPassword != null) data['currentPassword'] = currentPassword;
    if (newPassword != null) data['newPassword'] = newPassword;
    if (confirmNewPassword != null)
      data['confirmNewPassword'] = confirmNewPassword;
    if (profilePicture != null) data['profilePicture'] = profilePicture;
    if (role != null) data['role'] = role;
    if (createdAt != null) data['created_at'] = createdAt;
    if (updatedAt != null) data['updated_at'] = updatedAt;
    return data;
  }
}
