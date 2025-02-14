import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraPreviewScreen extends StatefulWidget {
  const CameraPreviewScreen({super.key});

  @override
  State<CameraPreviewScreen> createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isDenied) {
      final result = await Permission.camera.request();
      if (result.isDenied) {
        setState(() {
          _error = 'Camera permission is required to scan prescriptions';
        });
        return;
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      await _checkCameraPermission();
      if (_error.isNotEmpty) return;

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _error = 'No cameras found on device';
        });
        return;
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.max,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
      if (!mounted) return;

      await _controller!.setFlashMode(FlashMode.auto);
      await _controller!.setFocusMode(FocusMode.auto);
      await _controller!.setExposureMode(ExposureMode.auto);

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      setState(() {
        _error = 'Error initializing camera: $e';
      });
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
      setState(() {
        _error = 'Error capturing image: ${e.toString()}';
      });
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
    if (_error.isNotEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  _error,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isCameraInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Camera Preview
          CameraPreview(_controller!),
          
          // Prescription Guide Overlay
          Positioned.fill(
            child: CustomPaint(
              painter: PrescriptionGuidePainter(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
            ),
          ),
          
          // Capture Controls
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                FloatingActionButton(
                  onPressed: _isCapturing ? null : () => _captureImage(),
                  child: Icon(_isCapturing ? Icons.hourglass_empty : Icons.camera),
                ).animate(
                  target: _isCapturing ? 0 : 1,
                ).scaleXY(
                  begin: 0.9,
                  end: 1.0,
                  duration: const Duration(milliseconds: 200),
                ),
                const SizedBox(width: 64), // For balance
              ],
            ),
          ),
          
          // Guide Text
          Positioned(
            top: 48,
            left: 0,
            right: 0,
            child: Text(
              'Align prescription within the frame',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                shadows: [
                  Shadow(
                    offset: const Offset(0, 1),
                    blurRadius: 3.0,
                    color: Colors.black.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PrescriptionGuidePainter extends CustomPainter {
  final Color color;

  PrescriptionGuidePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw outer rectangle with rounded corners
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.1,
        size.height * 0.2,
        size.width * 0.8,
        size.height * 0.6,
      ),
      const Radius.circular(12),
    );
    canvas.drawRRect(rect, paint);

    // Draw corner indicators
    final cornerLength = size.width * 0.05;
    final corners = [
      // Top left
      [rect.left, rect.top, rect.left + cornerLength, rect.top], // horizontal
      [rect.left, rect.top, rect.left, rect.top + cornerLength], // vertical
      // Top right
      [rect.right - cornerLength, rect.top, rect.right, rect.top],
      [rect.right, rect.top, rect.right, rect.top + cornerLength],
      // Bottom left
      [rect.left, rect.bottom - cornerLength, rect.left, rect.bottom],
      [rect.left, rect.bottom, rect.left + cornerLength, rect.bottom],
      // Bottom right
      [rect.right - cornerLength, rect.bottom, rect.right, rect.bottom],
      [rect.right, rect.bottom - cornerLength, rect.right, rect.bottom],
    ];

    paint.strokeWidth = 3.0;
    for (final corner in corners) {
      canvas.drawLine(
        Offset(corner[0], corner[1]),
        Offset(corner[2], corner[3]),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
