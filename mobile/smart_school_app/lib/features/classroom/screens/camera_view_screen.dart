import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/models/camera_model.dart';
import 'dart:async';

class CameraViewScreen extends StatefulWidget {
  final int cameraId;

  const CameraViewScreen({
    super.key,
    required this.cameraId,
  });

  @override
  State<CameraViewScreen> createState() => _CameraViewScreenState();
}

class _CameraViewScreenState extends State<CameraViewScreen> {
  final TextEditingController _urlController = TextEditingController(text: 'http://192.168.0.22:3000/stream');
  bool _showDebugPanel = false;
  IOWebSocketChannel? _channel;
  Uint8List? _imageBytes;
  bool _isConnected = false;
  String? _connectionError;

  @override
  void initState() {
    super.initState();
    // Camera info will be loaded by the provider
  }

  @override
  void dispose() {
    _disconnectFromStream();
    _urlController.dispose();
    super.dispose();
  }

  void _connectToStream(String streamUrl) {
    // Disconnect any existing connection
    _disconnectFromStream();
    
    try {
      setState(() {
        _connectionError = null;
        _isConnected = false;
      });
      
      developer.log('⚡ Attempting connection to: $streamUrl', name: 'CameraStream');
      
      // Convert HTTP URL to WebSocket URL if needed
      final wsUrl = streamUrl.startsWith('http') 
          ? streamUrl.replaceFirst('http', 'ws')
          : streamUrl;
      
      // Add required headers to bypass localtunnel reminder
      Map<String, dynamic> headers = {
        'bypass-tunnel-reminder': 'true',
        'User-Agent': 'Smart-School-App-Client',
      };
      
      developer.log('📤 Connection attempt with URL: $wsUrl', name: 'CameraStream');
      developer.log('📤 Using headers: $headers', name: 'CameraStream');
      
      _attemptConnection(wsUrl, headers);
    } catch (e) {
      developer.log('❌ Setup error: $e', name: 'CameraStream');
      setState(() {
        _connectionError = 'Connection setup error: $e';
        _isConnected = false;
      });
    }
  }

