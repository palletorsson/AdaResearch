# Entropy: what does this account of the world keep?

15 October 2026 · Research brief and implementation plan

**User direction:** Entropy is foundational to Ada's research. This hall must explore Shannon entropy and other forms of entropy. The small counting lesson is an entrance into that inquiry, not its complete scope. This brief expands the [tutorial progression](../../randomness-tutorial-progression.md) accordingly.

The two-compartment bench and jar-label repair are now installed and tested; [the implementation receipt](../../../iterations/2026-10-15-entropy-compartments/README.md) separates native observations from pending learner/headset evidence. The optional [prefab originals/parts/hybrids comparison](../../../iterations/2026-10-16-seeded-hybrids/README.md) is also installed, with reversible cross-object grafts and saved targets; seeds now change memberships and joins. A [persistent kept gallery](../../../iterations/2026-10-16-hybrid-gallery/README.md) now compares four saved sets per page, labelled by seed and stage, with exact replay of any entry. Other extensions below remain proposals. The 48-value seed bench remains the first research pilot.

Palle's later proposal extends this inquiry across the book. The [cross-map framework](../../../research/entropy/README.md), [optional observation card](../../../research/entropy/observation-card.md) and [ER0–ER7 plan](../../../research/entropy/cross-map-plan.md) distinguish uncertainty, information retained by a record, predictability through time and the physical conditions sustaining organization. They connect this hall to existing encounters without turning every map into an entropy meter or changing the adopted room/final order.

## The question that can carry the encounters

A row changes while its number stays. A jar changes its number while keeping every colour. A building keeps every stone but loses a passage or support. These encounters invite a precise question: **which differences does each account preserve, and what would require another account?**

Entropy is not one slider from order to freedom. Nor should the hall become a catalogue of definitions. Each instrument should expose a limitation that gives a reason to build the next one. Physical systems, information sources and beliefs can have related mathematics while referring to different states, constraints and observations.

Palle's supplied handoff makes QFEP a proposed method of holding an organisation together and reopening it when an observation warrants that choice. It does not supply a calibrated objective function. Record when we change the partition, remembered history, admissible configurations or research question, and why. Neither increased variation nor a larger entropy reading establishes emancipation, learning or a useful encounter.

## What is here now

The authored map and generated museum plan include the ledger, four mixing jars, live jar, four-cube sorting table, two-compartment bench, prefab hybrids with local butterflies, hardware decay study, displacement enclosure, ruin and signal room. The new bench and jar labels have native runtime evidence in the implementation receipt; physical headset and learner observations remain open.

| Existing apparatus | Actual subject | Consequence for this revision |
|---|---|---|
| `shannon_entropy_meter` | Empirical marginal Shannon entropy from symbol counts; sorted display copy; cached contrasting sample. | Keep as the small tutorial entrance. Add explicitly named comparisons beside its existing reading. |
| `entropy_jar` | Weighted colour entropy within six height bins: a conditional Shannon measure when all beads are retained. | Make the partition visible and editable in a proposed extension. It is not a thermodynamic entropy meter. |
| `entropy_compartments` | Fixed 8 A/8 B inventory; whole-board Shannon colour entropy beside ln Ω for the declared left count. | Installed with manual/seeded exchanges, same-k permutations, exact KEEP/REPLAY and a 25-line tutorial model. |
| `prefab_disorder` | Same four prefabs and fifty meshes per side; originals → separation → four seeded mixed-source hybrids, and back. | Installed optional tutorial study; native hybrid/replay checks pass. Human recognition and one changed-graft trial remain open. Visual disorder has no entropy reading. Whole/part modes still use different draw assignments; matched base motion remains a separate refinement. |
| `entropy_axiom` | Growing positional displacement from a lattice. | Keep as a perceptual encounter. Displacement and visual irregularity are not themselves an entropy calculation. |
| `entropy_ruin` and weathering wall | The ruin removes one support from loose rigid masonry; gravity and contact move the other stones. The adjacent wall retains authored top-course dismantling. | Compare the requested action with its consequences. Inventory stays; support relations change. Neither apparatus measures thermodynamic entropy. |
| `signal_room` | Same binary inventory in different arrangements, with a neighbour witness. | A strong host for a proposed prediction/history comparison. An adjacency count is not automatically entropy rate. |
| `hardware_entropy_decay` | Input-driven weathering and shader parameters. | Audit its “entropy source” wording before treating it as evidence about physical unpredictability. |

The jar repair is complete: live labels and registry name H(colour | six height bands), its 0–1 bit range and RESET. “Cannot unmix,” the high-value “MAXIMUM ENTROPY” verdict and the registry's second-law demonstration claim have been removed. The native trial checks both separated and shared-band fixtures and the existing disclosure modes. The final preserves the distinction from thermal entropy.

