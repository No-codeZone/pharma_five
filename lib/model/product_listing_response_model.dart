class ProductListingResponseModel {
  int? serialNo;
  String? medicineName;
  String? genericName;

  ProductListingResponseModel(
      {this.serialNo, this.medicineName, this.genericName});

  ProductListingResponseModel.fromJson(Map<String, dynamic> json) {
    serialNo = json['serialNo'];
    medicineName = json['medicineName'];
    genericName = json['genericName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['serialNo'] = this.serialNo;
    data['medicineName'] = this.medicineName;
    data['genericName'] = this.genericName;
    return data;
  }
}