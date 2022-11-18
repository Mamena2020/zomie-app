class RoomLifeTime {
  String name;
  int lifeTime;

  RoomLifeTime({required this.name, required this.lifeTime});

  factory RoomLifeTime.init() => RoomLifeTime(
      name: roomLifeTimes.first.name, lifeTime: roomLifeTimes.first.lifeTime);
  factory RoomLifeTime.fromJson(Map<dynamic, dynamic> json) => RoomLifeTime(
      name: json["name"] ?? '1 minutes', lifeTime: json["lifeTime"] ?? 1);

  Map<String, dynamic> toJson() =>
      {"name": this.name, "lifeTime": this.lifeTime};

  static List<RoomLifeTime> roomLifeTimes = [
    new RoomLifeTime(name: "1 Minute", lifeTime: 1),
    new RoomLifeTime(name: "5 Minute", lifeTime: 5),
    new RoomLifeTime(name: "10 Minute", lifeTime: 10),
    new RoomLifeTime(name: "30 Minute", lifeTime: 30)
  ];

  static int GetRoomInstance(int lt) {
    return roomLifeTimes.indexWhere((e) => e.lifeTime == lt);
  }
}
