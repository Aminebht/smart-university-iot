/// Lightweight camera metadata; actual streaming is done via WebSocket
to the stream-server URL stored per-room.
class CameraModel {
  final int? cameraId;
  final String? name;
  final String streamUrl;
  final bool isActive;
  final String? roomId;
  final String? roomName;

  CameraModel({
    this.cameraId,
    this.name,
    required this.streamUrl,
    this.isActive = true,
    this.roomId,
    this.roomName,
  });

  factory CameraModel.fromRoomStreamUrl(String roomId, String streamUrl) {
    return CameraModel(
      roomId: roomId,
      streamUrl: streamUrl,
      name: 'Camera — $roomId',
    );
  }

  factory CameraModel.fromJson(Map<String, dynamic> json) {
    return CameraModel(
      cameraId: json['camera_id'] ?? json['id'],
      name: json['name']?.toString(),
      streamUrl: json['stream_url']?.toString() ?? '',
      isActive: json['is_active'] ?? true,
      roomId: json['room_id']?.toString() ?? json['classroom_id']?.toString(),
      roomName: json['room_name']?.toString() ?? json['classroom_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'camera_id': cameraId,
      'name': name,
      'stream_url': streamUrl,
      'is_active': isActive,
      'room_id': roomId,
    };
  }
}