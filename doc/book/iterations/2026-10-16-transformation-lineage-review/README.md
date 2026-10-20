# Transformation: what actually carries forward

16 October 2026. Editorial review of all seven canonical tutorials, their saved teaching choices and the Primitives/Arrays handoffs. Keep the hall order. The conceptual progression holds; exact code continuity and some planning labels need repair.

**No canonical tutorial, final.md, teaching choice or museum code changed in this review.**

## Hall-by-hall repair plan

| Hall | Bring | Learn | Carry | Repair |
| --- | --- | --- | --- | --- |
| Trans_Pre | Point Zero’s clock; coordinates; visible geometry versus a boundary; the cube construction already understood. | Position, orientation and uniform scale; elapsed time; a returning fraction; collection through an overlap signal. | A whole-box visual, a time-driven pose and the player-filtered collection connection. Preserve the collectible version for Arrays. | Resolve the upstream promise to carry CubeBody. The accepted lesson deliberately uses BoxMesh. Name this as a change of representation, including its centred origin. Read the existing lesson in two stages: movement, then collection. |
| Trans_Introduction | Pre’s box construction, three transform properties and returning time value; functions and loops from Primitives. | A held pose fraction; scalar interpolation; a returning constructor reused to make independent visual models. | A reusable visual construction and apply_pose(t): input and resulting pose can be inspected separately from the clock. | Keep the construction function available to later lessons instead of returning to inline mesh setup. Correct the card that currently selects the bank-slider/reset lesson. Say that duration is one leg here; Pre’s period was the whole return cycle. |
| Trans_Translation | Introduction’s travelling visual and interpolation; Lines’ displacement; Trace’s positions and conditions. | Vector interpolation; a bounded one-way journey; a branch choosing a direct or two-part route. | Positions can prescribe a route as well as record one. The object’s orientation and dimensions remain independent of travel. | Carry the box constructor rather than rebuild it. Align the card with the actual two-segment lesson. Keep waypoint indexing and zero-length-leg guards as a possible later extension; they are not in this program. |
| Trans_Rotation | The visual box and clock; Coordinates’ local/world distinction; Translation’s separation of position from orientation. | Axis, angle and pivot; degree-to-radian conversion; a fixed child offset beneath a rotating parent. | The parent-child relation: a fixed local position can have a changing world position. Rotation preserves internal distances. | Reuse visual construction for the cube and its face mark. Print the changed hierarchy and orientation calculation. Remove operation-order comparison from the required lesson labels unless a separate extension is deliberately selected. |
| Trans_Scale | Rotation’s parent-child relationship and the box construction; the sphere’s earlier geometric recipe. | Uniform and unequal scale; the scaling origin; which children inherit a change; fixed reference measurements. | A transform’s scope and a deliberately chosen factor. Origin placement determines whether the base stays on the floor. | Keep the visual constructor while changing its parent explicitly. Link the complete fixed witness construction once: it is a new mesh instance using a familiar sphere shape, not the carried pickable PointBody. Narrow the card from editing the supplied room to constructing the small doorway comparison. |
| Trans_Body | Scale’s factor, Lines’ distance, Coordinates’ world frame, and the museum player contract already named in Pre. | Horizontal world separation; range mapping and clamping; one input controlling scale or turn; reversible response. | A bounded response driven by the visitor. The body can change and return without keeping a history. | Reuse the box visual; concentrate printed code on the input connection and respond(distance). Remove retained-flag and collision-update promises from the card. The current program is visual and intentionally has no visit memory. |
| Trans_Pit | Pre’s player filter and overlap area; Introduction’s shared pose; Rotation’s axis; Scale’s scope; Body’s reversible response; Trace’s arrays and loops. | Continuing occupancy; target versus current progress; physics-time updates; moving solid bodies; matched visual/collision size; aligned reference arrays. | A composed, solid opening. Arrays takes a separate return to Pre’s collectible cube, adding stable addresses and presence records. | Keep the hall, but present three steps: construct and hold the solid leaves; derive a target from occupancy; approach the target over physics time. Declare the MeshInstance3D-to-AnimatableBody3D change. Reuse only the visual part of construction; the physics wrapper is new teaching code. |

