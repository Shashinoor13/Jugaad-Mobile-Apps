import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class PostVoicePlayer extends StatefulWidget {
  final Function(String) callback;
  final String path;
  PostVoicePlayer({required this.callback, required this.path});

  @override
  _PostVoicePlayerState createState() => _PostVoicePlayerState();
}

class _PostVoicePlayerState extends State<PostVoicePlayer> {
  late AudioPlayer audioPlayer;
  bool isRecording = false;
  String audioPath = "";
  String length = "00:00";
  bool playing = false;
  String mText = "Play";

  @override
  void initState() {
    super.initState();
    audioPath = widget.path;
    audioPlayer = AudioPlayer();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {},
        child: Container(
            padding: EdgeInsets.all(0),
            margin: EdgeInsets.all(0),
            width: context.width(),
            decoration: boxDecorationWithRoundedCorners(
                backgroundColor: context.dividerColor),
            child:
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: !playing
                            ? Icon(Icons.play_circle,
                            color: Colors.green, size: 30)
                            : Icon(Icons.pause_circle,
                            color: Colors.green, size: 30),
                        onPressed:
                        !playing ? playRecording : pauseRecording,
                      ),
                    ],
                  ),
                ],
              ),
              Text(mText, style: boldTextStyle(color: context.primaryColor)),
            ])));
  }

  @override
  void dispose() {
    super.dispose();
    audioPlayer.dispose();
  }

  Future<void> playRecording() async {
    try {
      playing = true;
      setState(() {
        mText = "Playing...";
      });

      print("AUDIO PLAYING+++++++++++++++++++++++++++++++++++++++++++++++++");
      Source urlSource = UrlSource(audioPath, mimeType: "audio/m4a");
      await audioPlayer.play(urlSource);
      // Add an event listener to be notified when the audio playback completes
      audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
        if (state == PlayerState.completed) {
          playing = false;

          print(
              "AUDIO PLAYING ENDED+++++++++++++++++++++++++++++++++++++++++++++++++");
          setState(() {
            length = audioPlayer.getDuration().toString();
            mText = "Play";
          });
        }
      });
    } catch (e) {
      print(
          "AUDIO PLAYING++++++++++++++++++++++++${e}+++++++++++++++++++++++++");
    }
  }

  Future<void> pauseRecording() async {
    try {
      playing = false;

      print("AUDIO PAUSED+++++++++++++++++++++++++++++++++++++++++++++++++");

      await audioPlayer.pause();
      setState(() {
        mText = "Play";
      });
      //print('Hive Playing Recording ${voiceRecordingsBox.values.cast<String>().toList().toString()}');
    } catch (e) {
      print(
          "AUDIO PAUSED++++++++++++++++++++++++${e}+++++++++++++++++++++++++");
    }
  }
}
