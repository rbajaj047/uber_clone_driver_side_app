import 'dart:async';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:drivers_app/global/global.dart';
import 'package:drivers_app/pushNotifictaions/notification_dialog_box.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/user_ride_request_information.dart';

class PushNotificationSystem
{
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  Future initializeCloudMessaging(BuildContext context) async
  {
    //1.Foreground state :: when the app is open/running and it receives a push notification
    FirebaseMessaging.onMessage.listen((RemoteMessage? remoteMessage)
    {
      //display ride request/user information who requested a ride
      readUserRideRequestInformation(remoteMessage!.data["rideRequestId"], context);
    });


    //2.Background state :: when the app is minimized/in background and opened directly from push notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? remoteMessage)
    {
      //display ride request/user information who requested a ride
      readUserRideRequestInformation(remoteMessage!.data["rideRequestId"], context);
    });


    //3.Terminated state :: when the app is completely closed and opened directly from push notification
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? remoteMessage)
    {
      if(remoteMessage != null)
        {
          //display ride request/user information who requested a ride
          readUserRideRequestInformation(remoteMessage.data["rideRequestId"], context);
        }
    });
  }

  readUserRideRequestInformation(String userRideRequestId, BuildContext context)
  {
    FirebaseDatabase.instance.ref()
        .child("All Ride Requests")
        .child(userRideRequestId).once().then((snapData)
    {
      if(snapData.snapshot.value != null)
        {
          audioPlayer.open(Audio("music/music_notification.mp3"));
          audioPlayer.play();
          
          double originLat = double.parse((snapData.snapshot.value! as Map)["origin"]["latitude"]);
          double originLng = double.parse((snapData.snapshot.value! as Map)["origin"]["longitude"]);
          String originAddress = (snapData.snapshot.value! as Map)["originAddress"];

          double destinationLat = double.parse((snapData.snapshot.value! as Map)["destination"]["latitude"]);
          double destinationLng = double.parse((snapData.snapshot.value! as Map)["destination"]["longitude"]);
          String destinationAddress = (snapData.snapshot.value! as Map)["destinationAddress"];

          String userName = (snapData.snapshot.value! as Map)["userName"];
          String userPhone = (snapData.snapshot.value! as Map)["userPhone"];

          String? rideRequestId = snapData.snapshot.key;

          UserRideRequestInformation userRideRequestDetails = UserRideRequestInformation();
          userRideRequestDetails.originLatLng = LatLng(originLat, originLng);
          userRideRequestDetails.destinationLatLng = LatLng(destinationLat, destinationLng);
          userRideRequestDetails.originAddress = originAddress;
          userRideRequestDetails.destinationAddress = destinationAddress;
          userRideRequestDetails.userName = userName;
          userRideRequestDetails.userPhone = userPhone;
          userRideRequestDetails.rideRequestId = rideRequestId;

          showDialog(
            context: context,
            builder: (BuildContext context) => NotificationDialogBox(
                userRideRequestDetails : userRideRequestDetails,
            ),
          );
        }
      else
        {
          Fluttertoast.showToast(msg: "This Ride Request Id no longer exists");
        }
    });
  }

  //tokens are generated by FCM(Firebase Cloud Messaging)
  //tokens are used to distinguish between user and driver and also in between multiple drivers
  //tokens need to be changed/regenerated/refreshed in case of reinstalling/uninstalling the app or when the driver user clears the app data
  //or when the app is restored on a new device maybe

  Future generateAndGetToken() async
  {
    String? registrationToken = await messaging.getToken();
    //print("FCM Registration token: ");
    //print(registrationToken);
    FirebaseDatabase.instance.ref()
        .child("drivers")
        .child(currentFirebaseUser!.uid)
        .child("token").set(registrationToken);
    messaging.subscribeToTopic("allDrivers");
    messaging.subscribeToTopic("allUsers");
  }
  //topic messaging and subscription to topics
  //Topic messaging supports unlimited subscriptions for each topics but there are some restrictions
  //*https://firebase.google.com/docs/cloud-messaging/flutter/topic-messaging*
  //suited for publicly available information
  //For fast, secure delivery to single devices or small groups of devices, target messages to registration tokens, not topics.
  //If you need to send messages to multiple devices per user, consider device group messaging for those use cases.

}