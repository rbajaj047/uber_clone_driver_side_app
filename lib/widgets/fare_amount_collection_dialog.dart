import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../global/global.dart';

class FareAmountCollectionDialog extends StatefulWidget {
  double? totalFareAmount;

  FareAmountCollectionDialog({this.totalFareAmount});

  @override
  State<FareAmountCollectionDialog> createState() => _FareAmountCollectionDialogState();
}

class _FareAmountCollectionDialogState extends State<FareAmountCollectionDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      backgroundColor: Colors.grey,
      child: Container(
        margin: const EdgeInsets.all(6),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Text(
              "Trip Fare Amount (${driverVehicleType!.toUpperCase()})",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                fontSize: 16.0,
              ),
            ),
            const SizedBox(height: 20),

            const Divider(thickness: 4, color: Colors.grey,),

            const SizedBox(height: 16),

            Text(widget.totalFareAmount.toString(),
                style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                fontSize: 50.0,
              ),
            ),

            const SizedBox(height: 10),

            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "This is the total fare amount. Please collect it from user.",
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.all(18.0),
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: (){
                    Future.delayed(const Duration(milliseconds: 2000),(){
                      SystemNavigator.pop();
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      //Icon(Icons.currency_rupee_sharp, color: Colors.white, size: 28,),
                      const Text("Collect Cash", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),),
                      Text("Rs. ${widget.totalFareAmount!}", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),),
                    ],
                  ),
              ),
            ),

            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
