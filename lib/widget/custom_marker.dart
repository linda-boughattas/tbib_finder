import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image/image.dart' as img;

class CustomMarker {
  static Future<Marker> createCustomMarker({
    required LatLng position,
    required String markerId,
    bool isRed = false,
  }) async {
    final Uint8List markerIcon = await _loadCustomMarkerImage(isRed);

    return Marker(
      markerId: MarkerId(markerId),
      position: position,
      icon: BitmapDescriptor.fromBytes(markerIcon),
    );
  }

  static Future<Uint8List> _loadCustomMarkerImage(bool isRed) async {
    final String assetPath =
        isRed ? 'assets/images/RedMarker.png' : 'assets/images/BlueMarker.png';
    final ByteData data = await rootBundle.load(assetPath);
    final Uint8List bytes = data.buffer.asUint8List();

    img.Image? image = img.decodeImage(Uint8List.fromList(bytes));
    if (image != null) {
      img.Image resizedImage = img.copyResize(image, width: 100, height: 100);
      return Uint8List.fromList(img.encodePng(resizedImage));
    } else {
      throw Exception('Failed to decode the image.');
    }
  }

  static void addAccuracyCircle(
    Set<Circle> circles,
    LatLng position,
    double radius,
  ) {
    circles.add(
      Circle(
        circleId: const CircleId("accuracy_circle"),
        center: position,
        radius: radius,
        fillColor: Colors.lightBlue.withAlpha((0.3 * 255).toInt()),
        strokeColor: Colors.blue,
        strokeWidth: 2,
      ),
    );
  }
}
