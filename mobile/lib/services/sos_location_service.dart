import 'package:geolocator/geolocator.dart';

enum SosLocationLabel { current, approximate, lastKnown, unavailable }

class SosLocationResult {
  final SosLocationLabel label;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final DateTime? capturedAt;

  /// Vietnamese copy for UI display
  final String displayLabel;

  SosLocationResult({
    required this.label,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.capturedAt,
    required this.displayLabel,
  });

  /// Machine-readable label for API submission
  String get machineLabel => switch (label) {
        SosLocationLabel.current => 'current',
        SosLocationLabel.approximate => 'approximate',
        SosLocationLabel.lastKnown => 'last_known',
        SosLocationLabel.unavailable => 'unavailable',
      };

  bool get hasCoordinates => latitude != null && longitude != null;
}

/// Seam for testing — abstracts geolocator static calls.
abstract class GeolocatorAdapter {
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Future<bool> isLocationServiceEnabled();
  Future<Position?> getCurrentPosition({Duration? timeLimit});
  Future<Position?> getLastKnownPosition();
}

/// Production adapter delegates to the real Geolocator plugin.
class RealGeolocatorAdapter implements GeolocatorAdapter {
  @override
  Future<LocationPermission> checkPermission() =>
      Geolocator.checkPermission();

  @override
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  @override
  Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  @override
  Future<Position?> getCurrentPosition({Duration? timeLimit}) =>
      Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeLimit ?? const Duration(seconds: 5),
        ),
      ).then((p) => p).catchError((_) => null);

  @override
  Future<Position?> getLastKnownPosition() =>
      Geolocator.getLastKnownPosition();
}

/// Retrieves device GPS location within a 5-second budget for SOS use.
///
/// Design decisions:
/// - Permission denial returns [SosLocationLabel.unavailable] — never throws.
///   SOS should always send even without location.
/// - GPS timeout falls back to last known position, then unavailable.
/// - Accuracy > 100m is labelled [SosLocationLabel.approximate].
/// - All display strings are in Vietnamese.
class SosLocationService {
  static const double _approximateAccuracyThresholdMeters = 100.0;
  static const Duration _gpsBudget = Duration(seconds: 5);

  final GeolocatorAdapter _adapter;

  SosLocationService({GeolocatorAdapter? adapter})
      : _adapter = adapter ?? RealGeolocatorAdapter();

  /// Get the best available location for an SOS alert.
  ///
  /// Never throws — returns [SosLocationLabel.unavailable] on any failure.
  Future<SosLocationResult> getLocationForSos() async {
    // Check / request permission
    var permission = await _adapter.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _adapter.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return SosLocationResult(
        label: SosLocationLabel.unavailable,
        displayLabel: 'Không có vị trí — SOS vẫn được gửi',
      );
    }

    final serviceEnabled = await _adapter.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return SosLocationResult(
        label: SosLocationLabel.unavailable,
        displayLabel: 'Không có vị trí — SOS vẫn được gửi',
      );
    }

    // Try GPS within budget
    Position? position;
    try {
      position = await _adapter.getCurrentPosition(timeLimit: _gpsBudget);
    } catch (_) {
      position = null;
    }

    if (position != null) {
      if (position.accuracy > _approximateAccuracyThresholdMeters) {
        return SosLocationResult(
          label: SosLocationLabel.approximate,
          latitude: position.latitude,
          longitude: position.longitude,
          accuracyMeters: position.accuracy,
          capturedAt: position.timestamp,
          displayLabel: 'vị trí gần đúng',
        );
      }
      return SosLocationResult(
        label: SosLocationLabel.current,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        capturedAt: position.timestamp,
        displayLabel: 'vị trí hiện tại',
      );
    }

    // GPS timed out — try last known position
    final lastKnown = await _adapter.getLastKnownPosition();
    if (lastKnown != null) {
      return SosLocationResult(
        label: SosLocationLabel.lastKnown,
        latitude: lastKnown.latitude,
        longitude: lastKnown.longitude,
        accuracyMeters: lastKnown.accuracy,
        capturedAt: lastKnown.timestamp,
        displayLabel: 'vị trí cuối cùng đã biết',
      );
    }

    return SosLocationResult(
      label: SosLocationLabel.unavailable,
      displayLabel: 'Không có vị trí — SOS vẫn được gửi',
    );
  }
}