## The linked encounters to develop

### 1. Keep a population; change its arrangement

Continue the four-object shelf into categories, counts and rearrangement. Define the variable being counted, the alphabet and the retained sample. `H(X) = -sum p(x) log2 p(x)` uses bits; in the present ledger, the probabilities are observed colour shares. Sorting leaves this particular calculation unchanged. That is a limit of a marginal measurement, not a defect of Shannon's whole theory. Conditional and sequence measures also belong to that theory. [Shannon, 1948](https://people.math.harvard.edu/~ctm/home/text/others/shannon/entropy/entropy.pdf)

**Need for the next encounter:** we can see a rhythm that the histogram does not read. Can an instrument remember enough to detect it?

### 2. Keep the counts; let a predictor remember

Propose a small extension at the signal witness: compare `01010101` with `00110011` as explicitly cyclic records. Both have four zeros and four ones. Their marginal entropy is one bit. A calculation using the preceding symbol gives conditional entropy zero for the first and one bit for the second. Letting it use the preceding two symbols gives zero for both.

These are exact statistics of authored circular records, not estimates proving that an unknown source is random. An entropy rate concerns a process and its longer histories; a finite one-step statistic should retain its narrower name. A short record can make an overfitted predictor look successful.

As a compact alternative readout, compare Shannon entropy with **min-entropy**, `H_min = -log2(max p)`, which focuses on the most likely outcome. For the declared law `[1/2, 1/4, 1/8, 1/8]`, the two values are 1.75 and 1 bit. This is a different entropy functional, not a thermodynamic quantity or a certification of a seed's security. [NIST definition](https://csrc.nist.gov/glossary/term/min_entropy)

**Need for the next encounter:** the answer changes when we change what is known. What happens when that condition is a place rather than a previous symbol?

### 3. Keep the beads; change the partition

The jar keeps forty red and forty blue beads, so its whole-population colour entropy stays one bit. Its existing function instead calculates colour entropy within six height bands and weights the results by occupancy: `H(colour | height band)`. A proposed overlay should show those bands, their counts and their contribution to the reading.

Freeze a recorded configuration before comparing height bands with radial shells. Do not shake again while claiming that only the measurement changed. Save bead coordinates, group identities, coordinate frame and partition settings. A shelled arrangement can be separated radially but mixed within horizontal bands. This gives the existing jar a stronger experiment than a generic statement that disorder increases.

**Need for the next encounter:** a partition describes a configuration. How many other configurations would satisfy the same description?

### 4. Count compatible arrangements: the statistical-physics bridge

Installed in this pass: a small two-compartment model with sixteen labelled sites and exactly eight A and eight B occupants. Each compartment holds eight sites. The macro-description is `k`, the number of A occupants in the left compartment. The number of compatible site arrangements is:

`Omega(k) = choose(8, k) * choose(8, 8-k)`.

At complete separation, `k=8`, there is one compatible arrangement. At `k=4`, there are 4,900. The global A/B histogram remains half-and-half throughout. This creates a concrete disagreement: one statistic stays constant while the multiplicity of the specified macro-description changes. The [fixture calculation](../../../iterations/2026-10-15-entropy-research-map/fixtures.json) checks these counts by enumeration.