  void _attemptConnection(String url, Map<String, dynamic> headers) {
    try {
      developer.log('Attempting connection to: $url', name: 'CameraStream');

      _channel = IOWebSocketChannel.connect(
        url,
        headers: headers,
      );

      developer.log('✅ WebSocket channel created for $url', name: 'CameraStream');

      _channel!.stream.listen(
        (data) {
          // Log the data type but not the content (could be large)
          developer.log(
            '📦 Received data type: ${data.runtimeType}, size: ${data is Uint8List ? data.length : (data is String ? data.length : 'unknown')}',
            name: 'CameraStream',
          );

          if (data is Uint8List) {
            // This is a binary frame - likely JPEG/PNG image data
            setState(() {
              _imageBytes = data;
              _isConnected = true;
            });
          } else if (data is String) {
            // This is a text frame - could be control message or error
            try {
              var jsonData = jsonDecode(data);
              developer.log(
                'Received JSON: ${jsonData.toString().substring(0, jsonData.toString().length > 100 ? 100 : jsonData.toString().length)}...',
                name: 'CameraStream',
              );

              // Handle any control messages if needed
            } catch (e) {
              // Not valid JSON, just a string message
              developer.log(
                'Received text: ${data.length > 100 ? data.substring(0, 100) + "..." : data}',
                name: 'CameraStream',
              );
            }
          }
        },
        onError: (error) {
          developer.log('❌ WebSocket error: $error', name: 'CameraStream');
          setState(() {
            _connectionError = 'Connection error: $error';
            _isConnected = false;
          });

          // Try fallback URL with WS protocol if WSS fails
          if (url.startsWith('wss://')) {
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                _attemptConnection(url.replaceFirst('wss', 'ws'), headers);
              }
            });
          }
        },
        onDone: () {
          developer.log('⏹️ WebSocket connection closed', name: 'CameraStream');
          if (mounted) {
            setState(() {
              _isConnected = false;
            });

            // Automatically try to reconnect after a delay
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted && _channel == null) {
                _connectToStream(url);
              }
            });
          }
        },
      );
    } catch (e, stack) {
      developer.log('❌ Connection failed: $e\n$stack', name: 'CameraStream');
      if (mounted) {
        setState(() {
          _connectionError = 'Failed to connect: $e';
          _isConnected = false;
        });
      }

      // Try HTTP stream as fallback - only if WS connection fails
      if (url.startsWith('ws')) {
        developer.log('🔄 Trying HTTP stream fallback...', name: 'CameraStream');
        _tryHttpStream();
      }
    }
  }

  void _tryHttpStream() {
    setState(() {
      _connectionError = 'Trying HTTP fallback...';
    });

    // HTTP fallback URL (using HTTP instead of WebSocket)
    final httpUrl = 'http://192.168.0.22:3000/stream';

    // Just for testing if the server exists and responds
    try {
      final httpHeaders = {
        'bypass-tunnel-reminder': 'true',
        'User-Agent': 'Smart-School-App-Client',
      };

      // Use a timer to simulate receiving frames
      Timer.periodic(Duration(milliseconds: 500), (timer) {
        if (!mounted || _channel != null) {
          timer.cancel();
          return;
        }

        // For debugging only - show a test image
        developer.log('📤 Simulating HTTP image stream frame', name: 'CameraStream');
        setState(() {
          _isConnected = true;
          _connectionError = null;
          // You can add placeholder image here if needed
        });
      });
    } catch (e) {
      developer.log('❌ HTTP fallback failed: $e', name: 'CameraStream');
      setState(() {
        _connectionError = 'All connection attempts failed';
        _isConnected = false;
      });
    }
  }

  void _disconnectFromStream() {
    if (_channel != null) {
      developer.log('⏹️ Closing existing WebSocket connection', name: 'CameraStream');
      _channel?.sink.close();
      _channel = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CameraProvider()..loadCamera(widget.cameraId),
      child: Consumer<CameraProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Scaffold(
              appBar: AppBar(title: const Text('Camera Feed')),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          if (provider.errorMessage != null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Camera Feed')),
              body: _buildErrorView(context, provider),
            );
          }

          final camera = provider.camera;
          if (camera == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Camera Feed')),
              body: const Center(
                child: Text('Camera not found'),
              ),
            );
          }

          // Connect to stream when camera info is loaded
          if (_channel == null) {
            // Always use the predefined URL with WebSocket protocol
            const streamUrl = 'http://192.168.0.22:3000/stream';
            // Using Future.microtask to avoid setState during build
            Future.microtask(() => _connectToStream(streamUrl));
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(camera.name),
              actions: [
                // Connection status indicator
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _isConnected ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    provider.toggleRecording();
                  },
                  icon: Icon(
                    provider.isRecording ? Icons.stop : Icons.fiber_manual_record,
                    color: provider.isRecording ? Colors.red : null,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    provider.takeSnapshot();
                  },
                  icon: const Icon(Icons.camera_alt),
                ),
              ],
            ),
            body: Column(
              children: [
                // Camera feed (takes most of the screen)
                Expanded(
                  flex: 3,
                  child: _buildWebSocketCameraFeed(context, provider),
                ),

                // Controls at the bottom
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status info
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _isConnected ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isConnected ? 'Connected' : 'Disconnected',
                            style: TextStyle(
                              color: _isConnected ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (provider.isRecording)
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Recording',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Camera controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildControlButton(
                            context,
                            Icons.refresh,
                            'Reconnect',
                            () => _connectToStream('http://192.168.0.22:3000/stream'),
                          ),
                          _buildControlButton(
                            context,
                            Icons.zoom_in,
                            'Zoom In',
                            () => provider.zoomIn(),
                          ),
                          _buildControlButton(
                            context,
                            Icons.zoom_out,
                            'Zoom Out',
                            () => provider.zoomOut(),
                          ),
                          _buildControlButton(
                            context,
                            Icons.fullscreen,
                            'Fullscreen',
                            () => provider.toggleFullscreen(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWebSocketCameraFeed(BuildContext context, CameraProvider provider) {
    return GestureDetector(
      onTap: () {
        provider.toggleFullscreen();
      },
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [
            Center(
              child: _imageBytes != null
                  ? Image.memory(
                      _imageBytes!,
                      fit: BoxFit.contain,
                      gaplessPlayback: true, // Important for smooth video
                    )
                  : _connectionError != null
                      ? _buildConnectionErrorView()
                      : _buildConnectingView(),
            ),
            if (provider.isFullscreen)
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  onPressed: () {
                    provider.toggleFullscreen();
                  },
                  icon: const Icon(
                    Icons.fullscreen_exit,
                    color: Colors.white,
                  ),
                ),
              ),
            if (provider.isRecording)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.fiber_manual_record,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        provider.recordingDuration,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        CircularProgressIndicator(color: Colors.white),
        SizedBox(height: 16),
        Text(
          'Connecting to camera stream...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionErrorView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 48,
        ),
        const SizedBox(height: 16),
        Text(
          _connectionError ?? 'Connection error',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        // Debug information
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Server: mystream.loca.lt\n'
            'Protocol: WSS/WS with bypass headers\n'
            'Last attempt: ${DateTime.now().toString().substring(0, 19)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _connectToStream('http://192.168.0.22:3000/stream'),
              child: const Text('Try WSS'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _connectToStream('http://192.168.0.22:3000/stream'),
              child: const Text('Try WS'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          color: AppColors.primary,
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(BuildContext context, CameraProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 60,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            provider.errorMessage ?? 'An error occurred',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.error),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Retry',
            onPressed: () => provider.loadCamera(widget.cameraId),
            icon: Icons.refresh,
          ),
        ],
      ),
    );
  }
}

class CameraProvider extends ChangeNotifier {
  bool _isFullscreen = false;
  bool _isRecording = false;
  bool _isPanning = false;
  bool _isLoading = false;
  double _zoomLevel = 1.0;
  String _recordingDuration = "00:00";
  Timer? _recordingTimer;
  int _recordingSeconds = 0;
  String? _errorMessage;
  CameraModel? _camera;

  // Properties
  double get zoomLevel => _zoomLevel;
  String get recordingDuration => _recordingDuration;
  bool get isFullscreen => _isFullscreen;
  bool get isRecording => _isRecording;
  bool get isPanning => _isPanning;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  CameraModel? get camera => _camera;

  Future<void> loadCamera(int cameraId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Here you would typically call an API or service to fetch camera details
      // For now using a simple Future.delayed to simulate network call
      await Future.delayed(const Duration(seconds: 1));

      // Mock camera data - replace with actual API call
      _camera = CameraModel(
        cameraId: cameraId,
        name: 'Camera $cameraId',
        streamUrl: 'ws://192.168.1.175:8080/stream',
        motionDetectionEnabled: false,
        description: '',
        isRecording: false,
        isActive: true
      );
      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load camera: $e';
    }

    notifyListeners();
  }

  void toggleFullscreen() {
    _isFullscreen = !_isFullscreen;
    notifyListeners();
  }

  void togglePan() {
    _isPanning = !_isPanning;
    notifyListeners();
  }

  void zoomIn() {
    if (_zoomLevel < 5.0) {
      // Maximum zoom level
      _zoomLevel += 0.5;
      notifyListeners();
    }
  }

  void zoomOut() {
    if (_zoomLevel > 1.0) {
      // Minimum zoom level
      _zoomLevel -= 0.5;
      notifyListeners();
    }
  }

  void toggleRecording() {
    _isRecording = !_isRecording;

    if (_isRecording) {
      // Start recording timer
      _recordingSeconds = 0;
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingSeconds++;
        final minutes = (_recordingSeconds ~/ 60).toString().padLeft(2, '0');
        final seconds = (_recordingSeconds % 60).toString().padLeft(2, '0');
        _recordingDuration = "$minutes:$seconds";
        notifyListeners();
      });
    } else {
      // Stop recording timer
      _recordingTimer?.cancel();
      _recordingTimer = null;
      _recordingDuration = "00:00";
    }

    notifyListeners();
  }

  void takeSnapshot() {
    // Implement snapshot capture logic
    // This would typically send a command to the camera server
    // or save the current frame from the video feed
    print('Taking snapshot');

    // You could show a flash effect or message to indicate success
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    super.dispose();
  }
}