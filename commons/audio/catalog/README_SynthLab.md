# Synth Lab - Deep Synthesis Research

A tool for exploring authentic recreations of classic synthesizers and drum machines.

## Quick Start

Open `SynthLabDesktop.tscn` in Godot to launch the Synth Lab.

## Philosophy

Instead of focusing on complete songs, this system focuses on **individual sound elements** with deep, research-backed implementations:

- Each element recreates actual circuit behavior
- Parameters map to real synthesizer controls
- Filter topologies match original designs
- Technical documentation explains the "why"

## Available Elements

### Bass Synthesizers
| Element | Based On | Key Characteristics |
|---------|----------|---------------------|
| `tb303_bass` | Roland TB-303 | 18dB diode ladder, accent/slide |
| `minimoog_bass` | Moog Minimoog | 3 OSC, 24dB ladder, drift |
| `sub_bass` | TR-808 | Sine + pitch env, long decay |

### Drum Machines
| Element | Based On | Key Characteristics |
|---------|----------|---------------------|
| `tr909_kick` | Roland TR-909 | Punchy body + click |
| `tr808_kick` | Roland TR-808 | Deep boom, long decay |
| `tr909_snare` | Roland TR-909 | Tone oscillators + noise |
| `tr909_hihat` | Roland TR-909 | 6 metallic oscillators |
| `tr808_clap` | Roland TR-808 | Multiple noise bursts |

### Pads & Strings
| Element | Based On | Key Characteristics |
|---------|----------|---------------------|
| `juno_pad` | Roland Juno-106 | BBD chorus, PWM |
| `supersaw` | Roland JP-8000 | 7 detuned saws |

### Leads
| Element | Based On | Key Characteristics |
|---------|----------|---------------------|
| `hoover` | Alpha Juno | Detune + filter sweep |
| `dx7_epiano` | Yamaha DX7 | FM synthesis |

## File Structure

```
commons/audio/
├── catalog/
│   ├── SynthLabDesktop.gd/tscn    ← Main launcher
│   ├── SynthElementBrowser.gd/tscn ← Element browser with params
│   └── README_SynthLab.md          ← This file
└── documentation/
    └── SYNTH_ELEMENTS.md           ← Deep technical reference
```

## Technical Reference

See `documentation/SYNTH_ELEMENTS.md` for:
- Circuit diagrams and signal flow
- Filter topology explanations
- Parameter ranges and units
- Implementation code examples
- Historical context

## Usage in Code

```gdscript
# Create element browser
var browser = preload("res://commons/audio/catalog/SynthElementBrowser.tscn").instantiate()
add_child(browser)

# Connect to parameter changes
browser.param_changed.connect(_on_param_changed)

# Or generate sounds directly
var stream = browser._generate_tb303({
    "cutoff": 800,
    "resonance": 0.85,
    "accent": 0.7,
    "waveform": "sawtooth"
})
```

## Parameter Guidelines

### TB-303 Acid Sound
```
cutoff: 200-600 (low base, let envelope open it)
resonance: 0.75-0.95 (higher = more scream)
env_mod: 0.6-0.9 (envelope depth)
decay: 0.1-0.4 (shorter for more rhythmic)
accent: 0.5-0.8 (boosts res AND env_mod)
```

### Fat Minimoog Bass
```
osc2_detune: 0.002-0.005 (subtle thickness)
osc3_octave: -1 (sub oscillator)
cutoff: 400-1200 (depends on brightness)
saturation: 0.2-0.4 (glue and warmth)
drift: 0.05-0.1 (analog character)
```

### Punchy 909 Kick
```
tune: 50-65 (Hz, fundamental)
pitch_start: 120-180 (Hz, transient)
pitch_decay: 0.015-0.025 (s, how fast pitch drops)
attack_level: 0.2-0.4 (click amount)
decay: 0.2-0.35 (s, overall length)
```

## Adding New Elements

1. Add entry to `SYNTH_ELEMENTS` dictionary in `SynthElementBrowser.gd`
2. Add generator function `_generate_<element_id>(params)`
3. Document in `SYNTH_ELEMENTS.md`

## Research Sources

- Sound On Sound "Synth Secrets" series (63 parts)
- Gordon Reid's analysis of classic synths
- Service manuals and schematics
- Original manufacturer documentation
