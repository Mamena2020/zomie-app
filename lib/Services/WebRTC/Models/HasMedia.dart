class HasMedia {
  bool video;
  // bool screen;
  bool audio;
  HasMedia({required this.video, required this.audio});

  factory HasMedia.init() => HasMedia(audio: true, video: true);

  factory HasMedia.fromJson(Map<dynamic, dynamic> json) =>
      HasMedia(audio: json['has_audio'], video: json['has_video']);

  factory HasMedia.copy(HasMedia origin) =>
      HasMedia(video: origin.video, audio: origin.audio);
}
