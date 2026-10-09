# Interface principles: coverage and integration plan

## Latest spine pass: Polyhedra (21 September 2026)

[Reach the corner](../../book/iterations/2026-09-21-interface-spine-polyhedra-review/index.html): the editable pyramid now faces the aisle on a low micropod, with larger visible grips and a compact physical reset station. Flat captions explain the held-state guard; native reset preserves the active constraint rule. The primary trihedron and tetrahedron also face clear approaches. 46 functional checks plus 42 actual-hall checks pass, including separate close standing poses for every pyramid vertex. Headset and seated testing remain open. [Reproduction and handoff](../interfaces-2026-09-21/spine-polyhedra/README.md). Next: Point_Animatedcube. RockScanner's unfinished section display and the trihedron's unassigned alternate material remain separate development items.

## Latest spine pass: Triangle (21 September 2026)

[Triangle, within reach](../../book/iterations/2026-09-21-interface-spine-triangle-review/index.html): both primary consoles in Point_Triangle_Context now have compact native 3D buttons, flat screen text, explicit fill state and lower inclined mounts. Excluding the console from museum seating bounds fixes the raised drawing station. 61 functional checks and 28 actual-hall checks pass, including the concave fan comparison and usable side approaches around the column. Headset usability and Quest performance remain open. [Reproduction and handoff](../interfaces-2026-09-21/spine-triangle/README.md). Next along the spine: Primitives_Polythedra; Grid's separate snap-sphere display remains an open item.

## Latest spine pass: Trace and Grid (21 September 2026)

[Hold the page](../../book/iterations/2026-09-21-interface-spine-primitives-review/index.html): fixed flat data instruments in Point_Trace and Point_Line_Grid, compact physical archive paging, held-by-default reading and optional Auto. Grid's inclined case now stands before and beside the lattice on an upright support. 53 recorder/paging checks and 24 actual-hall checks pass. Headset comfort, seated reach and Quest performance remain open. [Reproduction and handoff](../interfaces-2026-09-21/spine-primitives/README.md). Next: Point_Triangle_Context; the separate snap-sphere display in Grid also remains to review. This is a placement pass on two instruments, not certification of all interfaces in these halls.


## Latest pass: scalar controls (21 September 2026)

The library's shared sliders and audio dials now pass 471 functional checks, plus 173 all-page checks and 12 mounted-mixer regressions. Fixed vertical audio axis/offset, bounded axis-slider travel, local-coordinate grabs, stationary-hand drift, pointer ownership/release, and automatic/manual handover. All library text remains flat. The new review shows actual minimum/maximum positions: [scalar review](/book-review/doc/book/iterations/2026-09-21-interface-scalar-review/index.html).

Placement finding: Gallery_Furniture is a storage-gallery map outside the current museum plan/spine; the isolated museum test fell back to Point_One. Do not claim the library's floor token proves a reachable endless-museum placement. Next: intentional test-room entry and full approach/reach verification, then mixed-control racks. Detailed handoff: `doc/reports/interfaces-2026-09-21/scalar-controls/README.md`.


Latest mount and library pass (21 September): [one place to try every control](../../book/iterations/2026-09-21-interface-library-review/index.html) gives Point_One an opt-in supported 32-degree radio incline, clearing its numeric-window sight lines while retaining grip reach (55 hall checks). The component library now holds all 28 specimens across 11 compact pages with physical paging, flat legacy value cards and held-control guards. Visible bounds are 1.10 x 1.725 x 0.535 m; 173 checks cover pages, geometry, live values and shared audio analyser cleanup. The prior radio suite passes (78). [Reproduction and remaining scope](../interfaces-2026-09-21/console-placement/README.md). Next: legacy slider/audio-dial input under these inclined mounts and the library in Gallery_Furniture; headset and listening tests remain open.


