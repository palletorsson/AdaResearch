#!/usr/bin/env python
"""
generate_rack_configs.py — emit new rack JSON configs from archetype
templates, so `module_research.py audio-rack-auto` has fresh DNA to
render and rate.

Each archetype is a function that returns a valid rack_config dict:
  - rack_info: name, description, sound_type
  - layout:    padding_px, gap_px, visibility flags
  - grid:      2D array of control keys
  - control_definitions: dict of type/label/parameter/range/color entries

Archetypes represent distinct musical intents — minimal synth,
subtractive chain, FM pair, LFO modulator, delay+reverb, granular,
drum one-shot, filter bank, etc. Each is parametrized so N calls
produce N variants of the same idea.

Output: commons/audio/rack_configs/auto/<id>.json

Usage::

    python tools/generate_rack_configs.py                 # 20 default
    python tools/generate_rack_configs.py --count 40      # 40 variants
    python tools/generate_rack_configs.py --seed 42       # deterministic
    python tools/generate_rack_configs.py --archetype fm  # one family only
    python tools/generate_rack_configs.py --clean         # wipe auto/ first

After generation, run::

    python tools/module_research.py audio-rack-auto
"""
from __future__ import annotations

import argparse
import hashlib
import json
import random
import sys
from pathlib import Path
from typing import Callable

try:
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
except Exception:
    pass

REPO = Path(__file__).resolve().parent.parent
OUT_DIR = REPO / "commons" / "audio" / "rack_configs" / "auto"

# ─── Color accents (referenced by some control defs) ─────────────────────
ACCENTS = [
    "#ff4444", "#ff8844", "#ffcc44", "#88ff44", "#44ffaa",
    "#44ccff", "#4488ff", "#8844ff", "#cc44ff", "#ff44aa",
]

# ─── Archetype builders ─────────────────────────────────────────────────
#
# Each returns (id_suffix, rack_config_dict). The id_suffix is combined
# with the archetype name and the seed to produce a unique filename.

def _layout(padding: int = 18, gap: int = 14, hide_selection: bool = True) -> dict:
    return {
        "padding_px": padding,
        "gap_px": gap,
        "hide_selection": hide_selection,
        "hide_buttons": True,
    }

def _slider(label: str, param: str, lo: float, hi: float, default: float | None = None,
            variant: str = "slider", accent: str | None = None) -> dict:
    out = {"type": variant, "label": label, "parameter": param,
           "min": lo, "max": hi, "default": default if default is not None else (lo + hi) / 2}
    if accent:
        out["color"] = accent
    return out

def _knob(label: str, param: str, lo: float, hi: float, default: float | None = None) -> dict:
    return {"type": "knob", "label": label, "parameter": param,
            "min": lo, "max": hi, "default": default if default is not None else (lo + hi) / 2}

def _btn(label: str, param: str, action: str = "trigger", color: str = "#ff4444") -> dict:
    return {"type": "btn", "label": label, "parameter": param, "action": action, "color": color}

def _label(text: str, font_size: int = 18) -> dict:
    return {"type": "label", "text": text, "font_size": font_size}

def _meter(label: str) -> dict:
    return {"type": "meter", "label": label}


def minimal_synth(rng: random.Random, seed: int) -> tuple[str, dict]:
    """3 knobs: freq, amp, duration. The smallest meaningful rack."""
    freq_lo = rng.choice([20.0, 50.0, 80.0])
    freq_hi = rng.choice([1000.0, 2000.0, 4000.0])
    dur_hi = rng.choice([1.0, 3.0, 6.0])
    return f"{int(freq_hi)}", {
        "rack_info": {
            "name": f"Minimal {int(freq_hi)}Hz",
            "description": f"Three knobs — frequency {freq_lo:g}-{freq_hi:g}Hz, amp 0-1, duration up to {dur_hi:g}s. Smallest meaningful rack.",
            "version": "auto-1", "sound_type": "basic_sine_wave",
        },
        "layout": _layout(),
        "grid": [["lbl"], ["freq", "amp", "dur"]],
        "control_definitions": {
            "lbl": _label("MINIMAL", 20),
            "freq": _knob("FREQ", "freq", freq_lo, freq_hi, freq_lo * 4),
            "amp":  _knob("AMP",  "amp", 0.0, 1.0, 0.6),
            "dur":  _knob("DUR",  "duration", 0.1, dur_hi, 0.5),
        },
    }