Introduce the physical definitions explicitly: **Boltzmann entropy** `S_B = k_B ln Omega` relates a macrostate to compatible microstates; **Gibbs entropy** `S_G = -k_B sum p_i ln p_i` uses a distribution over physical microstates. A uniform distribution over the same compatible states gives the same value. Physical entropy has units J/K. Thermodynamics also relates reversible heat transfer to entropy change, `dS = delta Q_rev / T`. [Statistical mechanics](https://www.damtp.cam.ac.uk/user/tong/statphys/statmechhtml/S1.html), [thermodynamics](https://www.damtp.cam.ac.uk/user/tong/statphys/statmechhtml/S4.html)

The sixteen-site board is a deliberately limited configuration model. Initially show `Omega` and `ln Omega`, with its assumptions visible. It does not model temperature, energy exchange or the heat of shaking the jar. Any thermal extension must declare its physical states, conserved quantities, dynamics and boundary/reservoir conditions before displaying a physical entropy claim. Small-system paths need not rise monotonically, and RESET is an external intervention, not spontaneous reversal of a closed system.

**Need for the next encounter:** different macroscopic descriptions count different compatible arrangements. Which description does the task need, and what is lost when we retain only it?

### 5. Keep enough to reconstruct, then reopen the task

Return to the ruin and the signal room. A piece inventory is insufficient to restore either arrangement. Compare saving counts, saving ordered values and saving a recipe with its dependencies. This joins the research question to the tutorial's actual KEEP/REPLAY requirement.

A later compression exercise can compare reversible encodings of a repeated pattern and a retained irregular record. Report the chosen encoder and total data needed to decode it. **Kolmogorov complexity** concerns a shortest program in a specified universal description system; a practical compressor does not calculate it, and exact general computation is impossible. This is a related inquiry into descriptions, not another name for the jar's readout. [Vitányi](https://homepages.cwi.nl/~paulv/papers/incomp.pdf)

Belief uncertainty can likewise be investigated by naming a model's hypotheses and probabilities. It is often another application of Shannon entropy. Variational free energy is not an additional species of thermodynamic entropy. Active inference already includes epistemic exploration; QFEP's proposed distinction here concerns reconsidering the apparatus, preferences and classifications. This follows the supplied handoff, which cites [Friston and colleagues, 2015](https://doi.org/10.1080/17588928.2015.1020053), rather than treating ordinary FEP as incapable of exploring.

The research decision is concrete: preserve a useful arrangement, change the measure, change what may occur, or follow an unexpected consequence. An unchanged reading can motivate a better question. A higher reading is not the goal.

## Tutorial, final and space

**Tutorial:** divide the hall into short builds: counts/rearrangement; conditional prediction; partitions and multiplicity. Each has a complete small mechanism, declared inherited point/controls, known fixtures and a saved comparison. The physical interpretation is introduced with its assumptions, not as an extra block of unexplained code. Min-entropy is a small comparative extension; compression and belief models are later returns. The map's research depth must not be equated with the length of its introductory script.

**Final:** revised from the working bench and native observations. Adopted room/final order: ledger → four mixing jars → shakeable jar → four-cube sorting table → two compartments → displaced points → ruin → signal room. The writing wall carries the order, tags and text notes. The current final develops the constant colour reading, changing multiplicity, same-k difference and need to preserve site lists. The conceptual history/partition sequence above remains a future branch.

**Space:** the multiplicity bench is installed at grid (11,14), facing the entrance, after the jar and before the point enclosure. Native checks confirm supported, collision-free standing positions in front and to either side. Keep the ruin as a material return where inventory, arrangement and bodily consequence diverge. Full human traversal and headset comfort are separate checks.

## Verification and task order

| ID | Work | Evidence required | Status |
|---|---|---|---|
| E0 | Expand Entropy's research role and retain the two supplied texts. | This brief, provenance, source audit and exact mathematical fixtures. | Complete for planning; no new runtime experiment. |
| E1 | Correct jar labels/registry and stale incoming descriptions; expose the existing measurement. | Source and display agree on conditional colour entropy, units and partition; current controls still work. | Complete for labels, registry, fixtures and disclosure modes. |
| E2 | Build the small counts lesson and the cyclic history comparison. | Printed learner code reconstructs them; fixture values match; sorting/reading spends no hidden new draw. | Earlier counts lesson retained as counts-and-neighbours.md; cyclic history apparatus pending. |
| E3 | Add partition comparison and the sixteen-site multiplicity model. | Fixed configurations support matched measurements; all 12,870 site arrangements account for the multiplicity table; thermal assumptions and omissions are displayed. | Multiplicity bench complete and enumerated; editable jar partition/radial comparison still pending. No thermal model claimed. |
| E4 | Conduct one bounded encounter/reconstruction trial. | Baseline, one change, observation, alternative explanation, saved state, replay and next decision, including no useful change. | Native experiment cycle and fresh printed-code reconstruction pass. Human learning, reading response and physical headset trial pending. |
| E5 | Revise placement, final and tutorial from the result. | One shared adopted room/final order; exact code/dependencies; interpretations tied to the observation trajectory. | Implemented from the native trial; ready for a reader/learner to challenge. Tutorial mechanism is 25 nonblank lines with declared supplied host. |
| E6 | Consider min-entropy, compression, belief or heat-exchange extensions. | A question from E4 justifies each addition; a named quantity and reconstruction contract precede any gauge. | Available branches; not all compulsory. |
| EH | Extend the prefab study into reversible hybrids and let seeds change the assemblies. | Every part used once; mixed source membership; old/new saved replay; no floor crossing; actual hall controls. | Installed and natively verified, including thirty-nine sampled seeds, exact saved targets and earlier fixed-hybrid records. Human comparison of two saved variants and one alternative joining rule remain to test. |
| EHG | Retain several hybrids for comparison and replay. | Persistent index; four saved sets per page; seed/stage labels; exact older and intermediate replay; physical hall controls; missing records leave the experiment intact. | Installed: 104 apparatus and 32 hall checks pass. Human comparison of apparent roles and uses remains open. |
| E7 | Carry the question across maps using the entropy/information observation card. | Distinct variable/ensemble, intervention and evidence in each map; any actual transfer has a declared receiver and reconstruction check. | Framework, staged ER0–ER7 tasks and worked prefab/seed cards added. Exact synthetic fixtures and source audit recorded; no new runtime measurement or cross-hall transfer claimed. |

The first supplied text's “ghost student” suggests a useful executable check: construct the declared prerequisite object plus only the printed edits and assets, in a fresh scene, and test the intended behaviour. Do not quietly borrow an undeclared production component. This tests tutorial completeness, not the existence or experience of a future learner. Human reconstruction, assistance, confusion and reasons to continue remain separate evidence.

Keep artifact tests, experiment-cycle tests and promised cross-hall integration distinct. Runtime stability, performance and headset use need their own checks. Both tutorial and final may initiate or revise an experiment. Preserve observation, inference, analogy and proposal as different kinds of record, with a parent state and a reason for each change. No task requires an encounter to confirm QFEP.

## Visible ghost-student pilot · 16 October 2026

The prefab bench now has a holographic rehearsal: two articulated arms and fingered hands operate its existing pointer controls, with pauses at each consequence. It runs once for an idle watcher, or through WATCH; visitor input yields control immediately. The nine actions link to current tutorial excerpts, preserve a separate ghost KEEP record, change the conditions and replay. The final supplies an interpretive question, not a claim that this optional encounter is in the adopted final text. [Native recording and receipts](../../../iterations/2026-10-16-ghost-student-pilot/index.html).

1. **Apparatus rehearsal:** compare recorded input and actual state, including deliberately broken controls, stale text, cancellation, scene exit, human takeover and save isolation. Native checks are retained with the pilot.
2. **Next human observation:** watch the ghost once, then take over. Did an action invite a different action, or did the demonstration prescribe too much? Record the first interruption, an unresolved question, discomfort or boredom. Do not infer these from the scripted trace.
3. **One revision:** use that observation to change one pause, gesture, control or text claim, then compare the two versions from the same starting state. Preserve the rejected version and reason.
4. **Expand after comparison:** add an adapter for the first 48-value bench or abacus, then the compartment apparatus. Their own operations and observations must be declared; do not apply one choreography to every work. The prefab now has one checked continuation to the Shannon ledger; arrival is not a ledger control rehearsal or a full-hall tour.

### Eye-view comparison and continuation · 16 October

The [prefab playtest](../../../iterations/2026-10-16-ghost-prefab-playtest/index.html) changes one encounter's attention: compare left/right at the same midpoint, then follow the CRT screen through joining. Native views exposed an easily lost small part, a cropped text stream and a standing position too close to the entrance wall. The artifact now offers FOLLOW PART, a longer joining action, comparison pauses and revised observer framing/standing position. Save/replay and the original materials remain intact. The tutorial now names the part, holds the comparison condition fixed and distinguishes a saved image from an executable state.

| Task | Evidence / status |
|---|---|
| EGV1 — Compare both tables and track a source part | Paired renders retain seed, stage, stable part key, transforms and gaze. Inspect occlusion separately from computed frustum inclusion. |
| EGV2 — Expose the proposed reading | Tutorial/final excerpts and authored questions above the head; source text/hash in each receipt. A source mismatch is displayed, not silently presented as current text. |
| EGV3 — Continue after completion | Baseline restored, floor/capsule route to the ledger, arrival view; blocked/missing routes and visitor cancellation tested separately. No automatic ledger action claimed. |
| EGV4 — Human comparison | Pending: WATCH once, then take over with the marker off. Which relation becomes visible? Where does the cue prescribe a reading or conceal an ambiguity? Record assistance and boredom as evidence. |
| EGV5 — Revise a rule | Pending: change one bundle or join from a kept record, then compare using the same viewpoint and stage. A more legible form is not automatically a better research encounter. |

This makes the retention of one part across relations inspectable. It also privileges a preselected screen and a planned route. Unmarked parts, unexpected uses, a visitor's refusal to continue and the experience of handling the object remain outside the scripted result. Preserve those limits in the next observation card.

The 48-value seed bench remains the first research pilot. This is an encounter-rehearsal prototype. Printed-code reconstruction, cross-hall transfer, headset hand collision/haptics, Quest performance and human understanding remain separate work. No change to the main room/final order is required.

[Sources and calculation receipt](../../../iterations/2026-10-15-entropy-research-map/README.md)


## All-artifact layout · 16 October

The [hall-order review](../../../iterations/2026-10-16-entropy-hall-order/index.html) records the current positions, eight-encounter main route and optional side stops. Both bays are 25 m wide, joined at row 33. Museum arrival is before the ledger at (8,2). Geometry checks and a collision-tested path are technical evidence; the next human trial asks where the sequence loses its reason to continue. The first 48-value pilot remains unchanged.