Latest placement and lever pass (21 September): [what stays when you let go](../../book/iterations/2026-09-21-interface-lever-review/index.html) places the radio in Point_One at cell (3,4), on a 0.85 m plinth, facing minus Z, with a secondary role. Actual hall floor, approach, ray and grab checks pass (42). The stepped and returning levers now inherit the shared base, preserve hand poses, and demonstrate continuous / 5-degree / return-to-zero behavior in a compact InteractableDemo reference (100 checks). Slow pointer motion now crosses detents reliably; angular (100) and radio (78) regressions pass. [Implementation and headset handoff](../interfaces-2026-09-21/lever-variants/README.md). Next: assembled component-library panels; headset comfort and listening remain pending.


Status: shared text, compact Foundry, QFEP console, mixed-control reference and Shannon adoption implemented on 20 September 2026. Wider interface migration remains open. Builds on the [current-state audit](README.md).

Latest radio consumer (21 September): [turn until you hear it](../../book/iterations/2026-09-21-interface-radio-review/index.html) rebuilds SoundscapeRadioRack around two full-size wheels, flat surface text, synchronized station/angle state and a meaningful live dB level. Scale, preset lamps, list and listening-only void retain their different evidence rules. The soundscape backend now resolves current preset IDs and prepares event pools in the worker; latest-request switching avoids joining generation from a wheel callback. 78 input, face, gain and playback checks pass. [Source scope, unresolved legacy sound IDs and handoff](../interfaces-2026-09-21/radio-console/README.md). Headset, full listening and enlarged-case hall placement remain pending; next interface family is the duplicated stepped/zero lever scenes.

Latest angular-control reference (21 September): [place / keep moving](../../book/iterations/2026-09-21-interface-angular-review/index.html) repairs the shared smooth wheel and lever: collider/grip alignment, pointer input, turn-count stability, flat readings and pickup-layer restoration. A compact InteractableDemo reference sets angle with a retaining wheel and commands angular velocity with an explicitly returning lever. 100 checks pass, including real pickup/ray paths and timed visible consequences. Headset and museum placements remain pending. Next consumer: SoundscapeRadioRack (preserve its scale/presets/list/void modes); separate lever_snap and lever_zero scenes still need migration. [Implementation, source scope and handoff](../interfaces-2026-09-21/angular-controls/README.md).

Latest spatial-control integration (21 September): [the physical XY pad in the vector console](../../book/iterations/2026-09-21-interface-xy-pad-review/index.html) repairs the mismatched face/input plane and grab geometry, replaces scalar constraints with genuine two-axis input, and synchronizes pad, readout and vector receiver. The pair is grouped at 30 cm centre spacing in front of the work; all text in the vector console is flat on surfaces. A focused InteractableDemo configuration reuses this real encounter. 71 input, arithmetic, configuration and sibling-construction checks pass; headset and whole-hall placement remain pending. Next: wheel/lever angular controls and the distinction between setting position, commanding speed and applying force.

Latest physical principle (21 September): [the joystick family](../../book/iterations/2026-09-21-interface-joystick-review/index.html) now has aligned grab geometry, continuous/5-degree-detented/returning variants, compact flat readouts, and a focused `interactable_joystick_demo` with visible point receivers. 97 focused and 46 mixed-console checks pass. The preceding [mounting boundary](../../book/iterations/2026-09-21-interface-mounted-console-review/index.html) is also implemented for Grammar, Fitness and Edge. Next: inspect two-axis input in a spatial encounter; distinguish position settings from velocity commands.

21 September correction: **2D in 3D refers to text, not to the control geometry.** Primary buttons, sliders and knobs should support physical manipulation where that serves the encounter. Keep flat surface text, compact mounting and front placement. The [physical grammar slider comparison](../../book/iterations/2026-09-21-interface-physical-slider-review/index.html) replaces the screen slider with a graspable six-position control, retaining the screen variant for comparison. This is one migrated artifact, not a completed replacement of all rack interfaces.

