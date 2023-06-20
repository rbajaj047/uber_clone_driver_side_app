import 'package:firebase_database/firebase_database.dart';

class UserModel
{
  //with the help of this class we are going to get data from the realtime database
  String? email;
  String? id;
  String? phone;
  String? name;

  UserModel({this.email, this.id, this.name, this.phone,});

  UserModel.fromSnapshot(DataSnapshot snap)
  {
    email = (snap.value as dynamic)["email"];
    phone = (snap.value as dynamic)["phone"];
    name = (snap.value as dynamic)["name"];
    id = snap.key;
  }

}