import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'midi_device.dart';
import 'platform_services.dart'
    if (dart.library.js_interop) 'platform_services_web.dart'
    as platform;

const _bg = Color(0xff0a0b0e);
const _panel = Color(0xff14171e);
const _border = Color(0xff2a2f3d);
const _cyan = Color(0xff06b6d4);
const _amber = Color(0xfff59e0b);
const _green = Color(0xff10b981);
const _purple = Color(0xffa855f7);
const _notes = [
  'C',
  'C#',
  'D',
  'Eb',
  'E',
  'F',
  'F#',
  'G',
  'Ab',
  'A',
  'Bb',
  'B',
];
const _qwertyLabels = [
  'Z',
  'S',
  'X',
  'D',
  'C',
  'V',
  'G',
  'B',
  'H',
  'N',
  'J',
  'M',
  'Q',
  '2',
  'W',
  '3',
  'E',
  'R',
  '5',
  'T',
  '6',
  'Y',
  '7',
  'U',
  'I',
  '9',
  'O',
  '0',
  'P',
  '[',
];

class ScaleInfo {
  const ScaleInfo(
    this.name,
    this.intervals,
    this.degrees,
    this.mood,
    this.fingers,
  );

  final String name;
  final List<int> intervals;
  final List<String> degrees;
  final String mood;
  final List<int> fingers;
}

const _scales = <String, ScaleInfo>{
  'major': ScaleInfo(
    'Major (Ionian)',
    [0, 2, 4, 5, 7, 9, 11],
    ['1', '2', '3', '4', '5', '6', '7'],
    'Bright, consonant, happy & foundational',
    [1, 2, 3, 1, 2, 3, 4],
  ),
  'natural_minor': ScaleInfo(
    'Natural Minor (Aeolian)',
    [0, 2, 3, 5, 7, 8, 10],
    ['1', '2', 'b3', '4', '5', 'b6', 'b7'],
    'Melancholic, cinematic, emotional',
    [1, 2, 3, 1, 2, 3, 4],
  ),
  'harmonic_minor': ScaleInfo(
    'Harmonic Minor',
    [0, 2, 3, 5, 7, 8, 11],
    ['1', '2', 'b3', '4', '5', 'b6', '7'],
    'Classical tension, exotic leading tone',
    [1, 2, 3, 1, 2, 3, 4],
  ),
  'melodic_minor': ScaleInfo(
    'Melodic Minor (Jazz)',
    [0, 2, 3, 5, 7, 9, 11],
    ['1', '2', 'b3', '4', '5', '6', '7'],
    'Sophisticated modern jazz minor',
    [1, 2, 3, 1, 2, 3, 4],
  ),
  'dorian': ScaleInfo(
    'Dorian Mode',
    [0, 2, 3, 5, 7, 9, 10],
    ['1', '2', 'b3', '4', '5', '6', 'b7'],
    'Soulful, groovy minor with raised 6th',
    [1, 2, 3, 1, 2, 3, 4],
  ),
  'phrygian': ScaleInfo(
    'Phrygian Mode',
    [0, 1, 3, 5, 7, 8, 10],
    ['1', 'b2', 'b3', '4', '5', 'b6', 'b7'],
    'Dark, Spanish/Flamenco, intense electronic',
    [1, 2, 3, 1, 2, 3, 4],
  ),
  'lydian': ScaleInfo(
    'Lydian Mode',
    [0, 2, 4, 6, 7, 9, 11],
    ['1', '2', '3', '#4', '5', '6', '7'],
    'Dreamy, wonder, sci-fi & floating (#4)',
    [1, 2, 3, 4, 1, 2, 3],
  ),
  'mixolydian': ScaleInfo(
    'Mixolydian Mode',
    [0, 2, 4, 5, 7, 9, 10],
    ['1', '2', '3', '4', '5', '6', 'b7'],
    'Upbeat funk, rock, dominant synth vamps',
    [1, 2, 3, 1, 2, 3, 4],
  ),
  'locrian': ScaleInfo(
    'Locrian Mode',
    [0, 1, 3, 5, 6, 8, 10],
    ['1', 'b2', 'b3', '4', 'b5', 'b6', 'b7'],
    'Unstable, dissonant, diminished tension',
    [1, 2, 3, 1, 2, 3, 4],
  ),
  'minor_pentatonic': ScaleInfo(
    'Minor Pentatonic',
    [0, 3, 5, 7, 10],
    ['1', 'b3', '4', '5', 'b7'],
    'Universal synth solo & bassline staple',
    [1, 2, 3, 1, 2],
  ),
  'major_pentatonic': ScaleInfo(
    'Major Pentatonic',
    [0, 2, 4, 7, 9],
    ['1', '2', '3', '5', '6'],
    'Open, uplifting, folk & ambient melodies',
    [1, 2, 3, 1, 2],
  ),
  'blues': ScaleInfo(
    'Blues Scale',
    [0, 3, 5, 6, 7, 10],
    ['1', 'b3', '4', 'b5', '5', 'b7'],
    'Gritty, expressive, classic clav/lead',
    [1, 2, 3, 4, 1, 2],
  ),
  'phrygian_dominant': ScaleInfo(
    'Phrygian Dominant',
    [0, 1, 4, 5, 7, 8, 10],
    ['1', 'b2', '3', '4', '5', 'b6', 'b7'],
    'Exotic desert, Middle Eastern, psytrance',
    [1, 2, 3, 1, 2, 3, 4],
  ),
  'whole_tone': ScaleInfo(
    'Whole Tone',
    [0, 2, 4, 6, 8, 10],
    ['1', '2', '3', '#4', '#5', 'b7'],
    'Suspended dream sequence, symmetrical',
    [1, 2, 3, 1, 2, 3],
  ),
  'diminished': ScaleInfo(
    'Half-Whole Diminished',
    [0, 1, 3, 4, 6, 7, 9, 10],
    ['1', 'b2', 'b3', '3', '#4', '5', '6', 'b7'],
    'Symmetrical jazz fusion & sci-fi mystery',
    [1, 2, 3, 1, 2, 3, 4, 5],
  ),
};

void main() => runApp(const ScaleADayApp());

