import 'dart:io';

import 'package:InvoiceMate/screens/output_screen.dart';
import 'package:flutter/material.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scanbot_sdk/common_data.dart' as common;
import 'package:scanbot_sdk/scanbot_sdk_models.dart';
import 'dart:convert';

import '../ui/preview_document_widget.dart';
import '../ui/progress_dialog.dart';

import 'package:scanbot_sdk/barcode_scanning_data.dart';

import 'package:scanbot_sdk/document_scan_data.dart';
import 'package:scanbot_sdk/ehic_scanning_data.dart';
import 'package:scanbot_sdk/mrz_scanning_data.dart';
import 'package:scanbot_sdk/scanbot_sdk.dart';

import 'package:scanbot_sdk/scanbot_sdk_ui.dart';

import '../pages_repository.dart';

import '../ui/utils.dart';

import 'package:image_picker/image_picker.dart';
import 'package:flutter_amazon_s3/flutter_amazon_s3.dart';

final Color backgroundColor = Color(0xFF1E1E2B);
const SCANBOT_SDK_LICENSE_KEY = "AHdQOyBlJKagsSm/YT9Lta9lqy3RTj" +
    "rLQfRAZr2k6H7++i128GSWxZlhJxBS" +
    "/ENg+jXCOOm2HxLFvENuXGGcv6NwSG" +
    "lJF88V1UztLjAEwPow4Bz4GraehHnY" +
    "ejCvUhx4HI68GpiLyyaO23t2O3mcdQ" +
    "akQC0vJLsw10nogwUyR5TaCVkNNC/+" +
    "/YIescWLihxyI3vswZSGdoPw7M+CPj" +
    "umvHyHWCO23jggPeI0O0BgskVRa/0i" +
    "9JET+otc9tRhx9NNPVa7xlnDyYNrcb" +
    "5ZiaARQRIXDZr/gxKOee7HMeVI8BD4" +
    "nYb9lUb5raXFhhTj6T4T94R4I5Thwv" +
    "56oa/vp8NBvw==\nU2NhbmJvdFNESw" +
    "ppby5zY2FuYm90LmV4YW1wbGUuc2Rr" +
    "LmZsdXR0ZXIKMTU4NjIxNzU5OQoxMD" +
    "cxMDIKMw==\n";

initScanbotSdk() async {
  // Consider adjusting this optional storageBaseDirectory - see the comments below.
  var customStorageBaseDirectory = await storageBaseDirectory();

  var config = ScanbotSdkConfig(
    loggingEnabled:
        true, // Consider switching logging OFF in production builds for security and performance reasons.
    licenseKey: SCANBOT_SDK_LICENSE_KEY,
    imageFormat: common.ImageFormat.JPG,
    imageQuality: 80,
    storageBaseDirectory: customStorageBaseDirectory,
  );

  try {
    await ScanbotSdk.initScanbotSdk(config);
  } catch (e) {
    print(e);
  }
}

Future<String> storageBaseDirectory() async {
  // !! Please note !!
  // It is strongly recommended to use the default (secure) storage location of the Scanbot SDK.
  // However, for demo purposes we overwrite the "storageBaseDirectory" of the Scanbot SDK by a custom storage directory.
  //
  // On Android we use the "ExternalStorageDirectory" which is a public(!) folder.
  // All image files and export files (PDF, TIFF, etc) created by the Scanbot SDK in this demo app will be stored
  // in this public storage directory and will be accessible for every(!) app having external storage permissions!
  // Again, this is only for demo purposes, which allows us to easily fetch and check the generated files
  // via Android "adb" CLI tools, Android File Transfer app, Android Studio, etc.
  //
  // On iOS we use the "ApplicationDocumentsDirectory" which is accessible via iTunes file sharing.
  //
  // For more details about the storage system of the Scanbot SDK Flutter Plugin please see our docs:
  // - https://scanbotsdk.github.io/documentation/flutter/
  //
  // For more details about the file system on Android and iOS we also recommend to check out:
  // - https://developer.android.com/guide/topics/data/data-storage
  // - https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileSystemOverview/FileSystemOverview.html

  Directory storageDirectory;
  if (Platform.isAndroid) {
    storageDirectory = await getExternalStorageDirectory();
  } else if (Platform.isIOS) {
    storageDirectory = await getApplicationDocumentsDirectory();
  } else {
    throw ("Unsupported platform");
  }
  print("/storage/emulated/0/InvoiceMate");
  return "${storageDirectory.path}/InvoiceMate";
}

