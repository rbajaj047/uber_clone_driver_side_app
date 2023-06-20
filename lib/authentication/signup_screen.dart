import 'package:drivers_app/authentication/car_info_screen.dart';
import 'package:drivers_app/authentication/login_screen.dart';
import 'package:drivers_app/global/global.dart';
import 'package:drivers_app/widgets/progress_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {

  TextEditingController nameTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController phoneTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();

  validateForm()
  {
    if(nameTextEditingController.text.length < 3)
      {
        Fluttertoast.showToast(msg: "Name must be at least three characters");
      }
    else if(!emailTextEditingController.text.contains('@'))
      {
        Fluttertoast.showToast(msg: "Please enter a valid e-mail address");
      }
    else if(phoneTextEditingController.text.isEmpty)
      {
        Fluttertoast.showToast(msg: "Please enter a valid phone number");
      }
    else if(passwordTextEditingController.text.length < 6)
      {
        Fluttertoast.showToast(msg: "Password must be at least 6 characters");
      }
    else
      {
        saveDriverInfoNow();
      }
  }
  saveDriverInfoNow() async
  {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext c){
          return ProgressDialog(message: "Processing, please wait...",);
        }
    );
    final User? firebaseUser = (
      await fAuth.createUserWithEmailAndPassword(
          email: emailTextEditingController.text.trim(),
          password: passwordTextEditingController.text.trim(),
      ).catchError((msg){
        Navigator.pop(context);
        Fluttertoast.showToast(msg: "Error: " + msg.toString());
      })
    ).user;

    //now, to save it into the realtime database we write the following code
    if(firebaseUser!= null)
      {
        //driversMap contains all the info, we will save this to realtime database
        Map driversMap=
            {
              "id": firebaseUser.uid,
              "name": nameTextEditingController.text.trim(),
              "phone":phoneTextEditingController.text.trim(),
              "email": emailTextEditingController.text.trim(),
              "password": passwordTextEditingController.text.trim(),
            };

        //for saving it to realtime database, we have this code
        DatabaseReference driversRef = FirebaseDatabase.instance.ref().child("drivers"); //drivers is the parent node
        //we save it with the help of each driver's unique uid
        driversRef.child(firebaseUser.uid).set(driversMap);

        currentFirebaseUser = firebaseUser;
        Fluttertoast.showToast(msg: "Account has been created successfully.");
        Navigator.push(context, MaterialPageRoute(builder: (c)=>CarInfoScreen()));
      }
    else
      {
        Navigator.pop(context);
        Fluttertoast.showToast(msg: "Account couldn't be created.");
      }

  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(

        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 30,),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Image.asset("images/logo1.png"),

              ),
              const SizedBox(height: 20,),
              const Text(
                  "Register as a Driver",
              style: TextStyle(
                fontSize: 26,
                color: Colors.grey,
                fontWeight: FontWeight.bold,

              ),
              ),
              const SizedBox(height: 5,),
              TextField(
                controller: nameTextEditingController,
                keyboardType: TextInputType.text,
                style: const TextStyle(
                  color: Colors.grey,
                ),
                decoration: const InputDecoration(
                  labelText: "Name",
                  hintText: "Name",
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
                    color: Colors.yellow,

                  ),
                ),
              ),
              TextField(
                controller: emailTextEditingController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(
                  color: Colors.grey,
                ),
                decoration: const InputDecoration(
                  labelText: "E-mail",
                  hintText: "abc123@gmail.com",
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
                    color: Colors.yellow,

                  ),
                ),
              ),
              TextField(
                controller: phoneTextEditingController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(
                  color: Colors.grey,
                ),
                decoration: const InputDecoration(
                  labelText: "Phone",
                  hintText: "Phone No.",
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
                    color: Colors.yellow,

                  ),
                ),
              ),
              TextField(
                controller: passwordTextEditingController,
                keyboardType: TextInputType.text,
                obscureText: true,
                style: const TextStyle(
                  color: Colors.grey,
                ),
                decoration: const InputDecoration(
                  labelText: "Password",
                  hintText: "******",
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
                    color: Colors.yellow,

                  ),
                ),
              ),
              const SizedBox(height: 20,),
              ElevatedButton(
                  onPressed: ()
                  {
                    validateForm();
                    //Navigator.push(context, MaterialPageRoute(builder: (c)=>CarInfoScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.limeAccent,

                  ),
                  child: const Text(
                    "Create Account",
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                    ),
                  )),
              TextButton(
                child: const Text(
                  "Already have an account? SignIn here",
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                onPressed: (){
                  Navigator.push(context, MaterialPageRoute(builder: (c)=>LoginScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
