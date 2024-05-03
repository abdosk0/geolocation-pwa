import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
