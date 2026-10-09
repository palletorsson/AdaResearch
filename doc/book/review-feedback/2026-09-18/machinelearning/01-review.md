# Machine Learning — 01 Review

Source-aware editorial and reader-experience review of the **Machine Learning** sequence.

Basis: `machinelearning-book.md`, `machinelearning-review.md`, and the supplied ZIP snapshot on branch `palm-scanner-door-entry`, captured 2026-09-18. No repository code was executed.

This review uses two linked lenses:

1. **Structural / technical:** what the implemented encounter actually supports, what each return does in the sequence, and where source, scene configuration, metadata, map, and manuscript disagree.
2. **Reader experience:** where curiosity builds, where a learner can discover something before it is named, where explanation arrives too early, and whether the better intervention belongs to the artifact rather than the prose.

Before proposing any cut, the review asks what technical, poetic, critical, or structural work the passage performs. A machine-learning label is not treated as evidence that learning is actually taking place. This sequence especially needs to distinguish:

- an actual optimisation/update;
- a fixed model evaluated under another rule;
- a preprocessing operation;
- an explanatory diagram;
- a scripted animation;
- a literal supplied label;
- and a genuine learned prediction.

The strongest current **book** arc is:

> **selection condition → explicit objective → clustering geometry → learned parameter update → preprocessing versus recognition → diagram of recurrent memory → diagram of adversarial learning → anomaly rule**

A second formulation is:

> **“Learning” is never enough of an explanation. Ask what state changes, which evidence caused the change, which objective or rule values one change over another, and whether the displayed confidence, category or progress was actually computed by the learner being described.**

That is stronger than the inherited sequence truth:

> “Learning is optimization in a landscape you can't fully see.”

Several current halls are not optimization landscapes at all, and two of the declared halls are explicitly diagrams rather than running learning systems.

---

# 1. One line per hall

| Hall | What carries it / main gap / next useful revision |
|---|---|
| **ML Evolution** | **Carries:** an excellent opening because it removes the explicit leaderboard without removing consequences. Bodies gain energy when entering previously unvisited grid cells, lose energy over time, reproduce above a threshold and mutate colour/size/speed. The manuscript correctly says the environment supplies a preference even if no separate fitness number is displayed. **Gap:** source identity says “no selection pressure” and “drift alone,” but the energy economy is plainly selective; its header also says reproduction depends on proximity although the actual reproduction test is energy-only. One visited cell is regenerated every 120 drawn frames, making reward renewal frame-rate dependent. **Next:** preserve the manuscript, clean source identity and make the environmental reward/recovery rule more inspectable before adding another selection control. |
| **ML Gradient Landscape** | **Carries:** a very strong transition to explicit objective. Three loss surfaces evaluate the same current dataset; MSE, Huber and deliberately wavy “adversarial” loss give different landscapes for the same slope/intercept candidate. The manuscript wisely distinguishes the score surface from the observations and refuses the “adversarial” label as GAN training. **Gap:** the learner-facing OUTLIERS comparison is not controlled across slider/reset changes: the default `few` dataset is regenerated from a running RNG stream, and RESET does not reseed it. Changing outlier fraction therefore redraws clean jitter, outlier membership and outlier magnitudes as well as the requested fraction. **Next:** make the outlier comparison nested/reproducible using one fixed base sample and predetermined candidate outliers, or expose the deterministic `tail` axis already implemented in source. |
| **ML Classification** | **Carries:** k-means is a good representation lesson: assignment and centroid movement alternate; a stationary point can change colour because a centre moved; the centroid is explicitly treated as a compression of assigned positions; the text carefully says this is clustering, not labelled classification. **Gap:** the current shipped scene contradicts the manuscript’s key controlled example. The text says K=4 is imposed on **three broad blobs plus noise**, but the `.tscn` overrides `natural_cluster_count = 4`; the staged default is therefore K=4 on four generated clusters plus noise. The source already contains reproducible `rings`, `block`, `braid`, and `skew` cohorts that demonstrate limits far better than a hypothetical future dataset. **Next:** restore three blobs for the default or rewrite the chapter; preferably add a DATASET/COHORT control using the already-built axis. |
| **ML Neural Networks** | **Carries:** this is one of the few later halls that genuinely performs the process it describes. A small feed-forward network with trainable weights/biases runs forward passes, computes MSE on four fixed 4-input/2-output examples, backpropagates deltas and updates weights. The manuscript correctly separates transient activation from lasting weight state and warns that training error says nothing yet about unfamiliar examples. **Gap:** training batches are sampled with global `randi()` rather than the artifact’s seeded RNG, so repeated training is not reproducible even though initial weights are; the source identity’s “layers learn features” language is also too broad for this tiny fixed problem. **Next:** preserve prose; optionally seed batch order and add the manuscript’s proposed held-out example before expanding theoretical claims. |
| **ML Perception** | **Carries:** the manuscript makes exactly the right distinction: Sobel edge detection is real computation; object names/confidences are literal claims placed beside it, not predictions derived from the edges. The moving 3×3 window also makes the local-versus-image-wide scale difference inspectable. **Gap:** the artifact already has a strong hidden audit axis—`detection = named / invented / swarm / whole / bare`—that changes only the bounding-box claims while leaving the input image and Sobel map unchanged, but the museum placement exposes only the default `named` state. **Next:** add a CLAIM control so visitors can watch confident labels move while the evidence remains fixed; this turns the chapter’s critical paragraph into an experiment. |
| **ML Sequence Memory** | **Carries:** as written, this is a responsible diagram chapter. It separates retain/admit/expose roles and explicitly says the current installation does **not** compute an input sequence through a recurrent memory. **Gap:** the hall is absent from museum-authored order, and its source is less honest than the manuscript: “gate activations modulate memory flow” is claimed, but the animated particles follow a fixed sinusoidal path independent of forget/input/output activations. The “grabbable” gates are rigid bodies whose y-position changes an activation display, not a working LSTM update. Spatially, a transformer secondary sits earlier in the corridor than the manuscript-primary LSTM. **Next:** restore the hall only as an explicitly labelled diagram, move the LSTM encounter before the transformer if it remains primary, and make at least one gate visibly affect a flow/state quantity—or keep the particles clearly decorative. |
| **ML Generative** | **Carries:** the manuscript is admirably explicit that this room illustrates generator/discriminator roles and does not train a GAN. That distinction is exactly right for the current conceptual place in the sequence. **Gap:** the source is currently weaker even as theatre. Both fake-data and real-data creation loops use `range(particle_count, 2)`, which produces zero iterations for the shipped `particle_count=20`; no fake or real example particles are created. `generator_loss` and `discriminator_loss` are scripted curves, but the visible `MetricsLabel` remains hard-coded at `1.00 / 1.00` and is never updated. The room is also absent from museum-authored order. **Next:** restore only after fixing those construction/display bugs and label it unambiguously as a **GAN role/training diagram**, unless an actual toy adversarial update is implemented. |
| **ML Synthesis / Anomaly Detection** | **Carries:** a good ending because the point marked “anomalous” becomes a relation to a selected rule/reference population rather than an intrinsic property. The default z-score-like rule really computes coordinate-wise standardised displacement and includes the seeded outer points in the mean/std that later judge them. **Gap:** the source advertises three modes, but the placed scene has no physical controls and the script’s own identity says mode cycling/threshold adjustment are missing. More seriously, `AUTOENCODER_ERROR` contains no autoencoder: it scores distance from a hand-authored sine curve plus a radial penalty. **Next:** expose MODE/THRESHOLD and rename that mode to a reconstruction proxy unless a real autoencoder is added; then make the reference-population experiment the final active comparison. |

