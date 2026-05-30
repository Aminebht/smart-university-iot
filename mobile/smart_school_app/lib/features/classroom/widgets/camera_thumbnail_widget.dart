import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:smart_school/core/constants/app_constants.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import 'dart:developer' as developer;
import '../../../core/models/camera_model.dart';
import '../../camera/screens/camera_view_screen.dart';

class CameraThumbnailWidget extends StatefulWidget {
  final int classroomId;
  final double height;
  final double width;

  const CameraThumbnailWidget({
    Key? key,
    required this.classroomId,
    this.height = 160,
    this.width = double.infinity,
  }) : super(key: key);

  @override
  State<CameraThumbnailWidget> createState() => _CameraThumbnailWidgetState();
}

class _CameraThumbnailWidgetState extends State<CameraThumbnailWidget> {
  WebSocketChannel? _channel;
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _isConnected = false;
  String _errorMessage = '';
  CameraModel? _camera;
  bool _isDisposed = false;
  bool _isReconnecting = false;
  
  // Use a proper URL format with port 3000 as per Node.js server configuration
  static const String _streamUrl = 'ws://192.168.1.175:3000/stream';
  
  @override
  void initState() {
    super.initState();
    developer.log('📱 CameraThumbnail: initializing for classroom ${widget.classroomId}', name: 'Camera');
    _loadCamera();
  }

