import 'dart:typed_data';

import 'midi_device.dart';

Uint8List readWaveform() => Uint8List(0);

void closeAudio() {}

Future<List<MidiInputDevice>> requestMidiAccess() => Future.error(
  UnsupportedError('MIDI input is not supported on this platform.'),
);

void selectMidiInput(
  String? id,
  void Function(int midi, bool pressed) onNote,
) {}

String? readProgress() => null;

void writeProgress(String value) {}

void playNote(
  int midi,
  String waveform,
  double volume,
  double attack,
  double decay,
  double sustain,
  double cutoff,
  double resonance,
  double subMix,
  double detune,
  double delayMix,
  String voiceMode,
  double glide,
) {}

void releaseNote(int midi, double release) {}

void playMetronomeClick(bool downbeat) {}

void setAudioParams(
  double cutoff,
  double resonance,
  double volume,
  double delayMix,
) {}

void panicAudio() {}