Latest integration: [standalone rack controls and grammar depth](../../book/iterations/2026-09-20-interface-rack-wrapper-review/index.html). Individual cases and module panels now share a pointer bridge. The artifact helper's button callback and flat status screen are repaired; grammar provenance adopts a six-position selector. [46 wrapper/consumer checks plus 43 module checks](rack-wrapper-pilot/README.md) pass. The next placements are the fitness landscape and edge-of-chaos controls, including their intentional restrictions. Older pilot notes below describe their dated stage of completion.

Latest principle: [choice, returning command and retained setting](../../book/iterations/2026-09-20-interface-release-review/index.html). The two previously inert canonical 2D rack sliders now receive pointer input. Discrete values are quantized before emission, centre return is explicit/configurable, and the existing module-face route is verified through GUI dispatch to visible receivers. A focused `interactable_demo` configuration demonstrates the difference. See [43 checks and integration limits](rack-input-pilot/README.md). Next: give the standalone `VRRackControl` wrapper a working pointer path and review its consumers; it currently renders a screen without forwarding pointer input.

Latest placement: [Shannon's source and prediction controls](../../book/iterations/2026-09-20-interface-shannon-review/index.html). Its controls now retain full size, the active predictor stays indicated after release, and enabling the comparison can refit its housing without replacing the sample or readouts. Runtime direction checks also exposed and corrected the shared panel's left-increases orientation; the primary monitor support now sits behind its content. This extends the [instrument profile and mixed-control reference](../../book/iterations/2026-09-20-interface-finish-review/index.html). Compact/instrument slider and dial values use shared flat screens. Next: implement and verify the stepped/bipolar rack-control contracts identified by the census.

Second pilot: [QFEP console at authored control size](../../book/iterations/2026-09-20-interface-console-review/index.html). The optional compact console preset wraps at three columns, fits the casing around unscaled controls, and gives its faders live 2D value screens. QFEP Balance adopts it; QFEP Introduction is the verified placement. The same artifact appears in ten map files, including experimental layouts: these remain placement-review candidates, not ten verified rooms. Default consoles and the remaining dial/joystick text retain their earlier behaviour.

First placement report: [Pattern Foundry compact controls](../../book/iterations/2026-09-20-interface-compact-review/index.html). It connects the existing manuscript/encounter review to the changed component, matched museum captures and regression evidence. This is one adopted placement, not a project-wide completion claim.

The [full project census](full-inventory/README.md) now supplies the candidate pool. The next coverage unit is a **control in its assembled placement**: behaviour, mount, label/readout, receiver and player position. A source match alone cannot mark that unit complete.

## Required placement: the interface in front of the work

**User requirement: the interface has to be in front of the work.** Arrange the encounter as **player → controls → work**, so the player can operate the interface and observe its consequences while facing the same direction. Keep the controls low or inclined enough to preserve sightlines to the work and its essential captions. Keep the stand upright when tilting the operating surface.

This is the default for further placements, not a claim that existing placements have all been migrated. The grammar comparison is the first corrected example: a central inclined station replaces its side anchor. Its operating-position capture shows the three forms and their provenance boards behind the controls. Check the arrangement again in each museum placement, accounting for parent transforms and player height; a component capture does not establish headset reach.

## Required text treatment: 2D in 3D

**User requirement: all text must be 2D in 3D.** This applies to labels, values, instructions, titles, signs, plot annotations and code. Use flat text rendered on a surface in the world: button/panel printing, a screen, a page or an object's material. Text does not require a separate large monitor when it belongs directly on the control's supporting panel.

This requirement does **not** flatten buttons, handles or knobs. A 3D moving control can carry printed 2D labels and sit next to a flat value screen. Choose the control's geometry and interaction separately from how its lettering is rendered.

- Static text: use the existing `BakedTextAlbedo` texture helpers, mounted on the relevant surface.
- Changing values and interactive documents: use 2D `Label`/`RichTextLabel`/Control content rendered to a 3D screen through the existing viewport helpers. Select update frequency and texture resolution for the actual content; a static caption does not need a continuously rendering viewport.
- Use `TextScreen` when a framed, supported screen/stand/pad is appropriate. Its existing source already states this principle.
- Standalone `Label3D` and glyph geometry such as `TextMesh` are migration findings. A special housing or visual skin does not exempt text from the rule. Preserve wording, units, value bindings and reveal timing during conversion.
- Verify mounting, orientation, contrast and readable size from the player's position. Include labels carried by the child controls, not only titles generated by their parent console.

Initial implementation: removed `ControlPanel`'s extruded-glyph rendering branch, including when old callers enable `label_mesh`. Legacy colour settings remain compatible. `ControlConsole` now selects dark printed text through the normal colour properties. Its titles and panel-generated labels use the flat-text path; embedded controls still carry legacy labels that need migration. The existing dynamic readout remains a 2D Label on a viewport-backed screen.

Next migration targets: child-control value/name labels, the demo's captions, rack passive-element captions, artifact annotations and world signage. The source inventory supplies candidates; converting the shared console alone does not make all project text compliant.

Verification: reused `test_console_allcontrols.gd` through [a capture wrapper](capture_flat_text.gd). Godot exited successfully; [runtime inspection](flat-text-check.json) found zero `TextMesh` instances and confirmed the old `label_mesh=true` setting now produces a textured quad. The [front](flat_text_allcontrols_front.png) and [side](flat_text_allcontrols_side.png) captures were generated; the front was visually inspected. Two visible child-control `Label3D` value nodes remain on the slider and dial. This is a rendering/assembly check, not a headset readability verdict. The run retained the previously observed UID and certificate-store startup errors but reported no script errors.

## First integration priority: mounting and backing

The user's example of a button without a backplate is a concrete acceptance criterion. Review the assembled interface, because a button may correctly rely on its parent surface. The individual component and its parent must agree about who supplies that surface.

| Mounting arrangement | Required result |
|---|---|
| Standalone button | Own visible plate or case; label belongs to that mount; press direction is apparent |
| Button on a shared panel | Parent panel visibly supports the button and its label; button is seated on it without floating or being buried |
| Button embedded in an object | The object's body supplies the mounting surface; orientation and feedback remain legible |
| Deliberately freestanding interaction | Record why it is spatially freestanding and how the player identifies and operates it; review this as a distinct arrangement |

These are proposed mounting roles, not newly implemented runtime settings. A useful eventual record is `mount_mode`, the actual supporting `mount_node`, control/label nodes, intended player pose and any intentional exception. Missing metadata means **unclassified**, not an automatic failure. A node named `BackPanel` does not prove that its visible geometry supports the control.

Source findings on 20 September:

- `commons/interactables/push_button.tscn` already contains `ButtonBase/BaseMesh`.
- `commons/interactables/cube_button.gd` defaults `show_plate` to true and builds its own plate/rim while hiding the wrapped push button's base. Setting this off requires support from the assembled parent.
- `commons/ui/control_panel.gd` builds a content-sized `BackPanel`; its button factory uses the shared push button.
- `commons/audio/rack_templates/RackTemplates.gd` hides each button's `BaseMesh`. Normal panel mode provides panel geometry and recesses. `frameless=true` skips that geometry for an external case to provide it. Inspect this assembly boundary when a rack button appears unsupported; it is not proof that the user's unidentified button comes from this factory.
- `InteractableDemo.gd::_build_extra_button` constructs visual prototype meshes. A finished-looking plate would not make those prototypes operational.

### Spacing, grouping and reach

The user also reports buttons placed too far apart. **Excessive spacing is a layout defect to review independently of backing and button functionality.**

Source evidence: `ControlPanel.spacing` defaults to 0.30 metres and `_relayout()` arranges items in one horizontal row. Eight ordinary button slots therefore span 2.10 metres between the first and last centres at unit parent scale. The panel grows with the row rather than wrapping it. This is a plausible source of excessive travel; the exact reported placement has not yet been identified.

The reference arrangements should:

- Use control-specific footprint and label widths, with clearance for actual hit targets, hand motion and moving parts. A small action button and a long horizontal slider need different space.
- Keep related actions close together. Use larger gaps between functional groups, such as playback versus parameter editing. Give consequential actions appropriate separation.
- Wrap larger groups into rows or compact clusters when they exceed the chosen operating area's width. Compare an eight-button row with a four-by-two arrangement in the reference lab; treat this as a prototype comparison, not a universal ergonomic standard.
- Preserve usable button size and label legibility while reducing empty space. Review collision/input overlap as well as visual overlap. A global reduction of `spacing` can crowd larger controls and is not a sufficient migration strategy.
- Keep the readout close to its controls and preserve a clear view of the receiver. Check both horizontal spread and vertical reach from the declared player pose.
- Record the actual world-space control centres, input bounds, group extents and operating pose, including parent transforms. Mark desktop geometric checks separately from headset comfort tests.

**Reference acceptance question:** can the player operate this related group from its intended position, identify the correct target, and see the consequence? If operating the artwork requires deliberate walking or bodily displacement, record that purpose explicitly.

Implemented in the first pilot: opt-in `ControlPanel.layout_columns`, `layout_max_width` and `row_gap`. Wrapped rows measure visual and collision bounds, preserve authored control scale, and expand for oversized controls. Pattern Foundry adopts four columns; the default remains the original single row. Explicit functional groups and promotion through the principal setups remain open. `ControlConsole` still scales its inner panel to `board_width`; audit that enclosing scale before adopting wrapping through a console.

### A small, reusable rollout

1. **Reference button family:** show the same working button as standalone, panel-mounted and embedded. Give each a real receiver, visible activation feedback and a recorded mount provider. Use `interactable_demo` as the test catalogue.
2. **Reference arrangements:** put that family into a compact panel and a dense panel using existing shared builders. Include the eight-button row versus four-by-two spacing comparison. Principal setups supply grouping, mounting, label/readout placement and the operating position; skins remain a separate choice.
3. **Three real uses:** verify an independent control, the pattern control plate's randomise button and a dense comparison/time-control artifact. Preserve their action semantics. Capture before/after from the same operating pose, then exercise the actual action.
4. **Family rollout:** use the inventory's consumer links to find further users of the changed component. Confirm the actual factory and configuration before migration. Review shared-builder changes in the reference arrangements and the three pilot uses before expanding.
5. **Repeat for sliders and screens:** include range/value agreement, stepped/bipolar input behaviour, readout attachment, viewing angle and sightline to the controlled object. The two confirmed 2D rack-slider handler gaps have their own implementation tasks.

For every reviewed placement, record separate findings for **mounting, reach, readability, input target, feedback/receiver, recovery and cost**, plus source/render/desktop/headset evidence. Prioritise controls with no effect or inaccessible targets, then missing/misaligned mounts, then visual refinements. Use statuses **unclassified → diagnosed → changed → desktop verified → headset verified**; an intentional difference has an explicit reason rather than being forced into the same appearance.

Coverage should be reported as reviewed configured uses / discovered configured uses, with unresolved runtime uses shown separately. Report shared-component adoption separately from placement quality: fixing one factory can improve many consumers, but it does not verify their reach or viewing conditions.

The goal is to account for every interaction principle currently implemented in Ada, with an explicit queue for unclassified examples. A finite gallery cannot cover every possible future interface. It can make its present coverage, exceptions and missing evidence visible.

## Connect three existing layers

1. **Interactable demo: the control vocabulary.** Isolated buttons, sliders, dials, levers, displays, drawing tools, spatial handles and body triggers. Each entry states whether it is a working control, a passive display or a visual prototype.
2. **Principal setups: composition recipes.** How controls, readouts, receivers and a player's operating position are arranged. Retain the 17 housings and five skins as independent choices; add compact rows, grouped columns, side consoles, paired comparison stations, drawing surfaces and spatial instruments as layout/interaction recipes rather than inventing a new housing for every case.
3. **Museum examples: situated encounters.** A reference links to actual artifacts and map placements. The important question is whether the arrangement works in those rooms, not just in an isolated gallery image.

A reference therefore connects:

**action → value/state change → receiver → observable feedback**, with an input method, physical arrangement and evidence of operation.

The same lever can set an angle, command velocity or apply force. Its mesh alone does not tell us which. Those behaviours need distinct contracts even if they share a control scene.

## Initial principle coverage

These are overlapping capabilities, not mutually exclusive artifact categories. An artifact can use several; many visually different artifacts can share one.

| Principle | Example to inspect or extract | What the reference must demonstrate |
|---|---|---|
| Discrete action | Shared push buttons; exchange study STEP/INJECT | One accepted activation produces the stated action; repeat/hold semantics are explicit |
| Continuous scalar | Shannon workbench P(1) | Range, direction, current value and corresponding receiver stay in agreement |
| Named/discrete selection | Pattern control plate named slider values | Every selectable position maps to the declared choice; selection is visible |
| Two- or three-dimensional manipulation | Demo XY pad/joystick; vector-addition walk handles | Coordinates, constraints and local/world mapping are explicit; verify actual grab path |
| Rotation and angular control | Demo dial, wheel and lever variants | Bounded angle, wraparound, angular rate and spring return are distinguished |
| Displace and release | Restoring-forces spring handle | A constrained hand motion establishes initial conditions; release starts the declared dynamics |
| Draw a history | Whiteboard with pens enabled | Contact adds a sampled trace; pen colour, resolution and erasure have observable effects |
| Edit a discrete field | Pattern maker's motif grid | One local cell edit propagates to the tiled receiver; continuous painting does not repeat unintentionally |
| Advance and inspect time | Exchange study STEP/RUN/+100/REPLAY | Pause/run, single step, bounded batch and replay have distinct, visible effects |
| Timed presence | Palm scanner | Entry, dwell, interruption, success and release are legible; automatic door connection is checked in context |
| Body as input and receiver | Force pad | Entering a volume changes the body's movement; prediction and actual trajectory can be compared |
| Preview, commit and persistence | Fabric shader studio | Preview edits, saved recipe, worn fabric and undo are separate states |
| Multiple receivers | Fabric studio wall/preview, wearer and runway | Target and scope are explicit; applying to one receiver does not silently claim to update all others |
| Comparison and reveal | Exchange study's matched fields | Comparable starting conditions, retained observations and explanation timing support the lesson |
| Display without control | TextScreen, meters, scope displays | Clearly distinguish observed measurements, simulated displays and decorative animation |
| Symbolic or structural editing | Graph grammar station as a candidate | Separate choosing a preset/parameter from actually authoring a rule or graph; free symbolic editing remains unverified |

Two-handed gestures, voice input, text entry, patch-cable routing and multi-user arbitration must remain **unclassified or unverified** until their source and runtime paths have been inspected. A patch-matrix mesh does not establish patching support. Names and identity comments are discovery leads, not coverage proof.

## Existing examples worth learning from

These are source-grounded candidates. Except for the earlier exchange-study desktop pilot, they have not been newly operated during this collection; no candidate is certified as headset-comfortable.

| Candidate | Reusable contribution | What to check before promotion |
|---|---|---|
| [PatternControlPlate](../../../commons/artifacts/pattern_tunnel/pattern_control_plate.gd) | Configurable two-column layout, named choices, live preview, `changed(key,value)` contract | Uses `slider_horizontal`; verify reach and effective world scale; do not copy its mechanics uncritically |
| [ShannonWorkbench](../../../commons/artifacts/shannon_workbench/shannon_workbench.gd) | One parameter drives several corresponding views; input sets dirty state and expensive visual refresh is throttled | Actual mounted size, slider readout/range agreement and Quest response time |
| [Exchange study](../../../commons/artifacts/rd_artifact/exchange_study.gd) | Matched comparison, time controls, explicit reveal state | Earlier [31-check desktop pilot](../../space/reveal-play-pilot-2026-09-19/README.md) is dated evidence, not a current headset verdict; dense panel may still need rearrangement |
| [Whiteboard pen](../../../commons/artifacts/whiteboard/whiteboard_pen.gd) with [whiteboard](../../../commons/artifacts/whiteboard/whiteboard.gd) | Physical tool, contact-to-UV mapping, sampled trace, colour/resolution, erasure | `pens_enabled` defaults false; test a configured board, both hands, dropped-pen recovery and current surface feedback |
| [Restoring forces](../../../commons/artifacts/spring_tower/restoring_forces.gd) and [spring handle](../../../commons/artifacts/spring_tower/spring_handle.gd) | Direct constrained displacement and a separate release event | World/local mapping, grasp/release path and reset must survive placement and rotation |
| [Vector addition walk](../../../commons/artifacts/vector_addition_walk/vector_addition_walk.gd) | Spatial handles, operands and a visible result in an inhabitable grid | Need to exercise the actual input pipeline; a handle-building function alone is insufficient |
| [Palm scanner](../../../commons/artifacts/palm_scanner/palm_scanner.gd) | Dwell state, prompt/LED change, chime/haptic hooks and door signals | Hand recognition paths, leaving before completion, re-entry and the correct door receiver |
| [Force pad](../../../commons/artifacts/force_pad/force_pad.gd) | Whole-body activation and visible launch prediction options | Actual locomotion implementation, cooldown, receiver and headset experience |
| [Fabric shader studio](../../../commons/artifacts/fabric_shader_studio/fabric_shader_studio.gd) | Preview/save/apply/undo distinctions; handles missing wardrobe/runway and invalid saved recipes | It targets skirts for wear/runway, not every part of an outfit; verify saved vs preview state and undo scope |
| [Pattern maker station](../../../commons/artifacts/pattern_maker_station/pattern_maker_station.gd) | Direct cell painting with a room-scale floor receiver | Source contains known configuration/rebuild caveats; test actual placement and declared symmetry options |
| [Graph grammar station](../../../commons/artifacts/graph_grammar_station/graph_grammar_station.gd) | Preset and parameter selection linked to graph reconstruction | Classify as selection until genuine rule-authoring input is demonstrated |

## Extend the demo into a working reference lab

Keep the present large sampler as a catalogue view. Add focused configurations or bays so a visitor can operate one principle at a time. Do not squeeze all principles into one wider board.

Each functioning example needs a minimal receiver: a lamp for a button, a bar/object position for a scalar, a point in a plane for an XY input, an arrow for orientation, a finite record for time controls. Every visible action must either work or be explicitly labelled as a prototype. Passive displays need an identified data source.

Expose reset/replay only where those actions make sense and are implemented. Preserve the distinction between resetting simulation state, clearing a drawing, undoing an edit, restoring defaults and deleting persistent work.

Use the same Godot components and configuration data in the reference and the artifacts. The web gallery should display dated Godot captures and explicit browser-preview status. A Three.js approximation should not acquire a “VR tested” label.

## Reference record

Proposed fields for each reference (data contract to implement, not an existing API):

```json
{
  "id": "adjust_scalar",
  "input_modes": ["near_grab", "pointer"],
  "state": {"kind": "float", "range": [0, 1], "unit": "dimensionless"},
  "action": "set_value",
  "release_behaviour": "retain_value",
  "receiver": "sample_grid",
  "feedback": ["value_readout", "changed_sample"],
  "recovery": "restore_starting_value",
  "recipe": "compact_parameter_bench",
  "source_scene": "res://path/to/verified_reference.tscn",
  "placements": [],
  "evidence": [],
  "exceptions": []
}
```

Every evidence entry should identify source/config hash, renderer, scene/map, input mode, operating pose, action, observed result, date and capture/trace. Reach and readability are observations tied to a tested pose and person/profile, not universal booleans. A reference lists supported input modes only after evidence; the example above proposes a shape, not a claim that every scalar control supports both.

## Find more examples systematically

1. **Discover from behaviour as well as appearance.** Extend the current audit roots to include `commons/interactables`, `commons/audio`, player/body systems and other project-local input scripts. Search scene inheritance, input handlers, XR signals, Area3D entry/exit, pickable/grab handlers, touch surfaces, pointer events, persistence and receiver groups. Engine/addon widgets are dependencies, not automatically additional museum examples.
2. **Resolve to artifacts and placements.** Trace scene → script/factory → registry → map token/config → current hall. Keep unregistered helpers and configured variants visible. Report unresolved paths rather than silently discarding them.
3. **Separate discovery from evidence.** Source signatures produce candidates. Runtime inspection establishes what was constructed. Real pointer/grab events establish operation. Headset testing establishes embodied comfort. None substitutes for the next.
4. **Choose references per strength.** One artifact may contribute good layout, another good feedback, another correct temporal behaviour. A beautiful cabinet with a dead button must not become the complete standard.
5. **Measure coverage by actual uses.** Report mapped placements, principle families with tested references, unclassified uses and missing input modes. Do not equate number of skins or all theoretical combinations with coverage.

## Integrate weaker interfaces

For each finding choose one route:

- **Repair placement:** keep the control and behaviour; adjust mount, grouped layout, label placement or receiver sightline.
- **Repair implementation:** fix an unwired action, inaccurate readout, wrong input transform or unbounded workload before cosmetic migration.
- **Adapt to a shared control:** retain the artifact's public signals, parameter semantics, saved-state format and pedagogical timing while replacing the weaker widget.
- **Promote an existing solution:** extract a proven two-column layout or feedback/state pattern into a shared recipe, then update dependent artifacts deliberately.
- **Keep a justified variation:** a wheel, drawing surface, scanner or bodily force encounter should not become a row of generic buttons merely to match a screenshot.
- **Develop a missing encounter:** record the task when a prototype has useful intent but no operational implementation. Do not remove the associated strong writing merely because the reduced setup is incomplete.

Use before/after captures and the same short action sequence. Preserve labels, ranges, clamping, step sizes, coordinate space, replay seeds and reset/undo meaning unless a change is explicitly part of the improvement. Recheck shared components in at least a simple console, a dense board and a distinct spatial example before widening adoption.

## Gallery changes to make next

Add filters for **principle, housing, input mode, receiver, evidence and exception**, alongside material style. Each tile should link to its recipe, real source, using artifacts and open problems. Show separate badges for **working control / passive display / prototype** and **source / render / desktop input / headset evidence**.

Store variants as configuration, not copied implementations. Keep the existing 17×5 visual catalogue; add a small tested set of behavioural references and composed examples. The existing `interface-composer` already offers display position/rotation/scale editing for six workbenches, but is not a general control-layout or behaviour authoring tool. It can be extended once the shared recipe contract exists.

## First implementation slice

1. Add truthful functional/prototype labels to the demo catalogue and create one compact, fully wired scalar/action/readout reference.
2. Reuse the pattern plate's grouping idea to add a dense layout recipe without shrinking physics controls. Check it on an eight-control time/comparison instrument.
3. Add a pen-and-surface reference to prove the system also accommodates direct spatial interaction.
4. Put these three references in the principal gallery with reproducible action traces and unknown headset status until tested.
5. Only then migrate the next family, selected by actual hall use and severity of the usability problem.

This starts a measurable loop while retaining the project's broader vocabulary and the review principle: strengthen the encounter before cutting its ambition.