---

# 2. The largest structural issue: the book has eight halls; the museum route currently has six

## Declared/current book order

1. ML Evolution  
2. ML Gradient Landscape  
3. ML Classification  
4. ML Neural Networks  
5. ML Perception  
6. **ML Sequence Memory**  
7. **ML Generative**  
8. ML Synthesis

## Museum-authored order

1. ML Evolution  
2. ML Gradient Landscape  
3. ML Classification  
4. ML Neural Networks  
5. ML Perception  
6. ML Synthesis

Missing:

- **ML Sequence Memory**
- **ML Generative**

These are not simply extra topics.

They perform an important epistemic function:

> they are the two rooms where the book explicitly says **the exhibit is currently a diagram, not the learning process it depicts**.

That is a valuable contrast with Neural Networks, where an actual parameter update is implemented.

## The manuscript transitions assume all eight halls

Perception ends:

> “The sequence-memory room adds another source of evidence: what happened before the current input arrived.”

Sequence Memory ends:

> “Generative learning next changes the task again…”

Generative ends:

> “The synthesis room looks directly at that outside…”

The book therefore has a coherent eight-hall path.

The museum route currently jumps:

> Perception → Synthesis

and removes the two clearest opportunities to discuss the difference between:

- explanatory model;
- computational learner.

## But restoration should not mean pretending the current installations are more complete than they are

Sequence Memory is a spatial LSTM diagram.

Generative is a GAN role/training diagram with additional source bugs.

That is fine if the route tells the truth.

The right restoration is:

> **computed learner → computed preprocessing + invented labels → diagram of recurrent memory → diagram of adversarial training → computed anomaly rule**

This progression is actually very useful.

It gives the sequence three modes of epistemic status.

---

# 3. Sequence structure

## 1. Evolution — objective can be embedded in survival conditions

The opening challenges a simplistic equation:

> no explicit fitness score = no selection.

The source population gains energy only when entering unvisited grid cells.

That makes:

> exploration consequential.

A lineage whose traits alter movement can change its access to reward.

This is not “optimization without gradient” in the same direct sense as the next room.

It is selection under an authored environment.

That distinction is valuable.

## 2. Gradient Landscape — objective becomes visible

The next room makes evaluation explicit.

One candidate model can be assigned different heights under different loss definitions.

This is the first hall where “better” is literally represented as downhill.

The progression from Evolution is therefore:

> implicit survival economy  
> → explicit scalar objective.

Good.

## 3. Classification — representation chooses geometry before interpretation chooses a name

K-means introduces a different operation.

There is no target label.

There is:

- K;
- Euclidean distance;
- centroid mean;
- iteration.

The key distinction is:

> a cluster is a geometric partition under this representation, not a discovered natural category.

That develops the sequence’s concern with objective/measure.

## 4. Neural Networks — learned state is distributed across adjustable relations

This is the first primary hall in the sequence with a genuine backpropagation update.

The model’s state is not one centre or one point.

It is a set of weights/biases.

The display can therefore ask:

> where is learning stored?

Excellent.

## 5. Perception — computation can be real while the interpretation beside it is invented

This is a very important turn.

The Sobel operation is real.

The object-name boxes are not.

That gives the sequence a clean dependency question:

> what does the confident claim actually depend on?

Excellent preparation for the diagram halls.

## 6. Sequence Memory — the room is a diagram of a learning mechanism

This hall should be explicit about its epistemic status.

Its value is not proving that the installation remembers.

Its value is separating roles:

- retain;
- admit;
- expose.

That gives the visitor a vocabulary for future recurrent models without pretending a decorative flow path is evidence of memory.

## 7. Generative — the room is a diagram of a changing evaluator/evaluated relation

Again, the value is relational.

A GAN differs from the fixed loss landscape because:

> the discriminator is itself supposed to learn.

That is the key conceptual step.

The current artifact does not perform it.

The book says so.

Good.

## 8. Synthesis — anomaly is a rule applied to a reference population

The final room returns to actual computation.

A point becomes unusual because:

- sample statistics;
- score formula;
- threshold

make it so.

That is the right sequence ending because it asks:

> what did the model discover, and what did the representation/rule manufacture?

Graph Theory can then move from distance/score to explicit connections.

---

# 4. Reader-experience lens

## ML Evolution — Survival without a finish line

### Curiosity

The opening is strong because it asks the visitor to follow one body rather than begin from a population statistic.

A birth/death event can therefore be encountered as history before it becomes “evolution.”

### Discovery

The manuscript’s causal order is excellent:

> inherited variation → possible change in behaviour → consequence under the environment.

That resists the easy story:

> visible difference = adaptation.

The environment’s reward rule is also a good delayed reveal:

> new grid cell → energy.

A body that revisits old space receives no exploration energy until cells are reopened.

### Source truth and source rhetoric

The actual source is more selective than its header admits.

Header:

> “No selection pressure.”  
> “Bodies persist through drift alone.”  
> “reproduce based on proximity and energy.”

Implementation:

- gain energy from unvisited cells;
- lose energy per second;
- die at zero;
- reproduce above an energy threshold;
- no proximity test appears in reproduction;
- colour/size/speed mutate.

The manuscript is the accurate layer:

> environment supplies preference.

### Frame-dependent environment

Visited cells are slowly reopened through:

```gdscript
if Engine.get_frames_drawn() % 120 == 0:
    one random grid cell becomes unvisited
```

That is not time-normalised.

Reward renewal therefore depends on frame count.

For a qualitative continuous installation this may be acceptable, but if comparisons across machines matter, it should become time-based.

### Reader opportunity

The manuscript proposes changing the reward to favour dependable revisits.

That is a good future experiment.

But the source’s Stage-2 `selection` axis is mostly a set of **finished illustrative states** (`uniform`, `culled`, `runaway`, `split`), not live alternative survival economies.

Do not confuse that capture axis with a genuine reward-policy experiment.

### Return

Swarm’s objective/caretaker concern enters individual lineage persistence.

---

## ML Gradient Landscape — Three meanings of error

