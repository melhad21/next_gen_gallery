import 'dart:async';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:antigravity_gallery/domain/repositories/media_repository.dart';

class PermissionService {
  final StreamController<PermissionState> _permissionController =
      StreamController<PermissionState>.broadcast();

  Stream<PermissionState> get permissionStream => _permissionController.stream;

  Future<bool> requestPermission() async {
    final result = await PhotoManager.requestPermissionExtend();

    if (result.isAuth) {
      _permissionController.add(PermissionState.granted);
      return true;
    } else if (result == PermissionState.limited) {
      _permissionController.add(PermissionState.limited);
      return true;
    } else {
      _permissionController.add(PermissionState.denied);
      return false;
    }
  }

  Future<PermissionState> checkPermission() async {
    final result = await PhotoManager.requestPermissionExtend();

    if (result.isAuth) {
      return PermissionState.granted;
    } else if (result == PermissionState.limited) {
      return PermissionState.limited;
    } else {
      return PermissionState.denied;
    }
  }

  Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  void dispose() {
    _permissionController.close();
  }
}