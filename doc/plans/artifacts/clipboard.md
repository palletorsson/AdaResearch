# Artifact: Clipboard

> grabbable board with paginated text/code content, proximity reveal shader, VR page-flip via trigger/grip

## Context

**Category:** unknown | **Complexity:** beginner
**Tags:** interface, transformation, documentation, pagination, grabbable, vr, commons | **Themes:** commons, mixed

A world-space document you have to hold in order to read. Pages, code snippets, and tutorial fragments stay coherent while the object flips between states, positions, and content sets. Because it is grabbable, reading becomes an embodied interaction rather than a detached overlay. It is the sequence's stable carrier for changing information.

*a text in VR is not passive — the learner must pick it up, hold it, and navigate it with their hands*

## Design

- **Visual:** material: generated_texture, animation: transform
- **Scale:** [1.0, 1.0, 1.0] (compact)
- **Interaction:** learner picks up a physical document and reads it in VR — code and theory delivered as held artifact
- **Critical Parameter:** description_sets — the array of page strings; empty means no content, one means single-page
- **What Emerges:** reading as an embodied act — you must hold the clipboard to read it, creating intentional engagement
- **Triggers:** picking up → shows page navigation hint; trigger/grip buttons flip pages; drop → awards XP/SP

## Architecture

| | |
|---|---|
| **File** | `commons/context/clipboard/clipboard.gd` (538 lines) |
| **Scene** | `res://commons/context/clipboard/clipboard.tscn` |
| **Registry** | `commons_artifacts.json` |
| **Pattern** | clipboard |

### Exports

| Name | Type | Default |
|------|------|---------|
| `addxp` | int | 20 |
| `dessp` | int | -2 |
| `title` | - | "" |
| `description_sets` | Array[String] | [] |
| `fade_min_dist` | float | 1.5 |
| `fade_max_dist` | float | 2.0 |

### Dependencies

- `res://commons/context/clipboard/code_snippet_library.gd`
- `res://commons/context/clipboard/tutorial_text_library.gd`
- `res://commons/context/clipboard/smart_screen_reveal.gdshader`

### Key Methods

- `_process(_delta: float)` -- Proximity Reveal Logic (Smart Screen)
- `_ready()` -- Initialize tutorial library
- `_find_screen_mesh_recursive(node: Node)`
- `_on_item_dropped()`
- `_on_clipboard_picked_up(_pickable)` -- Update page display to show current page when picked up
- `_on_clipboard_dropped(_pickable)`
- `_next_page()`
- `_prev_page()`
- `_input(event: InputEvent)` -- Only process input if clipboard has multiple pages
- `_update_display()`
- `_extract_pages_from_metadata()`
- `_load_from_map_data()`
- `_get_title_from_map_data()`
- `refresh_content()`
- `apply_grid_config(config_data: Dictionary)`

### Grid Config


## Curriculum Position

### Sequences

- **Bricolage: From Parts to Structures** (bricolage) -- map: Bricolage_Inventory
- **Bricolage: From Parts to Structures** (bricolage) -- map: Bricolage_Affordances
- **Bricolage: From Parts to Structures** (bricolage) -- map: Bricolage_Arrays_as_Probes
- **Bricolage: From Parts to Structures** (bricolage) -- map: Bricolage_Constraints
- **Grammar Systems: Rules Generate Structure** (grammar_systems) -- map: ProceduralGeneration_Markov_Chains
- **Procedural Generation (All Maps)** (proceduralgeneration_all) -- map: ProceduralGeneration_Genetic_Programming
- **Procedural Generation (All Maps)** (proceduralgeneration_all) -- map: ProceduralGeneration_Markov_Chains
- **Randomness: Freedom from Pattern** (randomness) -- map: Random_Definition
- **Randomness: Freedom from Pattern** (randomness) -- map: Randomness_10_PRINT_Algorithm
- **Randomness: Freedom from Pattern** (randomness) -- map: Random_Pheromone
- **Randomness: Freedom from Pattern** (randomness) -- map: Random_Pheromone
- **Transformation: What Stays the Same When Everything Changes** (transformation) -- map: Trans_Scale
- **Unused** (unused) -- map: Directionality_Examples

### Map Placements

| Map | Cell | Config |
|-----|------|--------|
| Bricolage_Affordances | [1,6] | `#affordance_catalog_axioms:180:1.5` |
| Bricolage_Arrays_as_Probes | [1,7] | `#nested_arrays_axioms:180:1.5` |
| Bricolage_Constraints | [1,6] | `#constraint_catalog_axioms:180:1.5` |
| Bricolage_Inventory | [1,5] | `#bricolage_axioms:180:1.5` |
| Bricolage_Inventory | [8,1] | `#affordance_catalog_axioms:90:1.2` |
| Color_Sphere | [1,3] | `#rgb_axioms:180:1.5` |
| Directionality_Examples | [8,2] | `:0` |
| Point_Context | [4,2] | `#text_idenity:125:0.9` |
| Point_Context | [4,5] | `#the_trace:194:-0.3` |
| Point_Context | [12,0] | `#z_coordinate_system:180` |
| Point_Line_Context | [8,6] | `#grid_axioms:180:0.9` |
| ProceduralGeneration_Genetic_Programming | [2,2] | `#genetic_algorithms_axioms:180:1.2` |
| ProceduralGeneration_Markov_Chains | [1,2] | `#markov_chains_axioms:180:1.2` |
| Random_Definition | [13,4] | `#prng_axioms:-94` |
| Random_Pheromone | [6,2] | `#pheromone_axioms:194:1.0` |
| Random_Pheromone | [7,3] | `#queer_energy:194:1.0` |
| Random_Random_Bell_Curve | [6,5] | `#bell_curve_axioms:194:2.0` |
| Randomness_10_PRINT_Algorithm | [4,6] | `#ten_print_axioms:194:1.0` |
| Trans_Composition | [4,3] | `#vr_scale_controls:10:0:0.5` |
| Trans_Scale | [4,4] | `#vr_scale_controls:180:0:0.5` |
| ... | ... | +3 more |

### Relationships

- content loaded via apply_grid_config (tutorial ID or page keys); used in nearly every map
- Needs: [has grabbable GrabPlane [has], has VR trigger/grip page flip [has], has Label3D page number [has]]

## Verification

- [ ] Run scene directly
- [ ] Place in map, check interaction
- [ ] Capture screenshot

---
*Generated by generate_artifact_plans.py on 2026-04-15*
