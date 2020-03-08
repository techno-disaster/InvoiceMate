import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

String url =
    "https://invoice-storage-unifyed.s3.us-east-2.amazonaws.com/output.json";

class OutputScreen extends StatefulWidget {
  @override
  _OutputScreenState createState() => _OutputScreenState();
}

String date;
String org;
String location;
String items;
String bill;
String invoice;

class _OutputScreenState extends State<OutputScreen> {
  @override
  void initState() {
    super.initState();
    getoutput();
  }

  getoutput() async {
    var response = await http.get(Uri.encodeFull(url));
    var data = json.decode(response.body);
    print(data["date"].length);

    location = data["locations"].toString();
    date = data["date"].toString();
    org = data["organization"];
    items = (data["other_orgs"] + data["commercial_items"]).toString();
    bill = data["bill_amount"].toString();
    invoice = data["invoice"].toString();
    print(response.statusCode);
    if (response.statusCode == 200) {
      setState(() {
        date = date;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white, //change your color here
        ),
        backgroundColor: Color(0xFF1E1E2B),
        title: const Text(
          "Output",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: Container(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text("Date: " + date),
              Text("Organization: " + org),
              Text("Location: " + location),
              Text("Items: " + items),
              Text("Bill Amount: " + bill),
              Text("Invoice Number: " + invoice)
            ],
          ),
        ),
      ),
    );
  }
}
