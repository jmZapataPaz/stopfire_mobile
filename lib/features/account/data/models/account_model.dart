import 'package:stopfire_mobile/features/account/domain/entities/account.dart';

class AccountModel {
  final int id;
  final String? nombre;
  final String? apellido; 
  final String? email;
  final String? celular;

  AccountModel({
    required this.id,
    this.nombre,
    this.apellido, 
    this.email,
    this.celular,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic v) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return AccountModel(
      id: parseId(json['id'] ?? json['userId'] ?? json['Id'] ?? json['ID']),
      nombre: (json['nombre'] ?? json['name'])?.toString(),
      apellido: (json['apellido'] ?? json['lastName'])?.toString(),
      email: (json['email'] ?? json['correo'])?.toString(),
      celular: (json['celular'] ?? json['telefono'])?.toString(),
    );
  }

  Account toEntity() => Account(
        id: id,
        nombre: nombre,
        apellido: apellido, 
        email: email,
        celular: celular,
      );
}