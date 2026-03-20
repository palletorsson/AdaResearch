# A divided room where the left half is spacious and the right half cramped — algorithmic bias made architectural before it is mathematical

The QFEP Laboratory gave the learner a formula for navigating between order and chaos: QFE = F - lambda E(S) + phi delta E(S,t). The formula describes adaptive systems in general. This map asks: what happens when the adaptive system is a classifier deployed on people?

The answer is architectural. An 8x9 grid where a wall of height-5 blocks at column 6 divides the room into two halves. The left half: six columns wide, spacious, room to move. The right half: two columns, cramped, the same floor but less of it. The wall narrows at rows 4-5, where the height-5 blocks extend inward, squeezing the passage. The bias is spatial before it is mathematical.

## The Divided Grid

The structure layer encodes inequality directly:

```
Row 0:  1 1 1 1 1 1 5 1     Left: 6 cols at height 1 | Wall: height 5 | Right: 1 col at height 1
Row 1:  1 1 1 1 1 1 5 1
Row 2:  1 1 1 1 1 1 5 1
Row 3:  1 1 1 1 1 1 5 1
Row 4:  1 1 1 1 1 5 5 1     Wall widens — right side shrinks to 1 col
Row 5:  1 1 1 1 1 5 1 1     Wall at (5,5), passage opens slightly
Row 6:  1 1 1 1 1 1 1 1     Open — the passage between halves
Row 7:  1 1 1 1 1 1 0 1     Void at (6,7) — the structural gap
Row 8:  1 1 1 1 1 1 1 1
```

Height 5 is the maximum in this map. The wall towers over the height-1 floor by four units — impassable, visible from anywhere in the room. The learner spawns at (0,0) on the left side. To reach the right, they must navigate to row 6 where the wall breaks, or find the waypoint at (5,5) that redirects through the narrow gap.

The asymmetry is the argument. Both halves have the same floor height (1). Both halves are "equal" in the formal sense that every tile has the same structural value. But the left half has six times the area. The right half is compressed. Walk from left to right and the space contracts. The body feels the difference before the mind names it.

## The Bias Visualizer

The `bias_visualizer` artifact sits at grid position (2,4) — in the spacious left half, naturally. The artifact occupies the comfortable side. The learner does not need to squeeze into the cramped right side to access the primary interactive element. This placement is itself a bias: the tool for understanding bias is positioned where the bias benefits.

```gdscript
# bias_visualizer — algorithmic bias as spatial relationship
@export var embedding_dimensions: int = 3
@export var point_count: int = 100
@export var analogy_pairs: Array[Dictionary] = [
    {"from": "man", "to": "doctor", "category": "gender_profession"},
    {"from": "woman", "to": "nurse", "category": "gender_profession"},
    {"from": "white", "to": "approved", "category": "race_lending"},
    {"from": "black", "to": "denied", "category": "race_lending"}
]
```

The visualizer maps word embeddings — high-dimensional vector representations of concepts trained on text corpora — into navigable 3D space. Lines connect what the model connects: man to doctor, woman to nurse. Not because the world arranges itself this way, but because the training data did. The model learned statistical co-occurrence and reproduced it as geometric proximity.

The embedding space is a vector space — the same mathematical structure from the Vectors sequence, the same dot products and magnitudes and projections. But the vectors here represent social categories, not physical positions. The distance between "man" and "doctor" in embedding space encodes the statistical frequency with which those terms appeared in proximity in the training corpus. The frequency encodes historical allocation. The allocation encodes power. The power encodes bias. The bias appears as a short vector — a small distance — that the model treats as natural proximity.

```gdscript
func _compute_analogy_distance(word_a: String, word_b: String) -> float:
    var vec_a := _embeddings[word_a]
    var vec_b := _embeddings[word_b]
    return (vec_a - vec_b).length()

# The bias: man→doctor distance < woman→doctor distance
# This is not a feature of language. It is a feature of the data.
```

The learner can rotate the point cloud, switch between analogy pairs, and watch redlining draw itself in three dimensions: zip codes mapped to credit scores, the geometry of exclusion rendered as Euclidean distance. Every connection is a decision someone made by not deciding — by accepting the training data as given, by treating the embedding space as ground truth, by deploying the model without auditing its distances.

