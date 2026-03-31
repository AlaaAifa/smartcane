import 'dart:convert';

class UserModel {
  final String userId;
  final String nom;
  final String prenom;
  final String birthday;
  final String email;
  final String phoneNumberMalvoyant;
  final String phoneNumberFamille;
  final String? city;
  final String? street;
  final int battery;
  final String status;

  UserModel({
    required this.userId,
    required this.nom,
    required this.prenom,
    required this.birthday,
    required this.email,
    required this.phoneNumberMalvoyant,
    required this.phoneNumberFamille,
    this.city,
    this.street,
    this.battery = 100,
    this.status = "Active",
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      birthday: json['birthday'] ?? '',
      email: json['email'] ?? '',
      phoneNumberMalvoyant: json['phone_number_malvoyant'] ?? '',
      phoneNumberFamille: json['phone_number_famille'] ?? '',
      city: json['address']?['city'],
      street: json['address']?['street'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'nom': nom,
      'prenom': prenom,
      'birthday': birthday,
      'email': email,
      'phone_number_malvoyant': phoneNumberMalvoyant,
      'phone_number_famille': phoneNumberFamille,
      'address': {'city': city, 'street': street},
    };
  }
}
