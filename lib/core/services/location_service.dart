import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationService {
  // Check location permissions
  Future<bool> checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      bool hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  // Get location from coordinates
  Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.locality}, ${place.administrativeArea}';
      }
      return 'Unknown location';
    } catch (e) {
      print('Error getting address from coordinates: $e');
      return 'Unknown location';
    }
  }

  // Get coordinates from address
  Future<Position?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return Position(
          latitude: locations.first.latitude,
          longitude: locations.first.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }
      return null;
    } catch (e) {
      print('Error getting coordinates from address: $e');
      return null;
    }
  }

  // Convert Position to GeoPoint
  GeoPoint positionToGeoPoint(Position position) {
    return GeoPoint(position.latitude, position.longitude);
  }

  // Calculate distance between two points
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // Calculate distance in kilometers
  double calculateDistanceInKm(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  // Format distance for display
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      double distanceInKm = distanceInMeters / 1000;
      return '${distanceInKm.toStringAsFixed(1)} km';
    }
  }

  // Get location permission status
  Future<LocationPermission> getLocationPermissionStatus() async {
    return await Geolocator.checkPermission();
  }

  // Request location permission
  Future<LocationPermission> requestLocationPermission() async {
    return await Geolocator.requestPermission();
  }

  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Get last known position
  Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      print('Error getting last known position: $e');
      return null;
    }
  }

  // Get location updates stream
  Stream<Position> getLocationUpdates({
    LocationAccuracy desiredAccuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: desiredAccuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }

  // Validate coordinates
  bool isValidCoordinates(double latitude, double longitude) {
    return latitude >= -90 && latitude <= 90 && 
           longitude >= -180 && longitude <= 180;
  }

  // Get approximate location (city level)
  Future<String> getApproximateLocation(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        if (place.locality != null && place.locality!.isNotEmpty) {
          return place.locality!;
        } else if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          return place.administrativeArea!;
        } else if (place.country != null && place.country!.isNotEmpty) {
          return place.country!;
        }
      }
      return 'Unknown location';
    } catch (e) {
      print('Error getting approximate location: $e');
      return 'Unknown location';
    }
  }

  // Get detailed address components
  Future<Map<String, String>> getAddressComponents(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return {
          'street': place.street ?? '',
          'locality': place.locality ?? '',
          'administrativeArea': place.administrativeArea ?? '',
          'country': place.country ?? '',
          'postalCode': place.postalCode ?? '',
          'subLocality': place.subLocality ?? '',
        };
      }
      return {};
    } catch (e) {
      print('Error getting address components: $e');
      return {};
    }
  }
} 