from pathlib import Path
import hashlib, json

r = Path.cwd()
o = r / 'doc/book/iterations/2026-09-25-noise-opening-review'
maps = ['Random_Noise_Types', 'Noise_Columns', 'Noise_One', 'Noise_Voxel']
files = [str(p.relative_to(r)).replace('\\', '/') for m in maps for p in (r / 'commons/maps' / m).iterdir() if p.suffix in ['.md', '.json']]
files += ['commons/artifacts/perlin_terrain_sculptor/perlin_terrain_sculptor.gd',
          'algorithms/randomness/noisetorus/noisetorus.gd', 'algorithms/randomness/voxelnoise/voxelnoise.gd',
          'commons/data/museum_core_encounters.json', 'commons/data/dna_synthesis.json',
          'commons/artifacts/synthesis/synthesis_stand.gd', 'tools/synthesize_heroes.py',
          'commons/maps/sequences/noise.json', 'commons/data/book/noise.json', 'doc/tasks/book_noise.json']
files += [str(p.relative_to(r)).replace('\\', '/') for p in (r/'doc/book/captures/noise').glob('*') if p.is_file()]
assert not (o/'baseline.json').exists(), 'Baseline already frozen; do not overwrite it.'
hashes = {}
for rel in files:
    p = r/rel
    if not p.exists(): continue
    dest = o/'before'/rel
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(p.read_bytes())
    hashes[rel] = hashlib.sha256(p.read_bytes()).hexdigest()
(o/'baseline.json').write_bytes((json.dumps(hashes, indent=2)+'\n').encode())

def replace(rel, old, new):
    p = r/rel
    s = p.read_text(encoding='utf-8-sig')
    assert s.count(old) == 1, (rel, old)
    p.write_bytes(s.replace(old, new).encode('utf-8'))

replace('commons/maps/Random_Noise_Types/final.md',
        'It applies no pair-distance test. Shells may already be red before you touch anything.',
        'It applies no pair-distance test.\n\nShells may already be red before you touch anything.')
replace('commons/maps/Noise_Columns/final.md',
        "The stand's plaque records a chosen variant and a score from a saved comparison. That score explains something about the selection procedure; it cannot decide what you should want from this body.",
        "The plaque's 35% comes from comparing a saved image of these six orbs with one of the original orb. The score looks at the pixels that changed most.[^image-score] It helped choose a difference in pictures; it cannot decide what you should want from this body.")
p = r/'commons/maps/Noise_Columns/final.md'
p.write_bytes((p.read_text(encoding='utf-8').rstrip()+
    '\n\n[^image-score]: The comparison removes each image\'s corner background colour, converts it to greyscale at 160 × 160 pixels, and averages the largest 5% of absolute pixel differences on a scale from 0 to 1. The saved value 0.3509 is rounded to 35% on the plaque. It is not the percentage of the body, or of the pixels, that changed.\n').encode('utf-8'))
replace('commons/maps/Noise_One/final.md',
        "The room's opening now holds a small violet terrain within a pale coordinate frame.",
        'At the centre of the room, a small violet terrain stands within a pale coordinate frame.')
replace('commons/maps/Noise_Voxel/final.md',
        'The plate counts groups joined through cell faces. Stand beside the volume and ask what that count cannot tell you.',
        'The plate at the bench counts groups joined through cell faces. Stand beside the volume and ask what that count cannot tell you.')
replace('commons/maps/Noise_Voxel/final.md', 'In the recorded desktop comparison of 13 September 2026,',
        'In the recorded comparison of 13 September 2026,')

rel = 'commons/artifacts/perlin_terrain_sculptor/perlin_terrain_sculptor.gd'
replace(rel, '@export var height_gradient: bool = true',
        '@export var height_gradient: bool = true\n\n## Standalone shortcuts remain available; museum placements can reserve keys for movement.\n@export var keyboard_shortcuts: bool = true')
replace(rel, 'func _input(event):\n\tif event is InputEventKey and event.pressed:',
        'func _input(event):\n\tif not keyboard_shortcuts:\n\t\treturn\n\tif event is InputEventKey and event.pressed:')
replace(rel, 'func apply_grid_config(config_data: Dictionary):\n\t_grid_config = config_data',
        'func apply_grid_config(config_data: Dictionary):\n\t_grid_config = config_data\n\tif config_data.has("keyboard"):\n\t\tkeyboard_shortcuts = str(config_data["keyboard"]).to_lower() != "off"')
replace('commons/maps/Noise_Voxel/map_data.json',
        'perlin_terrain_sculptor:180:1.35:1#stand:lattice#seed:31415',
        'perlin_terrain_sculptor:180:1.35:1#stand:lattice#seed:31415#keyboard:off')
print('Frozen baseline; four narrow chapter revisions and one local keyboard setting applied.')
