# Glitch research: when parts stop agreeing

**PREVIEW ONLY · one new Godot artifact · three controlled studies · no museum map placement.** The images show a separate research courtyard. The earlier arcade supplies the model; the source is retained beside the instrument.

**[Explore the native models in 3D](/research/model-disagreement/index.html#feedback)** · [Earlier stack and vertex-address studies](../2026-10-09-the-model-calls-itself/index.html)

![Repeated deformation pulls the retained arcade into a leaning structure.](museum/feedback.png)

The working research question is: **what must agree for this object to remain the object we recognise?** Its parts need compatible coordinates, times, addresses and transformations. Change one relationship and the same source can become another kind of structure.

We now have three new comparisons. One performs an actual float32 storage conversion. Two deliberately alter the model's use of time and previous output. Their unusual forms follow declared operations; they are not evidence of a hidden engine defect.

## Research findings that guide the work

**Glitch is more than a reusable visual style.** Menkman's manifesto cautions that reproducible glitch effects can themselves become established conventions. Her distinction makes our controls useful only if they expose what is being changed. A button called GLITCH is less informative than a comparison between two concrete ways of storing or reading a model. This is our design inference from the manifesto, not a claim that controlled effects cannot be art. [Rosa Menkman, Glitch Studies Manifesto](https://www.artcornwall.org/features/Glitch_Studies_Manifesto.htm).

**Technical and cultural claims need separate support.** The publisher's account of *The Glitch Moment(um)* stresses the tension between technological interruption, artifact and filter. For Ada, this suggests keeping the exact mechanism alongside the interpretation rather than letting the appearance prove the argument. [Institute of Network Cultures](https://networkcultures.org/blog/publication/no-04-the-glitch-momentum-rosa-menkman/).

**Queer significance needs a question about bodies and power.** Russell's *Glitch Feminism* concerns gender, technology, identity and the possibilities opened within their relations. It gives us a reading direction; a distorted column alone does not demonstrate that politics. Our later reflection could ask who defines a correct body, who can refuse that definition, and who bears the consequences. This pass consulted the publisher's description, not a fresh close reading of the whole book. [Legacy Russell / Verso](https://www.versobooks.com/products/460-glitch-feminism).

**Precision and timing are material conditions.** Godot documents loss of coordinate precision far from the origin, and the discrepancy between physics ticks and rendered frames. Those sources motivate the first two studies below. Our time study uses explicitly chosen stale timestamps, rather than changing Godot's physics clock or provoking a renderer race. [Large world coordinates](https://docs.godotengine.org/en/stable/tutorials/physics/large_world_coordinates.html) · [Physics interpolation](https://docs.godotengine.org/en/stable/tutorials/physics/interpolation/physics_interpolation_introduction.html).

## 01 / A position too far away

The arcade still has its original 1,632 triangle records. We add a large offset to each coordinate, store it as float32, decode it and subtract the offset. The resulting local coordinates have already lost information. Rendering the result back beside us cannot recover it. The actual encoder and decoder are Godot's `PackedByteArray` operations. [API reference](https://docs.godotengine.org/en/stable/classes/class_packedbytearray.html).

![Float32 roundtrip at origin 8,388,608: thin details collapse.](museum/precision.png)

At the captured setting, the measured maximum positional error is **0.667 metres**, and **1,488 of 1,632 triangles have near-zero area** under the test's declared threshold. The operation changes where existing corners are stored; it does not reduce the original vertex/triangle list. A coarse-looking result can come from lost precision rather than a deliberately low-resolution mesh.

![Control: the same model and shift remain in local coordinates.](museum/precision-control.png)

CONTROL bypasses the large-coordinate roundtrip. CONDITION selects offsets from 2^18 to 2^25; zero selects the origin. STEPS changes a small horizontal translation. The player, camera and courtyard remain at ordinary coordinates throughout. This is an explicit numerical demonstration, not a traversal of the actual museum millions of metres away.

**Possible encounter:** carry a detailed body toward a distant reference and discover which distinctions its representation can still retain. Preserve the fine body for comparison. The coordinate choice becomes part of what can appear.

## 02 / Eight parts, eight times

All eight bays know the same movement function. Each reads a different time. The newest bay reads 3.60 seconds; the oldest reads 0.20 seconds. Between them lies a 3.40-second age spread.

![Different timestamps separate otherwise rigid bays.](museum/clocks.png)

![Control: all bays read one timestamp and their seams agree again.](museum/clocks-control.png)

The parts are not damaged. Each has a valid pose, but the poses no longer belong to one shared present. The test measures the separation of positions that should meet at a bay boundary. CONTROL makes those positions agree again by giving every bay the same timestamp.

![The time-skewed assembly viewed from the floor.](museum/clocks-ground.png)

The age spread is authored, not network latency measured from a connection. The movement function is defined for the entire sampled history, including negative times after reset. No actual asynchronous scene-tree or renderer access is involved.

**Possible encounter:** move the familiar sphere and let an attached body answer with several ages of that movement. The player could bring the parts back into the same present. A later hand-tracking version would need a real timestamped history buffer; this prototype uses a deterministic motion record.

## 03 / The output returns

A small vertex operation raises the upper points, shifts them sideways according to their height and bends them in depth. One pass changes little. Reading that result as the input to the next pass makes the effect accumulate.

![Twenty-four passes: the architecture leans out of its earlier proportions.](museum/feedback.png)

![Control: always reading the original gives one small deformation.](museum/feedback-control.png)

The captured comparison keeps the operation strength at 65%. FEEDBACK applies it 24 times. CONTROL displays a single pass from the source, so repeating the request does not compound the change. The control capture uses 32 requested steps to demonstrate this invariance. Floor contact vertices are retained; the original miniature remains unchanged.

This is **deformation feedback**, deliberately using output as the next input. It is not tiny floating-point round-off amplified by accident, nor a physical feedback controller. We retain the last complete state if the next pass would put a vertex outside a 64-metre radius.

![The repeated operation becomes a large structure over the visitor.](museum/feedback-ground.png)

**Possible encounter:** choose whether a change reads the original body or its last altered state. Both choices produce valid models. Only one accumulates a history. This offers a precise return to the earlier claim that a body carries its consequences.

## A working atlas for further research

This is a mechanism outline, not a proposal for one new hall per row. The first four rows are the recent built previews. The last three rows are proposed next studies.

| Relationship under pressure | Existing experiment or next candidate | What would count as evidence? |
|---|---|---|
| Calls and returns | [Pending call frames and forgotten restoration](../2026-10-09-the-model-calls-itself/index.html) — built preview | Frames are counted; admission is refused before capacity is exceeded; source can be restored |
| Coordinates and precision | Float32 roundtrip — built here | Known storage fixtures, measured displacement and collapsed-face count; local control |
| Parts and their timestamps | Skewed part times — built here | Declared ages, a measurable seam gap and a shared-time control |
| Current state and previous output | Deformation feedback — built here | One-pass control stays unchanged while iterated output develops; bounded replay |
| Shared vertices and separate copies | **Next candidate:** one surface split into independently edited chunks | Count seam duplicates; show equal positions separating under different operations; weld control |
| Orientation and visibility | **Candidate:** mirrored handedness and reversed face winding | Hold geometry fixed while winding/culling changes; distinguish an invisible face from a hole |
| Model and physical contact | **Candidate:** a changing mesh with an intentionally stale collision proxy | Show both representations, test the same probe against each, then update the proxy; no unmarked trap in the museum route |

The earlier [one-record study](../2026-10-09-one-record-many-readings/index.html) also remains relevant: a stored record can acquire a different body when its receiver changes. That is a different intervention from overwriting the record.

## How an experiment earns its place

Keep a recognisable source. Name one changed condition. Provide a control that removes that intervention. Record the parameters and a measurable disagreement. Let the player inspect and preserve a result, then restore the source. Only after that decide whether the artifact teaches, supports reflection, or simply belongs in the wider field of the museum.

For the current work, the strongest spatial comparison is **the shared-time body beside its displaced parts**. Feedback is the strongest sculptural result. Precision is the clearest demonstration that the same amount of stored geometry need not preserve the same distinctions. These are judgments from the rendered prototypes; their success for a visitor remains to be tested.

## Operate and verify

![The compact native instrument: four modes, condition, steps and control.](museum/console.png)

Run `res://commons/artifacts/model_disagreement/preview.tscn` with F6. CONDITION adjusts the selected intervention. STEPS changes logical time or pass count. STEP and PLAY / HOLD advance it. CONTROL switches the comparison while retaining inputs. RESET returns the step to zero; SOURCE displays the untouched model. Keys 1–4 select modes, C toggles control, Space plays, Enter steps, R resets.

**42 native checks pass.** Tests cover actual float32 values, positional loss and degenerate faces, timestamp spread, shared-seam restoration, feedback/source-reading, retained ground vertices, bounds, source invariance, reset, play/hold, native dials, real desktop pointer actions and seven GLB exports. There are eleven native captures, with identical cameras within each control/intervention image pair.

[Test receipt](validation/report.json) · [Engine log](validation/native.log) · [Exact operations and reproduction](source/README.md) · [Placement audit](museum-placement.json)

![The separate research courtyard seen from above.](museum/above.png)

These are model studies on a fixed floor. No new installation was added to a museum map. No canonical tutorial, final text or spine order changed. Existing project warnings remain in the log; the test run has no script or parse errors. Physical headset interaction and Quest performance remain untested. The browser viewer displays exact saved Godot geometry; the live generator and dials run in Godot.
