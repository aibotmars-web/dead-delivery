import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

enum SfxType {
  orderAccept,
  pickup,
  deliver,
  policeSiren,
  parkingTicket,
  cardDraw,
  cardRare,
  buttonTap,
  coin,
  ratingUp,
  scooterStart,
  scooterStop,
  achievement,
  dayEnd,
  eventPopup,
}

class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  web.AudioContext? _ctx;
  web.GainNode? _masterGain;
  web.GainNode? _sfxGain;
  web.GainNode? _musicGain;
  bool _sfxEnabled = true;
  bool _musicEnabled = true;
  bool _musicPlaying = false;
  Timer? _musicTimer;

  bool get sfxEnabled => _sfxEnabled;
  bool get musicEnabled => _musicEnabled;

  void init() {
    if (!kIsWeb) return;
    _ctx = web.AudioContext();
    _masterGain = _ctx!.createGain();
    _masterGain!.gain.value = 0.5;
    _masterGain!.connect(_ctx!.destination);

    _sfxGain = _ctx!.createGain();
    _sfxGain!.gain.value = 0.6;
    _sfxGain!.connect(_masterGain!);

    _musicGain = _ctx!.createGain();
    _musicGain!.gain.value = 0.25;
    _musicGain!.connect(_masterGain!);
  }

  void _ensureResumed() {
    if (_ctx?.state == 'suspended') {
      _ctx!.resume();
    }
  }

  void setSfxEnabled(bool v) {
    _sfxEnabled = v;
    _sfxGain?.gain.value = v ? 0.6 : 0.0;
  }

  void setMusicEnabled(bool v) {
    _musicEnabled = v;
    _musicGain?.gain.value = v ? 0.25 : 0.0;
    if (v && !_musicPlaying) {
      startMusic();
    } else if (!v) {
      stopMusic();
    }
  }

  void playSfx(SfxType type) {
    if (!_sfxEnabled || _ctx == null) return;
    _ensureResumed();
    switch (type) {
      case SfxType.orderAccept:
        _playTone(440, 0.08, wave: 'square');
        _playTone(554, 0.08, delay: 0.09, wave: 'square');
        _playTone(660, 0.12, delay: 0.18, wave: 'square');
      case SfxType.pickup:
        _playTone(523, 0.06, wave: 'square');
        _playTone(659, 0.06, delay: 0.07, wave: 'square');
        _playTone(784, 0.1, delay: 0.14, wave: 'square');
      case SfxType.deliver:
        _playTone(523, 0.08, wave: 'square');
        _playTone(659, 0.08, delay: 0.1, wave: 'square');
        _playTone(784, 0.08, delay: 0.2, wave: 'square');
        _playTone(1047, 0.15, delay: 0.3, wave: 'square');
      case SfxType.policeSiren:
        _playSiren();
      case SfxType.parkingTicket:
        _playTone(300, 0.15, wave: 'sawtooth');
        _playTone(200, 0.2, delay: 0.16, wave: 'sawtooth');
      case SfxType.cardDraw:
        _playTone(392, 0.06, wave: 'triangle');
        _playTone(494, 0.06, delay: 0.07, wave: 'triangle');
        _playTone(587, 0.06, delay: 0.14, wave: 'triangle');
        _playTone(784, 0.12, delay: 0.21, wave: 'triangle');
      case SfxType.cardRare:
        _playTone(523, 0.1, wave: 'sine');
        _playTone(659, 0.1, delay: 0.12, wave: 'sine');
        _playTone(784, 0.1, delay: 0.24, wave: 'sine');
        _playTone(1047, 0.2, delay: 0.36, wave: 'sine');
        _playTone(1319, 0.25, delay: 0.5, wave: 'sine');
      case SfxType.buttonTap:
        _playTone(800, 0.04, wave: 'square');
      case SfxType.coin:
        _playTone(1200, 0.06, wave: 'square');
        _playTone(1600, 0.08, delay: 0.07, wave: 'square');
      case SfxType.ratingUp:
        _playTone(660, 0.08, wave: 'triangle');
        _playTone(880, 0.12, delay: 0.1, wave: 'triangle');
      case SfxType.scooterStart:
        _playNoise(0.3, lowFreq: 80, highFreq: 200);
      case SfxType.scooterStop:
        _playNoise(0.15, lowFreq: 60, highFreq: 150);
      case SfxType.achievement:
        _playTone(523, 0.08, wave: 'square');
        _playTone(659, 0.08, delay: 0.1, wave: 'square');
        _playTone(784, 0.08, delay: 0.2, wave: 'square');
        _playTone(1047, 0.08, delay: 0.3, wave: 'square');
        _playTone(1319, 0.2, delay: 0.4, wave: 'square');
      case SfxType.dayEnd:
        _playTone(440, 0.15, wave: 'triangle');
        _playTone(349, 0.15, delay: 0.2, wave: 'triangle');
        _playTone(294, 0.3, delay: 0.4, wave: 'triangle');
      case SfxType.eventPopup:
        _playTone(600, 0.06, wave: 'square');
        _playTone(500, 0.06, delay: 0.08, wave: 'square');
        _playTone(600, 0.1, delay: 0.16, wave: 'square');
    }
  }

  void _playTone(double freq, double duration,
      {double delay = 0, String wave = 'square'}) {
    final ctx = _ctx!;
    final now = ctx.currentTime;
    final osc = ctx.createOscillator();
    final gain = ctx.createGain();

    osc.type = wave;
    osc.frequency.value = freq;
    gain.gain.value = 0.0;
    gain.gain.setValueAtTime(0.0, now + delay);
    gain.gain.linearRampToValueAtTime(0.3, now + delay + 0.01);
    gain.gain.linearRampToValueAtTime(0.0, now + delay + duration);

    osc.connect(gain);
    gain.connect(_sfxGain!);
    osc.start(now + delay);
    osc.stop(now + delay + duration + 0.02);
  }

  void _playSiren() {
    final ctx = _ctx!;
    final now = ctx.currentTime;
    final osc = ctx.createOscillator();
    final gain = ctx.createGain();

    osc.type = 'sine';
    osc.frequency.setValueAtTime(600.0, now);
    osc.frequency.linearRampToValueAtTime(900.0, now + 0.15);
    osc.frequency.linearRampToValueAtTime(600.0, now + 0.3);
    osc.frequency.linearRampToValueAtTime(900.0, now + 0.45);
    osc.frequency.linearRampToValueAtTime(600.0, now + 0.6);

    gain.gain.value = 0.0;
    gain.gain.linearRampToValueAtTime(0.25, now + 0.02);
    gain.gain.setValueAtTime(0.25, now + 0.5);
    gain.gain.linearRampToValueAtTime(0.0, now + 0.7);

    osc.connect(gain);
    gain.connect(_sfxGain!);
    osc.start(now);
    osc.stop(now + 0.72);
  }

  void _playNoise(double duration, {double lowFreq = 100, double highFreq = 300}) {
    // Approximate noise using detuned oscillators
    final ctx = _ctx!;
    final now = ctx.currentTime;
    final gain = ctx.createGain();
    gain.gain.value = 0.0;
    gain.gain.linearRampToValueAtTime(0.15, now + 0.02);
    gain.gain.linearRampToValueAtTime(0.0, now + duration);
    gain.connect(_sfxGain!);

    final rng = Random();
    for (int i = 0; i < 5; i++) {
      final osc = ctx.createOscillator();
      osc.type = 'sawtooth';
      osc.frequency.value = lowFreq + rng.nextDouble() * (highFreq - lowFreq);
      osc.connect(gain);
      osc.start(now);
      osc.stop(now + duration + 0.01);
    }
  }

  // ── Background Music (chiptune loop) ──

  void startMusic() {
    if (!_musicEnabled || _ctx == null) return;
    _ensureResumed();
    _musicPlaying = true;
    _playMusicBar();
  }

  void stopMusic() {
    _musicPlaying = false;
    _musicTimer?.cancel();
    _musicTimer = null;
  }

  void _playMusicBar() {
    if (!_musicPlaying || _ctx == null) return;

    final ctx = _ctx!;
    final now = ctx.currentTime;
    const bpm = 120.0;
    const beatDur = 60.0 / bpm;
    const barDur = beatDur * 8;

    // Pentatonic melody pattern (Taiwan night market vibe)
    final melodyNotes = [
      523.0, 587.0, 659.0, 784.0, 880.0, 784.0, 659.0, 587.0,
    ];
    final bassNotes = [
      131.0, 131.0, 165.0, 165.0, 175.0, 175.0, 165.0, 131.0,
    ];

    for (var i = 0; i < 8; i++) {
      final t = now + i * beatDur;
      _playMusicNote(melodyNotes[i], t, beatDur * 0.7, 'square', 0.12);
      _playMusicNote(bassNotes[i], t, beatDur * 0.9, 'triangle', 0.15);

      // Hi-hat rhythm
      if (i % 2 == 0) {
        _playMusicHihat(t, 0.03);
      }
    }

    _musicTimer = Timer(
      Duration(milliseconds: (barDur * 1000).round()),
      _playMusicBar,
    );
  }

  void _playMusicNote(
      double freq, double startTime, double duration, String wave, double vol) {
    final ctx = _ctx!;
    final osc = ctx.createOscillator();
    final gain = ctx.createGain();

    osc.type = wave;
    osc.frequency.value = freq;
    gain.gain.value = 0.0;
    gain.gain.setValueAtTime(0.0, startTime);
    gain.gain.linearRampToValueAtTime(vol, startTime + 0.01);
    gain.gain.setValueAtTime(vol, startTime + duration * 0.7);
    gain.gain.linearRampToValueAtTime(0.0, startTime + duration);

    osc.connect(gain);
    gain.connect(_musicGain!);
    osc.start(startTime);
    osc.stop(startTime + duration + 0.02);
  }

  void _playMusicHihat(double startTime, double duration) {
    final ctx = _ctx!;

    // High-frequency oscillators to simulate hi-hat click
    final gain = ctx.createGain();
    gain.gain.value = 0.0;
    gain.gain.setValueAtTime(0.06, startTime);
    gain.gain.linearRampToValueAtTime(0.0, startTime + duration);
    gain.connect(_musicGain!);

    // Multiple high-freq detuned oscillators ≈ metallic hi-hat sound
    final rng = Random();
    for (int i = 0; i < 3; i++) {
      final osc = ctx.createOscillator();
      osc.type = 'square';
      osc.frequency.value = 8000.0 + rng.nextDouble() * 4000;
      osc.connect(gain);
      osc.start(startTime);
      osc.stop(startTime + duration + 0.01);
    }
  }

  void dispose() {
    stopMusic();
    _ctx?.close();
    _ctx = null;
  }
}
