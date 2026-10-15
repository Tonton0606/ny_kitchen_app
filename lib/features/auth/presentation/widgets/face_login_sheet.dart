import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../../../core/services/ai_service_client.dart';
import '../../../../core/database/repositories/user_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/session/session_manager.dart';
import '../../../admin/presentation/pages/admin_shell.dart';
import '../../../cashier/presentation/pages/cashier_shell.dart';
import 'force_change_password_dialog.dart';

class FaceLoginSheet extends StatefulWidget {
  const FaceLoginSheet({super.key});

  @override
  State<FaceLoginSheet> createState() => _FaceLoginSheetState();
}

class _FaceLoginSheetState extends State<FaceLoginSheet> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitializing = true;
  bool _isProcessing = false;
  bool _isCheckingLiveness = false;
  bool _isCheckingFrame = false;
  bool _hasBlinked = false;
  Timer? _livenessTimer;
  
  final AIServiceClient _aiService = AIServiceClient();
  final UserRepository _userRepo = UserRepository();
  String _statusMessage = 'Align your face and tap start';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _statusMessage = 'No camera found.';
          _isInitializing = false;
        });
        return;
      }
      
      final camera = _cameras.first;
      _controller = CameraController(camera, ResolutionPreset.medium, enableAudio: false);
      
      await _controller!.initialize();
      if (mounted) setState(() => _isInitializing = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Camera error: $e';
          _isInitializing = false;
        });
      }
    }
  }

  void _startLivenessCheck() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    
    setState(() {
      _isCheckingLiveness = true;
      _hasBlinked = false;
      _statusMessage = 'Please blink to verify...';
    });

    // Check for blink every 150ms (faster polling to catch natural blinks)
    _livenessTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (_isCheckingFrame) return; // Skip if previous frame is still processing
      _isCheckingFrame = true;
      
      try {
        final XFile file = await _controller!.takePicture();
        final File imageFile = File(file.path);
        
        final bool? eyesClosed = await _aiService.checkEyesClosed(imageFile);
        
        if (eyesClosed == null) {
           _isCheckingFrame = false;
           return; // No face or eyes detected
        }
        
        if (eyesClosed) {
          _hasBlinked = true;
        } else if (_hasBlinked && !eyesClosed) {
          // Blink completed
          timer.cancel();
          if (mounted) {
            setState(() {
              _isCheckingLiveness = false;
              _statusMessage = 'Blink detected! Recognizing...';
            });
            _captureAndLogin(imageFile); // Proceed with the last captured frame
          }
        }
      } catch (_) {
        // Ignore capture errors during periodic check
      } finally {
        _isCheckingFrame = false;
      }
    });
  }

  Future<void> _captureAndLogin(File imageFile) async {
    setState(() {
      _isProcessing = true;
    });
    
    try {
      final List<double>? newEncoding = await _aiService.extractEncoding(imageFile);
      
      if (newEncoding != null) {
        final users = await _userRepo.getUsersWithFaceEncoding();
        Map<String, dynamic>? bestMatch;
        double minDistance = double.infinity;

        for (var user in users) {
          final String encodingStr = user['face_encoding'];
          final List<dynamic> rawList = jsonDecode(encodingStr);
          final List<double> savedEncoding = rawList.map((e) => (e as num).toDouble()).toList();
          
          final distance = _aiService.calculateEuclideanDistance(newEncoding, savedEncoding);
          if (distance < minDistance) {
            minDistance = distance;
            bestMatch = user;
          }
        }
        
        // Threshold for a match is usually around 0.5 for face_recognition library
        if (bestMatch != null && minDistance < 0.55) {
          if (mounted) {
            setState(() {
              _statusMessage = 'Welcome back, ${bestMatch!['full_name']}!';
            });
            await Future.delayed(const Duration(seconds: 1));
            
            final matchedUser = bestMatch!;
            final int mustChange = (matchedUser['must_change_password'] as int?) ?? 0;
            if (mustChange == 1) {
              Navigator.pop(context); // close sheet
              showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (dialogCtx) => ForceChangePasswordDialog(
                  user: matchedUser,
                  onSuccess: () {
                    Navigator.of(dialogCtx).pop();
                    SessionManager().setSession(matchedUser);
                    final role = matchedUser['role'] as String;
                    final destination = role == 'admin' ? const AdminShell() : const CashierShell();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute<void>(builder: (_) => destination),
                      (route) => false,
                    );
                  },
                  onCancel: () {
                    Navigator.of(dialogCtx).pop();
                    SessionManager().clearSession();
                  },
                ),
              );
              return;
            }

            SessionManager().setSession(matchedUser);
            final role = matchedUser['role'] as String;
            final destination = role == 'admin' ? const AdminShell() : const CashierShell();
            
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute<void>(builder: (_) => destination),
              (route) => false,
            );
          }
        } else {
          setState(() {
            _statusMessage = 'Face not recognized. Try again.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _livenessTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Face Login',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkCharcoal),
            ),
            const SizedBox(height: 16),
            if (_isInitializing)
              const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
            else if (_controller != null && _controller!.value.isInitialized)
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.goldenYellow, width: 4),
                  borderRadius: BorderRadius.circular(150),
                ),
                clipBehavior: Clip.hardEdge,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.previewSize!.height,
                    height: _controller!.value.previewSize!.width,
                    child: CameraPreview(_controller!),
                  ),
                ),
              )
            else
              const SizedBox(height: 200, child: Center(child: Icon(Icons.videocam_off, size: 64))),
            
            const SizedBox(height: 16),
            Text(
              _statusMessage,
              style: TextStyle(
                color: _statusMessage.contains('Error') || _statusMessage.contains('not recognized') ? AppColors.brandRed : AppColors.mutedText,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isProcessing || _isCheckingLiveness || _controller == null ? null : _startLivenessCheck,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldenYellow,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isProcessing || _isCheckingLiveness
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Text('Start Face Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