### Curiosity

This is one of the sequence’s strongest rooms.

Three surfaces represent:

- same parameter coordinates;
- same current dataset;
- three scoring rules.

The visitor can look at one slope/intercept candidate and ask:

> how high is the same candidate in each landscape?

That is excellent.

### Discovery

The manuscript’s MSE/Huber distinction is source-supported.

The third “adversarial” surface is explicitly:

```gdscript
sum( sin(3e) + 0.5 e² )
```

and the text correctly refuses GAN associations.

The balls take numerical finite-difference gradient steps.

Their parameter domain is clamped to `[-2,2]`.

So:

> local landscape + start + domain

can influence the final point.

Good.

### Major controlled-comparison issue

The physical OUTLIERS slider does not merely “add more outliers” to one held sample.

When the slider moves:

```gdscript
tail = "few"
outlier_fraction = ...
_regenerate()
```

`_regenerate()` calls `_generate_dataset()`.

It does **not** reset `_rng` to `DATA_SEED`.

Thus the whole default sample is redrawn from the continuing random stream:

- clean jitter changes;
- which points become outliers changes;
- outlier sign changes;
- outlier magnitude changes.

RESET does the same.

The three surfaces within one moment still share the same dataset.

But the before/after outlier comparison does not.

### Artifact fix

The source already demonstrates how to do controlled dataset states through deterministic tails:

- none;
- sole;
- few;
- heavy;
- split.

A better learner instrument would be:

> **DATA / TAIL**

or:

> **OUTLIERS: none → one → few → heavy**

using fixed baseline jitter and fixed preselected outlier identities/magnitudes.

Then the visitor can compare losses under a nested or otherwise explicitly composed dataset.

Keep `split` as a later complication:

> coherent second population, not “bad data.”

### Timing

Very good once the dataset comparison is controlled.

---

## ML Classification — A boundary that moves with its centre

### Curiosity

The opening question is excellent:

> why can a stationary point change groups?

It immediately makes membership relational.

### Discovery

Assignment and centroid update alternate.

That is the right rhythm.

The manuscript also makes a strong representational claim:

> a centroid is already a compression.

It stores a mean, not the group’s internal geometry.

Good.

### Current artifact/manuscript contradiction

The manuscript says:

> “The default display starts with four centres, while the generated sample contains three broad blobs and some noise.”

The source script default indeed says:

- `cluster_count = 4`
- `natural_cluster_count = 3`.

But the **current `.tscn` overrides**:

- `data_point_count = 80`
- `natural_cluster_count = 4`
- `cluster_spread = 3.5`
- `noise_points_percentage = 0.15`.

The map does not override `cohort`.

Therefore the placed default `blobs` case generates:

> four natural clusters + noise

for:

> four centroids.

The manuscript’s pedagogically useful K≠natural-cluster-count mismatch is not actually present.

### Preferred artifact fix

Restore:

> `natural_cluster_count = 3`

for this lesson placement.

Do not rewrite the book to four/four.

The mismatch is doing good conceptual work.

### The future rings experiment already exists

The manuscript says nested rings would be a useful future dataset.

The source already implements a `cohort` axis:

- blobs;
- block;
- rings;
- braid;
- skew.

This is a high-value missed opportunity.

Add:

> **DATASET**

cycling at minimum:

- BLOBS;
- RINGS;
- BLOCK.

Keep K=4.

Then the visitor can directly see:

- flattering dataset;
- geometry K-means cannot represent naturally;
- dataset with no cluster structure where K-means still confidently partitions.

That is far stronger than a paragraph declaring clustering limits.

### Readout nuance

`total_distance` sums **Euclidean distances**, not squared distances.

K-means centroid updates are the ordinary mean updates associated with squared-error/inertia objective.

So the displayed “Total Distance” is a useful summary but is not literally the K-means inertia being minimised.

The manuscript wisely calls it:

> “a particular readout.”

Keep that caution.

---

## ML Neural Networks — A connection changed by an error

### Curiosity

This hall has a clear local question:

> where is learning stored?

Following one connection over several updates is a good way to make a huge parameter system bodily manageable.

### Actual learning is present

Unlike Sequence Memory/GAN, this source genuinely trains.

It:

- initializes weights;
- has four training examples with four inputs/two targets;
- performs forward passes;
- calculates MSE;
- backpropagates deltas;
- updates weights/biases in batches.

The manuscript’s central distinction is therefore real:

> activation is transient; weight is persistent model state.

### Training sample

The four examples are essentially a small binary parity/XOR-like task encoded into four inputs/two outputs.

The manuscript wisely avoids overselling what the task means.

### Reproducibility seam

Initial weights use the artifact’s seeded RNG.

Batch sampling uses global:

```gdscript
randi() % training_data.size()
```

So identical rebuilds can begin from identical weights but follow different training-sample sequences.

The book does not claim deterministic replay, so this is not a current prose error.

If a future HOLDOUT/compare experiment needs reproducibility, use the local RNG here too.

### Source identity overreach

“Layers learn features” is too broad for this toy network.

Nothing in the current training setup establishes hierarchical feature extraction in the modern deep-learning sense.

The current manuscript is better:

> connected parameters adjust under training error.

### Future held-out example

This is the right artifact extension.

A fifth example that is excluded from updates and evaluated after each epoch would make:

> training improvement ≠ generalisation

visible.

Do not add more neural-network theory before adding that comparison.

### Timing

Good.

This is one of the sequence’s strongest actual-learning rooms.

---

## ML Perception — An edge is not yet an object

### Curiosity

Excellent opening question:

> at which point does pixel difference become a claim about what is there?

The 3×3 moving window makes the local operation visible.

### Actual computation

The source applies Sobel X/Y to the 16×16 input.

At the outermost border it explicitly writes zero.

The manuscript accurately exposes that boundary policy.

Good.

### Invented recognition

The current object detection stage is an authored claim layer.

Default `named` places:

- Circle: 92%
- Cross: 85%

over fixed regions.

These percentages are literal constants.

They do not depend on Sobel output.

The manuscript says exactly that.

### The artifact already has the experiment the manuscript needs

Stage-2 axis:

> `detection`

has values:

- `named`
- `invented`
- `swarm`
- `whole`
- `bare`.

Crucially, the input image does **not** change.

The Sobel edge map does **not** change.

Only the bounding-box claims change.

Examples:

**invented**
- Person 97%
- Vehicle 94%
- over mostly blank/different regions.

**bare**
- no claim at all.

**swarm**
- 36 low-confidence “Region” boxes.

**whole**
- one 51% “Image” claim over the entire canvas.

This is nearly a perfect Ada artifact.

### Artifact proposal

Add a physical:

> **CLAIM**

control.

Start with:

> BARE

or NAMED depending intended timing.

Then cycle.

The visitor can watch:

> evidence unchanged / asserted interpretation changed.