def subtractive(rng: random.Random, seed: int) -> tuple[str, dict]:
    """VCO → VCF → VCA + envelope. The classic signal chain."""
    cutoff_hi = rng.choice([4000.0, 8000.0, 12000.0])
    res_peak = rng.choice([0.7, 0.85, 0.95])
    return f"{int(cutoff_hi)}_{int(res_peak*100)}", {
        "rack_info": {
            "name": f"Subtractive {int(cutoff_hi)}",
            "description": f"VCO → VCF (cutoff 0-{int(cutoff_hi)}, res peak {res_peak}) → VCA with ADSR.",
            "version": "auto-1", "sound_type": "synth_wave",
        },
        "layout": _layout(),
        "grid": [
            ["lbl_osc", "lbl_flt", "lbl_env"],
            ["pitch", "cutoff", "attack"],
            ["shape", "reso",   "decay"],
            ["level", "drive",  "sustain"],
            ["",      "",       "release"],
        ],
        "control_definitions": {
            "lbl_osc": _label("VCO"),
            "lbl_flt": _label("VCF"),
            "lbl_env": _label("ADSR"),
            "pitch":   _slider("PITCH", "pitch", 20.0, 2000.0, 440.0, "slv"),
            "shape":   _slider("SHAPE", "shape", -3.0, 3.0, 0.0, "sls"),
            "level":   _knob("LEVEL", "level", 0.0, 1.0, 0.7),
            "cutoff":  _slider("CUT",  "cutoff", 50.0, cutoff_hi, cutoff_hi / 3, "slv"),
            "reso":    _knob("RES",  "resonance", 0.0, res_peak, 0.3),
            "drive":   _knob("DRIVE", "drive", 0.0, 1.0, 0.2),
            "attack":  _slider("A", "attack", 0.001, 2.0, 0.05, "slv"),
            "decay":   _slider("D", "decay", 0.001, 2.0, 0.2, "slv"),
            "sustain": _knob("S", "sustain", 0.0, 1.0, 0.7),
            "release": _slider("R", "release", 0.001, 4.0, 0.3, "slv"),
        },
    }


def fm_pair(rng: random.Random, seed: int) -> tuple[str, dict]:
    """2-operator FM — carrier × modulator with ratio + index."""
    ratio_hi = rng.choice([4.0, 8.0, 16.0])
    return f"r{int(ratio_hi)}", {
        "rack_info": {
            "name": f"FM Pair (ratio {ratio_hi:g})",
            "description": f"Two-operator FM. Carrier freq × modulator with ratio 0-{ratio_hi:g} and modulation index.",
            "version": "auto-1", "sound_type": "synth_wave",
        },
        "layout": _layout(),
        "grid": [
            ["lbl_c", "lbl_m"],
            ["carrier", "ratio"],
            ["c_amp",   "index"],
            ["",        "m_level"],
        ],
        "control_definitions": {
            "lbl_c":   _label("CARRIER"),
            "lbl_m":   _label("MODULATOR"),
            "carrier": _slider("FREQ", "carrier_freq", 20.0, 2000.0, 220.0, "slv"),
            "c_amp":   _knob("LEVEL",  "carrier_amp", 0.0, 1.0, 0.7),
            "ratio":   _slider("RATIO", "mod_ratio", 0.0, ratio_hi, 1.0, "slv"),
            "index":   _slider("INDEX", "mod_index", 0.0, 10.0, 2.0, "slv"),
            "m_level": _knob("M LVL",   "mod_amp", 0.0, 1.0, 0.5),
        },
    }


