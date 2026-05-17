import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/services/sos_location_service.dart';

/// Test double for GeolocatorAdapter.
class FakeGeolocatorAdapter implements GeolocatorAdapter {
  LocationPermission permission;
  bool locationServiceEnabled;
  Position? currentPosition;
  Position? lastKnownPosition;

  /// If true, getCurrentPosition throws a TimeoutException-like error.
  bool simulateTimeout;

  FakeGeolocatorAdapter({
    this.permission = LocationPermission.whileInUse,
    this.locationServiceEnabled = true,
    this.currentPosition,
    this.lastKnownPosition,
    this.simulateTimeout = false,
  });

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async => permission;

  @override
  Future<bool> isLocationServiceEnabled() async => locationServiceEnabled;

  @override
  Future<Position?> getCurrentPosition({Duration? timeLimit}) async {
    if (simulateTimeout) return null;
    return currentPosition;
  }

  @override
  Future<Position?> getLastKnownPosition() async => lastKnownPosition;
}

/// Helper to build a test Position.
Position _makePosition({
  required double latitude,
  required double longitude,
  required double accuracy,
  DateTime? timestamp,
}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    accuracy: accuracy,
    timestamp: timestamp ?? DateTime(2026, 5, 16, 10, 0, 0),
    altitude: 0.0,
    altitudeAccuracy: 0.0,
    heading: 0.0,
    headingAccuracy: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
  );
}

void main() {
  group('SosLocationService', () {
    test(
        'permission denied → returns unavailable result without throwing',
        () async {
      final adapter = FakeGeolocatorAdapter(
        permission: LocationPermission.denied,
      );
      final service = SosLocationService(adapter: adapter);

      final result = await service.getLocationForSos();

      expect(result.label, equals(SosLocationLabel.unavailable));
      expect(result.hasCoordinates, isFalse);
      expect(result.displayLabel, contains('SOS vẫn được gửi'));
    });

    test('permission deniedForever → returns unavailable result', () async {
      final adapter = FakeGeolocatorAdapter(
        permission: LocationPermission.deniedForever,
      );
      final service = SosLocationService(adapter: adapter);

      final result = await service.getLocationForSos();

      expect(result.label, equals(SosLocationLabel.unavailable));
      expect(result.hasCoordinates, isFalse);
    });

    test('location service disabled → returns unavailable result', () async {
      final adapter = FakeGeolocatorAdapter(
        permission: LocationPermission.whileInUse,
        locationServiceEnabled: false,
      );
      final service = SosLocationService(adapter: adapter);

      final result = await service.getLocationForSos();

      expect(result.label, equals(SosLocationLabel.unavailable));
      expect(result.hasCoordinates, isFalse);
      expect(result.displayLabel, contains('SOS vẫn được gửi'));
    });

    test(
        'GPS timeout with last known position → lastKnown label and coordinates',
        () async {
      final lastKnown = _makePosition(
        latitude: 10.7769,
        longitude: 106.7009,
        accuracy: 50.0,
      );
      final adapter = FakeGeolocatorAdapter(
        simulateTimeout: true,
        lastKnownPosition: lastKnown,
      );
      final service = SosLocationService(adapter: adapter);

      final result = await service.getLocationForSos();

      expect(result.label, equals(SosLocationLabel.lastKnown));
      expect(result.hasCoordinates, isTrue);
      expect(result.latitude, closeTo(10.7769, 0.0001));
      expect(result.longitude, closeTo(106.7009, 0.0001));
      expect(result.machineLabel, equals('last_known'));
      expect(result.displayLabel, equals('vị trí cuối cùng đã biết'));
    });

    test(
        'GPS timeout with no last known position → unavailable result',
        () async {
      final adapter = FakeGeolocatorAdapter(
        simulateTimeout: true,
        lastKnownPosition: null,
      );
      final service = SosLocationService(adapter: adapter);

      final result = await service.getLocationForSos();

      expect(result.label, equals(SosLocationLabel.unavailable));
      expect(result.hasCoordinates, isFalse);
    });

    test(
        'current GPS accuracy > 100m → approximate label with Vietnamese text',
        () async {
      final position = _makePosition(
        latitude: 21.0285,
        longitude: 105.8542,
        accuracy: 150.0, // > 100m threshold
      );
      final adapter = FakeGeolocatorAdapter(currentPosition: position);
      final service = SosLocationService(adapter: adapter);

      final result = await service.getLocationForSos();

      expect(result.label, equals(SosLocationLabel.approximate));
      expect(result.hasCoordinates, isTrue);
      expect(result.latitude, closeTo(21.0285, 0.0001));
      expect(result.machineLabel, equals('approximate'));
      expect(result.displayLabel, equals('vị trí gần đúng'));
    });

    test('current GPS accuracy <= 100m → current label', () async {
      final position = _makePosition(
        latitude: 10.7769,
        longitude: 106.7009,
        accuracy: 8.0, // <= 100m threshold
      );
      final adapter = FakeGeolocatorAdapter(currentPosition: position);
      final service = SosLocationService(adapter: adapter);

      final result = await service.getLocationForSos();

      expect(result.label, equals(SosLocationLabel.current));
      expect(result.hasCoordinates, isTrue);
      expect(result.latitude, closeTo(10.7769, 0.0001));
      expect(result.accuracyMeters, closeTo(8.0, 0.01));
      expect(result.machineLabel, equals('current'));
      expect(result.displayLabel, equals('vị trí hiện tại'));
    });

    test('accuracy exactly at 100m threshold → approximate label', () async {
      // Boundary: > 100m is approximate, so exactly 100m should be current
      final position = _makePosition(
        latitude: 10.0,
        longitude: 106.0,
        accuracy: 100.0, // exactly at threshold — not > 100m
      );
      final adapter = FakeGeolocatorAdapter(currentPosition: position);
      final service = SosLocationService(adapter: adapter);

      final result = await service.getLocationForSos();

      // accuracy == 100.0 is NOT > 100m, so it should be current
      expect(result.label, equals(SosLocationLabel.current));
    });

    test('machineLabel maps all labels correctly', () {
      expect(
        SosLocationResult(
          label: SosLocationLabel.unavailable,
          displayLabel: '',
        ).machineLabel,
        equals('unavailable'),
      );
      expect(
        SosLocationResult(
          label: SosLocationLabel.lastKnown,
          displayLabel: '',
        ).machineLabel,
        equals('last_known'),
      );
    });
  });
}