That is substantially better than only reading that the confidence is unsupported.

### Timing

This is a case where the prose is already good but the hidden artifact axis should do more work.

---

## ML Sequence Memory — What should survive the next input?

### Curiosity

The manuscript’s spatial task is useful:

- follow cell-state route;
- follow output route;
- imagine withholding information at one gate.

This gives memory three different jobs before equations arrive.

### Honest manuscript

The chapter explicitly says:

> the present arrangement is a spatial diagram.

That is correct.

It does not compute a recurrent sequence.

### Source overclaim

The source identity says:

> gate activations modulate memory particle flow.

They do not.

Gate y-position changes:

- activation number;
- sphere brightness/scale.

The “memory particles” follow a fixed path:

- x lerp;
- sinusoidal y;
- sinusoidal z;
- constant progress rate.

The gate activation values are not consulted.

Training progress is also a scripted clock:

- loss = linear decline;
- accuracy = linear rise.

No LSTM training occurs.

### Gate interaction

The gates are RigidBody3D spheres on an XRTools-associated collision layer, with activation derived from their global y position.

But there is no actual recurrent state calculation.

This is fine as a tactile diagram if framed that way.

### Reader issue: room order

If this map is restored, the corridor currently places:

- transformer secondary at z5;
- LSTM primary at z8.

The manuscript begins with the LSTM gate diagram.

So the physical room likely presents a secondary concept first.

Prefer:

> LSTM first, transformer later

or rewrite the hall as sequence-memory-family comparison.

I prefer restaging because the current manuscript has a focused primary.

### Minimal artifact improvement

If you want one causal experiment without building a full LSTM:

- let FORGET gate attenuate/fade an explicit “previous state” stream;
- let INPUT gate attenuate a new-candidate stream;
- let OUTPUT gate attenuate a separate display stream.

This can remain a diagram.

But gate values would then visibly affect the relation they are named for.

That is enough for this chapter.

---

## ML Generative — Learning from an opponent’s response

### Curiosity

Conceptually, the room asks the right question:

> what happens when the evaluator is also supposed to change?

That is an important contrast with Gradient Landscape.

### Honest manuscript

The text explicitly says:

> no generator/discriminator are actually trained.

This is correct.

### But the current source is broken even as an explanatory animation

Two creation loops read:

```gdscript
for i in range(particle_count, 2):
```

with `particle_count = 20`.

In GDScript, `range(20,2)` with the default positive step is empty.

Therefore:

- `fake_data_particles` remains empty;
- `real_data_particles` remains empty.

The room still creates:

- noise spheres;
- generator/discriminator cores;
- feedback-loop particles;
- a competition pillar.

But no actual real/fake example particles are generated.

### Scripted losses are not visibly updated

The source computes:

```gdscript
generator_loss = 1 - progress * .7
discriminator_loss = .5 + sin(time)*.2
```

But the visible `MetricsLabel` is created once as:

> Gen Loss: 1.00  
> Disc Loss: 1.00

and there is no code updating that label.

So the manuscript’s phrase:

> “displayed losses are prescribed curves over time”

is too generous.

The **variables** are prescribed curves.

The visible loss display appears static.

### Source identity is much stronger than source behaviour

It says:

> “both networks compete and improve together through adversarial training.”

No networks exist in the source.

### Preferred short-term repair

If this remains a diagram hall:

1. fix the loops so real/fake example particles actually exist;
2. update the metrics display from the scripted values;
3. label the room clearly:
   > **GAN TRAINING ROLES — SIMULATED METRICS / NO LEARNED MODELS**
4. do not say candidates “improve” unless the visual candidate itself changes in a defined way.

### Longer-term experiment

The manuscript proposes exactly the right future object:

- one real example;
- one generated candidate;
- discriminator response;
- one actual generator/discriminator update.

Even a tiny 1D or 2D toy GAN would be better evidence than elaborate theatrical animation.

### Route

The hall is absent from museum-authored order.

Restore it once its diagram is internally coherent.

---

## ML Synthesis — The point outside the rule

### Curiosity

The ending question is very strong:

> what exactly has been discovered when a point is flagged?

The raised/enlarged point is a clear bodily representation of a threshold decision.

### Default source supports the manuscript

The seeded dataset contains:

- 72 central “normal” samples by default;
- 10 generated outer samples.

The mean/std are computed over **all samples**, including those outer samples.

Then the default score is:

```gdscript
abs(z_x) + abs(z_y)
```

and threshold = 2.4.

So the manuscript’s point is exact:

> the population defining normality includes the observations that may later be called abnormal.

Excellent.

### Threshold visualization caveat

The visible threshold cylinder for Z-score mode is only an approximate radial visualisation:

```gdscript
visual_radius = mean(std_x,std_y) * threshold
```

But the actual decision boundary for:

> `|zx| + |zy| >= threshold`

is diamond-like in standardised coordinate space, not a circle.

So the ring should not be treated as the exact classifier boundary.

The manuscript currently does not rely on it.

Good.

### Missing controls

The source identity says:

> mode cycling missing  
> threshold adjustment missing.

The placed scene has no extra controls.

Thus the chapter’s active experience is essentially the fixed default Z-score rule.

The manuscript’s future proposal:

> expose threshold/reference population

is correctly identified.

### “Autoencoder Error” is not an autoencoder

The source’s third mode computes:

```gdscript
expected_y = sin(x * .6) * 1.5
reconstruction_error = abs(y - expected_y)
radial_penalty = abs(length - 2.4) * .25
```

There is no:

- encoder;
- bottleneck;
- decoder;
- learned reconstruction.

Calling this **Autoencoder Error** is technically false.

Rename it:

> **Curve Reconstruction Proxy**

or implement an actual small autoencoder.

### Strong final artifact

Add:

- MODE;
- THRESHOLD;
- REFERENCE (include/exclude seeded outer points).

Then the ending can become a real three-way experiment:

> same points / changed score family / changed threshold / changed reference population.

That is exactly the sequence thesis.

---

# 5. Five high-value changes

## 5.1 Restore Sequence Memory and Generative, but restore them explicitly as **diagram halls**

**Evidence type:** ROUTE + SOURCE + READER EXPERIENCE

The book declares:

> Perception → Sequence Memory → Generative → Synthesis.

Museum-authored order currently goes:

> Perception → Synthesis.

### Sequence Memory source status

No recurrent input sequence is computed.

Gate values do not alter memory particles.

Loss/accuracy are scripted from elapsed training progress.

### Generative source status

No GAN is trained.

Additionally:

- real/fake particle creation loops currently create zero particles;
- visible metric label is never updated.

### Proposal

Restore both halls, but mark the narrator/encounter mode.

For example:

> **DIAGRAM — MEMORY ROLES**

> **DIAGRAM — ADVERSARIAL TRAINING ROLES**