class MenuDashboardPage extends StatefulWidget {
  @override
  _MenuDashboardPageState createState() {
    initScanbotSdk();
    return _MenuDashboardPageState();
  }
}

class _MenuDashboardPageState extends State<MenuDashboardPage>
    with SingleTickerProviderStateMixin {
  PageRepository _pageRepository = PageRepository();

  bool isCollapsed = true;
  double screenWidth, screenHeight;
  final Duration duration = const Duration(milliseconds: 300);
  AnimationController _controller;
  Animation<double> _scaleAnimation;
  Animation<double> _menuScaleAnimation;
  Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: duration);
    _scaleAnimation = Tween<double>(begin: 1, end: 0.8).animate(_controller);
    _menuScaleAnimation =
        Tween<double>(begin: 0.5, end: 1).animate(_controller);
    _slideAnimation = Tween<Offset>(begin: Offset(-1, 0), end: Offset(0, 0))
        .animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    screenHeight = size.height;
    screenWidth = size.width;
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: <Widget>[
          menu(context),
          dashboard(context),
        ],
      ),
    );
  }

  Widget menu(context) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _menuScaleAnimation,
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text("Scannner",
                    style: TextStyle(color: Colors.white, fontSize: 22)),
                SizedBox(height: 10),
                FlatButton(
                  onPressed: () {
                    gotoImagesView();
                  },
                  child: Text("History",
                      style: TextStyle(color: Colors.white, fontSize: 22)),
                ),
                SizedBox(height: 10),
                FlatButton(
                  onPressed: () {
                    uploadimage();
                  },
                  child: Text("Upload",
                      style: TextStyle(color: Colors.white, fontSize: 22)),
                ),
                SizedBox(height: 10),
                FlatButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => OutputScreen()),
                    );
                  },
                  child: Text("Output",
                      style: TextStyle(color: Colors.white, fontSize: 22)),
                ),
                SizedBox(height: 10),
                FlatButton(
                  onPressed: () {
                    getOcrConfigs();
                  },
                  child: Text("Settings",
                      style: TextStyle(color: Colors.white, fontSize: 22)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget dashboard(context) {
    return AnimatedPositioned(
      duration: duration,
      top: 0,
      bottom: 0,
      left: isCollapsed ? 0 : 0.6 * screenWidth,
      right: isCollapsed ? 0 : -0.2 * screenWidth,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Material(
          animationDuration: duration,
          borderRadius: BorderRadius.all(Radius.circular(40)),
          elevation: 8,
          color: backgroundColor,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            physics: ClampingScrollPhysics(),
            child: Container(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        child: InkWell(
                          child: Icon(Icons.menu, color: Colors.white),
                          onTap: () {
                            setState(() {
                              if (isCollapsed)
                                _controller.forward();
                              else
                                _controller.reverse();

                              isCollapsed = !isCollapsed;
                            });
                          },
                        ),
                      ),
                      Text("InvoiceMate",
                          style: TextStyle(fontSize: 24, color: Colors.white)),
                      Icon(Icons.refresh, color: Colors.white),
                    ],
                  ),
                  SizedBox(height: 50),
                  Center(
                      child: Container(
                    height: 200,
                    width: 400,
                    child: ClipRect(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0),
                        ),
                      ),
                    ),
                    decoration: BoxDecoration(
                      image: DecorationImage(
                          image: AssetImage(
                              "assets/images/undraw_file_searching_duff.png"),
                          fit: BoxFit.cover),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  )),
                  SizedBox(
                    height: 30,
                  ),
                  Center(
                    child: Text(
                      "Welcome",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          Container(
                            child: Column(
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(right: 14),
                                  child: IconButton(
                                    onPressed: () {
                                      print("scanned");
                                      startDocumentScanning();
                                    },
                                    icon: Icon(
                                      Icons.scanner,
                                      size: 45,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Text("Scan")
                              ],
                            ),
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(210, 210, 210, 1),
                              borderRadius: new BorderRadius.all(
                                Radius.circular(20.0),
                              ),
                            ),
                            // color: Color.fromRGBO(35, 37, 40, 1),
                            height: 90,
                            width: 90,
                          ),
                          Container(
                            child: Column(
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(right: 14),
                                  child: IconButton(
                                    onPressed: () {
                                      print("selected");
                                      importImage();
                                    },
                                    icon: Icon(
                                      Icons.photo_album,
                                      size: 45,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Text("Choose")
                              ],
                            ),
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(210, 210, 210, 1),
                              borderRadius: new BorderRadius.all(
                                Radius.circular(20.0),
                              ),
                            ),
                            // color: Color.fromRGBO(35, 37, 40, 1),
                            height: 90,
                            width: 90,
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 50,
                      ), // Row 2 starts here
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          Container(
                            child: Column(
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(right: 14),
                                  child: IconButton(
                                    onPressed: () {
                                      startQRScanner();
                                      print("QR");
                                    },
                                    icon: FaIcon(FontAwesomeIcons.qrcode,
                                        size: 45),
                                  ),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Text("QR")
                              ],
                            ),
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(210, 210, 210, 1),
                              borderRadius: new BorderRadius.all(
                                Radius.circular(20.0),
                              ),
                            ),
                            // color: Color.fromRGBO(35, 37, 40, 1),
                            height: 90,
                            width: 90,
                          ),
                          Container(
                            child: Column(
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(right: 14),
                                  child: IconButton(
                                    onPressed: () {
                                      startBarcodeScanner();
                                      print("Barcode");
                                    },
                                    icon: FaIcon(FontAwesomeIcons.barcode,
                                        size: 45),
                                  ),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Text("Barcode")
                              ],
                            ),
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(210, 210, 210, 1),
                              borderRadius: new BorderRadius.all(
                                Radius.circular(20.0),
                              ),
                            ),
                            // color: Color.fromRGBO(35, 37, 40, 1),
                            height: 90,
                            width: 90,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  getLicenseStatus() async {
    try {
      var result = await ScanbotSdk.getLicenseStatus();
      showAlertDialog(context, jsonEncode(result), title: "License Status");
    } catch (e) {
      print(e);
      showAlertDialog(context, "Error getting OCR configs");
    }
  }

  getOcrConfigs() async {
    try {
      var result = await ScanbotSdk.getOcrConfigs();
      showAlertDialog(context, jsonEncode(result), title: "OCR Configs");
    } catch (e) {
      print(e);
      showAlertDialog(context, "Error getting license status");
    }
  }

  importImage() async {
    try {
      var image = await ImagePicker.pickImage(source: ImageSource.gallery);
      await createPage(image.uri);
      gotoImagesView();
    } catch (e) {
      print(e);
    }
  }

  uploadimage() async {
    try {
      var image = await ImagePicker.pickImage(source: ImageSource.gallery);
      await createPage(image.uri);
      print(image.path);
      //String imgname = image.path.split('/').last;
      String uploadedImageUrl = await FlutterAmazonS3.uploadImage(
          image.path,
          'invoice-storage-unifyed',
          'us-east-2:62f728ad-9d8a-4328-af78-ae9f4b159dd6',
          'us-east-2');
    } catch (e) {
      print(e);
    }
  }

  createPage(Uri uri) async {
    if (!await checkLicenseStatus(context)) {
      return;
    }

    var dialog = ProgressDialog(context,
        type: ProgressDialogType.Normal, isDismissible: false);
    dialog.style(message: "Processing");
    dialog.show();
    try {
      var page = await ScanbotSdk.createPage(uri, false);
      page = await ScanbotSdk.detectDocument(page);
      this._pageRepository.addPage(page);
    } catch (e) {
      print(e);
    } finally {
      dialog.hide();
    }
  }

  startDocumentScanning() async {
    if (!await checkLicenseStatus(context)) {
      return;
    }

    DocumentScanningResult result;
    try {
      var config = DocumentScannerConfiguration(
        bottomBarBackgroundColor: Colors.blue,
        ignoreBadAspectRatio: true,
        multiPageEnabled: true,
        //maxNumberOfPages: 3,
        //flashEnabled: true,
        //autoSnappingSensitivity: 0.7,
        cameraPreviewMode: common.CameraPreviewMode.FIT_IN,
        orientationLockMode: common.CameraOrientationMode.PORTRAIT,
        //documentImageSizeLimit: Size(2000, 3000),
        cancelButtonTitle: "Cancel",
        pageCounterButtonTitle: "%d Page(s)",
        textHintOK: "Perfect, don't move...",
        //textHintNothingDetected: "Nothing",
        // ...
      );
      result = await ScanbotSdkUi.startDocumentScanner(config);
    } catch (e) {
      print(e);
    }
    if (result?.operationResult != common.OperationResult.ERROR) {
      _pageRepository.addPages(result.pages);
      gotoImagesView();
    }
  }

  startBarcodeScanner() async {
    if (!await checkLicenseStatus(context)) {
      return;
    }

    try {
      var config = BarcodeScannerConfiguration(
        topBarBackgroundColor: Colors.blue,
        finderTextHint:
            "Please align any supported barcode in the frame to scan it.",
        // ...
      );
      var result = await ScanbotSdkUi.startBarcodeScanner(config);
      _showBarcodeScanningResult(result);
    } catch (e) {
      print(e);
    }
  }

  startQRScanner() async {
    if (!await checkLicenseStatus(context)) {
      return;
    }

    try {
      var config = BarcodeScannerConfiguration(
        barcodeFormats: [BarcodeFormat.QR_CODE],
        finderTextHint: "Please align a QR code in the frame to scan it.",
        // ...
      );
      var result = await ScanbotSdkUi.startBarcodeScanner(config);
      _showBarcodeScanningResult(result);
    } catch (e) {
      print(e);
    }
  }

  _showBarcodeScanningResult(final BarcodeScanningResult result) {
    if (result?.operationResult != common.OperationResult.ERROR) {
      showAlertDialog(
          context,
          "Format: " +
              result.barcodeFormat.toString() +
              "\nValue: " +
              result.text,
          title: "Barcode Result:");
    }
  }

  startEhicScanner() async {
    if (!await checkLicenseStatus(context)) {
      return;
    }

    HealthInsuranceCardRecognitionResult result;
    try {
      var config = HealthInsuranceScannerConfiguration(
        topBarBackgroundColor: Colors.blue,
        topBarButtonsColor: Colors.white70,
        // ...
      );
      result = await ScanbotSdkUi.startEhicScanner(config);
    } catch (e) {
      print(e);
    }

    if (result?.fields != null) {
      var concatenate = StringBuffer();
      result.fields
          .map((field) =>
              "${field.type.toString().replaceAll("HealthInsuranceCardFieldType.", "")}:${field.value}\n")
          .forEach((s) {
        concatenate.write(s);
      });
      showAlertDialog(context, concatenate.toString());
    }
  }

  startMRZScanner() async {
    if (!await checkLicenseStatus(context)) {
      return;
    }

    MrzScanningResult result;
    try {
      var config = MrzScannerConfiguration(
        topBarBackgroundColor: Colors.blue,
        // ...
      );
      result = await ScanbotSdkUi.startMrzScanner(config);
    } catch (e) {
      print(e);
    }

    if (result?.operationResult != common.OperationResult.ERROR) {
      var concatenate = StringBuffer();
      result.fields
          .map((field) =>
              "${field.name.toString().replaceAll("MRZFieldName.", "")}:${field.value}\n")
          .forEach((s) {
        concatenate.write(s);
      });
      showAlertDialog(context, concatenate.toString());
    }
  }

  gotoImagesView() async {
    imageCache.clear();
    return await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => DocumentPreview(_pageRepository)),
    );
  }
}
