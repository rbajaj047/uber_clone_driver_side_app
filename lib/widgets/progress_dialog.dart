import 'package:flutter/material.dart';

class ProgressDialog extends StatelessWidget {

  String? message;

  ProgressDialog({this.message});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black54,
      child: Container(
        margin: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2.0),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const SizedBox(width: 6.0,),
              const CircularProgressIndicator(
                backgroundColor: Colors.white70,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                strokeWidth: 3,
              ),
              const SizedBox(width:26.0,),
              Text(
                message!,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                ),
              )

            ],
          ),
        ),
      ),
    );
  }
}
