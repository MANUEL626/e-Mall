import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../ui/app_feedback.dart';

const LatLng _kDefaultMapCenter = LatLng(6.3703, 2.4301);

class LocationPicker extends StatefulWidget {
  const LocationPicker({
    super.key,
    required this.longitudeController,
    required this.latitudeController,
    this.title = 'Position',
    this.subtitle = 'Utilisez votre position actuelle ou touchez la carte.',
    this.enabled = true,
    this.compact = false,
  });

  final TextEditingController longitudeController;
  final TextEditingController latitudeController;
  final String title;
  final String subtitle;
  final bool enabled;
  final bool compact;

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> with WidgetsBindingObserver {
  final MapController _mapController = MapController();
  LatLng? _selected;
  bool _locating = false;
  String? _errorText;
  bool _showLocationSettingsAction = false;
  bool _openAppSettingsAction = false;
  bool _retryLocationOnResume = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selected = _readControllers();
    widget.longitudeController.addListener(_syncFromControllers);
    widget.latitudeController.addListener(_syncFromControllers);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.longitudeController.removeListener(_syncFromControllers);
    widget.latitudeController.removeListener(_syncFromControllers);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_retryLocationOnResume || _locating) {
      return;
    }
    _retryLocationOnResume = false;
    unawaited(_useCurrentLocation());
  }

  LatLng? _readControllers() {
    final lng = double.tryParse(widget.longitudeController.text.trim().replaceAll(',', '.'));
    final lat = double.tryParse(widget.latitudeController.text.trim().replaceAll(',', '.'));
    if (lng == null || lat == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    return LatLng(lat, lng);
  }

  void _syncFromControllers() {
    final next = _readControllers();
    if (next == null) return;
    if (_selected?.latitude == next.latitude && _selected?.longitude == next.longitude) return;
    setState(() => _selected = next);
  }

  void _setSelected(LatLng point, {bool moveMap = false}) {
    widget.latitudeController.text = point.latitude.toStringAsFixed(6);
    widget.longitudeController.text = point.longitude.toStringAsFixed(6);
    setState(() {
      _selected = point;
      _errorText = null;
      _showLocationSettingsAction = false;
      _openAppSettingsAction = false;
    });
    if (moveMap) {
      _mapController.move(point, 16);
    }
  }

  Future<void> _useCurrentLocation() async {
    if (!widget.enabled || _locating) return;
    setState(() {
      _locating = true;
      _errorText = null;
      _showLocationSettingsAction = false;
    });
    try {
      final position = await _determinePosition();
      if (!mounted) return;
      _setSelected(LatLng(position.latitude, position.longitude), moveMap: true);
    } catch (e) {
      if (!mounted) return;
      final message = AppFeedback.locationError(e);
      final openSettings = _isLocationServiceDisabled(e) || _isLocationPermissionBlocked(e);
      final openAppSettings = _isLocationPermissionBlocked(e);
      setState(() {
        _errorText = message.text;
        _showLocationSettingsAction = openSettings;
        _openAppSettingsAction = openAppSettings;
      });
      AppFeedback.show(
        context,
        message,
        actionLabel: openSettings ? 'Parametres' : null,
        onAction: openSettings ? () => _openLocationSettings(e) : null,
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  bool _isLocationServiceDisabled(Object error) {
    if (error is PlatformException && error.code == 'LOCATION_SERVICES_DISABLED') {
      return true;
    }
    final raw = error.toString().toLowerCase();
    return raw.contains('location_services_disabled') ||
        raw.contains('location services are disabled') ||
        raw.contains('localisation du telephone');
  }

  bool _isLocationPermissionBlocked(Object error) {
    if (error is PlatformException && error.code == 'PERMISSION_DENIED_NEVER_ASK') {
      return true;
    }
    final raw = error.toString().toLowerCase();
    return raw.contains('deniedforever') || raw.contains('bloquee');
  }

  Future<void> _openLocationSettings(Object error) async {
    _retryLocationOnResume = true;
    if (_isLocationPermissionBlocked(error)) {
      await Geolocator.openAppSettings();
      return;
    }
    await Geolocator.openLocationSettings();
  }

  Future<Position> _determinePosition() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Autorisation de localisation refusee.';
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw 'Autorisation de localisation bloquee. Ouvrez les parametres de l application.';
    }

    Position? lastKnown;
    try {
      lastKnown = await Geolocator.getLastKnownPosition();
    } catch (_) {
      lastKnown = null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on TimeoutException {
      if (lastKnown != null) return lastKnown;
      throw 'Position actuelle indisponible pour le moment.';
    } on PlatformException catch (e) {
      if (lastKnown != null && e.code == 'LOCATION_SERVICES_DISABLED') {
        return lastKnown;
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _selected ?? _kDefaultMapCenter;
    final height = widget.compact ? 220.0 : 260.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: widget.enabled && !_locating ? _useCurrentLocation : null,
              icon: _locating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded, size: 18),
              label: const Text('Ma position'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: height,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: _selected == null ? 12 : 16,
                interactionOptions: InteractionOptions(
                  flags: widget.enabled ? InteractiveFlag.all : InteractiveFlag.none,
                ),
                onTap: widget.enabled ? (_, point) => _setSelected(point) : null,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.e_mall',
                ),
                if (_selected != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selected!,
                        width: 48,
                        height: 48,
                        child: const Icon(
                          Icons.location_pin,
                          color: Color(0xFFC45A12),
                          size: 44,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _selected == null
              ? 'Aucune position choisie.'
              : 'Lat. ${_selected!.latitude.toStringAsFixed(6)} - Long. ${_selected!.longitude.toStringAsFixed(6)}',
          style: const TextStyle(fontSize: 12, color: Color(0xFF6A4A35)),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFF8A4B00)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _errorText!,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF8A4B00)),
                ),
              ),
              if (_showLocationSettingsAction)
                TextButton(
                  onPressed: () {
                    _retryLocationOnResume = true;
                    if (_openAppSettingsAction) {
                      unawaited(Geolocator.openAppSettings());
                    } else {
                      unawaited(Geolocator.openLocationSettings());
                    }
                  },
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 28),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Parametres'),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
