import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real-time Geolocation PWA',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const GeolocationPage(),
    );
  }
}

class GeolocationPage extends StatefulWidget {
  const GeolocationPage({super.key});

  @override
  _GeolocationPageState createState() => _GeolocationPageState();
}

class _GeolocationPageState extends State<GeolocationPage> {
  StreamSubscription<Position>? _positionStream;
  final List<LatLng> _userLocations = [];
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  Marker? _userMarker; // Marker for the user's current location
  Marker? _tapMarker; // Marker for the tapped location
  Polyline _route = const Polyline(
      polylineId: PolylineId('route'), points: []); // Initialize _route

  @override
  void initState() {
    super.initState();
    _requestLocationPermissionAndTrack();
    _route = const Polyline(polylineId: PolylineId('route'), points: []);
    _tapMarker = null;
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _requestLocationPermissionAndTrack() async {
    final locationPermission = await Geolocator.requestPermission();
    if (locationPermission == LocationPermission.denied) {
      // Handle denied permission
      print('Location permission denied.');
    } else if (locationPermission == LocationPermission.deniedForever) {
      // Handle denied permission permanently
      print('Location permission denied permanently.');
    } else {
      // Permission granted, start tracking location
      _startTrackingLocation();
    }
  }

  Future<void> _startTrackingLocation() async {
    if (await Geolocator.isLocationServiceEnabled()) {
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).listen((Position position) {
        setState(() {
          _userLocations.add(LatLng(position.latitude, position.longitude));
          _updateUserMarker(LatLng(position.latitude,
              position.longitude)); // Update user's marker on the map
        });
      });
    } else {
      // Handle case where location services are not enabled
      print('Location services are not enabled.');
    }
  }

  void _updateUserMarker(LatLng userPosition) {
    setState(() {
      _userMarker = Marker(
        markerId: const MarkerId('user_marker'),
        position: userPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor
            .hueAzure), // Custom icon for user's marker (optional)
        infoWindow: const InfoWindow(title: 'You are here'),
      );
    });
  }

  Set<Marker> _createMarkers() {
    Set<Marker> markers = _userLocations.map((location) {
      return Marker(
        markerId: MarkerId(location.toString()),
        position: location,
      );
    }).toSet();

    // Add user's marker to the set of markers
    if (_userMarker != null) {
      markers.add(_userMarker!);
    }

    // Add tapped marker to the set of markers
    if (_tapMarker != null) {
      markers.add(_tapMarker!);
    }

    return markers;
  }

  void _onMapTapped(LatLng latLng) async {
    // Remove previous route and marker
    setState(() {
      _route = const Polyline(polylineId: const PolylineId('route'), points: []);
      _tapMarker = Marker(
        markerId: const MarkerId('tap_marker'),
        position: latLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor
            .hueGreen), // Custom icon for tapped marker (optional)
      );
    });

    // Check if there are enough locations to calculate route
    if (_userLocations.isNotEmpty) {
      // Calculate and display route
      List<LatLng> routePoints = await _getRoutePoints(latLng);
      setState(() {
        _route = Polyline(
          polylineId: const PolylineId('route'),
          points: routePoints,
          color: Colors.blue,
          width: 4,
        );
      });
    }
  }

  Future<List<LatLng>> _getRoutePoints(LatLng destination) async {
    String apiKey = 'AIzaSyA1nK41GjHw1VHxIXZysVSrHntSX1hvHUQ';
    String apiUrl =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${_userLocations.last.latitude},${_userLocations.last.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          List<LatLng> routePoints = [];
          List<dynamic> steps = data['routes'][0]['legs'][0]['steps'];
          for (int i = 0; i < steps.length; i++) {
            double startLat = steps[i]['start_location']['lat'];
            double startLng = steps[i]['start_location']['lng'];
            double endLat = steps[i]['end_location']['lat'];
            double endLng = steps[i]['end_location']['lng'];
            routePoints.add(LatLng(startLat, startLng));
            routePoints.add(LatLng(endLat, endLng));
          }
          return routePoints;
        } else {
          print('Failed to fetch route. Status: ${data['status']}');
        }
      } else {
        print('Failed to fetch route. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching route: $e');
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-time Geolocation PWA'),
      ),
      body: _userLocations.isNotEmpty
          ? GoogleMap(
              mapType: MapType.hybrid,
              initialCameraPosition: CameraPosition(
                target: _userLocations.last,
                zoom: 15,
              ),
              markers: _createMarkers(),
              polylines: {if (_route.points.isNotEmpty) _route},
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              onTap:
                  _onMapTapped, // Call _onMapTapped when user taps on the map
            )
          : const Center(
              child: Text('No location updates'),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Implement point selection and route calculation here
          // This could involve showing a dialog for point selection and making API calls for route calculation
        },
        child: const Icon(Icons.directions),
      ),
    );
  }
}