For Sequence Memory:

- restage the LSTM before the transformer if LSTM remains manuscript-primary;
- either connect gate values to visible flow/state or explicitly mark particles decorative.

For Generative:

- fix empty loops;
- update scripted metrics display;
- label metrics as simulated;
- retain the manuscript’s statement that no model is trained.

### Reason

These halls are valuable precisely because they let the book distinguish:

> learning mechanism  
> from  
> explanatory representation.

Removing them loses that distinction.

Pretending they are working learners would be worse.

---

## 5.2 Gradient Landscape — make the OUTLIERS experiment compare one dataset under controlled contamination

**Hall:** `ML_Gradient_Landscape`  
**Artifact:** `loss_function_comparator`

### Current manuscript

> “Keep OUTLIERS low for a first comparison, then raise it and reset.”

This implies a controlled change in outlier burden.

### SOURCE

Default build seeds `_rng = 123`.

But after build:

```gdscript
_on_outlier_changed()
    tail = "few"
    _regenerate()

_on_reset_pressed()
    _regenerate()
```

and `_regenerate()` does **not** reseed `_rng`.

So every slider/reset regeneration redraws:

- clean jitter;
- outlier positions;
- signs;
- magnitudes.

### Proposal

Keep one fixed baseline dataset.

Precompute:

- clean jitter for all 20 samples;
- one deterministic random number per sample for “outlier eligibility”;
- one deterministic outlier magnitude/sign.

Then OUTLIERS changes only the cutoff selecting how many of those precomputed candidates are activated.

Alternative low-cost control:

Expose the source’s deterministic `tail` presets:

> NONE / SOLE / FEW / HEAVY / SPLIT.

### Reason

This hall is explicitly about how **the same evidence** is valued under different losses.

The outlier intervention should not quietly replace the evidence while trying to teach that lesson.

---

## 5.3 Classification — restore the K=4 / three-blobs mismatch and expose the existing cohort axis

**Hall:** `ML_Classification`  
**Artifact:** `enhanced_kmeans`

### Current manuscript

> “The default display starts with four centres, while the generated sample contains three broad blobs and some noise.”

### SOURCE / SCENE mismatch

Script defaults:

- K = 4
- natural clusters = 3.

But the current scene overrides:

> `natural_cluster_count = 4`.

Thus the placed default removes the intended mismatch.

### Artifact proposal

For this lesson placement:

- K = 4;
- natural cluster count = 3;
- keep noise.

Then expose a simple:

> **DATASET**

control over the source’s already implemented `cohort` axis:

1. BLOBS
2. RINGS
3. BLOCK

Optional later:

- BRAID
- SKEW.

Reset/reseed consistently between cohorts.

### Why these three

**BLOBS**

> the flattering case.

**RINGS**

> nearest-centre/Voronoi geometry cannot express ring membership.

**BLOCK**

> no natural cluster structure, yet K-means still returns four territories.

### Reason

The manuscript already asks for the nested-rings counterexample.

The code has it.

This is exactly where artifact work should replace hypothetical explanation.

---

## 5.4 Perception — turn the existing detection axis into a CLAIM experiment

**Hall:** `ML_Perception`  
**Artifact:** `computer_vision_vr`

### Current manuscript

> “the names and percentages are supplied in advance. They are not predictions learned from the computed edges.”

Excellent.

### SOURCE

The source already provides:

```text
detection:
    named
    invented
    swarm
    whole
    bare
```

The input image remains byte-identical.

The Sobel edge map remains identical.

Only the claim layer changes.

### Artifact proposal

Add a physical:

> **CLAIM**

control.

Suggested lesson sequence:

1. **BARE** — edges, no object claim.
2. **NAMED** — Circle 92%, Cross 85%.
3. **INVENTED** — Person/Vehicle labels elsewhere.
4. **WHOLE** — one full-image 51% box.

Keep SWARM as an optional exaggeration/coda.

### Reader timing

Begin BARE if you want maximum discovery.

The visitor first understands:

> local contrast.

Then a confident label arrives.

Then a clearly false label arrives over the same evidence.

### Reason

This is one of the strongest already-written critical experiments in the source and currently almost unused by the museum.

It makes:

> **computed evidence ≠ interpretive claim**

immediately visible.

---

## 5.5 Synthesis — make anomaly mode/threshold/reference population explicit, and remove the fake autoencoder label

**Hall:** `ML_Synthesis`  
**Artifact:** `anomaly_detection`

### Current source

Three modes:

- Z_SCORE
- ISOLATION_RADIUS
- AUTOENCODER_ERROR.

But:

- no physical mode control;
- no threshold control.

And AUTOENCODER_ERROR is:

```gdscript
expected_y = sin(x * 0.6) * 1.5
error = abs(y - expected_y)
+ radial penalty
```

No autoencoder exists.

### Proposal

Add:

- **MODE**
- **THRESHOLD**
- **REFERENCE**

REFERENCE:

> ALL POINTS / CENTRAL CLOUD ONLY

or equivalent.

Rename third mode:

> **CURVE RECONSTRUCTION PROXY**

unless an actual learned autoencoder is implemented.

### Additional display correction

If the circular threshold visual remains under Z-score mode, label it as:

> **threshold guide**

rather than the exact decision boundary, because the implemented score is `|zx| + |zy|`.

### Reason

This lets the final hall become the sequence’s synthesis:

> same observations  
> → another scoring representation  
> → another threshold  
> → another definition of the reference population  
> → another set of “anomalies.”

That is far stronger than a fixed default readout.

---

# 6. Source / artifact discrepancies

## 6.1 Evolution source says “no selection pressure,” but its energy economy imposes one

The source rewards first visits to grid cells.

Energy affects:

- death;
- reproduction.

That is selective consequence.

The manuscript correctly says:

> environmental preference remains even without explicit ranking.

Use that as canonical wording.

---

## 6.2 Evolution header says reproduction depends on proximity, but code does not

The current reproduction condition is:

> energy above threshold + population below max.

No mate/proximity test appears.

Fix the source identity.

---

## 6.3 Evolution’s visited-cell regeneration is frame-count based

One random cell is reopened every 120 drawn frames.

That makes the ecological timescale hardware/frame-rate dependent.

Convert to elapsed-time logic if reproducible temporal comparison becomes important.

---

## 6.4 Evolution’s “selection” Stage-2 axis is capture vocabulary, not the live causal experiment described by the chapter

Non-default values (`uniform`, `culled`, `runaway`, `split`) are static/terminal illustrative states.

They are not alternate live reward policies.

Do not present them as if a selection process produced those bodies during the visit.

---

## 6.5 Gradient Landscape’s three surfaces share data at one moment, but OUTLIERS/RESET redraw it

As detailed above.

The manuscript’s simultaneous comparison is valid.

The before/after slider comparison needs artifact repair.

---

