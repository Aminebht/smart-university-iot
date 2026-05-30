import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../core/models/camera_model.dart';

class CameraViewScreen extends StatefulWidget {
  final CameraModel camera;

  const CameraViewScreen({
    Key? key,
    required this.camera,
  }) : super(key: key);

  @override
  State<CameraViewScreen> createState() => _CameraViewScreenState();
}

class _CameraViewScreenState extends State<CameraViewScreen> {
  WebSocketChannel? _channel;
  Uint8List? _imageBytes;
  bool _isFullScreen = false;
  bool _showControls = true;
  bool _isConnected = false;
  bool _isConnecting = true;
  String? _connectionError;
  
  @override
  void initState() {
    super.initState();
    _connectToStream();
  }

  void _connectToStream() {
    try {
      setState(() {
        _isConnecting = true;
        _connectionError = null;
      });
      
      // Make sure we use WebSocket URL (ws:// or wss://)
      String streamUrl = widget.camera.streamUrl;
      if (streamUrl.startsWith('http')) {
        streamUrl = streamUrl.replaceFirst('http', 'ws');
      }

      print('Connecting to WebSocket: $streamUrl');
      
      _channel = WebSocketChannel.connect(
        Uri.parse(streamUrl)
      );
      
      _channel!.stream.listen(
        (data) {
          if (data is Uint8List) {
            setState(() {
              _imageBytes = data;
              _isConnected = true;
              _isConnecting = false;
            });
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          setState(() {
            _isConnected = false;
            _isConnecting = false;
            _connectionError = 'Connection error: $error';
          });
        },
        onDone: () {
          print('WebSocket connection closed');
          setState(() {
            _isConnected = false;
            _isConnecting = false;
          });
          
          // Try to reconnect after a delay
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted && !_isConnected) {
              _connectToStream();
            }
          });
        },
      );
    } catch (e) {
      print('Failed to connect to WebSocket: $e');
      setState(() {
        _isConnected = false;
        _isConnecting = false;
        _connectionError = 'Connection failed: $e';
      });
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _showControls = !_showControls;
              });
            },
            child: Center(
              child: _isConnecting
                  ? _buildConnectingIndicator()
                  : _isConnected && _imageBytes != null
                      ? _buildStreamView()
                      : _buildErrorView(),
            ),
          ),
          if (_showControls) _buildControlsOverlay(),
        ],
      ),
    );
  }

  Widget _buildStreamView() {
    return Image.memory(
      _imageBytes!,
      fit: _isFullScreen ? BoxFit.cover : BoxFit.contain,
      gaplessPlayback: true, // Prevents flickering between frames
    );
  }

  Widget _buildConnectingIndicator() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        CircularProgressIndicator(color: Colors.white),
        SizedBox(height: 16),
        Text(
          'Connecting to camera...',
          style: TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.videocam_off, size: 64, color: Colors.white54),
        const SizedBox(height: 16),
        Text(
          _connectionError ?? 'Camera feed unavailable',
          style: const TextStyle(color: Colors.white54),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _connectToStream,
          child: const Text('Reconnect'),
        ),
      ],
    );
  }

  Widget _buildControlsOverlay() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            bottom: 8,
            left: 16,
            right: 16,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  widget.camera.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isConnected ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isConnected ? 'Live' : 'Offline',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 8,
            top: 8,
            left: 16,
            right: 16,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                label: 'Fullscreen',
                onPressed: () {
                  setState(() {
                    _isFullScreen = !_isFullScreen;
                  });
                },
              ),
              _buildControlButton(
                icon: Icons.refresh,
                label: 'Reconnect',
                onPressed: _connectToStream,
              ),
              _buildControlButton(
                icon: Icons.photo_camera,
                label: 'Snapshot',
                onPressed: () {
                  // Implement snapshot functionality if needed
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Snapshot captured'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 4),
          Text(
            label, 
            style: const TextStyle(color: Colors.white, fontSize: 12)
          ),
        ],
      ),
    );
  }
}