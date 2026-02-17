# How to Add a New Map Sequence

This guide explains how to create and register a new map sequence in AdaResearch.

## Overview

A **sequence** is a series of maps that the player progresses through linearly. Sequences are used for tutorials, thematic explorations, and structured learning paths.

## Fast Path: Spine Map Workbench

For map-building sessions, use the workbench CLI to audit spine coverage, suggest artifacts, scaffold new maps, and append them to a sequence:

```powershell
# 1) Check full playable spine status + update taxonomy status block
python tools/spine_map_workbench.py status --report doc/reports/SPINE_MAP_BUILD_STATUS.md --update-taxonomy doc/TAXONOMY.md

# 2) Get artifact suggestions for a sequence
python tools/spine_map_workbench.py suggest --sequence noise --limit 12

# 3) Create a scaffold map and auto-add it to the sequence maps list
python tools/spine_map_workbench.py scaffold --sequence noise --map Noise_New_01 --auto-artifacts 3 --update-sequence
```

This is the recommended workflow when your goal is to keep the full spine playable while rapidly adding maps.

## Artifact Bridge Policy (Folders vs Sequences)

Artifacts can live in either `res://commons/...` or `res://algorithms/...`.  
Sequence ownership should come from registry metadata, not folder location.

- Use `lookup_name` as the stable artifact ID.
- Use registry fields like `sequence`, `category`, `dev_category`, and `tags` to bridge artifacts into sequence maps.
- It is valid for multiple sequences to reuse artifacts from the same folder domain (for example `randomness` and `noise`).
- In-progress artifacts are allowed: if a registry entry has a missing/unresolved `scene`, runtime now falls back to `res://commons/artifacts/placeholders/ArtifactPlaceholder.tscn`.
- Sequence membership for maps is explicit in each sequence JSON `maps[]`. A map name prefix alone does not assign the map to that sequence.

This keeps map flow playable while you gradually replace placeholders with real artifact scenes.

## Step 1: Create the Sequence Definition

Create a new JSON file in `commons/maps/sequences/` with your sequence name:

**File:** `commons/maps/sequences/your_sequence_name.json`

```json
{
	"sequences": {
		"your_sequence_name": {
			"name": "Display Name for UI",
			"description": "What this sequence teaches",
			"layer": "foundation|exploration|integration|synthesis",
			"prerequisites": ["primitives", "randomness"],
			"unlocks": ["advanced_topic"],

			"difficulty": "beginner|intermediate|advanced",
			"estimated_time": "15-20 minutes",

			"learning_objectives": [
				"First concept to learn",
				"Second concept to learn",
				"Third concept to learn"
			],

			"maps": [
				"First_Map_Name",
				"Second_Map_Name",
				"Third_Map_Name"
			],

			"return_to": "lab",
			"lab_map": "Lab/map_data_post_your_sequence",

			"completion_rewards": [
				"badge_name",
				"another_badge"
			]
		}
	}
}
```

### Key Fields:
- **`name`**: Human-readable title shown in UI
- **`maps`**: Array of map folder names in order
- **`return_to`**: Where to go after completion (usually "lab")
- **`lab_map`**: Which Lab variant to load after completing this sequence
- **`prerequisites`**: Sequences that must be completed first
- **`unlocks`**: Sequences that become available after this one

## Step 2: Register in GridSystem

Add your sequence name to the `known_sequences` list in **GridSystem.gd** (around line 179):

```gdscript
func _is_sequence_name(name: String) -> bool:
	var known_sequences = [
		"primitives", "transformation", "color",
		// ... existing sequences ...
		"your_sequence_name",  // ADD YOUR SEQUENCE HERE
		"testmaps"
	]
	return name in known_sequences
```

## Step 3: Register in LabGridSystem

Add your sequence name to the `known_sequences` list in **LabGridSystem.gd** (around line 406):

```gdscript
func _is_sequence_name(name: String) -> bool:
	var known_sequences = [
		"primitives", "transformation", "color",
		// ... existing sequences ...
		"your_sequence_name",  // ADD YOUR SEQUENCE HERE
		"testmaps"
	]
	return name in known_sequences
```

## Step 4: Add Lab Teleporter (Optional)

To make your sequence accessible from the Lab, add a teleporter in a Lab map variant:

**File:** `commons/maps/Lab/map_data_post_prerequisites.json`

In the `utilities` layer, add:
```json
"utilities": [
	["t:your_sequence_name", " ", " "],
	// ... other utilities ...
]
```

The teleporter format is: `t:sequence_name:rotation:height:scale`
- Just `t:your_sequence_name` uses defaults (rotation=0, height=1.0, scale=0.5)

## Step 5: Create Post-Sequence Lab Variant (Required for spine sequences)

