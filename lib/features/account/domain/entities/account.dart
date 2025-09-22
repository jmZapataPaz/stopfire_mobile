class Account {
  final int id;
  final String? nombre;
  final String? apellido;
  final String? email;
  final String? celular;

  const Account({
    required this.id,
    this.nombre,
    this.apellido,
    this.email,
    this.celular,
  });
}