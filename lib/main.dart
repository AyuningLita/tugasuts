import 'package:flutter/material.dart';
import 'dart:async'; // Untuk Timer dan Stream

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stopwatch & Timer',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const StopwatchTimerPage(),
    );
  }
}

class StopwatchTimerPage extends StatefulWidget {
  const StopwatchTimerPage({super.key});

  @override
  State<StopwatchTimerPage> createState() => _StopwatchTimerPageState();
}

class _StopwatchTimerPageState extends State<StopwatchTimerPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- Stopwatch Variables ---
  Stopwatch _stopwatch = Stopwatch();
  Timer? _stopwatchTimer;
  String _stopwatchDisplay = '00:00:00.00';
  final List<String> _laps = [];

  // --- Timer Variables ---
  Timer? _countdownTimer;
  Duration _currentDuration = const Duration();
  Duration _initialDuration = const Duration(minutes: 5); // Default 5 menit
  String _timerDisplay = '00:05:00';
  bool _isTimerRunning = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _updateTimerDisplay(); // Inisialisasi tampilan timer
  }

  // --- Stopwatch Functions ---
  void _startStopwatch() {
    _stopwatch.start();
    _stopwatchTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      setState(() {
        _stopwatchDisplay = _formatDuration(_stopwatch.elapsed);
      });
    });
  }

  void _stopStopwatch() {
    _stopwatch.stop();
    _stopwatchTimer?.cancel();
  }

  void _resetStopwatch() {
    _stopwatch.reset();
    _stopwatch.stop();
    _stopwatchTimer?.cancel();
    setState(() {
      _stopwatchDisplay = '00:00:00.00';
      _laps.clear();
    });
  }

  void _recordLap() {
    setState(() {
      _laps.add(_formatDuration(_stopwatch.elapsed));
    });
  }

  // --- Timer Functions ---
  void _setTimerDuration() async {
    final Duration? picked = await showDurationPicker(
      context: context,
      initialTime: _initialDuration,
    );
    if (picked != null) {
      setState(() {
        _initialDuration = picked;
        _currentDuration = picked;
        _updateTimerDisplay();
        _isTimerRunning = false; // Pastikan timer tidak berjalan saat durasi diubah
        _countdownTimer?.cancel(); // Hentikan timer sebelumnya jika ada
      });
    }
  }

  void _startTimer() {
    if (_isTimerRunning) return; // Prevent starting if already running
    if (_currentDuration.inSeconds <= 0) {
      _currentDuration = _initialDuration; // Reset to initial if already finished
      _updateTimerDisplay();
    }

    setState(() {
      _isTimerRunning = true;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentDuration.inSeconds > 0) {
        setState(() {
          _currentDuration = _currentDuration - const Duration(seconds: 1);
          _updateTimerDisplay();
        });
      } else {
        _countdownTimer?.cancel();
        setState(() {
          _isTimerRunning = false;
          // Optionally show a notification or play a sound when timer finishes
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Waktu habis!')),
          );
        });
      }
    });
  }

  void _pauseTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
    });
  }

  void _resetTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _currentDuration = _initialDuration;
      _updateTimerDisplay();
    });
  }

  // Helper untuk format durasi
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    String milliseconds = twoDigits((duration.inMilliseconds.remainder(1000) / 10).floor());
    return "$hours:$minutes:$seconds.${milliseconds}";
  }

  void _updateTimerDisplay() {
    _timerDisplay = _formatDuration(
        Duration(hours: _currentDuration.inHours, minutes: _currentDuration.inMinutes.remainder(60), seconds: _currentDuration.inSeconds.remainder(60)));
  }

  @override
  void dispose() {
    _stopwatchTimer?.cancel();
    _countdownTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stopwatch & Timer'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Stopwatch', icon: Icon(Icons.timer_outlined)),
            Tab(text: 'Timer', icon: Icon(Icons.alarm)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // --- Stopwatch UI ---
          Column(
            children: <Widget>[
              const SizedBox(height: 50),
              Text(
                _stopwatchDisplay,
                style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  FloatingActionButton(
                    heroTag: "stopwatch_start_stop",
                    onPressed: _stopwatch.isRunning ? _stopStopwatch : _startStopwatch,
                    backgroundColor: _stopwatch.isRunning ? Colors.red : Colors.green,
                    child: Icon(_stopwatch.isRunning ? Icons.pause : Icons.play_arrow),
                  ),
                  FloatingActionButton(
                    heroTag: "stopwatch_reset",
                    onPressed: _resetStopwatch,
                    backgroundColor: Colors.blueGrey,
                    child: const Icon(Icons.refresh),
                  ),
                  FloatingActionButton(
                    heroTag: "stopwatch_lap",
                    onPressed: _stopwatch.isRunning ? _recordLap : null,
                    backgroundColor: _stopwatch.isRunning ? Colors.orange : Colors.grey,
                    child: const Icon(Icons.flag),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Expanded(
                child: ListView.builder(
                  itemCount: _laps.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(
                        'Lap ${index + 1}: ${_laps[index]}',
                        style: const TextStyle(fontSize: 18),
                      ),
                      leading: const Icon(Icons.fiber_manual_record, size: 16),
                    );
                  },
                ),
              ),
            ],
          ),

          // --- Timer UI ---
          Column(
            children: <Widget>[
              const SizedBox(height: 50),
              Text(
                _timerDisplay,
                style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  FloatingActionButton(
                    heroTag: "timer_start_pause",
                    onPressed: _isTimerRunning ? _pauseTimer : _startTimer,
                    backgroundColor: _isTimerRunning ? Colors.red : Colors.green,
                    child: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow),
                  ),
                  FloatingActionButton(
                    heroTag: "timer_reset",
                    onPressed: _resetTimer,
                    backgroundColor: Colors.blueGrey,
                    child: const Icon(Icons.refresh),
                  ),
                  FloatingActionButton(
                    heroTag: "timer_set",
                    onPressed: _setTimerDuration,
                    backgroundColor: Colors.purple,
                    child: const Icon(Icons.alarm_add),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Tambahan: Informasi durasi awal
              Text(
                'Durasi Awal: ${_formatDuration(_initialDuration)}',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Widget untuk memilih durasi (contoh sederhana, bisa dikembangkan)
Future<Duration?> showDurationPicker({
  required BuildContext context,
  required Duration initialTime,
}) async {
  Duration? pickedDuration;

  await showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      int minutes = initialTime.inMinutes.remainder(60);
      int seconds = initialTime.inSeconds.remainder(60);
      int hours = initialTime.inHours;

      return AlertDialog(
        title: const Text('Set Timer Duration'),
        content: StatefulBuilder( // Menggunakan StatefulBuilder untuk memperbarui state di dalam dialog
          builder: (BuildContext context, StateSetter setStateDialog) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTimePickerColumn(
                      context, 'Jam', hours, (value) {
                      setStateDialog(() => hours = value);
                    },
                    ),
                    const Text(' : ', style: TextStyle(fontSize: 24)),
                    _buildTimePickerColumn(
                      context, 'Menit', minutes, (value) {
                      setStateDialog(() => minutes = value);
                    },
                    ),
                    const Text(' : ', style: TextStyle(fontSize: 24)),
                    _buildTimePickerColumn(
                      context, 'Detik', seconds, (value) {
                      setStateDialog(() => seconds = value);
                    },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    pickedDuration = Duration(hours: hours, minutes: minutes, seconds: seconds);
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        ),
      );
    },
  );
  return pickedDuration;
}

Widget _buildTimePickerColumn(BuildContext context, String label, int currentValue, Function(int) onChanged) {
  return Column(
    children: [
      Text(label, style: const TextStyle(fontSize: 16)),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () => onChanged(currentValue > 0 ? currentValue - 1 : 0),
          ),
          Text(
            currentValue.toString().padLeft(2, '0'),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => onChanged(currentValue + 1),
          ),
        ],
      ),
    ],
  );
}
