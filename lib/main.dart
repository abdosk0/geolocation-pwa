import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real-time Geolocation PWA',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GeolocationPage(),
    );
  }
}

class GeolocationPage extends StatefulWidget {
  @override
  _GeolocationPageState createState() => _GeolocationPageState();
}

class _GeolocationPageState extends State<GeolocationPage> {
  StreamSubscription<Position>? _positionStream;
  List<LatLng> _userLocations = [];
  Completer<GoogleMapController> _controller = Completer();

  @override
  void initState() {
    super.initState();
    _requestLocationPermissionAndTrack();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }
Future<void> _requestLocationPermissionAndTrack() async {
  // Check if permission is already granted
  if (await Permission.location.isGranted) {
    // Permission is already granted, start tracking location
    _startTrackingLocation();
  } else {
    // Permission is not granted, request permission
    final status = await Permission.location.request();
    if (status == PermissionStatus.granted) {
      // Permission granted, start tracking location
      _startTrackingLocation();
    } else {
      // Handle denied permission
      print('Location permission denied.');
    }
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
        });
      });
    } else {
      // Handle case where location services are not enabled
      print('Location services are not enabled.');
    }
  }

  Set<Marker> _createMarkers() {
    return _userLocations.map((location) {
      return Marker(
        markerId: MarkerId(location.toString()),
        position: location,
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Real-time Geolocation PWA'),
      ),
      body: _userLocations.isNotEmpty
          ? GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _userLocations.last,
                zoom: 15,
              ),
              markers: _createMarkers(),
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
            )
          : Center(
              child: Text('No location updates'),
            ),
    );
  }
}
