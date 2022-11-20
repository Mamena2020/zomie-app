# zomie

Online meeting app like google meet, build with flutter for all platforms.
this app uses webrtc for media streaming, and io sockets for signaling & messaging.
the server running in nodejs. each client will have 2 active peer 1 for broadcasting &
1 for consumer for all user in the room. 
for server using star topology & SFU(Selective Forwarding Unit) method for routing.

-#SS apps




- Current status platform
  - Android 
  - Windows
  - Web (addOnTrack not working on web-> on proggres new solution)
  - Ios (not tested yet)
  - Linux (not tested yet)
  - Mac (not tested yet)

   
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