# Find the text, then the actual encounter

All repository paths here are relative to C:/Users/palle/Documents/GitHub/AdaResearch_46. Work from that directory.

## Authority chain

1. commons/maps/curriculum_spine.json supplies spine membership/order; commons/maps/sequences/<sequence>.json supplies that sequence's current map list. Older prose and frozen packets can describe another order.
2. commons/maps/<Map>/final.md is the canonical book chapter. Read intent.md, critical.md, technical.md, tutorial.md, artifacts.md, field_notes.md and other companions when present. Their claims can be older; they are research material, not automatic replacements.
3. map_data.json holds placement tokens in layers.interactables, alongside structure/utilities and museum settings. inventory.json preserves literal tokens and raw nested array indices; those indices are **not world coordinates**.
4. The leading lookup resolves through commons/artifacts/registry/*.json to a res://...tscn scene. Inspect its scripts/resources and the actual map configuration. A registry description is a discovery aid, not proof of runtime behavior.
5. Museum construction/overrides, artifact roles and saved plans affect what is encountered. commons/data/museum_core_encounters.json selects a reading path but does not exhaust what belongs in a hall. Inspect roles and scene construction when the decision depends on them. A raw zero grid cell does not establish a pit, and the source grid alone does not establish the walkable museum.

Preserve whole tokens when reading configuration. For example, the changing-stack placement is random_decay_multimesh#stack_fit:10; the parameter belongs to the encounter. Do not infer parsing or vertical alignment from a generic template. Follow the loader when needed.

## Read-only discovery commands

```powershell
python tools/lod_query.py randomness
python tools/lod_query.py Randomness_10_PRINT_Algorithm
python tools/artifact_impact.py ten_print_maze_3d --terse
python tools/artifact_impact.py random_decay_multimesh --json
rg -n '"ten_print_structure"|"ten_print_maze_3d"' commons/artifacts/registry
```

LOD is an index and may lag the live tree. The impact command reports registry, other placements, sequences and existing capture references; it is read-only. A missing lookup in one index is not proof of absence from the project. Search narrowly with rg, then follow actual scene/script references.

When the reading site is running, these views can help:

- http://localhost:3003/compose/sources?map=Randomness_10_PRINT_Algorithm&doc=final
- http://localhost:3003/long-museum/encounters?map=Randomness_10_PRINT_Algorithm
- http://localhost:3003/map-curator?view=contributions&sequence=randomness&map=Randomness_10_PRINT_Algorithm
- http://localhost:3003/api/artifact/ten_print_maze_3d

The artifact endpoint's GET implementation was inspected in the sibling ada_encyclopedia/src/app/api/artifact/[token]/route.ts. It offers registry/script/use context; this handover did not test all its responses. It does not establish placement-specific runtime behavior. Use the repository if the site is unavailable.

## Packet contents

inventory.json records current sequence order, primary tokens, prose anchors, all placed tokens, registry matches, scene paths/hashes, companions and baseline hashes. Duplicate registry matches and unresolved lookups remain visible; resolve them through the loader rather than choosing whichever match is convenient.

snapshot/ contains assigned manuscripts, companion markdown, maps and sequence definitions. manuscripts/ combines current chapters for reading. references/ contains exact current voice references. MAPS.md is a concise navigation index. None are runtime evidence. Native images and artifact source dependencies are not copied into this handover; follow their live paths locally. This is not a self-contained online source review bundle.

## Verify proportionately

Check the consequential claim being changed: the actual update, replay, collision, support, route or gesture. Use an existing targeted probe when it tests that claim; do not rerun the whole museum for punctuation. A source check supports a source claim. Calling the same method twice does not necessarily test visitor interaction.

For a new capability claim, establish its input and visible/bodily consequence with an appropriate runtime check. If only source inspection is possible, say so in field notes. A staged render shows a composition; it does not prove a route or tracked hand works. Desktop controller tests are not headset comfort or learner evidence. Use native Godot figures when a working study can serve both museum and book. Do not replace evidence with generated illustrations.