def drum_oneshot(rng: random.Random, seed: int) -> tuple[str, dict]:
    """Trigger → pitch env + click + body. Kick-drum topology."""
    body_freq = rng.choice([40.0, 60.0, 80.0, 100.0])
    return f"{int(body_freq)}Hz", {
        "rack_info": {
            "name": f"Drum {int(body_freq)}Hz",
            "description": f"One-shot drum voice. Trigger sweeps pitch from {body_freq*4:g}Hz to {body_freq:g}Hz with a transient click.",
            "version": "auto-1", "sound_type": "heartbeat",
        },
        "layout": _layout(),
        "grid": [
            ["lbl"],
            ["trig"],
            ["pitch", "click"],
            ["decay", "body"],
        ],
        "control_definitions": {
            "lbl":   _label("DRUM"),
            "trig":  _btn("TRIG", "trigger", "trigger", rng.choice(ACCENTS)),
            "pitch": _knob("PITCH", "base_freq", 30.0, 200.0, body_freq),
            "click": _knob("CLICK", "click", 0.0, 1.0, 0.5),
            "decay": _knob("DECAY", "decay", 0.05, 2.0, 0.3),
            "body":  _knob("BODY",  "body_amt", 0.0, 1.0, 0.7),
        },
    }


def filter_bank(rng: random.Random, seed: int) -> tuple[str, dict]:
    """3-band EQ with freq+gain per band."""
    bands = rng.choice([3, 5])
    grid = [["lbl"]]
    defs: dict = {"lbl": _label(f"{bands}-BAND EQ")}
    freq_row, gain_row = [], []
    for i in range(bands):
        f_key = f"f{i}"; g_key = f"g{i}"
        freq_row.append(f_key); gain_row.append(g_key)
        # Bands spread geometrically 60..8000
        center = 60.0 * (8000.0 / 60.0) ** (i / max(1, bands - 1))
        defs[f_key] = _slider(f"{int(center)}Hz", f"freq_{i}", center * 0.5, center * 2.0, center, "slv")
        defs[g_key] = _knob("GAIN", f"gain_{i}", -12.0, 12.0, 0.0)
    grid.append(freq_row)
    grid.append(gain_row)
    return f"{bands}band", {
        "rack_info": {
            "name": f"{bands}-Band Filter",
            "description": f"{bands} parametric bands spread log-geometrically 60 Hz to 8 kHz.",
            "version": "auto-1", "sound_type": "synth_wave",
        },
        "layout": _layout(padding=16, gap=10),
        "grid": grid,
        "control_definitions": defs,
    }


def delay_reverb(rng: random.Random, seed: int) -> tuple[str, dict]:
    """Delay + reverb in series — space shaper."""
    max_time_ms = rng.choice([500, 1000, 2000, 4000])
    return f"{max_time_ms}ms", {
        "rack_info": {
            "name": f"Delay+Reverb {max_time_ms}ms",
            "description": f"Delay (up to {max_time_ms}ms) into reverb. Time, feedback, mix; size, damping, mix.",
            "version": "auto-1", "sound_type": "synth_wave",
        },
        "layout": _layout(),
        "grid": [
            ["lbl_d", "lbl_r"],
            ["time",  "size"],
            ["fbk",   "damp"],
            ["d_mix", "r_mix"],
            ["tap",   ""],
        ],
        "control_definitions": {
            "lbl_d": _label("DELAY"),
            "lbl_r": _label("REVERB"),
            "time":  _slider("TIME", "delay_time", 1.0, float(max_time_ms), max_time_ms / 4, "slv"),
            "fbk":   _knob("FBK",   "feedback", 0.0, 0.95, 0.35),
            "d_mix": _knob("MIX",   "delay_mix", 0.0, 1.0, 0.3),
            "size":  _slider("SIZE", "reverb_size", 0.0, 1.0, 0.6, "slv"),
            "damp":  _knob("DAMP",  "reverb_damp", 0.0, 1.0, 0.5),
            "r_mix": _knob("MIX",   "reverb_mix", 0.0, 1.0, 0.2),
            "tap":   _btn("TAP",   "tap_tempo", "trigger", "#44ccff"),
        },
    }


