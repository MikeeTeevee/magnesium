import 'dart:js_interop';
import 'dart:typed_data';

import 'midi_device.dart';

@JS('window.localStorage')
external _WebStorage get _localStorage;

@JS('navigator.requestMIDIAccess')
external JSPromise<_MidiAccess> _requestMidiAccess();

@JS()
extension type _WebStorage(JSObject _) implements JSObject {
  external String? getItem(String key);
  external void setItem(String key, String value);
}

@JS()
extension type _MidiAccess(JSObject _) implements JSObject {
  external _MidiInputMap get inputs;
}

@JS()
extension type _MidiInputMap(JSObject _) implements JSObject {
  external JSIterator<JSAny?> values();
}

@JS('Array.from')
external JSArray<JSAny?> _arrayFrom(JSAny? iterable);

@JS()
extension type _MidiInput(JSObject _) implements JSObject {
  external String get id;
  external String? get name;
  external set onmidimessage(JSFunction? handler);
}

@JS()
extension type _MidiMessageEvent(JSObject _) implements JSObject {
  external JSUint8Array get data;
}

@JS('scaleAudio')
external _ScaleAudioApi get _scaleAudio;

_MidiAccess? _midiAccess;
_MidiInput? _selectedMidiInput;

@JS()
extension type _ScaleAudioApi(JSObject _) implements JSObject {
  external void play(
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
  );
  external void release(int midi, double release);
  external void click(bool downbeat);
  external void setParams(
    double cutoff,
    double resonance,
    double volume,
    double delayMix,
  );
  external void panic();
  external void close();
  external JSUint8Array getWaveform();
}

Uint8List readWaveform() => _scaleAudio.getWaveform().toDart;

void closeAudio() => _scaleAudio.close();

Future<List<MidiInputDevice>> requestMidiAccess() async {
  _midiAccess = await _requestMidiAccess().toDart;
  return _getMidiInputs();
}

List<MidiInputDevice> _getMidiInputs() {
  final access = _midiAccess;
  if (access == null) return const [];
  return _arrayFrom(access.inputs.values()).toDart
      .cast<_MidiInput>()
      .map(
        (input) => MidiInputDevice(
          id: input.id,
          name: input.name?.trim().isNotEmpty == true
              ? input.name!.trim()
              : 'MIDI Input',
        ),
      )
      .toList();
}

void selectMidiInput(
  String? id,
  void Function(int midi, bool pressed) onNote,
) {
  final previous = _selectedMidiInput;
  if (previous != null) previous.onmidimessage = null;
  _selectedMidiInput = null;
  if (id == null) return;

  final access = _midiAccess;
  if (access == null) {
    throw StateError('Request MIDI access before selecting an input.');
  }
  final inputs = _arrayFrom(access.inputs.values()).toDart.cast<_MidiInput>();
  for (final input in inputs) {
    if (input.id != id) continue;
    _selectedMidiInput = input;
    input.onmidimessage = ((JSAny? event) {
      final data = (event as _MidiMessageEvent).data.toDart;
      if (data.length < 3) return;
      final status = data[0] & 0xf0;
      final note = data[1];
      final velocity = data[2];
      if (status == 0x90 && velocity > 0) {
        onNote(note, true);
      } else if (status == 0x80 || (status == 0x90 && velocity == 0)) {
        onNote(note, false);
      }
    }).toJS;
    return;
  }
  throw StateError('The selected MIDI input is no longer available.');
}

String? readProgress() => _localStorage.getItem('scaleADayProgress_v1');

void writeProgress(String value) =>
    _localStorage.setItem('scaleADayProgress_v1', value);

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
) => _scaleAudio.play(
  midi,
  waveform,
  volume,
  attack,
  decay,
  sustain,
  cutoff,
  resonance,
  subMix,
  detune,
  delayMix,
  voiceMode,
  glide,
);

void releaseNote(int midi, double release) =>
    _scaleAudio.release(midi, release);

void playMetronomeClick(bool downbeat) => _scaleAudio.click(downbeat);

void setAudioParams(
  double cutoff,
  double resonance,
  double volume,
  double delayMix,
) => _scaleAudio.setParams(cutoff, resonance, volume, delayMix);

void panicAudio() => _scaleAudio.panic();
