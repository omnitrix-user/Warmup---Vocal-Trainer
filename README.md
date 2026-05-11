# Warmup

iOS vocal warmup app. You sing a target note, the app draws your pitch as a flowing curve and tells you if you're in tune.

I've been singing for years (won a few solo competitions along the way) and I'm a first year CS undergrad. The existing vocal warmup apps don't really cut it, so I built the one I wanted.

## What's in it

Five screens:

- **Today** with a streak counter and the last few sessions
- **Library** with four routines (Quick 5, Daily 15, Pre-Show 8, Cool Down 5)
- **Active Session**, the main screen with the live pitch curve and target note
- **Voice Range** where you drag two handles and the app classifies you (Bass through Soprano)
- **History** with a 12 week activity heatmap and a full session log

Screenshots in `screenshots/`.

## Stack

SwiftUI throughout. Single shared AVAudioEngine for playback and mic capture. Custom YIN pitch detector, no audio libraries pulled in. Async/await sequencer for the routines. Hardcoded seed data for the practice journal (would be SwiftData if I were actually shipping this).

## The hard parts

**AudioKit didn't work.** Tried AudioKit's pitch tracking first. The problem is AudioKit runs its own AVAudioEngine, and I needed mine for playing piano scales while the mic was recording. Two engines fighting over the mic crashes CoreAudio with `IsFormatSampleRateAndChannelCountValid`. Ripped it out and wrote a YIN implementation from scratch. About 150 lines.

**Voice pitch detection is hard.** I spent more time on this than anything else. Even after switching from autocorrelation to YIN, adding a 5 sample median filter, and writing an octave continuity layer that snaps 2x or 0.5x detection errors back to the previous stable frequency, it still doesn't lock onto sustained notes as reliably as I'd want. Lip trills are basically broadband noise, there's no clean fundamental for the algorithm to find. Companies like Yousician and Vanido have whole teams working on this problem. At some point I accepted I wasn't going to fully solve it in a portfolio build and moved on.

**Octave matching was the wrong default.** First version of `centsOff` did exact frequency math, so if the target was C4 and I sang C3 (my comfortable octave) the app said I was 1200 cents flat. Useless. Switched to modular cents math so singing a C in any octave reads as in tune when the target is C4. That's how vocal warmups work in practice anyway, the singer doesn't need to match the piano's octave.

**Screenshots from real audio were unreliable.** Even when YIN was behaving, capturing a clean shot of the curve hitting the green zone was hit and miss. I built a demo mode (`demoCaptureMode` in `ActiveSessionView`) that feeds the curve with a synthetic generator. Five different curve shapes, one per note, with jitter mixed in so they look organic. The real pitch pipeline runs unchanged when the flag is off. Slightly hacky but it solved the capture problem without compromising the rest of the code.

## What I'd improve

- Replace the YIN detector with a small CoreML model (something CREPE based). Would handle lip trills and noise way better.
- SwiftData persistence so the practice history is real, not seeded.
- Note by note evaluation during a scale instead of one target per step.
- A real onboarding flow where you sing into the mic during range setup and the app calibrates your targets to what you can actually hit.
- Apple Watch companion so you can run a warmup with the phone face down.
- Accessibility pass for Dynamic Type and VoiceOver.

## Build

```bash
git clone https://github.com/[your-username]/warmup.git
open warmup/Warmup.xcodeproj
```

Xcode 15+, iOS 17+. Free Apple ID works. Mic permission required.

## Project layout

```
Warmup/
├── WarmupApp.swift
├── ContentView.swift
├── Audio/
│   ├── AudioEngine.swift
│   ├── SequenceStep.swift
│   ├── SessionPlayer.swift
│   ├── PitchDetector.swift
│   └── ActiveSessionView.swift
├── Models/
│   ├── Routine.swift
│   └── CompletedSession.swift
└── Views/
    ├── OnboardingView.swift
    ├── TodayView.swift
    ├── RoutinesListView.swift
    ├── HistoryView.swift
    └── RangeSelectorView.swift
```

## How it was built

Solo, roughly three days. Used Claude for architecture and review, Cursor for code generation. I made the build decisions. What to build, what to skip, when to throw out an approach. The tools handled execution speed.

## Credit

YIN: de Cheveigné & Kawahara, 2002.
Piano: scale_C.wav from Freesound.org, CC0.