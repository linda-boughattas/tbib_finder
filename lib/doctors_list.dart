import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:tbib_finder/widget/custom_button.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';

class DoctorsList extends StatefulWidget {
  final String selectedRegion;
  final String selectedCity;
  final String selectedSpecialization;
  final VoidCallback onClose;
  final Function(List<Map<String, dynamic>>) onDoctorsUpdated;

  const DoctorsList({
    super.key,
    required this.selectedRegion,
    required this.selectedCity,
    required this.selectedSpecialization,
    required this.onClose,
    required this.onDoctorsUpdated,
  });

  @override
  DoctorsListState createState() => DoctorsListState();
}

class DoctorCard extends StatelessWidget {
  final Map<String, dynamic> doctor;

  const DoctorCard({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  double imageSize = constraints.maxWidth * 0.4;

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      doctor["image"]!,
                      fit: BoxFit.cover,
                      width: imageSize,
                      height: imageSize,
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Text(
                      doctor["name"],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      doctor["specialty"],
                      style: const TextStyle(color: Colors.blue, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      doctor["adresseComplete"],
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.phone, size: 16, color: Colors.green),
                        const SizedBox(width: 5),
                        Text(
                          doctor["phone"],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DoctorsListState extends State<DoctorsList> {
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> doctors = [];
  List<Map<String, dynamic>> filteredDoctors = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchDoctors();
  }

  Future<void> fetchDoctors() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('doctors').get();

      List<Map<String, dynamic>> doctorsList =
          querySnapshot.docs.map((doc) {
            GeoPoint addressGeoPoint = doc["adresse"];
            double latitude = addressGeoPoint.latitude;
            double longitude = addressGeoPoint.longitude;
            return {
              "adresseComplete": doc["adresseComplete"] ?? "N/A",
              "city": doc["city"] ?? "All",
              "region": doc["region"] ?? "All",
              "name":
                  "Dr. ${doc["name"] ?? ""} ${doc["familyName"] ?? ""}".trim(),
              "image": doc["image"] ?? "https://via.placeholder.com/150",
              "phone": doc["phone"] ?? "N/A",
              "specialty": doc["specialty"] ?? "Unknown Specialty",
              "latitude": latitude,
              "longitude": longitude,
            };
          }).toList();

      setState(() {
        doctors = doctorsList;
        _applyFilters();
      });
    } catch (e) {
      setState(() {
        errorMessage = "Error loading doctors: $e";
      });
    }
  }

  void _applyFilters() {
    setState(() {
      filteredDoctors =
          doctors.where((doctor) {
            bool matchesRegion =
                widget.selectedRegion == "All" ||
                doctor["region"].contains(widget.selectedRegion);
            bool matchesCity =
                widget.selectedCity == "All" ||
                doctor["city"].contains(widget.selectedCity);
            bool matchesSpecialization =
                widget.selectedSpecialization == "All" ||
                doctor["specialty"] == widget.selectedSpecialization;

            return matchesRegion && matchesCity && matchesSpecialization;
          }).toList();

      widget.onDoctorsUpdated(filteredDoctors);
    });
  }

  void searchDoctor() {
    String query = searchController.text.trim().toLowerCase();

    setState(() {
      filteredDoctors =
          query.isEmpty
              ? doctors
              : doctors
                  .where(
                    (doctor) => doctor["name"].toLowerCase().contains(query),
                  )
                  .toList();
    });

    if (filteredDoctors.length == 1) {
      showDoctorDialog(filteredDoctors.first);
    }
  }

  void showDoctorDialog(Map<String, dynamic> doctor) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    doctor["image"],
                    fit: BoxFit.cover,
                    width: 150,
                    height: 150,
                    errorBuilder:
                        (context, error, stackTrace) => Image.asset(
                          "assets/profile.jpg",
                          fit: BoxFit.cover,
                          width: 200,
                          height: 200,
                        ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  doctor["name"],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                Text(
                  doctor["specialty"],
                  style: const TextStyle(fontSize: 18, color: Colors.blue),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                Text(
                  doctor["adresseComplete"],
                  style: const TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.phone, size: 20, color: Colors.green),
                    TextButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: doctor["phone"]));
                        Fluttertoast.showToast(
                          msg: "Number copied to clipboard",
                        );
                      },
                      child: Text(
                        doctor["phone"],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                CustomButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  text: 'Close',
                  widthFactor: 0.3,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child:
          filteredDoctors.isNotEmpty
              ? GestureDetector(
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity! > 50) {
                    widget.onClose();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: CarouselSlider(
                          options: CarouselOptions(
                            height: 300,
                            enlargeCenterPage: true,
                            autoPlay: false,
                            viewportFraction: 0.85,
                            aspectRatio: 16 / 9,
                          ),
                          items:
                              filteredDoctors.map((doctor) {
                                return GestureDetector(
                                  onTap: () => showDoctorDialog(doctor),
                                  child: DoctorCard(doctor: doctor),
                                );
                              }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : SingleChildScrollView(child: const SizedBox.shrink()),
    );
  }
}
