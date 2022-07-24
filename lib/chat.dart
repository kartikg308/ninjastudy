import 'dart:convert';
import 'dart:math';
import 'dart:developer' as dev;

import 'package:chat_bubbles/bubbles/bubble_special_three.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;

import 'main.dart';

List chatHistory = [];

class Chatting extends StatefulWidget {
  final int index;
  final bool isNew;
  // ignore: prefer_typing_uninitialized_variables
  final data;
  const Chatting({
    Key? key,
    required this.index,
    this.data,
    required this.isNew,
  }) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _ChattingState createState() => _ChattingState();
}

class _ChattingState extends State<Chatting> {
  List<dynamic> list = [];
  List<dynamic> chat = [];
  FlutterTts flutterTts = FlutterTts();
  bool _needsScroll = false;
  final _scrollController = ScrollController();
  bool _hasSpeech = false;
  bool _logEvents = false;
  final TextEditingController _pauseForController =
      TextEditingController(text: '3');
  final TextEditingController _listenForController =
      TextEditingController(text: '30');
  double level = 0.0;
  double minSoundLevel = 50000;
  double maxSoundLevel = -50000;
  String lastWords = '';
  String lastError = '';
  String lastStatus = '';
  String _currentLocaleId = '';
  // ignore: unused_field
  List<LocaleName> _localeNames = [];
  final SpeechToText speech = SpeechToText();

  @override
  void initState() {
    super.initState();
    initSpeechState();
    if (widget.isNew) {
      getResponse();
    } else {
      chat = widget.data;
    }
    setState(() {});
  }

  _scrollToEnd() async {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  /// This initializes SpeechToText. That only has to be done
  /// once per application, though calling it again is harmless
  /// it also does nothing. The UX of the sample app ensures that
  /// it can only be called once.
  Future<void> initSpeechState() async {
    _logEvent('Initialize');
    try {
      var hasSpeech = await speech.initialize(
        onError: errorListener,
        onStatus: statusListener,
        debugLogging: true,
      );
      if (hasSpeech) {
        // Get the list of languages installed on the supporting platform so they
        // can be displayed in the UI for selection by the user.
        _localeNames = await speech.locales();

        var systemLocale = await speech.systemLocale();
        _currentLocaleId = systemLocale?.localeId ?? '';
      }
      if (!mounted) return;

      setState(() {
        _hasSpeech = hasSpeech;
      });
    } catch (e) {
      setState(() {
        lastError = 'Speech recognition failed: ${e.toString()}';
        _hasSpeech = false;
      });
    }
  }

  getResponse() async {
    try {
      await http.get(
        Uri.parse(
          'https://my-json-server.typicode.com/tryninjastudy/dummyapi/db',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
      ).then((response) {
        dev.log(response.body);
        Map data = json.decode(response.body) as Map;
        list = data['restaurant'];
        dev.log(list.length.toString());
        chat.addAll(list);
        dev.log(list.toString());
        setState(() {});
      });
    } catch (e) {
      dev.log(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_needsScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
      _needsScroll = false;
      setState(() {});
    }
    return WillPopScope(
      onWillPop: () {
        if (widget.isNew) {
          chatHistory.add(chat);
        }
        Get.back();
        setState(() {});
        return Future.value(true);
      },
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        appBar: AppBar(
          title: const Text('Arya'),
          centerTitle: true,
          elevation: 0,
        ),
        body: chat.isNotEmpty
            ? SizedBox(
                height: MediaQuery.of(context).size.height - 150,
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: chat.length,
                  itemBuilder: (BuildContext context, int index) {
                    dev.log(chat.length.toString());
                    dev.log(chat[index].runtimeType.toString());
                    if (widget.isNew == false) {
                      chatHistory[widget.index] = chat;
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BubbleSpecialThree(
                          text: chat[index]["human"],
                          isSender: true,
                          color: const Color(0xFF1B97F3),
                          tail: false,
                          textStyle: const TextStyle(
                              color: Colors.white, fontSize: 16),
                        ),
                        BubbleSpecialThree(
                          text: chat[index]["bot"],
                          isSender: false,
                          color: Colors.blueGrey,
                          tail: false,
                          textStyle: const TextStyle(
                              color: Colors.white, fontSize: 16),
                        ),
                      ],
                    );
                  },
                ),
              )
            : const Center(
                child: CircularProgressIndicator(),
              ),
        floatingActionButton: SpeechControlWidget(
          _hasSpeech,
          speech.isListening,
          startListening,
          stopListening,
          cancelListening,
        ),
      ),
    );
  }

