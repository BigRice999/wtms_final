class Worker {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  String image;
  final String? birthDate; 
  final String? gender;    

  Worker({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.image,
    this.birthDate,
    this.gender,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: json['id'].toString(),
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      image: json['image'] ?? '',
      birthDate: json['birth_date'], 
      gender: json['gender'],
    );
  }
}
