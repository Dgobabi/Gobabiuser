class BizaoModel {
  String? statuts;
  String? createdAt;
  int? driverId;
  int? id;
  String? date;
  int? montant;

  String? updatedAt;

  BizaoModel({
    this.statuts,
    this.createdAt,
    this.driverId,
    this.id,
    this.date,
    this.montant,
    this.updatedAt,
  });

  factory BizaoModel.fromJson(Map<String, dynamic> json) {
    return BizaoModel(
      statuts: json['statuts'],
      createdAt: json['created_at'],
      driverId: json['id_driver'],
      id: json['id'],
      date: json['date'],
      montant: json['montant'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['statuts'] = this.statuts;
    data['created_at'] = this.createdAt;
    data['driver_id'] = this.driverId;
    data['id'] = this.id;
    data['date'] = this.date;
    data['montant'] = this.montant;

    data['updated_at'] = this.updatedAt;
    return data;
  }
}
