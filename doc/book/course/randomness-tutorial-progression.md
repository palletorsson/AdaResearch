# A small program learns what chance can do

**Implemented return, 15 October:** Random Entropy now includes the two-compartment comparison, corrected jar labels, a 25-line tutorial mechanism and a revised final. The former counts lesson is retained as `counts-and-neighbours.md`. [Native observations and fresh reconstruction](../iterations/2026-10-15-entropy-compartments/README.md) support these changes; learner/headset trials, editable partitions and conditional prediction remain pending. The proposal below retains its earlier scope, except for this completed step. The 48-value bench remains the first research pilot.

15 October 2026 · Comparison and proposed tutorial progression

**Recommendation:** keep Ada's fourteen-map order, but organise its tutorials around eight small cumulative builds. Use the other six maps as applications or advanced workshops. The learner should recognise the mechanism they are changing, even when its spatial consequence becomes unfamiliar.

This is a revision plan, not an implemented replacement curriculum or a learner-test result. The current four-object shelf is the starting point. Room placements, writing-wall order, canonical final texts and the particle branch are unchanged. The **48-value seed bench remains the first research pilot**; the eight-value shelf is a smaller introductory exercise.

**Research scope clarified, 15 October:** Palle identifies Entropy as foundational to the research. Core 2 below is its introductory build, not its complete map curriculum. The [Entropy research brief](text-plans/Random_Entropy/research-brief.md) requires conditional/predictive comparisons and a statistical-physics multiplicity experiment as well as marginal Shannon entropy. It distinguishes thermodynamic quantities, other information measures and related questions about compression, beliefs and QFEP. Small code increments must support that depth rather than reduce the hall to counting.

## What the comparison suggests

