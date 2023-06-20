import 'dart:async';
import 'package:drivers_app/pushNotifictaions/push_notification_system.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../assistants/assistant_methods.dart';
import '../assistants/black_theme_google_map.dart';
import '../global/global.dart';

class HomeTabPage extends StatefulWidget {
  const HomeTabPage({Key? key}) : super(key: key);

  @override
  State<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage> {
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController? newGoogleMapController;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  var geoLocator = Geolocator();
  LocationPermission? _locationPermission;

  String statusText = "Now Offline";
  Color buttonColor = Colors.grey;
  bool isDriverActive = false;


  checkIfLocationPermissionAllowed() async
  {
    _locationPermission = await Geolocator.requestPermission();

    if(_locationPermission == LocationPermission.denied)
    {
      _locationPermission = await Geolocator.requestPermission();
    }
  }

  locateDriverPosition() async
  {
    Position cPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    //the above line of code gives the position of the user with high accuracy
    driverCurrentPosition = cPosition;

    //convert position into latitude and longitude
    LatLng latLngPosition = LatLng(driverCurrentPosition!.latitude,driverCurrentPosition!.longitude);

    //adjust camera so that it adjusts when user moves
    CameraPosition cameraPosition = CameraPosition(target: latLngPosition, zoom: 40);

    newGoogleMapController!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    String humanReadableAddress = await AssistantMethods.searchAddressForGeographicCoordinates(driverCurrentPosition!, context);

    print("this is your address = $humanReadableAddress");

    //String humanReadableAddress = await AssistantMethods.searchAddressForGeographicCoordinates(userCurrentPosition!,context);
  }

  readCurrentDriverInformation() async
  {
    currentFirebaseUser = fAuth.currentUser;
    
    FirebaseDatabase.instance.ref().child("drivers").child(currentFirebaseUser!.uid)
    .once().then((snap) =>
    {
      if(snap.snapshot.value != null)
        {
          onlineDriverData.id = (snap.snapshot.value as Map<String, dynamic>)["id"],
          onlineDriverData.name = (snap.snapshot.value as Map<String, dynamic>)["name"],
          onlineDriverData.phone = (snap.snapshot.value as Map<String, dynamic>)["phone"],
          onlineDriverData.email = (snap.snapshot.value as Map<String, dynamic>)["email"],
          onlineDriverData.carColor = (snap.snapshot.value as Map<String, dynamic>)["car_details"]["car_color"],
          onlineDriverData.carModel = (snap.snapshot.value as Map<String, dynamic>)["car_details"]["car_model"],
          onlineDriverData.carNumber = (snap.snapshot.value as Map<String, dynamic>)["car_details"]["car_number"],
          driverVehicleType = (snap.snapshot.value as Map<String, dynamic>)["car_details"]["type"],
        }
    });

    
    PushNotificationSystem pushNotificationSystem = PushNotificationSystem();
    pushNotificationSystem.initializeCloudMessaging(context);
    pushNotificationSystem.generateAndGetToken();
  }


  @override
  void initState() {
    super.initState();

    checkIfLocationPermissionAllowed();
    readCurrentDriverInformation();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            myLocationEnabled: true,
            initialCameraPosition: _kGooglePlex,
            onMapCreated: (GoogleMapController controller)
            {
              _controllerGoogleMap.complete(controller);
              newGoogleMapController = controller;
              //an instance of GoogleMapController which will handle everything that will be updated on a realtime on the google map
              //for this purpose we have newGoogleMapController
              blackThemeGoogleMap(newGoogleMapController);

              locateDriverPosition();
            },
          ),

          //ui for online/offline driver
          statusText!="Now Online"
              ? Container(
                  height: MediaQuery.of(context).size.height,
                  width: double.infinity,
                  color: Colors.black54,
                )
              : Container(),

          //button for online offline driver
          Positioned(
            top: statusText!="Now Online"
                ? MediaQuery.of(context).size.height * 0.45
                : MediaQuery.of(context).size.height * 0.05,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                    onPressed: ()
                    {
                      if(isDriverActive != true)//offline
                        {
                          driverIsOnlineNow();
                          updateDriversLocationAtRealTime();
                          setState(() {
                            statusText = "Now Online";
                            isDriverActive = true;
                            buttonColor = Colors.transparent;
                          });
                          
                          //display toast
                          Fluttertoast.showToast(msg: "You are online now.");
                          
                        }
                      else
                        {
                          driverIsOfflineNow();
                          setState(() {
                            statusText = "Now Offline";
                            isDriverActive = false;
                            //buttonColor = Colors.transparent;
                          });
                          //display toast
                          Fluttertoast.showToast(msg: "You are offline now.");
                        }

                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26)
                      )
                    ),
                    child: statusText!="Now Online" ? Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                    : Icon(
                      Icons.phonelink_ring,
                      color: Colors.white,
                      size: 26,
                    ),
                ),
              ],
            ),
          ),
        ],
      );
  }

  driverIsOnlineNow() async
  {
    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    driverCurrentPosition = pos;

    Geofire.initialize("activeDrivers");

    Geofire.setLocation(
        currentFirebaseUser!.uid,
        driverCurrentPosition!.latitude,
        driverCurrentPosition!.longitude
    );

    DatabaseReference ref = FirebaseDatabase.instance.ref()
        .child("drivers")
        .child(currentFirebaseUser!.uid)
        .child("newRideStatus");

    ref.set("idle"); //searching for ride request
    ref.onValue.listen((event) { });
  }

  updateDriversLocationAtRealTime()
  {
    streamSubscriptionPosition = Geolocator.getPositionStream()
        .listen((Position position)
    {
      driverCurrentPosition = position;

      if( isDriverActive == true)
      {
        Geofire.setLocation(
            currentFirebaseUser!.uid,
            driverCurrentPosition!.latitude,
            driverCurrentPosition!.longitude
        );
      }

      LatLng latLng = LatLng(
          driverCurrentPosition!.latitude,
          driverCurrentPosition!.longitude,
      );
      
      newGoogleMapController!.animateCamera(CameraUpdate.newLatLng(latLng));

    });
  }

  driverIsOfflineNow()
  {
    Geofire.removeLocation(currentFirebaseUser!.uid);
    DatabaseReference? ref = FirebaseDatabase.instance.ref()
        .child("drivers")
        .child(currentFirebaseUser!.uid)
        .child("newRideStatus");
    ref.onDisconnect();
    ref.remove();
    ref = null;

    Future.delayed(const Duration(milliseconds: 2000), ()
    {
      //SystemChannels.platform.invokeMethod("SystemNavigator.pop");
      SystemNavigator.pop();
    });

  }

}
