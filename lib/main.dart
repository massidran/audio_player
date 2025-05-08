import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: Colors.black,
        cardColor: Colors.grey[900],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
      ),
      home: const AudioPlayerScreen(),
    );
  }
}

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  List<String> _songs = [];
  String? _currentSong;

  @override
  void initState() {
    super.initState();
    _loadSongs();

    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _totalDuration = duration;
      });
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _currentPosition = position;
      });
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _isPlaying = false;
        _currentSong = null;
        _currentPosition = Duration.zero;
        _totalDuration = Duration.zero;
      });
    });
  }

  Future<void> _loadSongs() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    final audioFiles = manifestMap.keys.toList();
    final List<String> songNames = [];
    for (final song in audioFiles) {
      songNames.add(song.split('/').last);
    }
    setState(() {
      _songs = songNames;
    });
  }

  void _play(String song) async {
    _audioPlayer.stop();
    _currentSong = song;
    await _audioPlayer.play(AssetSource('audio/$song'));
    setState(() {
      _isPlaying = true;
    });
  }

  void _pause() async {
    await _audioPlayer.pause();
    setState(() {
      _isPlaying = false;
    });
  }

  void _stop() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
      _currentSong = null;
      _currentPosition = Duration.zero;
      _totalDuration = Duration.zero;
    });
  }

  void _seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('Audio Player')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                final song = _songs[index];
                final bool isSelected = song == _currentSong;
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 4.0,
                  ),
                  elevation: 2.0,
                  child: ListTile(
                    leading: Icon(
                      Icons.music_note,
                      color:
                          isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                    ),
                    title: Text(
                      song,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    onTap: () => _play(song),
                  ),
                );
              },
            ),
          ),
          if (_currentSong != null) ...[
            Slider(
              value: _currentPosition.inSeconds.toDouble(),
              max: _totalDuration.inSeconds.toDouble(),
              onChanged: (value) {
                _seek(Duration(seconds: value.toInt()));
              },
            ),
            Text(
              '${_currentPosition.toString().split('.').first.substring(2)} / ${_totalDuration.toString().split('.').first.substring(2)}',
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: _isPlaying ? null : () => _play(_currentSong!),
                ),
                IconButton(
                  icon: const Icon(Icons.pause),
                  onPressed: _isPlaying ? _pause : null,
                ),
                IconButton(icon: const Icon(Icons.stop), onPressed: _stop),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