## 6.6 Gradient “adversarial” loss is not adversarial training

The current manuscript explicitly catches this.

Keep it.

The source identity should avoid using “adversarial” without the local definition:

> deliberately wavy custom loss.

---

## 6.7 Classification scene currently has four generated natural clusters, not three

As detailed above.

This is a direct manuscript/scene contradiction.

Prefer fixing the scene to preserve the stronger teaching point.

---

## 6.8 Classification’s “Total Distance” is not the standard squared-distance inertia

Assignments accumulate:

```gdscript
distance_to_centroid
```

not squared distance.

Centroid update still uses arithmetic means.

The manuscript correctly treats the readout as partial evidence.

Do not rename it inertia unless the computation changes.

---

## 6.9 Classification already contains the future counterexample datasets

`rings`, `block`, `braid`, and `skew` are fully implemented source cohorts.

Promote them.

---

## 6.10 Neural-network hall performs genuine forward/backprop weight updates

This is a positive discrepancy relative to some more theatrical ML rooms.

Keep this room as the sequence’s clearest example of actual model-state learning.

---

## 6.11 Neural-network batch sampling is unseeded/global

Initial weights are seeded through local `_rng`.

Batch sample selection uses global `randi()`.

So training history is not fully reproducible from the initial build.

No current prose claim is violated, but future held-out comparisons should seed this too.

---

## 6.12 “Layers learn features” is not established by the current tiny fixed training task

The source trains a small feed-forward network on four hand-coded examples.

It establishes:

- weighted layered computation;
- error-driven parameter update.

It does not establish hierarchical feature learning.

Clean sequence/source metadata.

---

## 6.13 Perception’s edge computation is real; recognition boxes are authored literals

Source:

- input pattern is fixed;
- Sobel is computed;
- detection boxes/confidences come from `_bbox_data_for()` constants.

The manuscript is exactly right.

---

## 6.14 Perception source already contains intentionally false claims

`invented` places Person/Vehicle claims without changing image data.

This is excellent critical material.

Expose it.

---

## 6.15 Sequence Memory particles do not respond to gate activations

Source identity says they do.

Implementation does not consult gate activations in `_animate_memory_flow()`.

This should be fixed or relabelled.

---

## 6.16 Sequence Memory training metrics are scripted, not learned

`training_progress` increases with time.

Loss/accuracy are deterministic functions of that progress.

No sequence, target or recurrent update is involved.

The manuscript correctly calls the room a diagram.

---

## 6.17 Sequence Memory “grabbable” gates are physics bodies, not evidence of working LSTM gating

Their y position maps to an activation scalar.

That scalar changes gate appearance.

It does not alter recurrent memory computation because no such computation exists.

---

## 6.18 Generative has no actual GAN training

The manuscript correctly says so.

Source identity does not.

Clean the identity.

---

## 6.19 Generative currently creates zero fake and zero real example particles

Both loops use:

```gdscript
range(particle_count, 2)
```

with particle_count = 20.

This is empty.

Fix it.

---

## 6.20 Generative computes scripted loss variables but never updates the visible metrics label

The visible metrics remain:

> 1.00 / 1.00

unless another external script not included here changes them.

No such dependency is shown.

The manuscript should say **scripted internal metrics** until the display is wired, or the artifact should be fixed.

---

## 6.21 Generative source panels say “both networks compete and improve together”

No networks are represented as trainable parameter systems.

That panel is stronger than the artifact.

Relabel as:

> intended GAN training relationship.

---

## 6.22 Anomaly default z-score mode includes seeded outer points in its reference statistics

This is source-supported and conceptually excellent.

The manuscript correctly highlights it.

---

## 6.23 Anomaly’s threshold visual is not the exact z-score decision boundary

The actual score is:

> `|zx| + |zy|`.

The display uses a circular cylinder radius derived from average standard deviation × threshold.

Treat it as a guide, not exact geometry.

---

## 6.24 “Autoencoder Error” is not an autoencoder

As detailed above.

This label should be changed unless a learned reconstruction model is added.

---

## 6.25 Anomaly mode/threshold controls are missing

The source identity itself says so.

The chapter’s future extension should become actual controls if this remains the sequence finale.

---

# 7. Sequence-level metadata that should be revised

The current `sequence.json` says:

> **Learning is optimization in a landscape you can't fully see.**

That is too narrow and too broad at once.

Too narrow because:

- k-means alternates assignment/means;
- perception performs a fixed Sobel transform;
- LSTM/GAN rooms are diagrams;
- anomaly detection applies rules.

Too broad because “learning” is not actually occurring in several rooms.

The QFEP connection also says:

> gradient descent **IS** the oscillation between order and entropy; overfitting is F-collapse; underfitting is E-dominance.

Those are project-theoretical mappings, not established machine-learning facts.

They should be marked as QFEP interpretation rather than sequence truth.

## Proposed editorial intention

> **Follow how models change—or merely appear to change—under different evidence, objectives and representations. Distinguish learned state from preprocessing, supplied labels, diagrams and fixed decision rules.**

## Proposed objectives

- Identify environmental selection pressure even when no explicit fitness score is displayed.
- Compare several loss functions on the same candidate model and controlled dataset.
- Treat K and distance as authored assumptions in clustering rather than discovered categories.
- Distinguish transient neural activations from learned weight/bias state.
- Separate computed image evidence from object labels/confidences that are supplied independently.
- Read recurrent-gating diagrams without confusing them with demonstrated memory.
- Read adversarial-learning diagrams without confusing prescribed metrics with trained models.
- Compare anomaly scores, thresholds and reference populations without treating “anomaly” as intrinsic.
- Distinguish training fit from evidence of generalisation.

## Sequence title/truth option

> **Machine Learning: What Changed, and Why?**

or retain the existing title with truth:

> **A learner changes state under evidence and an objective. An exhibit may also preprocess, classify, visualise or merely illustrate that relationship; the first task is to tell which one is happening.**

---

# 8. Spatial / curation findings

## ML Evolution

Primary `non_teleological_evolution` at `(6,3)` is preceded at z2 by:

- evolved creatures;
- gradient-descent visualisation.

The manuscript begins with the non-teleological population.

Because the room is an amphitheatre, this may not imply encounter order.

**RUNTIME / SPACE TEST:** verify whether the older fitness/gradient works visually dominate before the primary argument begins.

## ML Gradient Landscape

Primary loss comparator is at `(6,8)`.

Gradient-descent and PCA secondaries are earlier at z3/z5.

The manuscript begins directly with the three-loss comparator.

This could be a spatial reader-order issue.

If visitors encounter a conventional single gradient landscape first, it may actually be useful preparation—but the sequence should be intentional.

No restage recommended before walkthrough.

## ML Classification

Primary k-means at `(3,3)` is clearly first.

Good.

## ML Neural Networks

Primary neural-network visualisation `(2,3)` is before secondary works `(2,8)` and `(9,8)`.

