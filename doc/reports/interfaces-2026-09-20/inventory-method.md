# What the full interface inventory establishes

This extends the earlier three-directory `.gd` signature audit. It is a source census, not a statement that every interface has been played, every control works, or every runtime instance has been counted.

## Scope and reproducibility

Run `python tools/interface_inventory.py` from the project root. The tool reads source and configuration and writes `full-inventory/`. It does not modify game content, registries, maps or the existing interface tracker.

- Search the checkout for `.gd`, `.tscn`, `.tres`, `.cs`, `.gdshader` and `.shader`. Historical and test source is retained with a separate scope label. Addons have their own label.
- Read runtime `.json`, `.cfg`, `.godot` and `.gdns` configuration and GDScript UID sidecars. Generated report data and archived data are excluded; their paths are recorded. Exclude build/export copies, dependency caches and version-control internals. `summary.json` and `excluded-report-data.json` specify the exclusions.
- Record every successfully read file, including files with no recognised interface evidence, with its hash in `files.json`. This is the coverage denominator; recognition is still heuristic.
- Extract native controls, native subclasses, candidate factories and named classes, data-driven widget recipes, scene nodes and resources, embedded GDScript and text drawing. Keep signal wiring, input polling and suggestive node names as separate evidence kinds.
- Follow explicit resource paths, known UIDs, relative resource paths, class inheritance and static class references transitively, with cycle handling and no depth cutoff.
- Link registered artifact keys to possible interface dependencies. Preserve duplicate definitions instead of silently choosing a winner. Link configured map cells to those keys, retaining the layer, coordinates and token parameters.

## How to read the numbers

**A source construction site is not a runtime instance.** A single call inside a loop can create twenty sliders. A factory can contain several optional controls, none of which are constructed in a particular configuration. Two scenes can reuse the same source. Registry aliases can name one scene twice.

**A reference is not proof of an encounter.** Dependency traversal deliberately reports possible use. It does not perform execution-path or variable-value analysis. Type names and helper references can broaden results. Configured map cells are not a claim that the museum currently instantiates that layer, or that curation makes the object prominent.

**A name is not proof of function.** `ButtonBacking` may be a decorative mesh. A connected signal does not establish that its handler has a useful effect. The existing default-demo capture already distinguishes interactive controls from passive prototype meshes.

**A label is not a screen.** `text_surface` includes labels and text meshes. `viewport_surface` includes render targets, mirrors and displays. `image_surface` includes passive imagery. `display_candidate` is a named screen/readout/monitor whose role needs inspection. Keep these families separate when reviewing readability.

**Static coverage is not exhaustive recognition.** Generated code, assembled paths, `call()` dispatch, native/plugin internals, generic meshes with custom hit testing, procedural instancing and runtime variants can evade or broaden the scan. `unresolved.json` is a review queue, not a list of confirmed bugs. In particular, an unresolved UID can have a valid path fallback, and a non-literal load expression can refer to a resolvable constant.

## Turning this into improvements

1. Use the inventory to select one real example per interaction family: action button, toggle/selector, continuous slider, stepped/bipolar control, rotary control, drawing/touch surface, direct grab, body/presence control and display-only feedback.
2. Check its actual implementation and active configuration. Record what action changes what state, which receiver changes, and how the player sees the consequence.
3. Capture the interface from the player position and enumerate its instantiated controls. Measure positions, target size, spacing, viewing angle and obstruction before judging its appearance.
4. Activate each control and verify an observable effect, including reset, limits and failure states. Desktop evidence and headset evidence remain separate.
5. Generalise successful arrangements into the principal presets and demo. Keep a justified custom arrangement when its action, body or receiver needs it.

The inventory supplies a candidate pool and traceable evidence. It should not trigger automatic replacement of all interfaces with one console or removal of manuscript passages.
