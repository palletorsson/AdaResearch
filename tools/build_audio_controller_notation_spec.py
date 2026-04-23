from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ENCYCLOPEDIA_ROOT = ROOT.parent / "ada_encyclopedia"
RACK_CONFIG_DIR = ROOT / "commons" / "audio" / "rack_configs"
RACK_PRESET_SCENE_DIR = ROOT / "commons" / "audio" / "rack_presets"
MODULE_LIBRARY_PATH = ROOT / "commons" / "audio" / "eurorack_modules" / "module_library.json"
SOUND_MANAGER_PATH = ROOT / "commons" / "audio" / "components" / "SoundParameterManager.gd"
OUT_PATH = ENCYCLOPEDIA_ROOT / "public" / "audio-controller-notation" / "spec.json"
RACK_GALLERY_DIR = ENCYCLOPEDIA_ROOT / "public" / "rack-gallery"
AUDIO_CONTROLLER_DIR = ENCYCLOPEDIA_ROOT / "public" / "audio-controller-notation"


SUPPORTED_KEYS = [
    {
        "key": "preset",
        "type": "string",
        "description": "Load a Eurorack preset from module_library.json. This takes priority over #config.",
        "example": "#preset:basic_mono",
    },
    {
        "key": "config",
        "type": "string",
        "description": "Load a rack JSON from commons/audio/rack_configs.",
        "example": "#config:synth_rack",
    },
    {
        "key": "sound",
        "type": "string",
        "description": "Override the sound generator key used when the controller plays audio.",
        "example": "#sound:pickup_mario",
    },
    {
        "key": "autoplay",
        "type": "bool",
        "description": "Auto-play the current sound once the controller is ready.",
        "example": "#autoplay:true",
    },
    {
        "key": "col_spacing",
        "type": "float",
        "description": "Override the rack column spacing in JSON-config mode.",
        "example": "#col_spacing:0.26",
    },
    {
        "key": "row_spacing",
        "type": "float",
        "description": "Override the rack row spacing in JSON-config mode.",
        "example": "#row_spacing:0.13",
    },
    {
        "key": "hide_selection",
        "type": "bool",
        "description": "Hide the category and sound-selection panel.",
        "example": "#hide_selection:true",
    },
    {
        "key": "hide_buttons",
        "type": "bool",
        "description": "Hide the play/save button strip.",
        "example": "#hide_buttons:true",
    },
]


EXAMPLES = [
    {
        "label": "Minimal preset token",
        "token": "AudioContr:-90#preset:basic_mono",
        "notes": "Rotate the artifact -90 degrees and load the basic Eurorack preset.",
    },
    {
        "label": "Preset with clean kiosk UI",
        "token": "AudioContr:180#preset:interface_prototypes#hide_selection:true#hide_buttons:true",
        "notes": "Front-face the controller and strip away the legacy UI panels.",
    },
    {
        "label": "Rack config with sound override",
        "token": "AudioContr#config:synth_rack#sound:pickup_mario#autoplay:true",
        "notes": "Load a JSON rack, swap the sound generator, then auto-play it.",
    },
    {
        "label": "Full transform + spacing tuning",
        "token": "AudioContr:90:0.2:1.1#config:slider_rack#col_spacing:0.26#row_spacing:0.13",
        "notes": "Rotate, lift, and scale the artifact before applying a tighter rack layout.",
    },
]


def extract_sound_types() -> list[str]:
    text = SOUND_MANAGER_PATH.read_text(encoding="utf-8")
    start = text.find("static var sound_type_files = {")
    if start == -1:
        return []
    brace_start = text.find("{", start)
    brace_end = text.find("}\n\n# Default parameters", brace_start)
    if brace_start == -1 or brace_end == -1:
        return []
    block = text[brace_start + 1 : brace_end]
    sound_types: list[str] = []
    for raw_line in block.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if not line.startswith('"'):
            continue
        key = line.split(":", 1)[0].strip().strip('"')
        if key:
            sound_types.append(key)
    return sorted(sound_types)


def build_spec() -> dict:
    rack_configs = sorted(path.stem for path in RACK_CONFIG_DIR.glob("*.json"))
    rack_preset_scenes = sorted(
        path.stem
        for path in RACK_PRESET_SCENE_DIR.glob("*.tscn")
        if path.stem.startswith("rack_")
    )
    module_library = json.loads(MODULE_LIBRARY_PATH.read_text(encoding="utf-8"))
    presets = sorted(module_library.get("rack_presets", {}).keys())
    sound_types = extract_sound_types()
    preset_images = {
        name: f"/audio-controller-notation/presets/{name}.png"
        for name in presets
        if (AUDIO_CONTROLLER_DIR / "presets" / f"{name}.png").exists()
    }
    config_images = {
        name: f"/rack-gallery/{name}.png"
        for name in rack_configs
        if name != "all_components" and (RACK_GALLERY_DIR / f"{name}.png").exists()
    }
    rack_preset_scene_images = {
        name: f"/audio-controller-notation/rack-presets/{name}.png"
        for name in rack_preset_scenes
        if (AUDIO_CONTROLLER_DIR / "rack-presets" / f"{name}.png").exists()
    }

    return {
        "title": "Audio Controller Notation",
        "artifact": "AudioContr",
        "scene": "res://commons/audio/UniversalVRAudioController.tscn",
        "scene_preset_artifact": "RackPreset",
        "scene_preset_dir": "res://commons/audio/rack_presets/",
        "syntax": {
            "pattern": "AudioContr[:rotation_y][:y_offset][:uniform_scale][#key:value...]",
            "rotation": "Optional yaw in degrees, e.g. :-90",
            "height": "Optional vertical offset in grid units/meters used by the grid parser",
            "scale": "Optional uniform scale multiplier",
        },
        "behavior_notes": [
            "The artifact token is parsed by GridInteractablesComponent before config keys are applied.",
            "Inside UniversalVRAudioController.apply_grid_config(), #preset wins over #config if both are present.",
            "Booleans are passed as strings in map notation and interpreted from values like true / false.",
        ],
        "supported_keys": SUPPORTED_KEYS,
        "available_presets": presets,
        "available_configs": rack_configs,
        "available_scene_presets": rack_preset_scenes,
        "available_sound_types": sound_types,
        "preset_images": preset_images,
        "config_images": config_images,
        "scene_preset_images": rack_preset_scene_images,
        "examples": EXAMPLES,
        "source_files": {
            "notation_parser": "res://commons/grid/GridInteractablesComponent.gd",
            "audio_controller": "res://commons/audio/UniversalVRAudioController.gd",
            "sound_types": "res://commons/audio/components/SoundParameterManager.gd",
            "scene_presets": "res://commons/audio/rack_presets/README.md",
        },
    }


def main() -> None:
    spec = build_spec()
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(json.dumps(spec, indent=2), encoding="utf-8")
    print(f"[ok] wrote {OUT_PATH}")


if __name__ == "__main__":
    main()
