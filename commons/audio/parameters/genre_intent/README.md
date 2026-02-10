# Genre Intent Profiles

These files define **advisory guidance** for genre suits.

They are intentionally non-blocking:
- no validation gates
- no build restrictions
- no forced structure

The goal is to keep genre research available to generators, tools, and skills
while preserving experimentation.

## Path

`res://commons/audio/parameters/genre_intent/*.json`

## Schema (v1)

```json
{
  "_meta": {
    "version": 1,
    "mode": "advisory",
    "strict": false
  },
  "genre_id": "example_genre",
  "suit_guidance": {
    "core_roles": [],
    "common_roles": [],
    "experimental_roles": [],
    "continuity_preferences": []
  },
  "tempo": {
    "preferred_bpm": 120,
    "bpm_range": [110, 130]
  },
  "harmony": {
    "preferred_keys": [],
    "priority_progressions": [],
    "harmonic_devices": []
  },
  "rhythm": {
    "groove_notes": [],
    "swing_range": [0.0, 0.2]
  },
  "arrangement": {
    "energy_curve": [],
    "notes": []
  },
  "references": {
    "artists": [],
    "tracks": []
  }
}
```

## Usage

`SuitToSoundbankMapper` loads these profiles and adds them to runtime suite payloads
under the `intent` key.

Downstream systems can read and apply them softly.
