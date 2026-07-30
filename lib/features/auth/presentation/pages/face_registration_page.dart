import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../../../core/services/ai_service_client.dart';
import '../../../../core/database/repositories/user_repository.dart';
import '../../../../core/theme/app_colors.dart';

class FaceRegistrationPage extends StatefulWidget {
  final int userId;

  const FaceRegistrationPage({super.key, required this.userId});

  @override
  State<FaceRegistrationPage> createState() => _FaceRegistrationPageState();
}

class _FaceRegistrationPageState extends State<FaceRegistrationPage> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitializing = true;
  bool _isProcessing = false;
  final AIServiceClient _aiService = AIServiceClient();
  final UserRepository _userRepo = UserRepository();
  String _statusMessage = 'Align your face in the camera and capture';

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
          _statusMessage = 'No camera found on this device.';
          _isInitializing = false;
        });
        return;
      }
      
      final camera = _cameras.first;
      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Failed to initialize camera: $e';
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _captureAndRegister() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Capturing and analyzing face...';
    });
    
    try {
      final XFile file = await _controller!.takePicture();
      final File imageFile = File(file.path);
      
      final List<double>? encoding = await _aiService.extractEncoding(imageFile);
      
      if (encoding != null) {
        // Save to database
        await _userRepo.updateFaceEncoding(widget.userId, jsonEncode(encoding));
        
        setState(() {
          _statusMessage = 'Face registered successfully!';
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Face Registered Successfully!'), backgroundColor: AppColors.success),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Registration'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkCharcoal,
        elevation: 0,
      ),
      body: Center(
        child: _isInitializing
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_controller != null && _controller!.value.isInitialized)
                    Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.goldenYellow, width: 4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: CameraPreview(_controller!),
                    )
                  else
                    const Icon(Icons.videocam_off, size: 64, color: AppColors.mutedText),
                  
                  const SizedBox(height: 24),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: _statusMessage.contains('Error') ? AppColors.brandRed : AppColors.darkCharcoal,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  ElevatedButton.icon(
                    onPressed: _isProcessing || _controller == null ? null : _captureAndRegister,
                    icon: _isProcessing 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.camera_alt),
                    label: Text(_isProcessing ? 'Processing...' : 'Capture Face'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldenYellow,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
