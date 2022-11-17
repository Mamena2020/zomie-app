class Room {
  String id;
  String? password;
  int life_time_minutes;

  Room({required this.id, this.password, required this.life_time_minutes});

  factory Room.init() => Room(id: "", life_time_minutes: 1);
}
