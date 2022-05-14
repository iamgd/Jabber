import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class Map extends StatefulWidget {
  final channelId;
  Map(this.channelId);

  @override
  State<Map> createState() => _MapState();
}

class _MapState extends State<Map> {
  @override
  void dispose() {
    super.dispose();
  }

  Future _getCurrentUserLocation() async {
    try {
      final locData = await Location().getLocation();
      await FirebaseFirestore.instance
          .collection("messages")
          .doc(widget.channelId)
          .collection('channelMembers')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .update({
        'lat': locData.latitude,
        'lon': locData.longitude,
      });

      await FirebaseFirestore.instance
          .collection("messages")
          .doc(widget.channelId)
          .collection('channelMembers')
          .get()
          .then((items) {
        for (var item in items.docs) {
          addMarker({
            'lat': item['lat'],
            'lon': item['lon'],
            'name': item['userName'],
            'uid': item['userId'],
          });
        }
      });

      return locData;
    } catch (e) {
      return;
    }
  }

  List<Marker> markerss = [];
  addMarker(mapData) {
    if (mapData == null) {
      return;
    }
    var latitude = mapData["lat"] is String
        ? double.parse(mapData["lat"])
        : mapData["lat"];
    var longitude = mapData["lon"] is String
        ? double.parse(mapData["lon"])
        : mapData["lon"];

    Marker markerFormat = Marker(
      markerId: MarkerId('${mapData["uid"]}'),
      position: LatLng(latitude, longitude),
      infoWindow: InfoWindow(title: '${mapData["name"]}', onTap: () async {}),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueRed,
      ),
    );
    markerss.add(markerFormat);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder(
            future: _getCurrentUserLocation(),
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              } else if (snapshot.hasData) {
                return GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target:
                        LatLng(snapshot.data.latitude, snapshot.data.longitude),
                    zoom: 6,
                  ),
                  markers: markerss.map((e) => e).toSet(),
                );
              } else {
                return Center(
                  child:
                      Text('Allow location permission for better performance.'),
                );
              }
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: Color(0xC9000000),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        Get.back();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.close_rounded,
                          size: 35,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
