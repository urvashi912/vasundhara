import 'package:flutter/material.dart';
import 'package:vapi/vapi.dart';
import 'dart:async';
import 'dart:math';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';

class RecyclerChatbot extends StatefulWidget {
  const RecyclerChatbot({super.key});

  @override
  State<RecyclerChatbot> createState() => _RecyclerChatbotState();
}

class _RecyclerChatbotState extends State<RecyclerChatbot> {
  static const String vapiApiKey = '0a136b74-95f2-49ed-b473-a640c89494f6';
  // Platform channel for speakerphone control
  static const platform = MethodChannel('com.pict.recycler/audio');

  late Vapi vapi;
  bool _callOngoing = false;
  Timer? _timer;
  int _callSeconds = 0;
  List<_ChatMessage> _messages = [];
  String _userPartial = '';
  String _botPartial = '';
  bool _isListening = false;
  List<double> _waveHeights = List.generate(16, (i) => 8.0);
  Timer? _waveTimer;

  @override
  void initState() {
    super.initState();
    _initAudioSession();
    vapi = Vapi(vapiApiKey);
    vapi.onEvent.listen((event) {
      if (event.label == "call-start") {
        setState(() {
          _callOngoing = true;
          _callSeconds = 0;
          _isListening = true;
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          _setSpeakerphoneOn();
        });
        _startTimer();
        _startWaveAnimation();
        // Send greeting as spoken message
        vapi.send({
          "type": "add-message",
          "message": {
            "role": "assistant",
            "content": "Hi! I'm Repurpose Bot. Tell me about any broken or old item, and I'll help you turn it into something new and useful!"
          }
        });
      }
      if (event.label == "call-end") {
        setState(() {
          _callOngoing = false;
          _isListening = false;
          _userPartial = '';
          _botPartial = '';
        });
        _stopTimer();
        _stopWaveAnimation();
      }
      if (event.label == "error") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Repurpose Bot error: \n${event.value.toString()}')),
        );
      }
      // Handle live transcription events
      if (event.label == "message" && event.value is Map) {
        final value = event.value as Map;
        if (value['type'] == 'transcript') {
          final role = value['role'];
          final text = value['content'] ?? '';
          setState(() {
            if (role == 'user') {
              _userPartial = text;
            } else if (role == 'assistant') {
              _botPartial = text;
            }
          });
        } else if (value['type'] == 'add-message') {
          final role = value['message']['role'];
          final text = value['message']['content'] ?? '';
          setState(() {
            if (role == 'user') {
              _messages.add(_ChatMessage(text: text, isBot: false));
              _userPartial = '';
            } else if (role == 'assistant') {
              _messages.add(_ChatMessage(text: text, isBot: true));
              _botPartial = '';
            }
          });
        }
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callSeconds++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}' ;
  }

  Future<void> _startVapiCall() async {
    try {
      await vapi.start(assistant: {
        "model": {
          "provider": "openai",
          "model": "gpt-3.5-turbo",
          "systemPrompt": "You are Repurpose Bot, a creative assistant that helps users repurpose broken or old items into new, useful things. When a user mentions an item, give step-by-step, creative, and safe instructions for upcycling, DIY, or repurposing it. Always encourage eco-friendly, fun, and practical solutions. Greet the user when the conversation starts. Never wait for the user to say anything; always respond proactively, even if the user is silent."
        },
        "voice": {
          "provider": "11labs",
          "voiceId": "burt",
        },
        "name": "Repurpose Bot"
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start Repurpose Bot: \n$e')),
      );
    }
  }

  Future<void> _endVapiCall() async {
    try {
      await vapi.stop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to end Repurpose Bot: \n$e')),
      );
    }
  }

  void _startWaveAnimation() {
    _waveTimer?.cancel();
    _waveTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      setState(() {
        final rand = Random();
        for (int i = 0; i < _waveHeights.length; i++) {
          _waveHeights[i] = 8.0 + rand.nextDouble() * (_isListening ? 32.0 : 16.0);
        }
      });
    });
  }

  void _stopWaveAnimation() {
    _waveTimer?.cancel();
    _waveTimer = null;
    setState(() {
      _waveHeights = List.generate(16, (i) => 8.0);
    });
  }

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.speech());
  }

  Future<void> _setSpeakerphoneOn() async {
    try {
      await platform.invokeMethod('setSpeakerphoneOn');
    } catch (e) {
      // Optionally handle error
    }
  }

  @override
  void dispose() {
    _stopTimer();
    _stopWaveAnimation();
    super.dispose();
  }

  Widget _buildWaveBars() {
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _waveHeights.map((h) => AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 6,
          height: h,
          decoration: BoxDecoration(
            color: Colors.teal,
            borderRadius: BorderRadius.circular(4),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildMicButton() {
    return GestureDetector(
      onTap: _callOngoing ? _endVapiCall : _startVapiCall,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: _callOngoing
                ? [Colors.redAccent, Colors.red]
                : [Colors.teal, Colors.green],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: (_callOngoing ? Colors.red : Colors.teal).withOpacity(0.3),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          _callOngoing ? Icons.mic_off : Icons.mic,
          color: Colors.white,
          size: 48,
        ),
      ),
    );
  }

  Widget _buildChatBubbles() {
    List<Widget> bubbles = [];
    for (final msg in _messages) {
      bubbles.add(_ChatBubble(
        text: msg.text,
        isBot: msg.isBot,
      ));
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shrinkWrap: true,
      children: [
        ...bubbles,
        if (_userPartial.isNotEmpty)
          _ChatBubble(text: _userPartial, isBot: false, isPartial: true),
        if (_botPartial.isNotEmpty)
          _ChatBubble(text: _botPartial, isBot: true, isPartial: true),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        backgroundColor: Colors.teal,
        automaticallyImplyLeading: false,
        title: const Text(
          "Repurpose Bot",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Greeting (only at the top)
            if (_messages.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  "👋 Welcome! I'm Repurpose Bot. Tap the mic and tell me about any broken or old item, and I'll help you turn it into something new!",
                  style: TextStyle(fontSize: 18, color: Colors.teal[900]),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(child: _buildChatBubbles()),
            if (_callOngoing) ...[
              _buildWaveBars(),
              const SizedBox(height: 8),
              Text(
                "Ongoing call • ${_formatDuration(_callSeconds)}",
                style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
              ),
            ],
            const SizedBox(height: 16),
            _buildMicButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isBot;
  _ChatMessage({required this.text, required this.isBot});
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isBot;
  final bool isPartial;
  const _ChatBubble({required this.text, required this.isBot, this.isPartial = false, super.key});

  @override
  Widget build(BuildContext context) {
    final align = isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    final color = isBot ? Colors.white : Colors.teal[100];
    final border = isBot
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          );
    return Row(
      mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: border,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isBot) ...[
                  const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.teal,
                    child: Icon(Icons.lightbulb, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    text + (isPartial ? ' ...' : ''),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.teal[900],
                      fontStyle: isPartial ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