class ScaleADayApp extends StatelessWidget {
  const ScaleADayApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MAGNESIUM // Studio Synthesizer & Scale Trainer',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _bg,
      colorScheme: const ColorScheme.dark(
        primary: _cyan,
        secondary: _amber,
        surface: _panel,
      ),
      fontFamily: 'Roboto',
      useMaterial3: true,
    ),
    home: const SynthTrainerPage(),
  );
}

class SynthTrainerPage extends StatefulWidget {
  const SynthTrainerPage({super.key});

  @override
  State<SynthTrainerPage> createState() => _SynthTrainerPageState();
}

class _SynthTrainerPageState extends State<SynthTrainerPage>
    with SingleTickerProviderStateMixin {
  int root = 0;
  String scaleKey = 'major';
  String labelMode = 'all';
  String voiceMode = 'poly';
  String waveform = 'sawtooth';
  bool scaleLock = false;
  bool seventhChords = false;
  bool arpRunning = false;
  bool metronomeClick = false;
  bool drillActive = false;
  bool randomDrill = false;
  String arpPattern = 'updown';
  int bpm = 110;
  int lastMidi = -1;
  int? drillTarget;
  int drillReps = 0;
  int drillCursor = 0;
  List<int> drillSequence = [];
  int? chordPreview;
  int streak = 0;
  bool practicedToday = false;
  late final String todayKey;
  late final int dailyRoot;
  late final String dailyScale;
  Timer? _arpTimer;
  Timer? _noteTimer;
  final Set<int> _activeNotes = {};
  final Set<int> _midiActiveNotes = {};
  List<MidiInputDevice> _midiDevices = [];
  String? _selectedMidiId;
  String _midiStatus =
      'Scan in Chrome or Edge and grant access to list devices.';
  bool _midiLoading = false;
  final FocusNode _keyboardFocus = FocusNode();
  late final AnimationController _scopeController;

  double glide = 45;
  double sub = 35;
  double detune = 12;
  double cutoff = 2800;
  double resonance = 3.5;
  double delay = 25;
  double volume = 80;
  double attack = .015;
  double decay = .25;
  double sustain = .65;
  double release = .35;

  ScaleInfo get scale => _scales[scaleKey]!;
  String get rootName => _notes[root];
  String get dateLabel => todayKey;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    todayKey = _dateKey(now);
    final seed = now.year * 10000 + now.month * 100 + now.day;
    dailyRoot = (seed * 7 + 3) % 12;
    dailyScale = _scales.keys.elementAt((seed * 13 + 5) % _scales.length);
    root = dailyRoot;
    scaleKey = dailyScale;
    _loadProgress();
    _scopeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _arpTimer?.cancel();
    _noteTimer?.cancel();
    _scopeController.dispose();
    _keyboardFocus.dispose();
    platform.selectMidiInput(null, (_, _) {});
    platform.closeAudio();
    super.dispose();
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  void _loadProgress() {
    try {
      final raw = platform.readProgress();
      if (raw == null) return;
      final progress = jsonDecode(raw) as Map<String, dynamic>;
      final dates = (progress['practicedDates'] as List<dynamic>? ?? [])
          .map((entry) => entry.toString())
          .toList();
      streak = (progress['streak'] as num?)?.toInt() ?? 0;
      practicedToday = dates.contains(todayKey);
    } on FormatException {
      streak = 0;
      practicedToday = false;
    } on TypeError {
      streak = 0;
      practicedToday = false;
    }
  }

  void _markPracticed() {
    if (practicedToday) return;
    final yesterday = _dateKey(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    try {
      final raw = platform.readProgress();
      final progress = raw == null
          ? <String, dynamic>{
              'streak': 0,
              'lastDate': '',
              'practicedDates': <String>[],
            }
          : jsonDecode(raw) as Map<String, dynamic>;
      final dates = (progress['practicedDates'] as List<dynamic>? ?? [])
          .map((entry) => entry.toString())
          .toList();
      if (!dates.contains(todayKey)) dates.add(todayKey);
      final lastDate = progress['lastDate']?.toString() ?? '';
      final newStreak = lastDate == todayKey
          ? (progress['streak'] as num?)?.toInt() ?? 1
          : lastDate == yesterday
          ? ((progress['streak'] as num?)?.toInt() ?? 0) + 1
          : 1;
      platform.writeProgress(
        jsonEncode({
          'streak': newStreak,
          'lastDate': todayKey,
          'practicedDates': dates,
        }),
      );
      setState(() {
        streak = newStreak;
        practicedToday = true;
      });
    } on Object catch (error) {
      debugPrint('Unable to save practice progress: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save today’s practice progress.'),
          ),
        );
      }
    }
  }

  bool _isBlack(int midi) => const {1, 3, 6, 8, 10}.contains(midi % 12);
  String _noteName(int midi) => '${_notes[midi % 12]}${midi ~/ 12 - 1}';

  int? _degreeIndex(int midi) {
    final interval = (midi - root + 120) % 12;
    final index = scale.intervals.indexOf(interval);
    return index < 0 ? null : index;
  }

  List<int> _scaleNotes({int octaves = 2}) {
    final start = 48 + root;
    final result = <int>[];
    for (var octave = 0; octave < octaves; octave++) {
      for (final interval in scale.intervals) {
        final midi = start + octave * 12 + interval;
        if (midi >= 48 && midi < 78) result.add(midi);
      }
    }
    final topRoot = start + octaves * 12;
    if (topRoot < 78) result.add(topRoot);
    if (result.length < scale.intervals.length + 1) {
      return [
        for (var midi = 48; midi < 78; midi++)
          if (_degreeIndex(midi) != null) midi,
      ];
    }
    return result;
  }

  void _pressNote(int midi) {
    if (scaleLock && _degreeIndex(midi) == null) return;
    setState(() {
      _activeNotes.add(midi);
      lastMidi = midi;
    });
    _playTone(midi);
    if (drillActive && midi == drillTarget) _advanceDrill();
  }

  void _releaseNote(int midi) {
    setState(() => _activeNotes.remove(midi));
    platform.releaseNote(midi, release);
  }

  Future<void> _scanMidiInputs() async {
    setState(() {
      _midiLoading = true;
      _midiStatus = 'Requesting MIDI access...';
    });
    try {
      final devices = await platform.requestMidiAccess();
      if (!mounted) return;
      final selectedStillAvailable = devices.any(
        (device) => device.id == _selectedMidiId,
      );
      setState(() {
        _midiDevices = devices;
        _midiLoading = false;
        if (!selectedStillAvailable) _selectedMidiId = null;
        _midiStatus = devices.isEmpty
            ? 'No MIDI inputs found. Connect a keyboard, then scan again.'
            : selectedStillAvailable
            ? 'MIDI keyboard connected.'
            : 'Choose a MIDI input to play.';
      });
      if (selectedStillAvailable) {
        platform.selectMidiInput(_selectedMidiId, _handleMidiNote);
      } else {
        _clearMidiNotes();
        platform.selectMidiInput(null, _handleMidiNote);
      }
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _midiLoading = false;
        _midiStatus = 'Could not access MIDI: $error';
      });
    }
  }

  void _selectMidiInput(String? id) {
    try {
      _clearMidiNotes();
      platform.selectMidiInput(id, _handleMidiNote);
      setState(() {
        _selectedMidiId = id;
        _midiStatus = id == null
            ? 'No MIDI input selected.'
            : 'MIDI keyboard connected.';
      });
    } on Object catch (error) {
      setState(() => _midiStatus = 'Could not select MIDI input: $error');
    }
  }

  void _handleMidiNote(int midi, bool pressed) {
    if (!mounted) return;
    if (pressed) {
      if (scaleLock && _degreeIndex(midi) == null) return;
      if (_midiActiveNotes.add(midi)) _pressNote(midi);
    } else if (_midiActiveNotes.remove(midi)) {
      _releaseNote(midi);
    }
  }

  void _clearMidiNotes() {
    for (final midi in _midiActiveNotes.toList()) {
      _releaseNote(midi);
    }
    _midiActiveNotes.clear();
  }

  void _playTone(int midi) {
    platform.playNote(
      midi,
      waveform,
      volume / 100,
      attack,
      decay,
      sustain,
      cutoff,
      resonance,
      sub / 100,
      detune,
      delay / 100,
      voiceMode,
      glide,
    );
  }

  void _setScale({int? nextRoot, String? nextScale}) {
    setState(() {
      if (nextRoot != null) root = nextRoot;
      if (nextScale != null) scaleKey = nextScale;
      if (drillActive) _buildDrill();
    });
  }

  void _loadToday() => _setScale(nextRoot: dailyRoot, nextScale: dailyScale);

  void _randomize() {
    final random = math.Random();
    _setScale(
      nextRoot: random.nextInt(12),
      nextScale: _scales.keys.elementAt(random.nextInt(_scales.length)),
    );
  }

  void _setVoiceMode(String mode) {
    _panic();
    setState(() => voiceMode = mode);
  }

  void _panic() {
    _arpTimer?.cancel();
    _noteTimer?.cancel();
    setState(() {
      arpRunning = false;
      _activeNotes.clear();
      _midiActiveNotes.clear();
      chordPreview = null;
    });
    platform.panicAudio();
  }

  void _toggleArp() {
    if (arpRunning) {
      _arpTimer?.cancel();
      setState(() => arpRunning = false);
      return;
    }
    setState(() {
      arpRunning = true;
    });
    var step = -1;
    var direction = 1;
    void playStep() {
      if (!mounted || !arpRunning) return;
      final notes = _scaleNotes();
      if (notes.isEmpty) return;
      if (arpPattern == 'random') {
        step = math.Random().nextInt(notes.length);
      } else if (arpPattern == 'down') {
        step = (step - 1 + notes.length) % notes.length;
      } else if (arpPattern == 'up') {
        step = (step + 1) % notes.length;
      } else {
        step += direction;
        if (step >= notes.length - 1) {
          step = notes.length - 1;
          direction = -1;
        } else if (step <= 0) {
          step = 0;
          direction = 1;
        }
      }
      final midi = notes[step];
      if (metronomeClick) platform.playMetronomeClick(step == 0);
      _pressNote(midi);
      Timer(Duration(milliseconds: ((60 / bpm / 2) * 780).round()), () {
        if (mounted && _activeNotes.contains(midi)) _releaseNote(midi);
      });
    }

    playStep();
    _arpTimer = Timer.periodic(
      Duration(milliseconds: (60000 / bpm / 2).round()),
      (_) => playStep(),
    );
  }

  void _toggleDrill() {
    setState(() {
      drillActive = !drillActive;
      drillReps = 0;
      if (drillActive) {
        _buildDrill();
      } else {
        drillTarget = null;
        drillSequence = [];
      }
    });
  }

  void _buildDrill() {
    final ascending = _scaleNotes(octaves: 1);
    if (ascending.isEmpty) return;
    drillSequence = randomDrill
        ? List.generate(
            8,
            (_) => ascending[math.Random().nextInt(ascending.length)],
          )
        : [
            ...ascending,
            ...ascending.take(ascending.length - 1).toList().reversed,
          ];
    drillCursor = 0;
    drillTarget = drillSequence.first;
  }

  void _advanceDrill() {
    if (drillSequence.isEmpty) return;
    setState(() {
      drillCursor++;
      if (drillCursor >= drillSequence.length) {
        drillReps++;
        if (drillReps >= 3) {
          _markPracticed();
        }
        _buildDrill();
      } else {
        drillTarget = drillSequence[drillCursor];
      }
    });
  }

  List<int> _chordNotes(int degree) {
    final intervals = scale.intervals;
    final rootInterval = intervals[degree];
    int stacked(int offset) {
      final index = degree + offset;
      return intervals[index % intervals.length] +
          (index >= intervals.length ? 12 : 0) -
          rootInterval;
    }

    var midiRoot = 48 + root + rootInterval;
    if (midiRoot > 62) midiRoot -= 12;
    return [
      midiRoot,
      midiRoot + stacked(2),
      midiRoot + stacked(4),
      if (seventhChords) midiRoot + stacked(6),
    ];
  }

  String _chordQuality(int degree) {
    final intervals = scale.intervals;
    final rootInterval = intervals[degree];
    int stacked(int offset) {
      final index = degree + offset;
      return intervals[index % intervals.length] +
          (index >= intervals.length ? 12 : 0) -
          rootInterval;
    }

    final third = stacked(2);
    final fifth = stacked(4);
    var quality = '';
    if (third == 3 && fifth == 7) {
      quality = 'm';
    } else if (third == 3 && fifth == 6) {
      quality = 'dim';
    } else if (third == 4 && fifth == 8) {
      quality = 'aug';
    }
    if (seventhChords) {
      final seventh = stacked(6);
      if (quality.isEmpty && seventh == 11) return 'maj7';
      if (quality.isEmpty && seventh == 10) return '7';
      if (quality == 'm' && seventh == 10) return 'm7';
      if (quality == 'dim' && seventh == 10) return 'm7b5';
      return '${quality}7';
    }
    return quality;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final key = event.logicalKey.keyLabel.toLowerCase();
    final midi = switch (key) {
      'z' => 48,
      's' => 49,
      'x' => 50,
      'd' => 51,
      'c' => 52,
      'v' => 53,
      'g' => 54,
      'b' => 55,
      'h' => 56,
      'n' => 57,
      'j' => 58,
      'm' => 59,
      ',' => 60,
      'l' => 61,
      '.' => 62,
      ';' => 63,
      '/' => 64,
      'q' => 60,
      '2' => 61,
      'w' => 62,
      '3' => 63,
      'e' => 64,
      'r' => 65,
      '5' => 66,
      't' => 67,
      '6' => 68,
      'y' => 69,
      '7' => 70,
      'u' => 71,
      'i' => 72,
      '9' => 73,
      'o' => 74,
      '0' => 75,
      'p' => 76,
      '[' => 77,
      _ => null,
    };
    if (midi == null) return KeyEventResult.ignored;
    if (event is KeyDownEvent) {
      if (!_activeNotes.contains(midi)) _pressNote(midi);
      return KeyEventResult.handled;
    }
    if (event is KeyUpEvent) {
      _releaseNote(midi);
      return KeyEventResult.handled;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      focusNode: _keyboardFocus,
      onKeyEvent: _onKey,
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 900;
              return SingleChildScrollView(
                padding: EdgeInsets.all(compact ? 10 : 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1440),
                    child: Container(
                      padding: EdgeInsets.all(compact ? 12 : 20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xff1b1e26), Color(0xff12141a)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xff2d3240)),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black87,
                            blurRadius: 36,
                            offset: Offset(0, 20),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(compact),
                          const SizedBox(height: 16),
                          _buildMidiInput(),
                          const SizedBox(height: 12),
                          if (compact) ...[
                            _buildOled(),
                            const SizedBox(height: 12),
                            _buildExplorer(),
                            const SizedBox(height: 12),
                            _buildRack(compact),
                          ] else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    children: [
                                      _buildOled(),
                                      const SizedBox(height: 12),
                                      _buildExplorer(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(flex: 8, child: _buildRack(compact)),
                              ],
                            ),
                          const SizedBox(height: 12),
                          _buildChords(),
                          const SizedBox(height: 12),
                          _buildKeyboard(),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool compact) => Container(
    padding: const EdgeInsets.only(bottom: 14),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xff252a35))),
    ),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/magnesium-logo.jpg',
              width: 64,
              height: 64,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 11),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'MAGNESIUM',
                      style: _mono(
                        18,
                        color: Colors.white,
                        weight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _tag('PRO-8', _cyan),
                  ],
                ),
                const Text(
                  'Polyphonic / Monophonic Scale & Harmony Studio',
                  style: TextStyle(color: Color(0xff94a3b8), fontSize: 11),
                ),
              ],
            ),
            if (!compact) ...[
              const SizedBox(width: 24),
              _tag('●  AUDIO READY', _green),
            ],
          ],
        ),
        _dailyAssignment(compact),
      ],
    ),
  );

  Widget _buildMidiInput() => _panelCard(
    child: Wrap(
      spacing: 12,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MIDI INPUT',
              style: _mono(
                10,
                color: _cyan,
                weight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 330,
              child: Text(
                _midiStatus,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xff94a3b8), fontSize: 11),
              ),
            ),
          ],
        ),
        SizedBox(
          width: 260,
          child: DropdownButtonFormField<String>(
            initialValue: _selectedMidiId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'USB MIDI DEVICE',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            hint: const Text('Scan for devices'),
            items: _midiDevices
                .map(
                  (device) => DropdownMenuItem(
                    value: device.id,
                    child: Text(device.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: _midiDevices.isEmpty ? null : _selectMidiInput,
          ),
        ),
        _smallButton(
          _midiLoading ? 'SCANNING...' : 'SCAN / CONNECT',
          _cyan,
          _midiLoading ? () {} : _scanMidiInputs,
          active: _midiLoading,
        ),
      ],
    ),
  );

  Widget _dailyAssignment(bool compact) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xff0d1017),
      border: Border.all(color: _border.withValues(alpha: .8)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "TODAY'S ASSIGNMENT  ·  $dateLabel",
              style: _mono(
                9,
                color: _amber,
                weight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${_notes[dailyRoot]} ${_scales[dailyScale]!.name}',
              style: _mono(13, color: Colors.white, weight: FontWeight.w700),
            ),
          ],
        ),
        _smallButton('Load Today', _amber, _loadToday),
        _smallButton('Random', const Color(0xff64748b), _randomize),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xff07090d),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _border),
          ),
          child: Text(
            '🔥 $streak  DAY STREAK',
            style: _mono(10, color: Colors.white, weight: FontWeight.w700),
          ),
        ),
        _smallButton(
          practicedToday ? '✓ Practiced' : 'Mark Practiced',
          _green,
          _markPracticed,
          active: practicedToday,
        ),
      ],
    ),
  );

  Widget _buildOled() => Container(
    height: 192,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xff06090e),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xff222834), width: 2),
      boxShadow: [
        BoxShadow(
          color: _cyan.withValues(alpha: .08),
          blurRadius: 16,
          spreadRadius: 1,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ACTIVE SCALE MATRIX',
                    style: _mono(9, color: _cyan, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$rootName ${scale.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _mono(
                      21,
                      color: Colors.white,
                      weight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Intervals: ${scale.degrees.join(' - ')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _mono(10, color: const Color(0xff67e8f9)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _tag(
                  lastMidi < 0
                      ? 'NOTE: --'
                      : '${_noteName(lastMidi)} (${_degreeIndex(lastMidi) == null ? 'Out' : scale.degrees[_degreeIndex(lastMidi)!]})',
                  _cyan,
                ),
                const SizedBox(height: 5),
                SizedBox(
                  width: 130,
                  child: Text(
                    scale.mood,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xff94a3b8),
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: AnimatedBuilder(
            animation: _scopeController,
            builder: (context, child) => CustomPaint(
              painter: _ScopePainter(
                platform.readWaveform(),
                voiceMode == 'mono' ? _amber : _cyan,
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: Text(
                scale.intervals
                    .map((interval) => _notes[(root + interval) % 12])
                    .join('  •  '),
                overflow: TextOverflow.ellipsis,
                style: _mono(
                  10,
                  color: const Color(0xfffbbf24),
                  weight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              voiceMode == 'mono' ? 'MONO GLIDE' : 'POLY 8V',
              style: _mono(
                9,
                color: voiceMode == 'mono' ? _amber : _cyan,
                weight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildExplorer() => _panelCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'SCALE EXPLORER',
                style: _mono(
                  11,
                  color: const Color(0xffcbd5e1),
                  weight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
            _check(
              'SCALE LOCK',
              scaleLock,
              (value) => setState(() => scaleLock = value),
              color: _cyan,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: 150,
              child: _dropdown<int>(
                'ROOT KEY',
                root,
                List.generate(
                  12,
                  (i) => DropdownMenuItem(value: i, child: Text(_notes[i])),
                ),
                (value) {
                  if (value != null) _setScale(nextRoot: value);
                },
              ),
            ),
            SizedBox(
              width: 260,
              child: _dropdown<String>(
                'SCALE / MODE',
                scaleKey,
                _scales.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(
                          entry.value.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                (value) {
                  if (value != null) _setScale(nextScale: value);
                },
              ),
            ),
          ],
        ),
        const Divider(height: 20, color: Color(0xff29303c)),
        Wrap(
          spacing: 5,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'KEY LABELS:',
              style: _mono(9, color: const Color(0xff94a3b8)),
            ),
            _modeChip('Notes + Degrees', 'all'),
            _modeChip('Degrees', 'degrees'),
            _modeChip('QWERTY', 'qwerty'),
          ],
        ),
      ],
    ),
  );

  Widget _buildRack(bool compact) => Column(
    children: [
      _panelCard(
        child: Column(
          children: [
            if (compact)
              Column(
                children: [
                  _voiceControls(),
                  const Divider(height: 20, color: Color(0xff29303c)),
                  _filterControls(),
                  const Divider(height: 20, color: Color(0xff29303c)),
                  _adsrControls(),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _voiceControls()),
                  const SizedBox(width: 13),
                  const SizedBox(
                    height: 180,
                    child: VerticalDivider(color: Color(0xff29303c)),
                  ),
                  Expanded(child: _filterControls()),
                  const SizedBox(width: 13),
                  const SizedBox(
                    height: 180,
                    child: VerticalDivider(color: Color(0xff29303c)),
                  ),
                  Expanded(child: _adsrControls()),
                ],
              ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      if (compact)
        Column(
          children: [
            _arpControls(),
            const SizedBox(height: 10),
            _drillControls(),
          ],
        )
      else
        Row(
          children: [
            Expanded(child: _arpControls()),
            const SizedBox(width: 10),
            Expanded(child: _drillControls()),
          ],
        ),
    ],
  );

  Widget _voiceControls() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '1. VOICE & OSC',
            style: _mono(10, color: _amber, weight: FontWeight.w700),
          ),
          Row(
            children: [
              _voiceButton('MONO', 'mono'),
              _voiceButton('POLY', 'poly'),
            ],
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('WAVEFORM', style: _mono(9, color: const Color(0xff94a3b8))),
          Text(waveform.toUpperCase(), style: _mono(9, color: _cyan)),
        ],
      ),
      const SizedBox(height: 5),
      Row(
        children: [
          _waveButton('sawtooth', 'SAW', '/|/|'),
          _waveButton('square', 'SQR', '|_|-'),
          _waveButton('triangle', 'TRI', '/\\'),
          _waveButton('sine', 'SIN', '~'),
        ],
      ),
      const SizedBox(height: 10),
      _slider(
        'GLIDE / PORTAMENTO',
        glide,
        0,
        350,
        '${glide.round()} ms',
        _amber,
        (v) => setState(() => glide = v),
      ),
      Row(
        children: [
          Expanded(
            child: _slider(
              'SUB OSC (-1 OCT)',
              sub,
              0,
              100,
              '${sub.round()}%',
              _cyan,
              (v) => setState(() => sub = v),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _slider(
              'UNISON DETUNE',
              detune,
              0,
              50,
              '${detune.round()} ct',
              _cyan,
              (v) => setState(() => detune = v),
            ),
          ),
        ],
      ),
    ],
  );

  Widget _filterControls() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        '2. FILTER (24dB LP) & SPACE',
        style: _mono(10, color: _cyan, weight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      _slider(
        'CUTOFF FREQUENCY',
        cutoff,
        120,
        10000,
        '${cutoff.round()} Hz',
        _cyan,
        (v) {
          setState(() => cutoff = v);
          _updateFilter();
        },
      ),
      _slider(
        'RESONANCE (PEAK)',
        resonance,
        .5,
        16,
        '${resonance.toStringAsFixed(1)} Q',
        _cyan,
        (v) {
          setState(() => resonance = v);
          _updateFilter();
        },
      ),
      Row(
        children: [
          Expanded(
            child: _slider(
              'STEREO DELAY',
              delay,
              0,
              75,
              '${delay.round()}%',
              _purple,
              (v) => setState(() => delay = v),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _slider(
              'MASTER VOL',
              volume,
              0,
              100,
              '${volume.round()}%',
              _green,
              (v) => setState(() => volume = v),
            ),
          ),
        ],
      ),
    ],
  );

  Widget _adsrControls() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        '3. ADSR ENVELOPE',
        style: _mono(10, color: _green, weight: FontWeight.w700),
      ),
      const SizedBox(height: 10),
      _slider(
        'ATTACK',
        attack,
        .005,
        1,
        '${attack.toStringAsFixed(2)}s',
        _green,
        (v) => setState(() => attack = v),
      ),
      _slider(
        'DECAY',
        decay,
        .05,
        1.5,
        '${decay.toStringAsFixed(2)}s',
        _green,
        (v) => setState(() => decay = v),
      ),
      _slider(
        'SUSTAIN',
        sustain,
        0,
        1,
        '${(sustain * 100).round()}%',
        _green,
        (v) => setState(() => sustain = v),
      ),
      _slider(
        'RELEASE',
        release,
        .05,
        2.5,
        '${release.toStringAsFixed(2)}s',
        _green,
        (v) => setState(() => release = v),
      ),
      const Divider(height: 18, color: Color(0xff29303c)),
      Wrap(
        spacing: 4,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('PATCH:', style: _mono(9, color: const Color(0xff94a3b8))),
          _preset('Tobacco', 'tobacco', _amber),
          _preset('Mono Lead', 'lead', _amber),
          _preset('Poly Warm', 'keys', _cyan),
          _preset('Arp Pluck', 'pluck', _green),
        ],
      ),
    ],
  );

  Widget _arpControls() => _panelCard(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _led(arpRunning ? _cyan : const Color(0xff475569)),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                'SCALE AUTO-PLAYER / ARP',
                style: _mono(
                  10,
                  color: const Color(0xffe2e8f0),
                  weight: FontWeight.w700,
                ),
              ),
            ),
            _check(
              'Click',
              metronomeClick,
              (value) => setState(() => metronomeClick = value),
              color: _amber,
            ),
            const SizedBox(width: 5),
            _smallButton(
              arpRunning ? '■ STOP ARP' : '▶ PLAY SCALE',
              arpRunning ? const Color(0xfff43f5e) : _cyan,
              _toggleArp,
            ),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: _slider(
                'TEMPO',
                bpm.toDouble(),
                50,
                200,
                '$bpm BPM',
                _amber,
                (v) {
                  setState(() => bpm = v.round());
                  if (arpRunning) _restartArp();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _dropdown<String>(
                'DIRECTION',
                arpPattern,
                const [
                  DropdownMenuItem(value: 'updown', child: Text('Up & Down')),
                  DropdownMenuItem(value: 'up', child: Text('Ascending Only')),
                  DropdownMenuItem(
                    value: 'down',
                    child: Text('Descending Only'),
                  ),
                  DropdownMenuItem(
                    value: 'random',
                    child: Text('Random Notes'),
                  ),
                ],
                (value) {
                  if (value != null) setState(() => arpPattern = value);
                },
              ),
            ),
          ],
        ),
      ],
    ),
  );

  void _restartArp() {
    _arpTimer?.cancel();
    if (arpRunning) {
      setState(() => arpRunning = false);
      _toggleArp();
    }
  }

  Widget _drillControls() => _panelCard(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'INTERACTIVE SCALE DRILL',
              style: _mono(10, color: _green, weight: FontWeight.w700),
            ),
            _tag('$drillReps / 3 REPS', _green),
            _dropdown<bool>(
              'MODE',
              randomDrill,
              const [
                DropdownMenuItem(value: false, child: Text('Step Run')),
                DropdownMenuItem(
                  value: true,
                  child: Text('Random Degree Quiz'),
                ),
              ],
              (value) {
                if (value != null) {
                  setState(() {
                    randomDrill = value;
                    if (drillActive) _buildDrill();
                  });
                }
              },
            ),
            _smallButton(
              drillActive ? 'STOP DRILL' : 'START DRILL',
              drillActive ? const Color(0xfff43f5e) : _green,
              _toggleDrill,
            ),
          ],
        ),
        const SizedBox(height: 9),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xff090b10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  drillActive && drillTarget != null
                      ? 'Play pulsing key: ${_noteName(drillTarget!)}  (Degree ${scale.degrees[_degreeIndex(drillTarget!) ?? 0]}, Finger ${scale.fingers[_degreeIndex(drillTarget!) ?? 0]})'
                      : 'Press START DRILL to follow the highlighted target keys.',
                  style: _mono(10, color: const Color(0xffcbd5e1)),
                ),
              ),
              Text(
                drillActive && drillTarget != null
                    ? _noteName(drillTarget!)
                    : '--',
                style: _mono(14, color: _green, weight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildChords() {
    final roman = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII'];
    return _panelCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'POLYSYNTH DIATONIC CHORDS   ·   Hold a pad to audition harmony',
                style: _mono(10, color: _purple, weight: FontWeight.w700),
              ),
              _check(
                '7th Chords',
                seventhChords,
                (value) => setState(() => seventhChords = value),
                color: _purple,
              ),
            ],
          ),
          const SizedBox(height: 9),
          LayoutBuilder(
            builder: (context, constraints) {
              final count = constraints.maxWidth > 780
                  ? 7
                  : constraints.maxWidth > 460
                  ? 4
                  : 2;
              final width = (constraints.maxWidth - (count - 1) * 7) / count;
              return Wrap(
                spacing: 7,
                runSpacing: 7,
                children: List.generate(scale.intervals.length, (degree) {
                  final midi = 48 + root + scale.intervals[degree];
                  final pc = (root + scale.intervals[degree]) % 12;
                  final isPreview = chordPreview == degree;
                  return SizedBox(
                    width: width,
                    child: GestureDetector(
                      onTapDown: (_) => _auditionChord(degree),
                      onTapUp: (_) => _stopChord(degree),
                      onTapCancel: () => _stopChord(degree),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isPreview
                              ? _purple.withValues(alpha: .2)
                              : const Color(0xff0b0e14),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isPreview
                                ? _purple
                                : const Color(0xff2b303c),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              roman[degree],
                              style: _mono(
                                9,
                                color: _purple,
                                weight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${_notes[pc]}${_chordQuality(degree)}',
                              style: _mono(
                                13,
                                color: Colors.white,
                                weight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              _noteName(midi),
                              style: _mono(8, color: const Color(0xff64748b)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  void _auditionChord(int degree) {
    final notes = _chordNotes(degree);
    setState(() {
      if (voiceMode == 'mono') voiceMode = 'poly';
      chordPreview = degree;
      _activeNotes.addAll(notes);
    });
    for (final midi in notes) {
      _playTone(midi);
    }
  }

  void _stopChord(int degree) {
    if (chordPreview != degree) return;
    final notes = _chordNotes(degree);
    setState(() {
      chordPreview = null;
      _activeNotes.removeAll(notes);
    });
    for (final midi in notes) {
      _releaseNote(midi);
    }
  }

  Widget _buildKeyboard() {
    const pianoWidth = 1080.0;
    const whiteWidth = pianoWidth / 18;
    final whiteKeys = [
      for (var midi = 48; midi < 78; midi++)
        if (!_isBlack(midi)) midi,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          runSpacing: 7,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Wrap(
              spacing: 15,
              runSpacing: 5,
              children: [
                _legend('Root Note (1)', _amber),
                _legend('Scale Tone (Interval & Fingering)', _cyan),
                _legend('Drill Target', _green),
              ],
            ),
            Wrap(
              spacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'QWERTY: Z-M (LOW) / Q-I (HIGH)',
                  style: _mono(9, color: const Color(0xff94a3b8)),
                ),
                _smallButton(
                  'PANIC / SILENCE',
                  const Color(0xfff43f5e),
                  _panic,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 215,
          decoration: BoxDecoration(
            color: const Color(0xff08090c),
            borderRadius: BorderRadius.circular(9),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                blurRadius: 15,
                spreadRadius: -4,
                blurStyle: BlurStyle.inner,
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: pianoWidth,
              height: double.infinity,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    children: whiteKeys
                        .map(
                          (midi) => SizedBox(
                            width: whiteWidth,
                            child: _pianoKey(midi, false),
                          ),
                        )
                        .toList(),
                  ),
                  for (var midi = 48; midi < 78; midi++)
                    if (_isBlack(midi))
                      Positioned(
                        left:
                            (whiteKeys.where((key) => key < midi).length *
                                whiteWidth) -
                            16,
                        top: 0,
                        width: 32,
                        height: 128,
                        child: _pianoKey(midi, true),
                      ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _pianoKey(int midi, bool black) {
    final index = _degreeIndex(midi);
    final isRoot = index == 0;
    final inScale = index != null;
    final active = _activeNotes.contains(midi);
    final target = drillActive && drillTarget == midi;
    final chordTone =
        chordPreview != null && _chordNotes(chordPreview!).contains(midi);
    Color keyColor;
    if (black) {
      keyColor = isRoot
          ? const Color(0xffb45309)
          : inScale
          ? const Color(0xff0e7490)
          : const Color(0xff16191f);
    } else {
      keyColor = isRoot
          ? const Color(0xfffbbf24)
          : inScale
          ? const Color(0xff67e8f9)
          : const Color(0xfff1f5f9);
    }
    if (scaleLock && !inScale) {
      keyColor = black ? const Color(0xff0d0f14) : const Color(0xff374151);
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _pressNote(midi),
      onTapUp: (_) => _releaseNote(midi),
      onTapCancel: () => _releaseNote(midi),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        margin: black
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 1.2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: black
                ? [
                    Color.lerp(keyColor, Colors.black, inScale ? .75 : .35)!,
                    Color.lerp(keyColor, Colors.black, inScale ? .5 : .15)!,
                    keyColor,
                  ]
                : [
                    Color.lerp(keyColor, Colors.white, .6)!,
                    Color.lerp(keyColor, Colors.white, .3)!,
                    Color.lerp(
                      keyColor,
                      const Color(0xff0891b2),
                      inScale ? .12 : .04,
                    )!,
                  ],
            stops: const [0, .45, 1],
          ),
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(black ? 6 : 8),
          ),
          border: Border.all(
            color: target
                ? _green
                : chordTone
                ? _purple
                : Colors.transparent,
            width: target || chordTone ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Color.lerp(keyColor, Colors.black, .35)!,
              offset: const Offset(0, 5),
            ),
            if (black)
              BoxShadow(
                color: Colors.black.withValues(alpha: .5),
                offset: const Offset(0, 6),
                blurRadius: 6,
              ),
            if (!black)
              BoxShadow(
                color: Colors.black.withValues(alpha: .35),
                offset: const Offset(0, 8),
                blurRadius: 5,
              ),
            if (isRoot)
              BoxShadow(color: _amber.withValues(alpha: .55), blurRadius: 14),
            if (inScale && !isRoot)
              BoxShadow(color: _cyan.withValues(alpha: .24), blurRadius: 10),
            if (active)
              BoxShadow(
                color: Colors.white.withValues(alpha: .8),
                blurRadius: 16,
              ),
            if (target)
              BoxShadow(color: _green.withValues(alpha: .8), blurRadius: 14),
          ],
        ),
        transform: active
            ? (Matrix4.identity()..translateByDouble(0.0, 3.0, 0.0, 1.0))
            : Matrix4.identity(),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: black ? 8 : 10),
            child: inScale
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (labelMode != 'degrees')
                        _keyBadge(
                          labelMode == 'qwerty'
                              ? _qwertyLabels[midi - 48]
                              : _noteName(midi),
                          black,
                          labelMode == 'qwerty',
                        ),
                      if (labelMode == 'all') ...[
                        const SizedBox(height: 4),
                        Text(
                          'F${scale.fingers[index]}',
                          style: TextStyle(
                            color: black
                                ? Colors.white70
                                : const Color(0xff334155),
                            fontSize: 8,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      if (labelMode != 'qwerty')
                        Text(
                          scale.degrees[index],
                          style: TextStyle(
                            color: isRoot
                                ? const Color(0xff78350f)
                                : black
                                ? Colors.white
                                : const Color(0xff164e63),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                    ],
                  )
                : Text(
                    labelMode == 'qwerty'
                        ? _qwertyLabels[midi - 48]
                        : midi % 12 == 0
                        ? _noteName(midi)
                        : '',
                    style: TextStyle(
                      color: black ? Colors.white54 : const Color(0xff64748b),
                      fontSize: 8,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _keyBadge(String text, bool black, bool qwerty) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
    decoration: BoxDecoration(
      color: qwerty
          ? const Color(0xff0f172a)
          : black
          ? const Color(0xff082f49)
          : const Color(0xffcffafe),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: qwerty
            ? _amber
            : black
            ? Colors.white
            : const Color(0xff164e63),
        fontSize: 8,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    String display,
    Color color,
    ValueChanged<double> onChanged,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: _mono(8, color: const Color(0xff94a3b8)),
              ),
            ),
            Text(
              display,
              style: _mono(8, color: color, weight: FontWeight.w600),
            ),
          ],
        ),
        SizedBox(
          height: 24,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: const Color(0xff0d0f14),
              thumbColor: const Color(0xff9ca3af),
              overlayColor: color.withValues(alpha: .16),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _dropdown<T>(
    String label,
    T value,
    List<DropdownMenuItem<T>> items,
    ValueChanged<T?> onChanged,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: _mono(8, color: const Color(0xff94a3b8))),
      const SizedBox(height: 4),
      Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xff080a0f),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: const Color(0xff313746)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            dropdownColor: const Color(0xff11151d),
            style: _mono(10, color: Colors.white),
            iconEnabledColor: const Color(0xff94a3b8),
            items: items,
            onChanged: onChanged,
          ),
        ),
      ),
    ],
  );

  Widget _panelCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(14),
  }) => Container(
    padding: padding,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xff171a21), Color(0xff12151b)],
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xff262b38)),
      boxShadow: const [
        BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 2)),
      ],
    ),
    child: child,
  );

  Widget _tag(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      border: Border.all(color: color.withValues(alpha: .42)),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      text,
      style: _mono(8, color: color, weight: FontWeight.w700),
    ),
  );

  Widget _smallButton(
    String text,
    Color color,
    VoidCallback onPressed, {
    bool active = false,
  }) => Material(
    color: active ? color.withValues(alpha: .8) : color.withValues(alpha: .12),
    borderRadius: BorderRadius.circular(7),
    child: InkWell(
      borderRadius: BorderRadius.circular(7),
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withValues(alpha: active ? .8 : .4)),
        ),
        child: Text(
          text,
          style: _mono(
            9,
            color: active ? Colors.black : color,
            weight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );

  Widget _check(
    String text,
    bool value,
    ValueChanged<bool> onChanged, {
    required Color color,
  }) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 22,
        height: 22,
        child: Checkbox(
          value: value,
          onChanged: (value) => onChanged(value ?? false),
          activeColor: color,
          checkColor: Colors.black,
          side: BorderSide(color: color.withValues(alpha: .55)),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
      const SizedBox(width: 3),
      Text(text, style: _mono(8, color: const Color(0xffcbd5e1))),
    ],
  );

  Widget _modeChip(String label, String value) {
    final selected = labelMode == value;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => setState(() => labelMode = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? _cyan.withValues(alpha: .18)
              : const Color(0xff090c12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? _cyan.withValues(alpha: .55)
                : const Color(0xff29303c),
          ),
        ),
        child: Text(
          label,
          style: _mono(
            8,
            color: selected ? const Color(0xffa5f3fc) : const Color(0xff94a3b8),
          ),
        ),
      ),
    );
  }

  Widget _voiceButton(String label, String value) {
    final selected = voiceMode == value;
    final color = value == 'mono' ? _amber : _cyan;
    return InkWell(
      onTap: () => _setVoiceMode(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color : const Color(0xff080a0f),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: _mono(
            8,
            color: selected ? Colors.black : const Color(0xff94a3b8),
            weight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _waveButton(String value, String label, String glyph) => Expanded(
    child: Padding(
      padding: const EdgeInsets.only(right: 4),
      child: InkWell(
        onTap: () => setState(() => waveform = value),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: waveform == value
                ? _cyan.withValues(alpha: .17)
                : const Color(0xff090c12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: waveform == value ? _cyan : _border),
          ),
          child: Column(
            children: [
              Text(
                glyph,
                style: _mono(
                  10,
                  color: waveform == value ? _cyan : const Color(0xff94a3b8),
                ),
              ),
              Text(
                label,
                style: _mono(
                  7,
                  color: waveform == value ? _cyan : const Color(0xff94a3b8),
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _preset(String label, String preset, Color color) =>
      _smallButton(label, color, () {
        setState(() {
          if (preset == 'tobacco') {
            voiceMode = 'mono';
            waveform = 'sawtooth';
            glide = 350;
            sub = 97;
            detune = 50;
            cutoff = 9719;
            resonance = 13.8;
            delay = 65;
            volume = 80;
            attack = .35;
            decay = 1.07;
            sustain = .75;
            release = 1.48;
          } else if (preset == 'lead') {
            voiceMode = 'mono';
            waveform = 'sawtooth';
            glide = 65;
            cutoff = 3600;
            resonance = 4.5;
            attack = .01;
            decay = .3;
            sustain = .8;
            release = .25;
          } else if (preset == 'keys') {
            voiceMode = 'poly';
            waveform = 'triangle';
            cutoff = 2100;
            resonance = 1.5;
            attack = .03;
            decay = .45;
            sustain = .6;
            release = .6;
          } else {
            voiceMode = 'poly';
            waveform = 'square';
            cutoff = 2900;
            resonance = 5;
            attack = .005;
            decay = .15;
            sustain = .15;
            release = .2;
          }
        });
        _updateFilter();
      });

  Widget _legend(String label, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 11,
        height: 11,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: .45), blurRadius: 5),
          ],
        ),
      ),
      const SizedBox(width: 5),
      Text(label, style: _mono(8, color: const Color(0xffcbd5e1))),
    ],
  );

  Widget _led(Color color) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: color.withValues(alpha: .4), blurRadius: 5)],
    ),
  );

  TextStyle _mono(
    double size, {
    Color color = Colors.white,
    FontWeight weight = FontWeight.w500,
    double letterSpacing = 0,
  }) => TextStyle(
    fontFamily: 'monospace',
    fontSize: size,
    color: color,
    fontWeight: weight,
    letterSpacing: letterSpacing,
  );

  void _updateFilter() {
    platform.setAudioParams(cutoff, resonance, volume / 100, delay / 100);
  }
}

class _ScopePainter extends CustomPainter {
  const _ScopePainter(this.samples, this.color);

  final Uint8List samples;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.height / 2;
    final path = Path();
    if (samples.isEmpty) {
      path
        ..moveTo(0, center)
        ..lineTo(size.width, center);
    } else {
      // Start at a rising zero crossing so the trace stays steady.
      var start = 0;
      final window = samples.length ~/ 2;
      for (var i = 1; i < samples.length - window; i++) {
        if (samples[i - 1] < 128 && samples[i] >= 128) {
          start = i;
          break;
        }
      }
      const gain = 3.0;
      for (var i = 0; i < window; i++) {
        final x = i / (window - 1) * size.width;
        final v = (samples[start + i] - 128) / 128 * gain;
        final y = center - v.clamp(-1.0, 1.0) * size.height * .45;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _ScopePainter oldDelegate) => true;
}
