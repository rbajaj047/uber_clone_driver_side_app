/*import 'package:flutter/cupertino.dart';
import '../models/directions.dart';

class AppInfo extends ChangeNotifier
{
  Directions? userPickUpLocation;

  void updatePickUpLocationAddress(Directions userPickUpAddress)
  {
    userPickUpLocation = userPickUpAddress;
    notifyListeners();
  }
}*/

import 'package:flutter/cupertino.dart';

import '../models/directions.dart';

class AppInfo extends ChangeNotifier
{
  Directions? userPickUpLocation;
  Directions? userDropOffLocation;

  void updatePickUpLocationAddress(Directions userPickUpAddress)
  {
    userPickUpLocation = userPickUpAddress;
    notifyListeners();
  }

  void updateDropOffLocationAddress(Directions userDropOffAddress)
  {
    userDropOffLocation = userDropOffAddress;
    notifyListeners();
  }
}