  Future<void> _loadCamera() async {
    if (_isDisposed) return;
    
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      developer.log('📱 CameraThumbnail: loading camera for classroom ${widget.classroomId}', name: 'Camera');
      
      // Create a simplified camera model (no need for Supabase)
      _camera = CameraModel(
        cameraId: widget.classroomId,
        name: 'Classroom Camera',
        streamUrl: _streamUrl,
        isActive: true,
        motionDetectionEnabled: true,
        description: 'Camera for classroom monitoring',
        isRecording: false,
      );
      
      developer.log('📱 CameraThumbnail: camera model created with URL: $_streamUrl', name: 'Camera');
      
      // Connect to the stream when in thumbnail view
      _connectToStream();
      
      if (!_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      developer.log('❌ CameraThumbnail: Error loading camera: $e', name: 'Camera', error: e, stackTrace: stackTrace);
      if (!_isDisposed) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load camera: $e';
        });
      }
    }
  }
  
  void _connectToStream() {
    if (_isReconnecting || _isDisposed) {
      developer.log('🔄 CameraThumbnail: Skipping connection attempt - already reconnecting or disposed', name: 'Camera');
      return;
    }
    
    _isReconnecting = true;
    
    try {
      developer.log('🔌 CameraThumbnail: Connecting to WebSocket at $_streamUrl', name: 'Camera');
      
      // Safer way to close any existing connection
      _safeCloseChannel();
      
      // Connect to the WebSocket server
      _channel = WebSocketChannel.connect(Uri.parse(_streamUrl));
      
      // Setup connection timeout
      Future.delayed(const Duration(seconds: 10), () {
        if (_isDisposed) return;
        
        if (!_isConnected && _isReconnecting) {
          developer.log('⏱️ CameraThumbnail: Connection timeout', name: 'Camera');
          if (!_isDisposed) {
            setState(() {
              _isReconnecting = false;
              _errorMessage = 'Connection timeout';
            });
          }
        }
      });
      
      _channel!.stream.listen(
        (data) {
          // Data from WebSocket is the raw JPEG bytes
          try {
            if (_isDisposed) return;
            
            if (data is Uint8List && data.isNotEmpty) {
              if (!_isDisposed) {
                setState(() {
                  _imageBytes = data;
                  _isConnected = true;
                  _isReconnecting = false;
                });
              }
              developer.log('📦 CameraThumbnail: Received frame: ${data.length} bytes', name: 'Camera');
            } else {
              developer.log('⚠️ CameraThumbnail: Received non-binary data or empty data', name: 'Camera');
            }
          } catch (e, stackTrace) {
            developer.log('❌ CameraThumbnail: Error processing frame: $e', name: 'Camera', error: e, stackTrace: stackTrace);
          }
        },
        onError: (error, stackTrace) {
          developer.log('❌ CameraThumbnail: WebSocket error: $error', name: 'Camera', error: error, stackTrace: stackTrace);
          if (_isDisposed) return;
          
          setState(() {
            _isConnected = false;
            _isReconnecting = false;
            _errorMessage = 'Connection error';
          });
        },
        onDone: () {
          developer.log('👋 CameraThumbnail: WebSocket connection closed', name: 'Camera');
          if (_isDisposed) return;
          
          setState(() {
            _isConnected = false;
            _isReconnecting = false;
          });
          
          // Try to reconnect after a delay
          Future.delayed(const Duration(seconds: 3), () {
            if (_isDisposed) return;
            
            if (!_isConnected) {
              developer.log('🔄 CameraThumbnail: Attempting reconnection', name: 'Camera');
              _connectToStream();
            }
          });
        },
        cancelOnError: false, // Don't cancel on error, let us handle reconnection
      );
    } catch (e, stackTrace) {
      developer.log('❌ CameraThumbnail: Failed to connect to WebSocket: $e', name: 'Camera', error: e, stackTrace: stackTrace);
      if (_isDisposed) return;
      
      setState(() {
        _isConnected = false;
        _isReconnecting = false;
        _errorMessage = 'Connection failed: $e';
      });
      
      // Try to reconnect after a delay
      Future.delayed(const Duration(seconds: 5), () {
        if (_isDisposed) return;
        
        if (!_isConnected) {
          _connectToStream();
        }
      });
    }
  }

  // Safely close the WebSocket channel
  void _safeCloseChannel() {
    if (_channel != null) {
      try {
        developer.log('🔌 CameraThumbnail: Closing existing WebSocket connection', name: 'Camera');
        _channel!.sink.close(ws_status.goingAway);
      } catch (e) {
        developer.log('⚠️ CameraThumbnail: Error closing existing WebSocket: $e', name: 'Camera');
        // Connection might already be closed, continue
      } finally {
        _channel = null;
      }
    }
  }

  @override
  void dispose() {
    developer.log('👋 CameraThumbnail: Disposing', name: 'Camera');
    _isDisposed = true;
    _safeCloseChannel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_camera == null) {
      return _buildNoCameraWidget();
    }

    return GestureDetector(
      onTap: () => _openFullscreenView(context),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            SizedBox(
              height: widget.height,
              width: widget.width,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildCameraPreview(),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isConnected 
                      ? Colors.green 
                      : _isReconnecting 
                          ? Colors.orange 
                          : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isConnected 
                      ? 'Live' 
                      : _isReconnecting 
                          ? 'Connecting...' 
                          : 'Offline',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: Text(
                _camera != null ? _camera!.name : 'Camera',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 3.0,
                      color: Colors.black,
                      offset: Offset(1.0, 1.0),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: const Icon(
                Icons.fullscreen,
                color: Colors.white,
                size: 20,
                shadows: [
                  Shadow(
                    blurRadius: 3.0,
                    color: Colors.black,
                    offset: Offset(1.0, 1.0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isConnected || _imageBytes == null) {
      return _buildOfflineCamera();
    }

    try {
      return Image.memory(
        _imageBytes!,
        fit: BoxFit.cover,
        gaplessPlayback: true, // Prevents flickering between frames
        errorBuilder: (context, error, stackTrace) {
          developer.log('❌ CameraThumbnail: Error displaying image: $error', name: 'Camera', error: error, stackTrace: stackTrace);
          return _buildOfflineCamera();
        },
      );
    } catch (e, stackTrace) {
      developer.log('❌ CameraThumbnail: Exception in _buildCameraPreview: $e', name: 'Camera', error: e, stackTrace: stackTrace);
      return _buildOfflineCamera();
    }
  }

  Widget _buildLoadingWidget() {
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: const Card(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildNoCameraWidget() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        height: widget.height,
        width: widget.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off, size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              _errorMessage.isNotEmpty 
                  ? _errorMessage 
                  : 'No camera installed',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineCamera() {
    return Container(
      color: Colors.black12,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off, size: 30, color: Colors.black54),
            const SizedBox(height: 8),
            Text(
              _isReconnecting 
                  ? 'Connecting to camera...' 
                  : 'Camera feed unavailable',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            if (_errorMessage.isNotEmpty && !_isReconnecting)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.black54, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ),
            if (_isReconnecting)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black45),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openFullscreenView(BuildContext context) {
    if (_camera != null) {
      try {
        developer.log('🔍 CameraThumbnail: Opening fullscreen view', name: 'Camera');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CameraViewScreen(camera: _camera!),
          ),
        ).then((_) {
          // Handle return from camera view properly
          developer.log('🔙 CameraThumbnail: Returned from fullscreen view', name: 'Camera');
          // Only reconnect if needed and if we're still mounted
          if (!_isConnected && !_isDisposed && mounted) {
            _connectToStream();
          }
        });
      } catch (e, stackTrace) {
        developer.log('❌ CameraThumbnail: Error opening fullscreen: $e', name: 'Camera', error: e, stackTrace: stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error opening camera view: $e'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No camera available'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}