def lfo_mod(rng: random.Random, seed: int) -> tuple[str, dict]:
    """LFO with rate, depth, shape, destination select. Classic modulator."""
    return f"{rng.randint(0, 99):02d}", {
        "rack_info": {
            "name": "LFO Modulator",
            "description": "Rate × depth × shape selector × destination. Universal modulation source.",
            "version": "auto-1", "sound_type": "synth_wave",
        },
        "layout": _layout(),
        "grid": [
            ["lbl"],
            ["rate",  "depth"],
            ["shape", "dest"],
            ["sync",  ""],
        ],
        "control_definitions": {
            "lbl":   _label("LFO"),
            "rate":  _slider("RATE", "lfo_rate", 0.01, 20.0, 2.0, "slv"),
            "depth": _knob("DEPTH",  "lfo_depth", 0.0, 1.0, 0.5),
            "shape": _slider("SHAPE", "lfo_shape", 0.0, 4.0, 0.0, "sls"),
            "dest":  _slider("DEST", "lfo_dest", 0.0, 7.0, 0.0, "sls"),
            "sync":  _btn("SYNC",   "sync", "toggle", "#44ccff"),
        },
    }


def granular(rng: random.Random, seed: int) -> tuple[str, dict]:
    """Granular synth — density, size, pitch, position, dry/wet."""
    return f"g{rng.randint(0, 99):02d}", {
        "rack_info": {
            "name": "Granular",
            "description": "Density × grain size × pitch × position. Jean Garnier-style pad substrate.",
            "version": "auto-1", "sound_type": "synth_wave",
        },
        "layout": _layout(),
        "grid": [
            ["lbl"],
            ["density", "size"],
            ["pitch",   "pos"],
            ["spread",  "mix"],
        ],
        "control_definitions": {
            "lbl":     _label("GRANULAR"),
            "density": _slider("DENS", "density", 1.0, 60.0, 12.0, "slv"),
            "size":    _slider("SIZE", "grain_size", 10.0, 500.0, 80.0, "slv"),
            "pitch":   _knob("PITCH", "pitch", -12.0, 12.0, 0.0),
            "pos":     _slider("POS",  "position", 0.0, 1.0, 0.5, "slh"),
            "spread":  _knob("SPREAD", "spread", 0.0, 1.0, 0.3),
            "mix":     _knob("MIX", "mix", 0.0, 1.0, 0.5),
        },
    }


def wavefolder(rng: random.Random, seed: int) -> tuple[str, dict]:
    """Wavefolder — drive, fold, bias, symmetry."""
    return f"w{rng.randint(0, 99):02d}", {
        "rack_info": {
            "name": "Wavefolder",
            "description": "Drive → fold → bias → symmetry. West-coast saturation topology.",
            "version": "auto-1", "sound_type": "synth_wave",
        },
        "layout": _layout(),
        "grid": [
            ["lbl"],
            ["drive", "fold"],
            ["bias",  "sym"],
            ["mix",   ""],
        ],
        "control_definitions": {
            "lbl":   _label("WAVEFOLD"),
            "drive": _knob("DRIVE", "drive", 0.0, 10.0, 1.5),
            "fold":  _knob("FOLD",  "fold", 0.0, 1.0, 0.4),
            "bias":  _knob("BIAS",  "bias", -1.0, 1.0, 0.0),
            "sym":   _knob("SYM",   "symmetry", 0.0, 1.0, 0.5),
            "mix":   _knob("MIX",   "mix", 0.0, 1.0, 0.7),
        },
    }


