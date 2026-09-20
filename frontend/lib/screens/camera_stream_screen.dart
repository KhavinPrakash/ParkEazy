import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class CameraStreamScreen extends StatefulWidget {
  final bool isActive;

  const CameraStreamScreen({
    Key? key,
    this.isActive = true,
  }) : super(key: key);

  @override
  State<CameraStreamScreen> createState() => _CameraStreamScreenState();
}

class _CameraStreamScreenState extends State<CameraStreamScreen> {
  Uint8List? _currentFrameBytes;
  bool _isStreaming = false;
  bool _isFetching = false;
  bool _hasError = false;
  Timer? _timer;
  int _fpsCount = 0;
  int _displayedFps = 30;
  Timer? _fpsTimer;
  String _selectedCameraFacility = "Phoenix Marketcity Mall (CAM-01)";

  final List<String> _cameraOptions = [
    "Phoenix Marketcity Mall (CAM-01)",
    "D-Mart Supermarket (CAM-02)",
    "City Care Hospital (CAM-03)",
    "Global Tech Park (CAM-04)",
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _startStream();
    }
    _fpsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _displayedFps = _fpsCount;
          _fpsCount = 0;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant CameraStreamScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _startStream();
      } else {
        _stopStream();
      }
    }
  }

  void _startStream() {
    _isStreaming = true;
    _hasError = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _fetchLatestFrame();
    });
  }

  void _stopStream() {
    _isStreaming = false;
    _timer?.cancel();
    _timer = null;
  }

  void _fetchLatestFrame() async {
    if (!_isStreaming || !widget.isActive || _isFetching) return;
    _isFetching = true;
    try {
      final response = await http.get(
        Uri.parse("${ApiService.baseUrl}/api/camera/frame?t=${DateTime.now().millisecondsSinceEpoch}"),
        headers: {'Connection': 'close'},
      ).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200 && mounted && widget.isActive) {
        setState(() {
          _currentFrameBytes = response.bodyBytes;
          _hasError = false;
          _fpsCount++;
        });
      }
    } catch (_) {
      if (mounted && !_hasError && widget.isActive) {
        setState(() {
          _hasError = true;
        });
      }
    } finally {
      _isFetching = false;
    }
  }

  @override
  void dispose() {
    _stopStream();
    _fpsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("AI Camera Live Stream"),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.crimsonRed.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.crimsonRed),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.crimsonRed,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  "LIVE 1080P • $_displayedFps FPS",
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.crimsonRed),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Facility Camera Selector Bar
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.cardBg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select Enrolled Parking Camera",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCameraFacility,
                        isExpanded: true,
                        dropdownColor: AppTheme.cardBg,
                        icon: const Icon(Icons.videocam_rounded, color: AppTheme.primary),
                        items: _cameraOptions.map((opt) {
                          return DropdownMenuItem<String>(
                            value: opt,
                            child: Text(opt, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCameraFacility = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Video Stream Container
            Container(
              height: 320,
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary.withOpacity(0.6), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.25),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _currentFrameBytes != null
                    ? Image.memory(
                        _currentFrameBytes!,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                      )
                    : _hasError
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.videocam_off_rounded, color: AppTheme.crimsonRed, size: 48),
                                const SizedBox(height: 10),
                                const Text(
                                  "Camera Stream Disconnected",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "Ensure backend server is running on port 8000",
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _startStream,
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text("Reconnect Stream"),
                                ),
                              ],
                            ),
                          )
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: AppTheme.primary),
                                SizedBox(height: 14),
                                Text(
                                  "Initializing YOLO AI Vision Engine...",
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
              ),
            ),

            // AI Metadata Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.memory_rounded, color: AppTheme.emeraldGreen, size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            "YOLOv8 Object Detection Engine",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: AppTheme.cardBorder),
                      _buildDetailRow("Active Location", _selectedCameraFacility),
                      _buildDetailRow("Target Dataset", "HD Multi-Lot Parking CCTV Feed"),
                      _buildDetailRow("Detection Mode", "Vehicle Bounding Box + Slot Polygon Overlaps"),
                      _buildDetailRow("Real-Time Frame Rate", "$_displayedFps FPS"),
                      _buildDetailRow("Model Accuracy", "97.2% Mean Average Precision (mAP)"),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