  // This is called each time the users wants to start a new speech
  // recognition session
  void startListening() {
    _logEvent('start listening');
    lastWords = '';
    lastError = '';
    final pauseFor = int.tryParse(_pauseForController.text);
    final listenFor = int.tryParse(_listenForController.text);
    // Note that `listenFor` is the maximum, not the minimum, on some
    // systems recognition will be stopped before this value is reached.
    // Similarly `pauseFor` is a maximum not a minimum and may be ignored
    // on some devices.
    speech.listen(
      onResult: resultListener,
      listenFor: Duration(seconds: listenFor ?? 30),
      pauseFor: Duration(seconds: pauseFor ?? 3),
      partialResults: false,
      localeId: _currentLocaleId,
      onSoundLevelChange: soundLevelListener,
      cancelOnError: true,
      listenMode: ListenMode.confirmation,
    );
    setState(() {});
  }

  void stopListening() {
    _logEvent('stop');
    speech.stop();
    setState(() {
      level = 0.0;
    });
  }

  void cancelListening() {
    _logEvent('cancel');
    speech.cancel();
    setState(() {
      level = 0.0;
    });
  }

  /// This callback is invoked each time new recognition results are
  /// available after `listen` is called.
  Future<void> resultListener(SpeechRecognitionResult result) async {
    _logEvent(
        'Result listener final: ${result.finalResult}, words: ${result.recognizedWords}');
    setState(() {
      lastWords = result.recognizedWords;
      chat.add({
        "human": lastWords,
        "bot": "I m listening",
      });
      _needsScroll = true;
    });
    await flutterTts.awaitSpeakCompletion(true);
    await flutterTts.awaitSynthCompletion(true);
    await flutterTts.speak("I m listening");
  }

  void soundLevelListener(double level) {
    minSoundLevel = min(minSoundLevel, level);
    maxSoundLevel = max(maxSoundLevel, level);
    // _logEvent('sound level $level: $minSoundLevel - $maxSoundLevel ');
    setState(() {
      this.level = level;
    });
  }

  void errorListener(SpeechRecognitionError error) {
    _logEvent(
        'Received error status: $error, listening: ${speech.isListening}');
    setState(() {
      lastError = '${error.errorMsg} - ${error.permanent}';
    });
  }

  void statusListener(String status) {
    _logEvent(
        'Received listener status: $status, listening: ${speech.isListening}');
    setState(() {
      lastStatus = status;
    });
  }

  // ignore: unused_element
  void _switchLang(selectedVal) {
    setState(() {
      _currentLocaleId = selectedVal;
    });
    log(selectedVal);
  }

  void _logEvent(String eventDescription) {
    if (_logEvents) {
      var eventTime = DateTime.now().toIso8601String();
      dev.log('$eventTime $eventDescription');
    }
  }

  // ignore: unused_element
  void _switchLogging(bool? val) {
    setState(() {
      _logEvents = val ?? false;
    });
  }
}

/// Displays the most recently recognized words and the sound level.
class RecognitionResultsWidget extends StatelessWidget {
  const RecognitionResultsWidget({
    Key? key,
    required this.lastWords,
    required this.level,
  }) : super(key: key);

