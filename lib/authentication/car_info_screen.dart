import 'package:drivers_app/global/global.dart';
import 'package:drivers_app/splashScreen/splash_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CarInfoScreen extends StatefulWidget {
  const CarInfoScreen({Key? key}) : super(key: key);

  @override
  State<CarInfoScreen> createState() => _CarInfoScreenState();
}

class _CarInfoScreenState extends State<CarInfoScreen> {

  TextEditingController carModelTextEditingController = TextEditingController();
  TextEditingController carNumberTextEditingController = TextEditingController();
  TextEditingController carColorTextEditingController = TextEditingController();

  List<String> carTypesList = ["uber-x","uber-go","bike"];
  String? selectedCarType;

  validateCarInfo()
  {
    if(carModelTextEditingController.text.isEmpty)
    {
      Fluttertoast.showToast(msg: "Car Model field cannot be empty");
    }
    else if(carNumberTextEditingController.text.isEmpty)
    {
      Fluttertoast.showToast(msg: "Car Number field cannot be empty");
    }
    else if(carColorTextEditingController.text.isEmpty)
    {
      Fluttertoast.showToast(msg: "Car Color field cannot be empty");
    }
    else if(selectedCarType == null)
      {
        Fluttertoast.showToast(msg: "Please select a vehicle type");
      }
    else
      {
        saveCarInfo();
      }
  }
  saveCarInfo()
  {
    Map driversCarInfoMap=
    {
      "car_model": carModelTextEditingController.text.trim(),
      "car_number":carNumberTextEditingController.text.trim(),
      "car_color": carColorTextEditingController.text.trim(),
      "car_type": selectedCarType.toString(),
    };
    DatabaseReference driversRef = FirebaseDatabase.instance.ref().child("drivers"); //drivers is the parent node
    //we save it with the help of each driver's unique uid
    driversRef.child(currentFirebaseUser!.uid).child("car_details").set(driversCarInfoMap);

    Fluttertoast.showToast(msg: "Car details have been saved. Congratulations!");
    Navigator.push(context, MaterialPageRoute(builder: (c) => const MySplashScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40,),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Image.asset("images/logo1.png"),
              ),
              const SizedBox(height: 20,),
              const Text(
                "Vehicle Details",
                style: TextStyle(
                  fontSize: 26,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,

                ),
              ),
              TextField(
                controller: carModelTextEditingController,
                style: const TextStyle(
                  color: Colors.grey,
                ),
                decoration: const InputDecoration(
                  labelText: "Vehicle Model Name",
                  hintText: "",
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                  labelStyle: TextStyle(
                    color: Colors.grey,

                  ),
                ),
              ),
              TextField(
                controller: carNumberTextEditingController,
                style: const TextStyle(
                  color: Colors.grey,
                ),
                decoration: const InputDecoration(
                  labelText: "Vehicle Number",
                  hintText: "",
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                  labelStyle: TextStyle(
                    color: Colors.grey,

                  ),
                ),
              ),
              TextField(
                controller: carColorTextEditingController,
                style: const TextStyle(
                  color: Colors.grey,
                ),
                decoration: const InputDecoration(
                  labelText: "Color of your Vehicle",
                  hintText: "",
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                  labelStyle: TextStyle(
                    color: Colors.grey,

                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),
              DropdownButton(
                dropdownColor: Colors.black,
                hint: const Text(
                  "Please choose vehicle type",
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                value: selectedCarType,
                onChanged: (newValue)
                {
                  setState(()
                  {
                    selectedCarType = newValue.toString();
                  });
                },
                items: carTypesList.map((car) {
                  return DropdownMenuItem(
                      value: car,
                      child: Text(
                        car,
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                  );
                }).toList(),
              ),
              ElevatedButton(
                  onPressed: ()
                  {
                    //Navigator.push(context, MaterialPageRoute(builder: (c)=>CarInfoScreen()));
                    validateCarInfo();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreenAccent,

                  ),
                  child: const Text(
                    "Save Details",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 18,
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
