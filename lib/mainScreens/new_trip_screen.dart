import 'dart:async';

import 'package:drivers_app/global/global.dart';
import 'package:drivers_app/models/user_ride_request_information.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../assistants/assistant_methods.dart';
import '../assistants/black_theme_google_map.dart';
import '../widgets/fare_amount_collection_dialog.dart';
import '../widgets/progress_dialog.dart';

class NewTripScreen extends StatefulWidget {

  UserRideRequestInformation? userRideRequestDetails;
  NewTripScreen({this.userRideRequestDetails});

  @override
  State<NewTripScreen> createState() => _NewTripScreenState();
}

class _NewTripScreenState extends State<NewTripScreen> {

  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController? newTripGoogleMapController;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  String? buttonTitle = "Arrived";

  Color? buttonColor = Colors.green;
  Set<Marker> setOfMarkers = Set<Marker>();
  Set<Circle> setOfCircles = Set<Circle>();
  Set<Polyline> setOfPolyline = Set<Polyline>();
  List<LatLng> polylinePositionCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();

  double mapPadding = 0;
  BitmapDescriptor? iconAnimatedMarker;
  var geoLocator = Geolocator();
  Position? onlineDriverCurrentPosition;
  String rideRequestStatus = "accepted";
  String durationFromOriginToDestination = "";

  bool isRequestDirectionDetails = false;

  //1st case: sourceLatLng::driverCurrent location, destinationLatLng::userPickUp location (when driver accepts the user ride request)
  //2nd case: sourceLatLng::userPickUp location, destinationLatLng::userDropOff location (driver has already picked up user)