## Classification Boundaries and Structural Incompleteness

The map's title in the map_data is "Bias as Structural Incompleteness." This connects the bias visualizer to the Foundations Crisis: Godel proved that formal systems have statements they cannot prove or disprove. Bias is the social form of incompleteness. Every classification system draws boundaries. Boundaries require exclusion. The people on the boundary — the edge cases, the ambiguous inputs, the samples that fall between categories — are not errors in the classifier. They are the classifier's constitutive outside: the set of cases it was never built to handle correctly.

The height-5 wall is Godel's incompleteness made architectural. The formal system (the room) contains a structure (the wall) that divides without justification from within. The wall is not derived from the floor plan's logic. It is imposed. It creates the inequality it then measures. The classifier does not discover that "man" is closer to "doctor" than "woman" is. It produces that proximity through the training process, then treats the result as a finding.

```gdscript
# Classification boundary — the line that creates the categories it separates
func classify(input: Vector3, boundary_normal: Vector3,
              boundary_offset: float) -> String:
    var projection := input.dot(boundary_normal) + boundary_offset
    if projection > 0.0:
        return "Category A"  # spacious side
    else:
        return "Category B"  # cramped side
```

A hyperplane in three dimensions. Points on one side are Category A. Points on the other side are Category B. The boundary normal and offset are learned from training data. The categories are the output, not the input. Before the classifier runs, there are no categories. After it runs, the categories appear natural — as natural as the wall in the room.

The waypoint at (5,5) with rotation 90 degrees redirects the learner's gaze toward the wall from inside the spacious half. The waypoint says: look at the boundary. Notice the structure. The wall is not decoration. It is the classifier's decision surface rendered as architecture.

## The Void and the Passage

The void at grid position (6,7) — height 0, the floor removed — sits in the wall's column at the southern end. The floor is gone. Underneath: the substrate the room tries to forget. The void is the map's formal acknowledgment that every classification system has an outside — a set of cases it cannot process, a region where its categories break down.

The teleporter at (6,7) leads to the next map in the sequence. To exit, the learner must stand on the void — must literally step into the gap in the classification system, the space where the boundary does not hold. The passage out of bias goes through the structural incompleteness, not around it. The exit strategy is not to fix the classifier. It is to inhabit its failure point.

The spawn point at (0,0) with an announcement board at (1,0) places the learner firmly in the privileged half. They begin where the space is generous. The walk to the cramped side is optional — no artifact requires it. The curriculum does not force the learner to experience the cramped half. It presents the option and waits. Some learners will walk through. Some will stay on the spacious side and observe the visualizer from comfort. The map does not judge. It documents.

## From QFEP to Bias

In QFEP terms, algorithmic bias is the F-term run amok. F minimizes prediction error by finding patterns. The pattern in the training data is real: historically, men have been doctors more often than women have. The model minimizes F by encoding this historical pattern as geometric proximity. The model is correct about the past. It is wrong about the future — but F does not distinguish between patterns that should be preserved and patterns that should be disrupted.

Lambda at zero: the model treats the training distribution as ground truth. No entropy, no exploration, no consideration of alternative distributions. The model crystallizes historical inequality into geometric fact. The dark room problem in its social form: a system that only minimizes prediction error converges on the most predictable model of the world, and the most predictable model of a biased world is a biased model.

The E term — entropy, the size of the possibility space — is what bias suppresses. A fair model would have high entropy over the profession dimension: many possible associations between gender and career, no single pattern dominating. The biased model has low entropy: man-doctor is probable, woman-nurse is probable, and the narrow distribution forecloses the alternatives. Bias is a compression — a reduction in possibility space that the system enforces as efficiency.

The map does not solve bias. It makes it spatial. The learner walks through the divided room and feels the allocation in the body. The visualizer shows the allocation in the data. The wall shows the allocation in the architecture. Three representations of the same structure: unequal distribution of resources — space, proximity, access — maintained by a boundary that presents itself as natural.
