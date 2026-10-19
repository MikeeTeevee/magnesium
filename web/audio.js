globalThis.scaleAudio = (() => {
  let context;
  let filter;
  let master;
  let delayNode;
  let delayFeedback;
  let delayWet;
  let filterCutoff = 2800;
  let filterResonance = 3.5;
  let masterVolume = 0.8;
  let delayMix = 0.25;
  let lastMonoFrequency = 0;
  let analyser;
  let spectrum = new Uint8Array(0);
  const voices = new Map();

  function initialize() {
    if (context) {
      if (context.state === 'suspended') void context.resume();
      return;
    }

    context = new AudioContext();
    filter = context.createBiquadFilter();
    filter.type = 'lowpass';
    filter.frequency.value = filterCutoff;
    filter.Q.value = filterResonance;

    master = context.createGain();
    master.gain.value = masterVolume * 0.4;
    delayNode = context.createDelay(1);
    delayNode.delayTime.value = 0.32;
    delayFeedback = context.createGain();
    delayFeedback.gain.value = 0.36;
    delayWet = context.createGain();
    delayWet.gain.value = delayMix;

    filter.connect(master);
    filter.connect(delayNode);
    delayNode.connect(delayFeedback);
    delayFeedback.connect(delayNode);
    delayNode.connect(delayWet);
    delayWet.connect(master);
    master.connect(context.destination);

    analyser = context.createAnalyser();
    analyser.fftSize = 2048;
    master.connect(analyser);
    spectrum = new Uint8Array(analyser.fftSize);
  }

  function release(midi, releaseSeconds) {
    const voice = voices.get(midi);
    if (!voice || !context) return;
    voices.delete(midi);
    const now = context.currentTime;
    voice.gain.gain.cancelScheduledValues(now);
    voice.gain.gain.setTargetAtTime(0, now, Math.max(0.02, releaseSeconds / 4));
    window.setTimeout(() => {
      for (const oscillator of voice.oscillators) {
        try {
          oscillator.stop();
          oscillator.disconnect();
        } catch {
          // An oscillator may already have been stopped by panic.
        }
      }
      voice.gain.disconnect();
    }, (releaseSeconds * 1000) + 100);
  }

  return {
    play(midi, waveform, volume, attack, decay, sustain, cutoff, resonance, subMix, detune, delay, voiceMode, glide) {
      initialize();
      if (voiceMode === 'mono') {
        for (const heldMidi of voices.keys()) release(heldMidi, 0.01);
      }
      release(midi, 0.01);
      this.setParams(cutoff, resonance, volume, delay);

      const now = context.currentTime;
      const frequency = 440 * Math.pow(2, (midi - 69) / 12);
      const gain = context.createGain();
      gain.gain.setValueAtTime(0, now);
      gain.gain.linearRampToValueAtTime(0.22, now + attack);
      gain.gain.linearRampToValueAtTime(0.22 * sustain, now + attack + decay);
      gain.connect(filter);

      const oscillator = context.createOscillator();
      oscillator.type = waveform;
      oscillator.frequency.value = voiceMode === 'mono' && lastMonoFrequency && glide > 0
        ? lastMonoFrequency
        : frequency;
      if (voiceMode === 'mono' && lastMonoFrequency && glide > 0) {
        oscillator.frequency.setTargetAtTime(frequency, now, glide / 1000);
      }
      oscillator.connect(gain);
      oscillator.start();
      const oscillators = [oscillator];

      const unison = context.createOscillator();
      const unisonGain = context.createGain();
      unison.type = waveform;
      unison.frequency.value = oscillator.frequency.value;
      unison.detune.value = detune;
      if (voiceMode === 'mono' && lastMonoFrequency && glide > 0) {
        unison.frequency.setTargetAtTime(frequency, now, glide / 1000);
      }
      unisonGain.gain.value = 0.35;
      unison.connect(unisonGain);
      unisonGain.connect(gain);
      unison.start();
      oscillators.push(unison);

      if (subMix > 0) {
        const sub = context.createOscillator();
        const subGain = context.createGain();
        sub.type = waveform;
        sub.frequency.value = oscillator.frequency.value / 2;
        if (voiceMode === 'mono' && lastMonoFrequency && glide > 0) {
          sub.frequency.setTargetAtTime(frequency / 2, now, glide / 1000);
        }
        subGain.gain.value = subMix * 0.5;
        sub.connect(subGain);
        subGain.connect(gain);
        sub.start();
        oscillators.push(sub);
      }

      voices.set(midi, { gain, oscillators });
      if (voiceMode === 'mono') lastMonoFrequency = frequency;
    },
    release,
    click(downbeat) {
      initialize();
      const oscillator = context.createOscillator();
      const gain = context.createGain();
      const now = context.currentTime;
      oscillator.type = 'sine';
      oscillator.frequency.value = downbeat ? 1320 : 880;
      gain.gain.setValueAtTime(0.15, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.045);
      oscillator.connect(gain);
      gain.connect(context.destination);
      oscillator.start(now);
      oscillator.stop(now + 0.05);
    },
    setParams(cutoff, resonance, volume, delay) {
      filterCutoff = cutoff;
      filterResonance = resonance;
      masterVolume = volume;
      delayMix = delay;
      if (!context) return;
      const now = context.currentTime;
      filter.frequency.setTargetAtTime(filterCutoff, now, 0.015);
      filter.Q.setTargetAtTime(filterResonance, now, 0.015);
      master.gain.setTargetAtTime(masterVolume * 0.4, now, 0.02);
      delayWet.gain.setTargetAtTime(delayMix, now, 0.02);
    },
    getWaveform() {
      if (analyser) analyser.getByteTimeDomainData(spectrum);
      return spectrum;
    },
    panic() {
      for (const midi of voices.keys()) release(midi, 0.01);
      voices.clear();
      lastMonoFrequency = 0;
    },
    close() {
      this.panic();
      if (context) void context.close();
      context = undefined;
      analyser = undefined;
      spectrum = new Uint8Array(0);
    },
  };
})();