  final String lastWords;
  final double level;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Last words: $lastWords',
          style: Theme.of(context).textTheme.headline6,
        ),
        Text(
          'Sound level: $level',
          style: Theme.of(context).textTheme.headline6,
        ),
      ],
    );
  }
}

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Hello! Arya',
        style: TextStyle(fontSize: 22.0),
      ),
    );
  }
}

/// Display the current error status from the speech
/// recognizer
class ErrorWidget extends StatelessWidget {
  const ErrorWidget({
    Key? key,
    required this.lastError,
  }) : super(key: key);

  final String lastError;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Center(
          child: Text(
            'Error Status',
            style: TextStyle(fontSize: 22.0),
          ),
        ),
        Center(
          child: Text(lastError),
        ),
      ],
    );
  }
}

/// Controls to start and stop speech recognition
class SpeechControlWidget extends StatelessWidget {
  const SpeechControlWidget(this.hasSpeech, this.isListening,
      this.startListening, this.stopListening, this.cancelListening,
      {Key? key})
      : super(key: key);

  final bool hasSpeech;
  final bool isListening;
  final void Function() startListening;
  final void Function() stopListening;
  final void Function() cancelListening;

  @override
  Widget build(BuildContext context) {
    return !hasSpeech || isListening
        ? IconButton(
            icon: Icon(
              Icons.stop,
              color: isListening ? Colors.red : Colors.grey,
              size: 40,
            ),
            onPressed: isListening ? stopListening : null,
          )
        : IconButton(
            onPressed: !hasSpeech || isListening ? null : startListening,
            icon: const Icon(
              Icons.mic,
              color: Colors.blue,
              size: 40,
            ),
          );
  }
}

class SessionOptionsWidget extends StatelessWidget {
  const SessionOptionsWidget(
      this.currentLocaleId,
      this.switchLang,
      this.localeNames,
      this.logEvents,
      this.switchLogging,
      this.pauseForController,
      this.listenForController,
      {Key? key})
      : super(key: key);

  final String currentLocaleId;
  final void Function(String?) switchLang;
  final void Function(bool?) switchLogging;
  final TextEditingController pauseForController;
  final TextEditingController listenForController;
  final List<LocaleName> localeNames;
  final bool logEvents;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: [
              const Text('Language: '),
              DropdownButton<String>(
                onChanged: (selectedVal) => switchLang(selectedVal),
                value: currentLocaleId,
                items: localeNames
                    .map(
                      (localeName) => DropdownMenuItem(
                        value: localeName.localeId,
                        child: Text(localeName.name),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          Row(
            children: [
              const Text('pauseFor: '),
              Container(
                  padding: const EdgeInsets.only(left: 8),
                  width: 80,
                  child: TextFormField(
                    controller: pauseForController,
                  )),
              Container(
                  padding: const EdgeInsets.only(left: 16),
                  child: const Text('listenFor: ')),
              Container(
                  padding: const EdgeInsets.only(left: 8),
                  width: 80,
                  child: TextFormField(
                    controller: listenForController,
                  )),
            ],
          ),
          Row(
            children: [
              const Text('Log events: '),
              Checkbox(
                value: logEvents,
                onChanged: switchLogging,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class InitSpeechWidget extends StatelessWidget {
  const InitSpeechWidget(this.hasSpeech, this.initSpeechState, {Key? key})
      : super(key: key);

  final bool hasSpeech;
  final Future<void> Function() initSpeechState;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        TextButton(
          onPressed: hasSpeech ? null : initSpeechState,
          child: const Text('Initialize'),
        ),
      ],
    );
  }
}

/// Display the current status of the listener
class SpeechStatusWidget extends StatelessWidget {
  const SpeechStatusWidget({
    Key? key,
    required this.speech,
  }) : super(key: key);

  final SpeechToText speech;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      color: Theme.of(context).backgroundColor,
      child: Center(
        child: speech.isListening
            ? const Text(
                "I'm listening...",
                style: TextStyle(fontWeight: FontWeight.bold),
              )
            : const Text(
                'Not listening',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
