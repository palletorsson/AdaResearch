# KnowledgeTerrainSpace — How to Use in Maps

## What It Is
The AdaResearch curriculum itself rendered as walkable landscape. Concepts are peaks, QFEP phases determine elevation, category neighborhoods cluster spatially, spine connections are visible paths. The terrain IS the knowledge graph.

*"The ground you walk on is shaped by what humanity wrote down."*

## Scene Path
```
res://commons/context/walkgrids/knowledge_terrain_space.tscn
```

## Drop Into a Map Scene

```gdscript
var kt = preload("res://commons/context/walkgrids/knowledge_terrain_space.tscn").instantiate()
kt.space_size = Vector2(40, 40)
kt.resolution = 80
kt.terrain_scale = 5.0
kt.show_concept_markers = true
kt.height_scale = 2.0
add_child(kt)
```

## Key Parameters

| Parameter | Default | What It Does |
|-----------|---------|-------------|
| `terrain_scale` | 5.0 | How spread out concepts are |
| `concept_influence_radius` | 3.0 | How far each concept affects terrain |
| `base_height` | 0.5 | Minimum terrain height |
| `phase_height_influence` | 1.5 | How much QFEP phase affects elevation |
| `show_concept_markers` | true | Show labeled spheres at each concept |
| `marker_height` | 2.0 | How high markers float above terrain |

## QFEP Phase → Height Mapping

| Phase | Height | Color | Meaning |
|-------|--------|-------|---------|
| F_order | 0.5 | Blue | Order, prediction — low terrain |
| oscillation | 0.7 | Purple | F↔E balance |
| E_entropy | 0.9 | Red | Entropy, disorder |
| lambda_edge | 1.2 | Orange | Edge of chaos |
| integration | 1.4 | Green | φΔE emergence |
| synthesis | 1.6 | Pink | Full QFEP — highest peaks |

## Map Integration Examples

### Meta-Learning Map — The Curriculum as Terrain
```gdscript
func _ready():
    var kt = KnowledgeTerrainSpace.new()
    kt.terrain_scale = 6.0
    kt.space_size = Vector2(50, 50)
    kt.show_concept_markers = true
    kt.phase_height_influence = 2.0  # Exaggerate phase differences
    add_child(kt)
```

### Without Markers — Pure Terrain
```gdscript
# The knowledge graph as unlabeled landscape — let students discover
var kt = KnowledgeTerrainSpace.new()
kt.show_concept_markers = false
kt.space_size = Vector2(40, 40)
kt.height_scale = 3.0
add_child(kt)
```

### Interactive Concept Lookup
```gdscript
var kt: KnowledgeTerrainSpace

func _ready():
    kt = KnowledgeTerrainSpace.new()
    kt.space_size = Vector2(40, 40)
    add_child(kt)

func _process(_delta):
    # Show nearest concept as player walks
    var player_pos = $Player.global_position
    var concept = kt.get_concept_at_position(player_pos)
    if concept != "":
        $UI/ConceptLabel.text = concept

func _on_concept_selected(name: String):
    # Teleport player to a concept
    var pos = kt.teleport_to_concept(name)
    $Player.global_position = pos
    kt.highlight_concept(name)
```

### Find Nearby Concepts
```gdscript
# What concepts are near the player?
var nearby = kt.get_nearby_concepts($Player.global_position, 8.0)
for concept_name in nearby:
    print("Nearby: ", concept_name)
```

## API Methods

| Method | Returns | What It Does |
|--------|---------|-------------|
| `get_concept_at_position(Vector3)` | String | Nearest concept name (or "" if too far) |
| `get_nearby_concepts(Vector3, radius)` | Array[String] | All concepts within radius |
| `highlight_concept(name)` | void | Enlarge + brighten a concept marker |
| `teleport_to_concept(name)` | Vector3 | Get position above a concept for teleporting |

## Data Sources
- Reads from `res://commons/maps/curriculum_spine.json`
- Falls back to WorldMapDataProvider if available
- Category positions are hand-tuned in `CATEGORY_POSITIONS` constant

## Teaching Suggestions
- This IS the meta-lesson: the curriculum has a shape
- Higher terrain = later QFEP phases = more complex understanding
- Category neighborhoods show how topics cluster
- Spine connections show the intended learning path
- Walking from "Primitives" to "Synthesis" is literally ascending

## Performance Notes
- Generation depends on curriculum size — typically fast (< 100 sequences)
- Concept markers use CSGSphere3D + Label3D — keep `show_concept_markers` off for VR perf
- Connection lines use ImmediateMesh — lightweight
- Static terrain — no per-frame cost (except Label3D billboarding)
