class ResponseApi {
  int status_code;
  String message;

  ResponseApi({required this.status_code, required this.message});

  factory ResponseApi.init() =>
      ResponseApi(status_code: 200, message: "success");
}
