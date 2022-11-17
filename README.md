# zomie

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

   
#Flutter info
- build with version.
  - Flutter 3.3.4, dart 2.18.2
- Android 
  - targetSdk
    ```
      compileSdkVersion 33
      minSdkVersion 23
      targetSdkVersion 33
    ```


#Credential
- none


#Note

- Socket io  
  - Platform
    - All Platform
  - version info match [1]
    ```
      - server(nodejs): "socket.io": "^2.4.1"
      - client(flutter):  socket_io_client: ^1.0.1 | ^1.0.2
    ```
  - version info match [2]
    ```
      - server(nodejs): "socket.io": "^4.5.3"
      - client(flutter):  socket_io_client: ^2.0.0
    ```
- WebRTC 
  - Android, Windows, Web
  
- Flutter Code 
  - App Life Cycle 
    - https://www.reddit.com/r/FlutterDev/comments/l7wqb2/flutter_tutorial_detect_app_background_app_closed/ 

#References

- Socket Io
  - Issues
    - https://stackoverflow.com/questions/68058896/latest-version-of-socket-io-nodejs-is-not-connecting-to-flutter-applications

- WebRTC 
  - Articles | Doc
    - https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia
    - https://bloggeek.me/webrtc-vs-zoom-video-quality/
    - https://webrtchacks.com/zoom-avoids-using-webrtc/
    - https://stackoverflow.com/questions/56944864/can-we-remove-and-add-audio-stream-dynamically-in-webrtc-video-call-without-rene
    - https://stackoverflow.com/questions/64012898/how-to-completely-turn-off-camera-on-mediastream-javascript
  - Issues
    - https://github.com/flutter-webrtc/flutter-webrtc/issues/938 windows rtc
    - https://github.com/flutter-webrtc/flutter-webrtc/issues/436 close conection
    - media stream, muted, stop camera
      ```
       - https://stackoverflow.com/questions/63666576/how-restart-a-closed-video-track-stopped-using-userstream-getvideotracks0
       - https://stackoverflow.com/questions/57563002/do-cloned-streams-from-mediastreamdestination-are-still-somehow-bound-to-this-au
       - https://stackoverflow.com/questions/72857922/replace-webrtc-track-of-different-kind-without-renegotiations
       - https://stackoverflow.com/questions/41309682/check-if-selected-microphone-is-muted-or-not-with-web-audio-api/41309852#41309852
       - https://stackoverflow.com/questions/56944864/can-we-remove-and-add-audio-stream-dynamically-in-webrtc-video-call-without-rene
       - https://stackoverflow.com/questions/39831238/webrtc-how-to-change-the-audio-track-for-a-existing-stream
       - https://stackoverflow.com/questions/64012898/how-to-completely-turn-off-camera-on-mediastream-javascript
      ```