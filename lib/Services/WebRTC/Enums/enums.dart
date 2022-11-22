enum SdpType {
  offer,
  answer,
}

// enum RTCConnectType { create, join }

enum CallType { videoCall, audioCall, screenSharing }

enum RoomEventType { join_room, leave_room, update_data, none }

enum WRTCMessageType {
  message,
  info,
  join_room,
  leave_room,
  start_screen,
  stop_screen,
  none
}

enum ProducerType { user, screen }
