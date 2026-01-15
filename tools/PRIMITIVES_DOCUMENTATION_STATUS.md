# Primitives Sequence Documentation Status

## Completed (3/13)

✅ **Point_Zero** - All 3 docs complete
- `commons/maps/Point_Zero/summary.md`
- `commons/maps/Point_Zero/technical.md`
- `commons/maps/Point_Zero/critical.md`

✅ **Point_One** - All 3 docs complete
- `commons/maps/Point_One/summary.md`
- `commons/maps/Point_One/technical.md`
- `commons/maps/Point_One/critical.md`

✅ **Point_Line** - All 3 docs complete
- `commons/maps/Point_Line/summary.md`
- `commons/maps/Point_Line/technical.md`
- `commons/maps/Point_Line/critical.md`

## Remaining (10/13)

### Next Priority

⏳ **Point_Lines** - Needs all 3 docs
- Reuse content from: `grid_axioms.md`, `line_axioms.md`
- Key themes: Networks, grids, addressability, political mapping
- Features: modulor_man_demo, parallel_line_puzzle, grab_line tools
- Critical angle: Grid as governance, quantization as violence

⏳ **Point_Trace** - Needs all 3 docs
- Reuse content from: existing tutorial about duration/embodiment
- Key themes: Duration, gesture, resistance to discretization
- Features: draw_dot tool for continuous tracing
- Critical angle: Trace vs. line, embodied vs. measured

⏳ **Point_Line_Grid** - Needs all 3 docs
- Reuse content from: `grid_axioms.md`
- Key themes: Coordinate systems, indexing, addressability
- Critical angle: Grids enable calculation while erasing locality

### Triangle Sequence

⏳ **Point_Triangle** - Needs all 3 docs
- Reuse content from: `triangle_axioms.md` ✓ (excellent content already exists!)
- Key themes: Closure, surface, inside/outside
- Features: Editable triangle with grabbable vertices
- Critical angle: Triangle as governance, boundary as exclusion

⏳ **Point_Triangle_Context** - Needs all 3 docs
- Reuse content from: `triangle_axioms.md`, `quad_axioms.md`
- Key themes: Rigidity, Pythagorean theorem, triangulation
- Features: Multiple triangle variations, pythagorean proof, quads
- Critical angle: Geometric constraint as political constraint

### Advanced Primitives

⏳ **Primitives_1** - Needs all 3 docs
- Reuse content from: `primitives_axioms.md`
- Survey/synthesis map bringing together points, lines, triangles

⏳ **Point_Animatedcube** - Needs all 3 docs
- Reuse content from: `cube_axioms.md`
- Key themes: 3D volume, faces, procedural generation
- Features: Animated cube builder (we fixed reflections!)
- Critical angle: Volume as enclosure, the cube as unit

⏳ **Primitives_Ignorance** - Needs all 3 docs
- Meta-map about what primitives cannot represent
- Critical focus: Gaps, absences, exclusions

⏳ **Primitives_Portals** - Needs all 3 docs
- Transition map to other sequences
- Shows how primitives enable other systems

⏳ **Primitives_Melencolia** - Needs all 3 docs
- Reuse content from: `melencolia_axioms.md`
- Dürer's Melencolia I - magic squares, geometry, melancholy
- Final reflection on geometric knowledge

## Content Reuse Map

### Existing Tutorial Files to Incorporate

From `commons/context/clipboard/tutorial_text/`:

- `point_axioms.md` → Point_Zero, Point_One ✓
- `point_zero.md` → Point_Zero ✓
- `line_axioms.md` → Point_Line ✓, Point_Lines
- `triangle_axioms.md` → Point_Triangle, Point_Triangle_Context
- `grid_axioms.md` → Point_Lines, Point_Line_Grid
- `cube_axioms.md` → Point_Animatedcube
- `quad_axioms.md` → Point_Triangle_Context
- `primitives_axioms.md` → Primitives_1
- `melencolia_axioms.md` → Primitives_Melencolia

### Critical Themes Library

**For Technical Docs:**
- Reuse existing axiom .md files extensively
- Add map-specific implementation details
- Include Godot code examples from actual scene files

**For Critical Docs:**
- Point/Line: Discretization, compression, erasure
- Triangle: Enclosure, governance, binary boundaries
- Grid: Indexing, addressability, colonial mapping
- Cube: Volume, containment, standardization
- Melencolia: Melancholy of geometric knowledge

## Next Steps

1. **Read existing map_data.json** for remaining maps
2. **Extract structure/interactables** to describe spatial layout
3. **Incorporate existing axiom content** into technical.md
4. **Develop critical reflections** using established themes
5. **Generate all 3 docs** per map

## Template Locations

Templates are in:
- `commons/context/clipboard/tutorial_text/_TEMPLATE_map_summary.md`
- `commons/context/clipboard/tutorial_text/_TEMPLATE_technical_tutorial.md`
- `commons/context/clipboard/tutorial_text/_TEMPLATE_critical_reflection.md`

## Quality Standards

Each map should have:

### Summary.md
- Clear spatial description
- All interactables listed
- Learning sequence outlined
- Design intent explained
- Position in sequence noted

### Technical.md
- Reuses existing axiom content
- 3-5 code examples
- Implementation specifics for this map
- Godot/VR details
- Key takeaway

### Critical.md
- "What X Cannot Hold" section
- Political/philosophical analysis
- Embodiment discussion
- Queer possibilities
- Conclusion tying tech+critique

## Progress Tracking

Run this to see completed docs:
```bash
find commons/maps -name "summary.md" | wc -l
find commons/maps -name "technical.md" | wc -l
find commons/maps -name "critical.md" | wc -l
```

Target: 13 of each (39 total files for primitives sequence)
Current: 3 of each (9 total files)
Remaining: 10 maps × 3 docs = 30 files