Good.

## ML Perception

Primary computer-vision work `(3,3)` before CNN secondary `(1,6)`.

Good.

## ML Sequence Memory

Transformer secondary `(1,5)` comes before LSTM primary `(0,8)` in the narrow corridor.

This conflicts with the manuscript’s LSTM-first argument.

If restored:

> swap/restage, or rewrite the hall as transformer-first.

I prefer LSTM first.

## ML Generative

Single primary at `(2,2)`.

Clean once restored/fixed.

## ML Synthesis

Primary anomaly detection `(2,2)` shares the front row with `joint_learn_walk` `(6,2)`.

The manuscript ignores the other two synthesis artifacts and focuses entirely on anomaly detection.

That is acceptable if role/lighting make anomaly clearly primary.

Otherwise the room name “Synthesis Arena” may promise a multi-artifact synthesis the book does not actually perform.

Runtime observation should settle this before adding more prose.

---

# 9. Runtime questions

No repository code was executed. Every hall still records `learner_verified: false`.

| Hall / encounter | RUNTIME TEST |
|---|---|
| **Whole sequence** | Does the assembled museum currently route Perception directly to Synthesis, omitting Sequence Memory and Generative exactly as `map_authored` reports? |
| **Whole sequence** | After restoring both maps, verify the complete eight-hall `next_in_sequence` route. |
| **Evolution — reward** | Can a visitor visually associate entry into a previously unvisited grid cell with enough energy/alpha change or later reproduction to make the environmental preference legible? |
| **Evolution — reproduction** | Confirm reproduction is energy-only in current source/runtime and does not require proximity to another body. |
| **Evolution — frame dependence** | Compare visited-cell renewal over equal wall-clock time at different frame rates; replace frame-count reopening if needed. |
| **Gradient — same dataset** | Within one moment, verify all three surfaces use exactly the same `_data_x/_data_y` arrays. |
| **Gradient — slider confound** | Before artifact fix, demonstrate that OUTLIERS/RESET redraw clean jitter and outlier identity as well as fraction. |
| **Gradient — fixed-tail control** | After fix, verify NONE/SOLE/FEW/HEAVY preserve declared baseline where intended and allow one candidate slope/intercept to be compared across losses. |
| **Classification — default dataset** | Confirm current `.tscn` produces four broad natural clusters, contradicting the three-blob manuscript. |
| **Classification — proposed fix** | With natural clusters restored to three and K=4, can a visitor see one broad blob divided or noise claimed by an extra centroid? |
| **Classification — rings** | Expose `cohort:rings`; confirm four Voronoi-like territories divide the rings rather than recover ring membership. |
| **Classification — step visibility** | Can one near-boundary point be followed through assignment and centre movement at the configured iteration speed? |
| **Neural Network — training** | Does error generally decrease on the four training examples under current seeded weights but unseeded batch sequence? |
| **Neural Network — weight witness** | Is one selected weight visually trackable across multiple updates, or do simultaneous colour/thickness changes make the local study unreadable? |
| **Neural Network — future holdout** | Add one non-training example and compare its error with training error under repeatable training order. |
| **Perception — edge** | Can the moving 3×3 window be matched to one local Sobel response on the displayed edge map? |
| **Perception — CLAIM** | With image/edge map fixed, cycle BARE/NAMED/INVENTED/WHOLE and verify only the assertion boxes change. |
| **Perception — input editing** | Source has `set_pixel_value`; if painting is meant to be interactive, verify current XR/filter objects actually call it. |
| **Sequence Memory — route** | If restored, does the visitor currently encounter the transformer secondary before the manuscript-primary LSTM? |
| **Sequence Memory — gate interaction** | Can XR hands actually move the RigidBody gate spheres reliably, or do collision layers only make them theoretically pickable? |
| **Sequence Memory — gate consequence** | Confirm current gate activations do not alter memory-particle path/rate. If a diagrammatic flow link is added, verify each gate changes only its intended visual stream. |
| **Generative — particles** | Confirm current `range(20,2)` loops create zero real and zero fake data particles. |
| **Generative — metrics** | Confirm visible metrics label remains 1.00/1.00 while internal scripted loss variables change. |
| **Generative — repaired diagram** | After fixes, verify simulated metric labels, fake/real particles and feedback animation all agree with the explicit “diagram / no model trained” status. |
| **Synthesis — default detector** | Verify the seeded dataset/statistics and z-score-like flagged set are deterministic under `dataset_seed=20241031`. |
| **Synthesis — threshold visual** | Check whether visitors interpret the circular guide as the exact Z-score decision boundary; relabel if necessary. |
| **Synthesis — MODE** | After adding control, compare Z-score, radial-distance and renamed reconstruction-proxy flags on the exact same points. |
| **Synthesis — REFERENCE** | Exclude seeded outer points from reference statistics and observe which flags change; restore them and compare. |

---

# 10. What I would not cut

## Do not cut Evolution’s absence of an explicit leaderboard

It gives the sequence an important first distinction:

> selection can be encoded in resource/reward conditions rather than one printed fitness score.

Keep it.

## Do not call that absence “no selection pressure”

The manuscript’s environmental-preference wording is better.

Keep the mechanism, fix the identity.

## Do not cut the proposed alternative reward rule

It is the right question:

> what if revisiting reliable places paid?

That makes the environment’s authorship visible.

It can remain proposed until the control exists.

## Do not cut all three loss surfaces

MSE, Huber and deliberately wavy custom loss answer different questions.

The problem is the uncontrolled dataset redraw between slider states, not the three-loss comparison.

## Do not cut “adversarial” solely because the label is misleading

The manuscript already disowns the GAN interpretation.

It can remain a deliberately provocative name if the actual formula stays visible.

## Do not cut k-means from a “Classification” sequence simply because it is unsupervised

The chapter itself uses the mismatch productively.

It teaches:

> grouping geometry ≠ named class.

Keep it.

## Do not cut the K=4 versus three-cluster mismatch

Restore it.

It is much more pedagogically valuable than four centres finding four authored blobs.

## Do not leave the rings dataset hypothetical

The source already contains it.

Use it.

## Do not cut Neural Networks’ local connection-following task

A single wire is not “the answer,” but following one changing weight is exactly how the visitor can enter a distributed parameter system.

Keep both local and aggregate views.

## Do not call training-error decline generalisation

The manuscript’s proposed holdout is the right next experiment.

Keep the distinction.

## Do not cut Sobel preprocessing because the classification claim is fake

The contrast is the point:

> one stage is computed, one stage is asserted.

Make the claim layer more interactive instead.

## Do not replace the invented detection labels with a real recogniser immediately

The false labels are valuable once made into a controlled CLAIM experiment.

A later actual recogniser can be another comparison.

## Do not cut Sequence Memory because it is a diagram

