import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;

class PostVoiceRecorder extends StatefulWidget {
  final Function(String) callback;

  const PostVoiceRecorder({required this.callback});

  @override
  _PostVoiceRecorderState createState() => _PostVoiceRecorderState();
}

class _PostVoiceRecorderState extends State<PostVoiceRecorder> {
  late Record audioRecord;
  late AudioPlayer audioPlayer;
  bool isRecording = false;
  String audioPath = "";
  String length = "00:00";

  String mText = "Start Recording";

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    audioRecord = Record();
  }

  @override
  void dispose() {
    super.dispose();
    audioRecord.dispose();
    audioPlayer.dispose();
  }

  bool playing = false;

  Future<void> startRecording() async {
    try {
      print("START RECODING+++++++++++++++++++++++++++++++++++++++++++++++++");
      if (await audioRecord.hasPermission()) {
        await audioRecord.start();
        setState(() {
          isRecording = true;
          mText = "Stop Recording";
        });
      }
    } catch (e, stackTrace) {
      print(
          "START RECODING+++++++++++++++++++++${e}++++++++++${stackTrace}+++++++++++++++++");
    }
  }

  Future<void> stopRecording() async {
    try {
      print("STOP RECODING+++++++++++++++++++++++++++++++++++++++++++++++++");
      String? path = await audioRecord.stop();
      setState(() {
        recoding_now = false;
        isRecording = false;
        audioPath = path!;
        widget.callback.call(audioPath);
        mText = "Play   Delete";
      });
    } catch (e) {
      print(
          "STOP RECODING+++++++++++++++++++++${e}+++++++++++++++++++++++++++");
    }
  }

  Future<void> playRecording() async {
    try {
      playing = true;
      setState(() {
        mText = "Playing...";
      });

      print("AUDIO PLAYING+++++++++++++++++++++++++++++++++++++++++++++++++");
      Source urlSource = UrlSource(audioPath);
      await audioPlayer.play(urlSource);
      // Add an event listener to be notified when the audio playback completes
      audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
        if (state == PlayerState.completed) {
          playing = false;

          print(
              "AUDIO PLAYING ENDED+++++++++++++++++++++++++++++++++++++++++++++++++");
          setState(() {
            length = audioPlayer.getDuration().toString();
            mText = "Play   Delete";
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
        mText = "Play   Delete";
      });
      //print('Hive Playing Recording ${voiceRecordingsBox.values.cast<String>().toList().toString()}');
    } catch (e) {
      print(
          "AUDIO PAUSED++++++++++++++++++++++++${e}+++++++++++++++++++++++++");
    }
  }

  Future<void> uploadAndDeleteRecording() async {
    try {
      final url =
          Uri.parse('YOUR_UPLOAD_URL'); // Replace with your server's upload URL

      final file = File(audioPath);
      if (!file.existsSync()) {
        print(
            "UPLOADING FILE NOT EXIST+++++++++++++++++++++++++++++++++++++++++++++++++");
        return;
      }
      print(
          "UPLOADING FILE ++++++++++++++++${audioPath}+++++++++++++++++++++++++++++++++");
      final request = http.MultipartRequest('POST', url)
        ..files.add(
          http.MultipartFile(
            'audio',
            file.readAsBytes().asStream(),
            file.lengthSync(),
            filename: 'audio.mp3', // You may need to adjust the file extension
          ),
        );

      final response = await http.Response.fromStream(await request.send());

      if (response.statusCode == 200) {
        // Upload successful, you can delete the recording if needed
        // Show a snackbar or any other UI feedback for a successful upload
        const snackBar = SnackBar(
          content: Text('Audio uploaded.'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);

        // Refresh the UI
        setState(() {
          audioPath = "";
        });
      } else {
        // Handle the error or show an error message
        print('Failed to upload audio. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading audio: $e');
    }
  }

  Future<void> deleteRecording() async {
    if (audioPath.isNotEmpty) {
      try {
        recoding_now = true;
        File file = File(audioPath);
        if (file.existsSync()) {
          file.deleteSync();
          const snackBar = SnackBar(
            content: Text('Recoding deleted'),
          );

          print(
              "FILE DELETED+++++++++++++++++++++++++++++++++++++++++++++++++");
        }
      } catch (e) {
        print(
            "FILE NOT DELETED++++++++++++++++${e}+++++++++++++++++++++++++++++++++");
      }

      setState(() {
        audioPath = "";
        widget.callback.call(audioPath);
        mText = "Start Recording";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {},
        child: Container(
            padding: EdgeInsets.all(8),
            margin: EdgeInsets.all(0),
            width: context.width(),
            decoration: boxDecorationWithRoundedCorners(
                backgroundColor: context.cardColor),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  recoding_now
                      ? IconButton(
                          icon: !isRecording
                              ? const Icon(Icons.mic_rounded,
                                  color: Colors.red, size: 30)
                              : const Icon(Icons.stop_circle,
                                  color: Colors.red, size: 30),
                          onPressed:
                              isRecording ? stopRecording : startRecording,
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
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
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red, size: 30),
                              onPressed: deleteRecording,
                            ),
                            // IconButton(
                            //     icon: const Icon(Icons.trending_up,
                            //         color: Colors.green, size: 30),
                            //     onPressed: uploadAndDeleteRecording),
                          ],
                        ),
                ],
              ),
              Text(mText, style: boldTextStyle(color: context.primaryColor))
                  .paddingOnly(bottom: 16, left: 8),
            ])));
  }

  bool recoding_now = true;
}