## Where the records disagree

- **Trans_Pre:** The current subject labels fit. The contradiction is with Cube and Melencolia’s promised class handoff.
- **Trans_Introduction:** The saved card selects slider/RESET signals, target/current state and gradual reset. The canonical program instead compares three visual models. Its code contains none of that control wiring.
- **Trans_Translation:** The saved card promises waypoint lists, retained route index and zero-length guards. The program has start/finish/corner variables and two branches. Unequal legs intentionally receive equal time.
- **Trans_Rotation:** The card promises reversed rotation order; the canonical tutorial explicitly leaves that museum comparison beyond its single-axis lesson.
- **Trans_Scale:** The subjects broadly fit, but the card’s focus describes the installed room and a supplied opening comparison; the lesson constructs a three-box doorway. Relocation is discussed, not reconstructed.
- **Trans_Body:** The card selects a remembered visit and says visitor input/collision updates are supplied. The program performs the player lookup itself, has no retained visit flag and creates no collider.
- **Trans_Pit:** The card calls frame, occupancy and physical wrappers supplied. The canonical 67-line program constructs all of them. This is the largest real teaching jump, not unchanged support.

## The first decisions

1. Keep the accepted whole BoxMesh branch. Update Cube/Melencolia’s forward promise to say which knowledge carries and which construction is replaced. CubeBody’s y=0..1 recipe and BoxMesh’s centred origin are not interchangeable. Returning to CubeBody is an alternative requiring an intentional lesson redesign, not an automatic repair.
2. Reconcile the saved focus with the smaller accepted canonical lessons. Do not implement waypoint machinery, retained flags or reversed rotation order merely because an older card still lists them.
3. Keep one lineage for the reusable visual construction. A candidate `box_visual.gd` would make a MeshInstance3D with an owned BoxMesh; the caller chooses parent and placement. This is proposed code, not an existing dependency. The last hall adds its solid wrapper explicitly. Avoid a universal artifact class or hidden collision support.
4. Keep the full current scripts as recoverable edition states while trying the compact reading view. Show complete new functions and exact edits. Changed files are changed; the current three different `box` functions cannot be called unchanged support.
5. Treat the Pit as a composition in three passes: solid pose; occupancy target; time-driven progress. Preserve Pre’s collectible snapshot for the branch into Arrays. A lineage can branch and reuse earlier work without passing every responsibility to every later object.

## What the tests establish

The 12 October runner extracts and runs each complete resulting lesson and its variants. It does not apply printed edits to a predecessor. Add that source-reconstruction gate when the compact continuation views are written: uniquely anchored edits + pinned incoming files must produce the downloadable full state. Then run the existing behavioural checks on that assembled output. Keep variation and fault tests. Do not turn automated execution into a claim about student understanding.

Current audit: all seven tutorial hashes and seven extracted programs match the archived evidence. That run records 204 assertions, 19 variants and 12 detected faults. No new Godot run was performed. See `audit.json` for source hashes and current/proposed teaching records.

The generic planner currently links older Pre ghost evidence as stale and no native record for the other six; the sequence’s 12 October evidence exists separately. Evidence discovery needs a later source-bound link, not an invented fresh test or a claim that these lessons have no checks.

## Compact writer instruction

```text
KEEP order and accepted simple BoxMesh branch.
RECONCILE card focus with the actual selected lesson.
BRING exact files; distinguish code carry from conceptual reuse.
PRINT new complete units + exact edits; link versioned full states.
NAME origin, duration, parent and physics responsibility changes.
ASSEMBLE from predecessor; test output, variation and fault.
RETURN Pre pickup to Arrays; retain Pit as a composition.
```