The Lab is one living space that grows. Each `map_data_post_*.json` is a snapshot of the Lab after completing a sequence. **Every post-map must be a strict superset of the previous one in the chain** — you can add structure, teleporters, and artifacts, but never remove them.

### The Chain Rule

The Lab progression chain is defined in `curriculum_spine.json` → `lab_evolution.actual_progression`. Each entry's map must contain everything from the previous entry's map, plus new content.

```
map_data.json → post_primitives → post_transformation → post_color → 
post_wavefunctions → post_forces → post_noise → post_cellularautomata → 
post_fractals → post_softbodies → post_morphogenesis → post_machinelearning → 
post_foundationscrisis → post_qfeplaboratory
```

### How to add your post-map

1. **Find your position in the chain** — check `curriculum_spine.json` `lab_evolution`
2. **Copy the previous stage's post-map** as your starting point
3. **Add your new content** (teleporters, artifacts, opened passages)
4. **Leave void space** (`0` cells) where future stages will expand
5. **Run the audit** to verify continuity:

```bash
python scripts/audit_lab_chain.py
```

All transitions should show either `OK (superset)` or only `STRUCTURE CHANGED` (opening passages). Never `LOST`.

### If things get out of sync

The rebuild script reconstructs the entire chain from the original maps:

```bash
python scripts/rebuild_lab_chain.py
```

This reads each map's unique additions and accumulates them forward, guaranteeing monotonic growth. It also fixes common issues like `m:t:destination:0.1` (should be `m:0.1`).

### Key rules

- **Teleporters**: `t:destination` or `t:destination:rotation:height:scale`. Each destination should appear at exactly one position per stage (it can move between stages).
- **Structure heights**: Changing a wall (`6`) to floor (`1`) is how you "open" a passage — this is an intentional change, not a loss.
- **Dimensions grow or stay**: Grid width/height can increase, never decrease.
- **Preserve everything**: All artifacts, utilities, and interactables from earlier stages must persist.

## Common Issues & Solutions

### Issue: "No map data found" / Stuck at "loading..."

**Cause:** Sequence name not registered in `known_sequences` lists.

**Solution:** Make sure you added the sequence name to BOTH:
- `GridSystem.gd` line ~179
- `LabGridSystem.gd` line ~406

### Issue: Teleporter loads as map instead of sequence

**Console shows:** `"LabGridSystem: Map-based teleporter 'your_name' -> sequence ''"`

**Cause:** Missing from `LabGridSystem.gd` known_sequences list.

**Solution:** Add to `LabGridSystem._is_sequence_name()` list.

### Issue: Sequence not found by AdaSceneManager

**Cause:** JSON file not in `commons/maps/sequences/` directory.

**Solution:** Verify file is saved in correct location with correct name.

## Testing Your Sequence

1. **Launch game** and enter the Lab
2. **Check console** for: `"AdaSceneManager: ✅ Successfully loaded N sequence configurations"`
3. **Activate teleporter** (or run `/start_sequence your_sequence_name` in debug console)
4. **Verify console output:**
   ```
   LabGridSystem: Direct sequence teleporter: 'your_sequence_name'
   LabGridSystem: Starting sequence 'your_sequence_name'
   AdaSceneManager: Loading grid scene with map: First_Map_Name
   ```
5. **Confirm first map loads** successfully
6. **Test progression** - complete first map and verify it advances to second map
7. **Test completion** - finish sequence and verify return to Lab

## Example: QFEP Laboratory Sequence

See `commons/maps/sequences/qfeplaboratory.json` for a complete example with:
- 9 maps progressing through QFEP concepts
- Custom learning objectives per section
- Post-sequence Lab variant with QFEP controls
- Integration with artifact registry

## File Checklist

When adding a new sequence, you should modify these files:

- [ ] `commons/maps/sequences/your_sequence_name.json` - Sequence definition
- [ ] `commons/grid/GridSystem.gd` - Add to known_sequences (~line 179)
- [ ] `commons/scenes/LabGridSystem.gd` - Add to known_sequences (~line 406)
- [ ] `commons/maps/Lab/map_data_post_*.json` - Add teleporter to the right stage's post-map
- [ ] `commons/maps/Lab/map_data_post_your_sequence.json` - Post-sequence Lab variant (copy previous stage, add new content)
- [ ] `commons/maps/curriculum_spine.json` - Add to `lab_evolution.actual_progression` if spine sequence
- [ ] Run `python scripts/audit_lab_chain.py` - Verify zero LOST issues in the chain

## Additional Resources

- **Sequence patterns:** See `commons/maps/sequences/` for examples
- **Lab variants:** See `commons/maps/Lab/` for different Lab states
- **Map structure:** See `doc/MAP_STRUCTURE.md` for map format details
- **Teleporter options:** See `commons/grid/GridUtilitiesComponent.gd` for utility definitions
