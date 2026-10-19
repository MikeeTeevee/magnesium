# MAGNESIUM

A Flutter Web port of the SCALE-A-DAY studio synthesizer and scale trainer.

## Run

```powershell
flutter run -d chrome
```

To serve it with Flutter's web server instead:

```powershell
flutter run -d web-server --web-port 8765
```

## Features

- 15 scale and mode definitions, daily scale assignment, and a persistent
  practice streak.
- A 30-key C3–F5 piano with scale-degree, fingering, and QWERTY labels.
- Web Audio synthesizer with waveform, filter, envelope, sub-oscillator,
  unison, and delay controls.
- Scale arpeggiator, metronome click, three-repetition practice drills, and
  diatonic chord pads.

The project targets Flutter Web. Audio is generated with the browser's Web
Audio API; practice progress is saved in browser local storage.

## MIDI input

In Chrome, use the **MIDI INPUT** panel and select **SCAN / CONNECT** to grant
MIDI access, then choose the connected keyboard from the device list. The
browser's Web MIDI API requires a supported browser and a secure context
(`localhost` is allowed); USB MIDI keyboards such as the Akai MPK Mini appear
as inputs when connected and permitted. MIDI input is currently supported in
the web app only.

## Verify

```powershell
flutter analyze
flutter test
flutter build web
```

## Deploy to a subdomain

Build the production web app with a root-relative base path:

```powershell
flutter build web --release --base-href /
```

Publish the contents of `build/web` to the root of a static web host. This
build is intended for a subdomain (for example, `synth.example.com`), where the
app is served from `/`; it is not configured for a nested URL path. If the host
supports single-page-app rewrites, configure unknown paths to serve
`index.html`.

In your hosting provider's domain settings, add the subdomain and configure
the DNS record(s) it provides. Enable HTTPS: secure contexts are required for
Web MIDI outside `localhost`. The build output is generated locally and is not
committed to Git.