def sample_hold(rng: random.Random, seed: int) -> tuple[str, dict]:
    """S&H — clock, amount, smoothing, output."""
    return f"sh{rng.randint(0, 99):02d}", {
        "rack_info": {
            "name": "Sample & Hold",
            "description": "Clock triggers random sample × amount × smoothing. Arvo Pärt tintinnabuli via chance.",
            "version": "auto-1", "sound_type": "synth_wave",
        },
        "layout": _layout(),
        "grid": [
            ["lbl"],
            ["clock", "amt"],
            ["smooth", "range"],
            ["trig",  ""],
        ],
        "control_definitions": {
            "lbl":    _label("S&H"),
            "clock":  _slider("CLK", "clock_rate", 0.1, 16.0, 2.0, "slv"),
            "amt":    _knob("AMT", "amount", 0.0, 1.0, 0.6),
            "smooth": _knob("SMTH", "smoothing", 0.0, 1.0, 0.1),
            "range":  _knob("RNG", "range", 0.0, 1.0, 1.0),
            "trig":   _btn("TRIG", "manual_trig", "trigger", "#44ffaa"),
        },
    }


# ─── Archetype registry ───────────────────────────────────────────────

ARCHETYPES: dict[str, Callable[[random.Random, int], tuple[str, dict]]] = {
    "minimal":     minimal_synth,
    "subtractive": subtractive,
    "fm":          fm_pair,
    "drum":        drum_oneshot,
    "filter":      filter_bank,
    "delay":       delay_reverb,
    "lfo":         lfo_mod,
    "granular":    granular,
    "wavefolder":  wavefolder,
    "sample_hold": sample_hold,
}


def generate(count: int, seed: int, archetype: str | None, clean: bool) -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    if clean:
        n_removed = 0
        for p in OUT_DIR.glob("*.json"):
            try: p.unlink(); n_removed += 1
            except Exception: pass
        print(f"[clean] removed {n_removed} existing files in {OUT_DIR.name}/")

    keys = [archetype] if archetype else list(ARCHETYPES.keys())
    for k in keys:
        if k not in ARCHETYPES:
            print(f"[ERR] unknown archetype: {k}. Known: {', '.join(ARCHETYPES)}")
            return 1

    base_rng = random.Random(seed)
    per_arch = max(1, count // len(keys))
    remainder = count - per_arch * len(keys)
    emitted = 0
    for idx, k in enumerate(keys):
        n = per_arch + (1 if idx < remainder else 0)
        for i in range(n):
            sub_seed = base_rng.randint(0, 1 << 30)
            rng = random.Random(sub_seed)
            suffix, cfg = ARCHETYPES[k](rng, sub_seed)
            cfg_id = f"auto_{k}_{suffix}_{sub_seed:08x}"[:64]
            cfg.setdefault("rack_info", {})["auto_generated"] = True
            cfg["rack_info"]["archetype"] = k
            cfg["rack_info"]["seed"] = sub_seed
            out_path = OUT_DIR / f"{cfg_id}.json"
            out_path.write_text(json.dumps(cfg, indent=2, ensure_ascii=False) + "\n",
                                encoding="utf-8")
            emitted += 1

    print(f"[ok] wrote {emitted} rack config(s) to {OUT_DIR}")
    print("Next: python tools/module_research.py audio-rack-auto")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--count", type=int, default=20, help="total configs to emit")
    ap.add_argument("--seed", type=int, default=None, help="RNG seed (default: random)")
    ap.add_argument("--archetype", help="only this family (see --list)")
    ap.add_argument("--list", action="store_true", help="list archetypes")
    ap.add_argument("--clean", action="store_true", help="wipe auto/ dir first")
    args = ap.parse_args()

    if args.list:
        for k, fn in ARCHETYPES.items():
            doc = (fn.__doc__ or "").strip().splitlines()[0]
            print(f"  {k:<12s} {doc}")
        return 0

    seed = args.seed if args.seed is not None else random.randint(0, 1 << 30)
    print(f"seed={seed}  count={args.count}  archetype={args.archetype or 'all'}")
    return generate(args.count, seed, args.archetype, args.clean)


if __name__ == "__main__":
    sys.exit(main())
