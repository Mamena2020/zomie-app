class Candidate {
  String candidate;
  String sdpMid;
  int sdpMLineIndex;

  Candidate(
      {required this.candidate,
      required this.sdpMid,
      required this.sdpMLineIndex});

  factory Candidate.init() =>
      Candidate(candidate: "", sdpMid: "", sdpMLineIndex: -1);

  Map<String, dynamic> toJson() => {
        "candidate": this.candidate,
        "sdpMid": this.sdpMid,
        "sdpMLineIndex": this.sdpMLineIndex
      };
}
