# How to Add a New Map Sequence

This guide explains how to create and register a new map sequence in AdaResearch.

## Overview

A **sequence** is a series of maps that the player progresses through linearly. Sequences are used for tutorials, thematic explorations, and structured learning paths.

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

## Step 5: Create Post-Sequence Lab Variant (Optional)

Create a Lab variant that appears after completing your sequence:

**File:** `commons/maps/Lab/map_data_post_your_sequence.json`

```json
{
	"map_info": {
		"name": "Lab - Post Your Sequence",
		"description": "Lab after completing your sequence",
		"metadata": {
			"post_sequence": "your_sequence_name",
			"narrative": "Describe what changed after completing this sequence"
		}
	},
	"completed_sequences": ["your_sequence_name"],
	// ... rest of lab structure ...
}
```

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
- [ ] `commons/maps/Lab/map_data_*.json` - Add teleporter (optional)
- [ ] `commons/maps/Lab/map_data_post_your_sequence.json` - Post-sequence variant (optional)

## Additional Resources

- **Sequence patterns:** See `commons/maps/sequences/` for examples
- **Lab variants:** See `commons/maps/Lab/` for different Lab states
- **Map structure:** See `doc/MAP_STRUCTURE.md` for map format details
- **Teleporter options:** See `commons/grid/GridUtilitiesComponent.gd` for utility definitions