[Daniel Shiffman's randomness chapter](https://natureofcode.com/random/) starts with a walker, develops probability and distributions, then introduces coherent noise. Examples and exercises return to a recognisable system as its rules change. My reading is that this continuity matters as much as the topics: the next example gives the learner a reason to change a small part of something they already understand.

Ada already covers these subjects and adds eligibility, recording, replay, embodiment, feedback and the consequences of a rule. Its strongest recurring question is: **what is this number allowed to change?** We can keep that question visible in the code as well as in the final text.

The source audit found a teaching-scale discontinuity. Definition now prints 26 nonblank GDScript lines; Entropy prints 142. That count includes display and control support, not 142 new algorithmic lines. Thirteen chapters already repeat an identical PointBody dependency. They also explain useful comparisons and handovers. The revision should expose and reuse this existing continuity, rather than discard it or build a new general framework.

There are three different kinds of continuity:

- **Code:** keep a recognisable sample, mapping, state and display; identify the exact changed function.
- **Experiment:** keep a baseline, change one condition and retain enough information to replay the comparison.
- **Question:** let a result expose a limit that makes the next operation worth trying.

These need not require every lesson to use the same literal sample. A categorical choice, a Gaussian sampler and a spatial field need different procedures. Each transition must name what is retained, what is regenerated and why.

## The proposed route, in the existing map order

“Core” identifies eight cumulative builds. “Application” reuses them in another encounter. “Advanced” adds a substantial new relation after the foundations. These are proposed teaching roles, not changes to room membership or visitor access.

| # | Map and role | Small operation to build | Comparison that earns the next question |
|---|---|---|---|
| 1 | [Random Definition](../../../commons/maps/Random_Definition/tutorial.md) · **Core 1** | Read one stored value into position, size, rotation and hue together. | Halve only the position range. The number stays; its consequence changes. What happens across a whole record? |
| 2 | [Random Entropy](../../../commons/maps/Random_Entropy/tutorial.md) · **Core 2 / research centre** | Enter through counts/rearrangement; continue through prediction history, spatial partitions and compatible microstates in short builds. | An unchanged marginal reading creates the need for another question. Compare Shannon measures with statistical-physical multiplicity; then inspect which outcomes and descriptions are permitted. See the dedicated research brief. |
| 3 | [Random Remove](../../../commons/maps/Random_Remove/tutorial.md) · **Core 3** | Make an eligible list; draw an index; remove that member. | Change the eligible row to a column while keeping the choice procedure. The same index can remove a different place. Can allowed alternatives have unequal chances? |
| 4 | [10 PRINT](../../../commons/maps/Randomness_10_PRINT_Algorithm/tutorial.md) · **Core 4** | Compare a retained value with a probability threshold to choose one of two diagonals. | Change the threshold, keeping values and addresses. Some marks change; a short record need not match the expected proportion. Can an outcome determine whether another event happens? |
| 5 | [Random Cubes](../../../commons/maps/Random_Cubes/tutorial.md) · Application | Reuse discrete choice; a six permits another draw in a continuing die. | Keep the drawn faces and the stop rule separately. Changing permission changes the event chain. What if each outcome contributes to a state? |
| 6 | [Random Rotate XYZ](../../../commons/maps/Random_Rotate_Random_XYZ/tutorial.md) · **Core 5** | Compare assigning an angle with adding an angle to the previous orientation. | Use the same signed increments. The difference comes from the update rule. What would addition do to a point's position? |
| 7 | [Random Walk](../../../commons/maps/Random_Walk/tutorial.md) · **Core 6** | Add displacements to position; retain the resulting path. Introduce a boundary explicitly. | Replay a fixed step record, then change only its scale. Distinguish proposed motion, boundary handling and the drawn trail. Which steps occur often? |
| 8 | [Random Gaussian](../../../commons/maps/Random_Gaussian/tutorial.md) · **Core 7** | Sample a distribution into a retained batch; count it in bins. | First rebin the same batch. Then compare sampling laws with their settings recorded. A histogram is a measurement, not the source itself. How can these choices populate a world? |
| 9 | [Random Mushrooms](../../../commons/maps/Random_Mushrooms/tutorial.md) · Application | Store kind, position, rotation and size in named records; construct instances from them. | Switch off sampled scale while retaining records and recipe identities. Equal scale need not mean equal size. How should neighbouring instances relate? |
| 10 | [Random Space Geometry](../../../commons/maps/Random_Space_Geometry/tutorial.md) · **Core 8** | Compare independent heights with samples of a position-based field at matching addresses. | Change field frequency while preserving the independent side. Then change display spacing without changing sample addresses. Which sampling relations suit the next task? |
| 11 | [Examples of Randomness](../../../commons/maps/Randomness_Examples_of_Randomness/tutorial.md) · Application | Reuse sampled points in an area estimate. | Narrow the sampling strip but retain the old area formula. More samples do not repair that mismatch. What changes if a past sample affects a future choice? |
| 12 | [Random Pheromone](../../../commons/maps/Random_Pheromone/tutorial.md) · Advanced | Let visits deposit a decaying field that guides later steps. | Compare guidance on/off from a declared initial state; keep the update order fixed. A retained trace now participates in the procedure. How are multiple influences combined? |
| 13 | [Random Space](../../../commons/maps/Random_Space/tutorial.md) · Advanced | Sum spatial contributions with explicit frequencies and weights. | Keep offsets; change one layer weight; compare raw values before display stretching. The current learner function is a sum of sine terms, not a Perlin implementation. What if a value governs time instead of space? |
| 14 | [Random Game](../../../commons/maps/Random_Game/tutorial.md) · Advanced | Draw a wait once, store its deadline and reveal a cue separately. | Change warning time while keeping the scheduled event. What is already decided differs from what has become perceptible. Carry the field questions into the existing Noise sequence. |

The main build path is therefore **direct → count → select → bias → accumulate → walk → distribute → relate neighbours**. It does not require reconstructing every artifact encountered in the rooms. The other workshops remain complete, valuable choices rather than compulsory detours into six new apparatuses.

## Make the code carry forward

Each revised lesson should provide a small complete learner script, its scene and an exact change from its declared predecessor. Aim for roughly 15–40 new or changed mechanism lines when that remains clear; this is an editorial target, not a quota. Keep inherited controls, meshes and optional recording code available through explicit links. Do not hide an undeclared dependency merely to achieve a short listing.

Keep four operations recognisable: obtain or read a value; map it; update a property or state; display and record the consequence. These are teaching distinctions, not a proposed abstract base class. A direct assignment is enough for lesson one.

Manual NEXT or STEP should precede automatic movement. Later introduce a declared simulation tick and show that changing render cadence does not silently change the draw schedule. A faster displayed motion, a higher draw rate and a different sampling law are distinct interventions.

The same stored value drives all four introductory objects deliberately. This couples their changes; it is not four independent samples. When a later lesson needs independent draws or a new record format, give that transition a name. Seed 435 remains the Definition hall baseline. The later tutorials currently use local recipes such as seed 42; this proposal does not silently make every map share a generator.

## The first revision to try: shelf to counts

The current Entropy tutorial creates a new integer sample. The following is a **proposed replacement opening**, not a claim that it already imports the shelf:

1. Keep the eight shelf values, their indices and seed. Freeze the four-object comparison before adding a category strip.
2. Divide the unit interval into four categories. Explicitly handle the upper endpoint so it belongs to the last category. Show the category beside each sample; a category is a choice among four labels, not another random draw.
3. Count those eight classifications into four bars. Use the authored fixture `0.10, 0.20, 0.60, 0.90`: categories `0, 0, 2, 3`, counts `2, 0, 1, 1`. Mark the fixture as a check, not sampled evidence.
4. Sort a display copy while keeping the original record and counts. With the fixture above, shuffle or reverse the display first so sorting has a visible effect. Compare adjacency as well as the bars.
5. Only then introduce empirical categorical Shannon entropy as a measure calculated from category proportions. Its value stays under sorting because the proportions stay. It does not measure the spatial arrangement or political freedom.
6. Use a separately labelled larger batch to investigate proportions. Eight retained values let us inspect a mechanism; they do not establish that a generator is statistically uniform. Keep batch generation separate from changing the view.

This produces a useful transition: **the same number can mean different things; the same counts can hide different arrangements**. The next lesson then changes which places may be selected. Fix Remove's stale reference to Definition's old cube grid when implementing that handover.

This is only the entrance to the expanded Entropy teaching route. Before treating the research hall as complete, develop its conditional prediction and partition comparisons and its Boltzmann/Gibbs bridge, with explicit model assumptions. The [hall task plan](text-plans/Random_Entropy/research-brief.md#verification-and-task-order) records the required work and distinguishes optional later branches. Existing jar and ruin encounters are not substitutes for an actual thermodynamic model.

## Add only what earns its place

The current 10 PRINT threshold already supplies a weighted binary choice. Generalising it to several weighted directions is a useful later walk exercise, not a missing prerequisite for every map. A custom accept/reject sampler can be a Gaussian-hall extension if a learner wants a particular distribution. Explain that rejection of candidate values is different from removing selected members without replacement.

Keep the distinction between the source, its law, its recording and its destination. A Gaussian batch can extend beyond a chosen display interval; clipping is a separate operation. A smoothly interpolated sequence of independent targets and a sampled coherent field can both look smooth, but they are different procedures. Name the actual algorithm in each lesson rather than translating an API label blindly.

The [existing five-stage particle proposal](randomness-research-2026-10-14/PARTICLE_PATH.md) stays Single/Arrays → Emitters → Forces → Lifetime/Types → Collision. Carry the shelf's mapping into birth position, size, colour or velocity only where that lesson needs it. Keep a deterministic starter; learners should not need all fourteen randomness maps before constructing a particle. A shared record import needs a specified adapter and a test before it is described as working.

## How we judge the progression

Use the established experiment cycle: baseline and prediction → one changed condition → observation → keep → reopen/replay → independent reconstruction → a further proposed change. A seed alone is not a complete recording: retain values or sufficient generator state, procedure version, settings, cursor, relevant simulation state and clock schedule where applicable.

For the first teaching trial, give a learner the shelf and proposed counts lesson. Observe whether they can locate the assignment, predict a known value's consequences, alter only its range, explain an unchanged count after sorting, and reconstruct the comparison from the stated materials. Record assistance and the point of confusion. “No useful difference” and “I cannot tell what changed” are evidence, not failed participation. A suggested next change should follow the observation, rather than an obligatory philosophical conclusion.

Retain three evidence levels: artifact correctness; the complete experiment cycle; and explicitly specified cross-hall transfers. Keep scene loading, stability, performance and physical VR usability as separate checks. Passing automated tests does not establish independent learning or an interesting encounter. The six application/advanced workshops must each add a consequence or question; if one repeats a lesson without gaining either, shorten its tutorial role.

## Task plan

| Order | Work | Done when | Status |
|---|---|---|---|
| 0 | Compare the reference chapter with all fourteen current tutorials; retain sources and counts. | The route, existing strengths, proposed changes and limits are inspectable. | Complete: this plan and linked audit. |
| 1 | Revise Entropy's entrance into counts/rearrangement, then develop its research comparisons under the dedicated E1–E6 plan. | Small reconstructable builds distinguish marginal/conditional entropy, spatial partition and statistical-physical multiplicity. Counts alone do not complete this foundational map. | Required scope; staged implementation proposed. |
| 2 | Try Definition → Entropy with a learner and preserve the result. | Baseline, comparison, replay and independent reconstruction are recorded; assistance and next change are explicit. | Pending observation. |
| 3 | Revise Remove and 10 PRINT around the same small board and declared record transitions. | Eligibility and probability are separately editable; empty sets and threshold endpoints work; stale handovers are fixed. | Proposed, informed by step 2. |
| 4 | Revise Rotate → Walk → Gaussian around retained increments and batches. | Assignment/addition, boundaries, law and binning each have a one-condition comparison. Full code remains reconstructable. | Proposed. |
| 5 | Revise Space Geometry, then review the six workshops and Noise handover. | Field coordinates and display coordinates are distinct; each workshop earns its new consequence. | Proposed. |
| 6 | Align sequence summaries and teaching-role notes with the revisions actually adopted. | Metadata describes current lessons, without claiming unbuilt record imports or changing the room/final route. | Pending adoption. |

Current sequence prose still says to begin by recovering a picture, and its Definition artifact-group rationale reflects that older opening. Reconcile this metadata after deciding how the new learner shelf relates to the installed opening; do not mistake the tutorial shelf for an already placed replacement artifact.

[Audit and reproducible counts](../iterations/2026-10-15-randomness-progression/README.md) · [Current shelf plan and verification](text-plans/Random_Definition/tutorial.md)
