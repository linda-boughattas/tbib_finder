import 'package:flutter/material.dart';
import 'package:tbib_finder/widget/custom_button.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';
import 'package:logger/logger.dart';
import '../doctors_list.dart';
import '../dropdown_data.dart';
import '../widget/custom_marker.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  LatLng? _currentLocation;
  final loc.Location location = loc.Location();
  final logger = Logger();
  bool showDoctorsList = false;
  Set<Marker> userMarker = {};
  Set<Marker> doctorsMarker = {};
  Set<Circle> circles = {};
  Set<Polyline> polylines = {};
  List<Map<String, dynamic>> currentFilteredDoctors = [];

  String selectedRegion = "All";
  String selectedCity = "All";
  String selectedSpecialization = "All";

  @override
  void initState() {
    super.initState();
    _requestAndSetLocation();
  }

  Future<void> _requestAndSetLocation() async {
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;
    loc.LocationData locationData;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        logger.e("Location services are disabled.");
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) {
        logger.e("Location permission denied.");
        return;
      }
    }

    locationData = await location.getLocation();

    if (!mounted) return;

    if (locationData.latitude == null || locationData.longitude == null) {
      logger.e("Failed to get location data.");
      return;
    }

    List<Placemark> placemarks = await placemarkFromCoordinates(
      locationData.latitude!,
      locationData.longitude!,
    );

    if (placemarks.isNotEmpty) {
      Placemark place = placemarks.first;
      String region = place.administrativeArea ?? "Ariana";
      String city = place.locality ?? "Borj Baccouche";

      if (!regions.contains(region)) {
        region = "Ariana";
      }
      if (!cities.containsKey(region) || !cities[region]!.contains(city)) {
        city = cities[region]!.first;
      }

      setState(() {
        _currentLocation = LatLng(
          locationData.latitude!,
          locationData.longitude!,
        );
        selectedRegion = region;
        selectedCity = city;
      });
    }

    if (_currentLocation != null) {
      mapController.animateCamera(CameraUpdate.newLatLng(_currentLocation!));
    }
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    if (_currentLocation == null) return;
    mapController = controller;

    Marker customMarker = await CustomMarker.createCustomMarker(
      position: _currentLocation!,
      markerId: 'current_location',
    );

    CustomMarker.addAccuracyCircle(circles, _currentLocation!, 1000.0);

    setState(() {
      userMarker.add(customMarker);
    });

    mapController.animateCamera(CameraUpdate.newLatLng(_currentLocation!));
  }

  void _updateDoctorMarkers(List<Map<String, dynamic>> filteredDoctors) async {
    currentFilteredDoctors = filteredDoctors;
    Set<Marker> newMarkers = {};

    for (var doctor in filteredDoctors) {
      final marker = await CustomMarker.createCustomMarker(
        position: LatLng(doctor["latitude"], doctor["longitude"]),
        markerId: doctor["name"],
        isRed: true,
      );
      newMarkers.add(marker);
    }

    setState(() {
      doctorsMarker = newMarkers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: Drawer(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0, top: 20.0),
                  child: Text(
                    'Filter Doctors',
                    style: TextStyle(color: Colors.black, fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                ),
                _buildDropdown("Select Region", regions, selectedRegion, (
                  newValue,
                ) {
                  setState(() {
                    selectedRegion = newValue!;
                    selectedCity = cities[selectedRegion]!.first;
                  });
                }),
                _buildDropdown(
                  "Select City",
                  cities[selectedRegion]!,
                  selectedCity,
                  (newValue) {
                    setState(() {
                      selectedCity = newValue!;
                    });
                  },
                ),
                _buildDropdown(
                  "Specialization",
                  specializations,
                  selectedSpecialization,
                  (newValue) {
                    setState(() {
                      selectedSpecialization = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        onPressed: () {
                          setState(() {
                            showDoctorsList = true;
                          });

                          if (currentFilteredDoctors.isNotEmpty) {
                            _updateDoctorMarkers(currentFilteredDoctors);
                          }
                        },
                        text: 'Apply',
                        widthFactor: 1.0,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomButton(
                        onPressed: () {
                          setState(() {
                            showDoctorsList = false;
                            doctorsMarker = {};
                            currentFilteredDoctors = [];
                          });
                        },
                        text: 'Clear',
                        backgroundColor: Colors.red,
                        widthFactor: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Container(
          height: 44,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              Builder(
                builder: (context) {
                  return IconButton(
                    icon: const Icon(Icons.menu, color: Colors.black),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  );
                },
              ),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search for doctors...',
                    hintStyle: const TextStyle(color: Colors.black54),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search, color: Colors.black),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
      body:
          _currentLocation == null
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                children: [
                  GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: _currentLocation!,
                      zoom: 14.0,
                    ),
                    markers: {...userMarker, ...doctorsMarker},
                    circles: circles,
                  ),
                  if (showDoctorsList)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: DoctorsList(
                        selectedRegion: selectedRegion,
                        selectedCity: selectedCity,
                        selectedSpecialization: selectedSpecialization,
                        onClose: () {
                          setState(() {
                            showDoctorsList = false;
                          });
                        },
                        onDoctorsUpdated: _updateDoctorMarkers,
                      ),
                    ),
                ],
              ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String selectedItem,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          DropdownButtonFormField<String>(
            value: selectedItem,
            items:
                items.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
            onChanged: onChanged,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            ),
            menuMaxHeight: 200,
          ),
        ],
      ),
    );
  }
}