  Future<void> drawPolylineFromSourceToDestination(LatLng sourceLatLng, LatLng destinationLatLng) async
  {

    showDialog(
        context: context,
        builder: (BuildContext context) =>
            ProgressDialog(message: "Please wait...",)
    );

    var directionDetailsInfo = await AssistantMethods
        .obtainOriginToDestinationDirectionDetails(sourceLatLng, destinationLatLng);

    Navigator.pop(context);

    //print("These are points : ");
    //print(directionDetailsInfo!.ePoints);

    PolylinePoints pPoints = PolylinePoints();

    List<PointLatLng> decodedPolylinePointsResultList = pPoints.decodePolyline(
        directionDetailsInfo!.ePoints!);
    //we can accept a list of LatLng points only for drawing polyline so the above list needs to be decoded from PointsLatLng to just LatLng
    //hence we will run a loop and do the necessary conversion

    polylinePositionCoordinates.clear();

    if (decodedPolylinePointsResultList.isNotEmpty) {
      decodedPolylinePointsResultList.forEach((PointLatLng pointLatLng) {
        polylinePositionCoordinates.add(
            LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
      //polyLineSet.clear();
    }

    setOfPolyline.clear();

    setState(() {
      Polyline polyline = Polyline(polylineId: const PolylineId("PolylineId"),
          color: Colors.indigo,
          jointType: JointType.round,
          points: polylinePositionCoordinates,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          geodesic: true);
      setOfPolyline.add(polyline);
    });

    LatLngBounds boundsLatLng;
    if (sourceLatLng.latitude > destinationLatLng.latitude && sourceLatLng.longitude > destinationLatLng.longitude) {
      boundsLatLng = LatLngBounds(
        southwest: destinationLatLng,
        northeast: sourceLatLng,
      );
    }
    else if (sourceLatLng.longitude > destinationLatLng.longitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(sourceLatLng.latitude, destinationLatLng.longitude),
        northeast: LatLng(destinationLatLng.latitude, sourceLatLng.longitude),
      );
    }
    else if (sourceLatLng.latitude > destinationLatLng.latitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(destinationLatLng.latitude, sourceLatLng.longitude),
        northeast: LatLng(sourceLatLng.latitude, destinationLatLng.longitude),
      );
    }
    else {
      boundsLatLng = LatLngBounds(
        southwest: sourceLatLng,
        northeast: destinationLatLng,
      );
    }

    newTripGoogleMapController!.animateCamera(
        CameraUpdate.newLatLngBounds(boundsLatLng, 65));

    Marker sourceMarker = Marker(
      markerId: const MarkerId("sourceID"),
      position: sourceLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
    );

    Marker destinationMarker = Marker(
      markerId: const MarkerId("destinationID"),
      position: destinationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
    );

    setState(() {
      setOfMarkers.add(sourceMarker);
      setOfMarkers.add(destinationMarker);
    });

    Circle sourceCircle = Circle(
      circleId: const CircleId("sourceID"),
      center: sourceLatLng,
      fillColor: Colors.green,
      radius: 12,
      strokeColor: Colors.white70,
      strokeWidth: 3,
    );

    Circle destinationCircle = Circle(
      circleId: const CircleId("destinationID"),
      center: destinationLatLng,
      fillColor: Colors.orangeAccent,
      radius: 12,
      strokeColor: Colors.white70,
      strokeWidth: 3,
    );

    setState(() {
      setOfCircles.add(sourceCircle);
      setOfCircles.add(destinationCircle);
    });
  }

  @override
  void initState() {
    super.initState();

    saveAssignedDriverDetailsToUserRideRequest();
  }

  createDriverIconMarker()
  {
    if(iconAnimatedMarker == null)
    {
      ImageConfiguration imageConfiguration = createLocalImageConfiguration(context, size: Size(2, 2));
      BitmapDescriptor.fromAssetImage(imageConfiguration, "images/car.png").then((value)
      {
        iconAnimatedMarker = value;
      });
    }
  }

  getDriversLocationUpdatesAtRealTime()
  {
    var oldLatLng = LatLng(0, 0);
    streamSubscriptionDriverLivePosition = Geolocator.getPositionStream()
        .listen((Position position)
    {
      driverCurrentPosition = position;
      onlineDriverCurrentPosition = position;

      LatLng latLngLiveDriverPosition = LatLng(
        onlineDriverCurrentPosition!.latitude,
        onlineDriverCurrentPosition!.longitude,
      );

      Marker animatingMarker = Marker(
          markerId: const MarkerId("AnimatedMarker"),
          position: latLngLiveDriverPosition,
          icon: iconAnimatedMarker!,
          infoWindow: const InfoWindow(title: "This is your current Position",),
      );

      setState(() {
        CameraPosition cameraPosition = CameraPosition(target: latLngLiveDriverPosition, zoom: 16);
        newTripGoogleMapController!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));


        //using the below two lines of code,
        //we are basically moving the icon along the polyline made between driverCurrentLocation and userPickUpLocation
        setOfMarkers.removeWhere((element) => element.markerId.value == "AnimatedMarker");
        //when the driver moves to a new location, we want the previous markers to be removed from the map
        setOfMarkers.add(animatingMarker);
      });
      oldLatLng = latLngLiveDriverPosition;
      updateDurationTimeAtRealTime();

      Map driverLatLngDataMap = {
        "latitude": onlineDriverCurrentPosition!.latitude.toString(),
        "longitude": onlineDriverCurrentPosition!.longitude.toString(),
      };

      //update driver location at real time in Database
      FirebaseDatabase.instance.ref()
          .child("All Ride Requests")
          .child(widget.userRideRequestDetails!.rideRequestId!)
          .child("driverLocation").set(driverLatLngDataMap);
    });
  }

  updateDurationTimeAtRealTime() async
  {
    if(isRequestDirectionDetails == false) {
      isRequestDirectionDetails = true;
      if(onlineDriverCurrentPosition == null){
        return;
      }
      var originLatLng = LatLng(
          onlineDriverCurrentPosition!.latitude,
          onlineDriverCurrentPosition!.longitude);
      var destinationLatLng;
      if (rideRequestStatus == "accepted") {
        destinationLatLng =
            widget.userRideRequestDetails!.originLatLng; //userPickUpLocation
      } else {
        destinationLatLng = widget
            .userRideRequestDetails!.destinationLatLng; //userDropOffLocation
      }
      var directionInformation =
          await AssistantMethods.obtainOriginToDestinationDirectionDetails(
              originLatLng, destinationLatLng);

      if (directionInformation != null) {
        setState(() {
          durationFromOriginToDestination = directionInformation.durationText!;
        });
      }
      isRequestDirectionDetails = false;
    }
  }


  @override
  Widget build(BuildContext context) {
    createDriverIconMarker();
    return Scaffold(
      body: Stack(
        children: [
          //googleMap
          GoogleMap(
            padding: EdgeInsets.only(bottom: mapPadding,),
            mapType: MapType.normal,
            myLocationEnabled: true,
            initialCameraPosition: _kGooglePlex,
            markers: setOfMarkers,
            circles: setOfCircles,
            polylines: setOfPolyline,
            onMapCreated: (GoogleMapController controller)
            {
              _controllerGoogleMap.complete(controller);
              newTripGoogleMapController = controller;
              //an instance of GoogleMapController which will handle everything that will be updated on a realtime on the google map
              //for this purpose we have newTripGoogleMapController

              setState(() {
                mapPadding = 400;
              });

              blackThemeGoogleMap(newTripGoogleMapController);

              var driverCurrentLatLng = LatLng(driverCurrentPosition!.latitude, driverCurrentPosition!.longitude);

              var userPickUpLatLng = widget.userRideRequestDetails!.originLatLng;
              drawPolylineFromSourceToDestination(driverCurrentLatLng, userPickUpLatLng!);

              getDriversLocationUpdatesAtRealTime();

            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white30,
                    blurRadius: 18,
                    spreadRadius: .5,
                    offset: Offset(0.6, 0.6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                child: Column(
                  children: [

                    //duration
                    Text(durationFromOriginToDestination, style: const TextStyle( fontSize: 18, fontWeight: FontWeight.bold, color: Colors.lightGreenAccent, ),),

                    const SizedBox(height: 18,),

                    const Divider(
                      thickness: 2,
                      height: 2,
                      color: Colors.grey,
                    ),

                    const SizedBox(height: 8,),

                    //username - icon
                    Row(
                      children: [
                        Text(widget.userRideRequestDetails!.userName!, style: const TextStyle( fontSize: 20, fontWeight: FontWeight.bold, color: Colors.lightGreenAccent, ),),
                        const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Icon(Icons.phone_android, color: Colors.grey,),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18,),

                    //user pickUp address with icon
                    Row(
                      children: [
                        Image.asset("images/origin.png", width: 30, height: 30,),
                        const SizedBox(width: 22,),
                        Expanded(
                          child: Container(
                            child: Text(widget.userRideRequestDetails!.originAddress!,
                              style: const TextStyle( fontSize: 16, color: Colors.grey),),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20,),

                    //user dropOff address with icon
                    Row(
                      children: [
                        Image.asset("images/destination.png", width: 30, height: 30,),
                        const SizedBox(width: 22,),
                        Expanded(
                          child: Container(
                            child: Text(widget.userRideRequestDetails!.destinationAddress!,
                              style: const TextStyle( fontSize: 16, color: Colors.grey),),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24,),

                    const Divider(
                      thickness: 2,
                      height: 2,
                      color: Colors.grey,
                    ),

                    const SizedBox(height: 10,),

                    ElevatedButton.icon(
                        onPressed: () async
                        {
                          //driver has reached the userPickUpLocation
                          if(rideRequestStatus == "Accepted"){
                            rideRequestStatus = "Arrived";
                            FirebaseDatabase.instance.ref().child("All Ride Requests")
                                .child(widget.userRideRequestDetails!.rideRequestId!)
                                .child("status").set(rideRequestStatus);

                            setState(() {
                              buttonTitle = "Let's Go"; //start the trip with the user
                              buttonColor = Colors.lightGreen;
                            });

                            showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext c) => ProgressDialog(
                                  message: "Loading...",
                                ),
                            );

                            await drawPolylineFromSourceToDestination(widget.userRideRequestDetails!.originLatLng!, widget.userRideRequestDetails!.destinationLatLng!);

                            Navigator.pop(context);
                          }
                          //user sat in Driver's car -Let's Go Button
                          else if(rideRequestStatus == "Arrived"){
                            rideRequestStatus = "ontrip";
                            FirebaseDatabase.instance.ref().child("All Ride Requests")
                                .child(widget.userRideRequestDetails!.rideRequestId!)
                                .child("status").set(rideRequestStatus);

                            setState(() {
                              buttonTitle = "End Trip"; //start the trip with the user
                              buttonColor = Colors.redAccent;
                            });

                          }
                          //user/driver reached location -End Trip Button
                          else if(rideRequestStatus == "ontrip"){
                            endTripNow();
                          }

                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                        ),
                        icon: const Icon(Icons.directions_car, color: Colors.white, size: 25,),
                        label: Text(buttonTitle!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, ),),
                    ),

                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  endTripNow() async
  {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext c) => ProgressDialog(
        message: "Please Wait...",
      ),
    );

    //get the tripDirectionDetails = distance travelled
    var currentDriverPositionLatLng = LatLng(onlineDriverCurrentPosition!.latitude, onlineDriverCurrentPosition!.longitude);
    var tripDirectionDetails = await AssistantMethods.obtainOriginToDestinationDirectionDetails(currentDriverPositionLatLng, widget.userRideRequestDetails!.originLatLng!);

    //fare amount
    double totalFareAmount = AssistantMethods.calculateFareAmountFromSourceToDestination(tripDirectionDetails!);

    FirebaseDatabase.instance.ref().child("All Ride Requests").child(widget.userRideRequestDetails!.rideRequestId!).child("fareAmount").set(totalFareAmount.toString());
    FirebaseDatabase.instance.ref().child("All Ride Requests").child(widget.userRideRequestDetails!.rideRequestId!).child("status").set("ended");

    streamSubscriptionDriverLivePosition!.cancel();
    Navigator.pop(context);

    //display fare amount to dialog box
    showDialog(context: context, builder: (BuildContext c) =>
        FareAmountCollectionDialog(totalFareAmount: totalFareAmount),
    );

    //save fare amount to driver total earnings
    saveFareAmountToDriverEarnings(totalFareAmount);
  }

  saveFareAmountToDriverEarnings(double totalFareAmount)
  {
    double oldEarnings;
    double driverTotalEarnings;
    FirebaseDatabase.instance.ref()
        .child("drivers")
        .child(currentFirebaseUser!.uid)
        .child("earnings")
        .once().then((snap) => {
          //find whether the sub-child earnings exist or not
      if(snap.snapshot.value!=null){
        //exists
        oldEarnings = double.parse(snap.snapshot.value.toString()),
        driverTotalEarnings = oldEarnings + totalFareAmount,
        FirebaseDatabase.instance.ref()
            .child("drivers")
            .child(currentFirebaseUser!.uid)
            .child("earnings")
            .set(driverTotalEarnings.toString())
      }
      else{
        FirebaseDatabase.instance.ref()
            .child("drivers")
            .child(currentFirebaseUser!.uid)
            .child("earnings")
            .set(totalFareAmount.toString())
      }
    });
  }

  saveAssignedDriverDetailsToUserRideRequest()
  {

    DatabaseReference databaseReference = FirebaseDatabase.instance.ref().child("All Ride Requests").child(widget.userRideRequestDetails!.rideRequestId!);
    Map driverLocationDataMap =
    {
      "latitude":driverCurrentPosition!.latitude.toString(),
      "longitude":driverCurrentPosition!.longitude.toString(),
    };
    databaseReference.child("driverLocation").set(driverLocationDataMap);

    databaseReference.child("status").set("accepted");
    databaseReference.child("driverId").set(onlineDriverData.id);
    databaseReference.child("driverName").set(onlineDriverData.name);
    databaseReference.child("driverPhone").set(onlineDriverData.phone);
    databaseReference.child("car_details").set(onlineDriverData.carNumber.toString() + onlineDriverData.carModel.toString() + onlineDriverData.carColor.toString());

    saveRideRequestIdToDriverHistory();

  }

  saveRideRequestIdToDriverHistory()
  {
    DatabaseReference tripsHistoryRef = FirebaseDatabase.instance.ref().child("drivers").child(currentFirebaseUser!.uid).child("tripsHistory");
    tripsHistoryRef.child(widget.userRideRequestDetails!.rideRequestId!).set(true);
  }
}
