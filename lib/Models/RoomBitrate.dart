class RoomBitrate {
  int bitrate;
  String unit;
  RoomBitrate({required this.bitrate, required this.unit});

  factory RoomBitrate.init() => new RoomBitrate(bitrate: 90, unit: "90 kbps");

  static List<RoomBitrate> RoomBitrates = [
    new RoomBitrate(unit: "2000 kbps", bitrate: 2000),
    new RoomBitrate(unit: "1000 kbps", bitrate: 1000),
    new RoomBitrate(unit: "500 kbps", bitrate: 500),
    new RoomBitrate(unit: "250 kbps", bitrate: 250),
    new RoomBitrate(unit: "125 kbps", bitrate: 125),
    new RoomBitrate(unit: "90 kbps", bitrate: 90),
    new RoomBitrate(unit: "75 kbps", bitrate: 75),
  ];

  static int GetBitrateIndex(int br) {
    return RoomBitrates.indexWhere((e) => e.bitrate == br);
  }
}
