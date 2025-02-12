import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CameraPreviewScreen extends StatefulWidget {
  const CameraPreviewScreen({super.key});

  @override
  State<CameraPreviewScreen> createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller?.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isCapturing) return;

    try {
      setState(() {
        _isCapturing = true;
      });

      final image = await _controller!.takePicture();
      if (mounted) {
        Navigator.pop(context, image);
      }
    } catch (e) {
      print('Error capturing image: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
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
    if (!_isCameraInitialized || _controller == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),
            ),
            Positioned(
              left: 16,
              top: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ).animate()
                .fadeIn()
                .scale(delay: 200.ms),
            ),
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const Text(
                    'Position prescription within frame',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ).animate()
                    .fadeIn()
                    .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FloatingActionButton.large(
                        onPressed: _captureImage,
                        child: _isCapturing
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Icon(Icons.camera, size: 32),
                      ).animate()
                        .fadeIn()
                        .scale(delay: 400.ms),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