A diagram can be a legitimate artifact if its epistemic status is explicit.

The hall’s error would be pretending the animation demonstrates remembered content.

The manuscript does not do that.

## Do not call decorative particles “memory flowing” without qualification

If they remain unrelated to gate values, call them a path/diagram.

Better: connect them visibly to gate state.

## Do not cut Generative merely because it does not train a GAN

The relationship:

> evaluator changes while evaluated model changes

is important.

Fix the broken diagram and label it honestly.

## Do not treat falling scripted loss curves as learning evidence

The manuscript already refuses this.

Keep that refusal.

## Do not cut the anomaly detector’s inclusion of outer points in its own normality statistics

That is one of the strongest final examples:

> the judged population helps define the judge.

Keep it.

## Do not cut multiple anomaly rules

Once controls exist, they are ideal for demonstrating that “anomaly” is model-relative.

Just rename the fake autoencoder mode.

---

# 11. Reader-experience strengths to protect

## Discovery before naming

**Evolution**  
birth/death and movement reward before selection-pressure abstraction.

**Gradient**  
same candidate sits at different heights before “loss function authors the landscape.”

**Classification**  
stationary point changes colour before k-means explanation.

**Neural Networks**  
connection appearance changes before weight-versus-activation distinction.

**Perception**  
local edges before object labels are interrogated.

**Sequence Memory**  
trace the retain/admit/expose routes before formal LSTM equations—provided the room is labelled diagram.

**Generative**  
walk generator/discriminator roles before judging scripted losses—provided the theatre is honest.

**Synthesis**  
raised point before anomaly interpretation.

---

## Prediction before explanation

- Which evolving body will reach fresh territory?
- Which loss pulls more under one outlier?
- Which centroid will claim this stationary point next?
- Which connection change persists after activity passes?
- Does this edge fragment uniquely identify an object?
- What should a forget/input/output gate withhold?
- If the discriminator improves, what should the generator have to change?
- Which arithmetic pushed this point above the anomaly threshold?

These are strong and should remain the sequence’s rhythm.

---

## Productive distinctions to protect

- no explicit fitness number ≠ no selection condition
- inherited variation ≠ improvement
- loss landscape ≠ data itself
- same candidate ≠ same score under another loss
- outlier treatment ≠ judgement of what the outlier means
- cluster ≠ named class
- centroid ≠ complete group geometry
- training activation ≠ learned weight
- training error ≠ generalisation
- edge response ≠ object identity
- confidence label ≠ learned confidence
- diagram of memory ≠ demonstrated memory
- scripted loss curve ≠ adversarial training
- anomaly score ≠ explanation of anomaly
- reference population ≠ neutral ground truth.

This list is the real Machine Learning curriculum.

---

# 12. Questions for the author

## 12.1 Are Sequence Memory and Generative definitively part of the current spine?

The book and transitions say yes.

`map_authored` says no.

I recommend restoring them **because** they are diagrams, not despite it; they create a useful contrast with actual computation elsewhere.

## 12.2 Do you want “Machine Learning” to include non-learning preprocessing/diagram halls intentionally?

I think yes, if the sequence’s question is:

> what kind of evidence is this exhibit actually giving us about learning?

Then Perception, LSTM diagram and GAN diagram become valuable critical cases.

## 12.3 Should Gradient OUTLIERS be stochastic on every adjustment?

For free exploration that can be fine.

For the current manuscript’s comparison, I recommend fixed/nested evidence so only contamination changes.

## 12.4 Is the three-blobs/four-centres mismatch still the intended Classification lesson?

The manuscript strongly suggests yes.

If so, fix the current scene override.

## 12.5 Do you want the Perception room to keep deliberately false labels?

I strongly recommend yes.

Expose the CLAIM axis.

It may be one of the clearest “model output versus evidence” artifacts in the whole sequence.

## 12.6 Should Generative remain a role diagram or become a tiny working GAN?

A tiny working learner would be valuable, but the current critical text does not require it.

Short term:

> repair diagram, make its status explicit.

Long term:

> add one real update with actual candidate/reference/discriminator response.

## 12.7 Is “Autoencoder Error” meant as a future placeholder name?

If so, rename it now until the autoencoder exists.

The current scripted curve proxy is useful in its own right.

---

# 13. Overall conclusion

Machine Learning is already strongest when it asks a surprisingly simple question:

> **What actually changed?**

Across the sequence, different things change.

In Evolution:

> population composition changes because a reward economy changes who can persist/reproduce.

In Gradient Landscape:

> parameter position changes under a chosen error function.

In Classification:

> assignments and centroids change one another under distance.

In Neural Networks:

> weights and biases change under training error.

In Perception:

> the Sobel representation is computed—but the confident object claim beside it may not be computed at all.

In Sequence Memory:

> currently, only a diagram changes; no recurrent memory state is being learned.

In Generative:

> currently, scripted progress variables/animations change; no adversarial models are trained.

In Synthesis:

> the observation itself does not change; the score/threshold/reference makes it appear normal or anomalous.

That is an excellent epistemic progression.

The old sequence framing:

> “algorithms that learn”

is not wrong as a title.

But it is incomplete as an explanation.

The current artifacts repeatedly demonstrate that a machine-learning room can contain:

- selection without an explicit score;
- optimisation under an explicit score;
- grouping without labels;
- genuine gradient-based parameter learning;
- preprocessing without recognition;
- a diagram of a learner;
- a simulation of training rhetoric;
- a fixed decision rule called anomaly detection.

The visitor should learn to tell those apart.

The highest-value work now is therefore:

1. **restore Sequence Memory and Generative as explicitly labelled diagram halls, while repairing their current source/display defects;**
2. **make Gradient Landscape’s outlier intervention compare controlled evidence rather than redrawing the dataset on every change;**
3. **restore Classification’s K=4 / three-blob mismatch and expose its already-implemented rings/block cohorts;**
4. **turn Perception’s existing detection axis into a CLAIM control so object labels can change while evidence remains fixed;**
5. **make Synthesis interactive around mode, threshold and reference population, and remove the false “Autoencoder Error” label;**
6. **rewrite sequence metadata so “learning” is not equated universally with gradient descent/optimization and QFEP interpretations remain explicitly project-specific;**
7. **headset-test whether local evidence is actually legible: one evolving lineage, one loss-ball response, one boundary point, one changing neural weight, one Sobel neighbourhood, and one anomaly decision.**

The reader-experience principle I would carry forward from Machine Learning is:

> **Let a confident model claim appear, then make the visitor discover whether the claim came from learned state, a chosen objective, a fixed rule, a preprocessing operation—or merely a label.**

And the structural principle is:

> **Learning is a change in model state under evidence and a rule for valuing error or reward. Everything around that change—the representation, dataset, objective, threshold, diagram and interpretation—decides what the learner can notice and what its apparent improvement can mean.**
