import 'dart:async';
import 'dart:typed_data';
import 'package:smart_school/core/models/camera_model.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../services/supabase_service.dart';

/// Handles WebSocket MJPEG streaming from the Node.js stream-server.
class CameraService {
  WebSocketChannel? _channel;
  final _frameController = StreamController<Uint8List>.broadcast();
  bool _connected = false;

  Stream<Uint8List> get frameStream => _frameController.stream;
  bool get isConnected => _connected;

  /// Fetch camera metadata for a room from Supabase (rooms.stream_ws_url).
  Future<CameraModel?> getCameraForRoom(String roomId) async {
    final url = await SupabaseService.getStreamUrlForRoom(roomId);
    if (url == null || url.isEmpty) return null;
    return CameraModel.fromRoomStreamUrl(roomId, url);
  }

  /// Connect to the WebSocket stream-server and decode binary JPEG frames.
  Future<void> connect(String wsUrl) async {
    disconnect();
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _connected = true;

      _channel!.stream.listen(
        (data) {
          if (data is List<int>) {
            _frameController.add(Uint8List.fromList(data));
          } else if (data is Uint8List) {
            _frameController.add(data);
          }
        },
        onError: (e) {
          _connected = false;
          _frameController.addError(e);
        },
        onDone: () {
          _connected = false;
        },
      );
    } catch (e) {
      _connected = false;
      rethrow;
    }
  }

  void disconnect() {
    _connected = false;
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _frameController.close();
  }
}