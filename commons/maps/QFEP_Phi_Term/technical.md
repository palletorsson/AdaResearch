# A split chamber where one half freezes and the other melts, separated by a slider that decides which way a system leans into time

The Lambda Spectrum gave the learner a body-scale gradient from crystal to fog. Walking from left to right was walking from order to entropy, and somewhere in the green zone around lambda 0.4 the world felt alive — complex enough to surprise, structured enough to cohere. But the spectrum was static. Every point on it described a balance between F and E(S) at a given moment. It said nothing about what happens next. It said nothing about how the system responds when that balance shifts.

Phi fills the gap. The final term of the Quantized Free Energy Principle introduces time — not as a background parameter but as a force with its own weight:

**QFE = F - lambda E(S) + phi delta E(S,t)**

The phi delta E(S,t) term measures the rate at which entropy changes, then amplifies or dampens that rate according to the sign and magnitude of phi. The question is no longer "how much entropy does the system have?" but "how does the system feel about the fact that entropy is changing?" Phi is disposition. Phi is attitude toward becoming.

## The Temporal Derivative: Entropy in Motion

Delta E(S,t) is the temporal derivative of entropy — positive when entropy rises, negative when it falls. A system crystallizing from disorder has negative delta E: its possibility space contracts frame by frame. A system dissolving from pattern has positive delta E: its possibility space expands.

```gdscript
var _entropy_history: Array[float] = []
var _history_window: int = 30

func compute_delta_entropy(current_entropy: float) -> float:
    _entropy_history.append(current_entropy)
    if _entropy_history.size() > _history_window:
        _entropy_history.pop_front()
    if _entropy_history.size() < 2:
        return 0.0
    var oldest := _entropy_history[0]
    var newest := _entropy_history[_entropy_history.size() - 1]
    return (newest - oldest) / float(_entropy_history.size())
```

The sliding window matters. A window of 30 frames means the derivative captures roughly half a second of entropic trajectory at 60fps. Too short and the derivative spikes on noise — a single particle bouncing changes the reading. Too long and the derivative flattens, missing real transitions. The window size is itself a design parameter: how far back does the system look when evaluating its own direction?

The derivative is not entropy. A system at high entropy with zero delta E is stable chaos — dissolved but not dissolving further. A system at low entropy with positive delta E is a crystal beginning to crack. The derivative captures process, not state. It answers the question the E(S) term alone cannot: is this getting worse or better? And "worse" and "better" depend entirely on phi.

## Phi Negative: The Conservative Regime

Phi below zero means the system resists entropic change. When entropy rises, negative phi subtracts from QFE — the system pushes back, favoring restoration of the prior entropy level. When entropy falls, negative phi adds to QFE — the system reinforces consolidation. Negative phi is a stabilizer. It dampens oscillation, resists perturbation, preserves whatever pattern currently holds.

The `rigid_sculpture` artifact embodies this regime. A geometric form — crystalline, angular, dense — that actively resists deformation. The phi_slider controls its behavior:

```gdscript
# rigid_sculpture — phi < 0 demonstration
@export var base_rigidity: float = 0.9
@export var restoration_speed: float = 4.0

var _original_vertices: PackedVector3Array
var _current_phi: float = -1.0

func _process(delta: float) -> void:
    if _current_phi < 0.0:
        var restoration_strength := abs(_current_phi) * restoration_speed
        for i in range(_vertices.size()):
            var displacement := _vertices[i] - _original_vertices[i]
            _vertices[i] -= displacement * restoration_strength * delta
        _update_mesh()
```

The restoration loop is the geometric expression of negative phi. Every frame, each vertex measures its displacement from the original position and moves back toward it. The speed of return scales with the magnitude of phi — more negative phi means faster restoration, harder resistance to change. At phi = -1.0, the sculpture snaps back almost instantly from any perturbation. At phi = -0.1, it drifts back slowly, tolerating temporary deformation but always returning.

Perturb the sculpture. Push a face, displace a vertex cluster, inject noise into the mesh. Under negative phi, every perturbation decays. The form reconstitutes. The pattern is remembered. This is conservative in the precise thermodynamic sense: the system conserves its current configuration against the arrow of entropy.

The `preserved_pattern` artifact extends this principle into two dimensions. A tiled grid of cells — each holding a color, a state — that resists mutation:

```gdscript
# preserved_pattern — 2D cellular pattern under phi < 0
@export var grid_size: int = 8
@export var mutation_rate: float = 0.02

func _process(delta: float) -> void:
    if _current_phi < 0.0:
        # Revert mutations — pattern resists change
        for x in range(grid_size):
            for y in range(grid_size):
                if _grid[x][y] != _original_grid[x][y]:
                    var revert_chance := abs(_current_phi) * delta * 3.0
                    if randf() < revert_chance:
                        _grid[x][y] = _original_grid[x][y]
        _update_display()
```

Random mutations occur — cells flip, colors shift. Under negative phi, the pattern heals. Flipped cells revert probabilistically, the reversion rate scaling with phi magnitude. The original pattern reasserts itself through stochastic repair. The learner watches mutations appear and vanish like ripples dying on a still pond. The pattern endures.

This is homeostasis. Biological systems maintain temperature, pH, glucose levels through feedback loops that resist deviation from a setpoint. Negative phi is the setpoint mechanism generalized: any departure from the established state triggers corrective force proportional to the departure. The stronger the negative phi, the tighter the regulation, the narrower the band of tolerable variation.

## Phi Positive: The Regime of Becoming

Phi above zero inverts everything. When entropy rises, positive phi adds to QFE — the system amplifies the change, leaning into dissolution, exploring further. When entropy falls, positive phi subtracts — the system resists consolidation, pushing away from crystallization. Positive phi is a destabilizer. It rewards flux, amplifies perturbation, treats change as signal rather than noise.

The `fluid_form` artifact sits on the opposite side of the map from `rigid_sculpture`. Same initial geometry. Radically different behavior:

```gdscript
# fluid_form — phi > 0 demonstration
@export var fluidity: float = 0.8
@export var exploration_speed: float = 2.0
@export var noise_frequency: float = 1.5

var _time: float = 0.0
var _current_phi: float = 1.0

func _process(delta: float) -> void:
    _time += delta
    if _current_phi > 0.0:
        var wander_strength := _current_phi * exploration_speed
        for i in range(_vertices.size()):
            var noise_offset := Vector3(
                _sample_noise(_vertices[i].x, _time * noise_frequency),
                _sample_noise(_vertices[i].y, _time * noise_frequency + 100.0),
                _sample_noise(_vertices[i].z, _time * noise_frequency + 200.0)
            )
            _vertices[i] += noise_offset * wander_strength * delta
        _update_mesh()
```

No restoration. No memory of original position. Each vertex wanders according to noise — continuous, smooth, but directionless. The form flows. Faces stretch, edges bend, the geometry deforms continuously without returning to any prior configuration. The sculpture becomes a process rather than an object. It has no fixed state to conserve because positive phi defines the system as fundamentally temporal — always becoming, never arrived.

The noise offset uses three independent samples offset by constants (0, 100, 200) to decorrelate the axes. Without this, vertices would stream in unison — orderly dissolution, a contradiction. The offsets ensure each axis wanders independently.

The `transforming_pattern` mirrors this in two dimensions:

```gdscript
# transforming_pattern — 2D cellular pattern under phi > 0
func _process(delta: float) -> void:
    if _current_phi > 0.0:
        # Amplify mutations — pattern embraces change
        var mutation_boost := _current_phi * delta * 5.0
        for x in range(grid_size):
            for y in range(grid_size):
                if randf() < mutation_rate * (1.0 + mutation_boost):
                    _grid[x][y] = _random_state()
                # Spread mutations to neighbors
                if _grid[x][y] != _original_grid[x][y]:
                    _spread_mutation(x, y, _current_phi * delta)
        _update_display()
```

Under positive phi, mutations do not heal. They propagate. A flipped cell increases the probability that neighboring cells flip — not through a rule (this is not a cellular automaton) but through the phi-weighted spread function. The original pattern dissolves from points of mutation outward, new colors replacing old, the grid never settling. Where the preserved_pattern resisted change, the transforming_pattern amplifies it.

The spread mechanic is the key insight. Negative phi isolates perturbations — each mutation dies independently. Positive phi connects perturbations — each mutation seeds further change. The topology of change is different. Under negative phi, disturbances are local and self-limiting. Under positive phi, disturbances are contagious and self-amplifying. The difference is not magnitude. It is network structure.

## The Phi Slider: Crossing Zero

The `phi_slider` sits at the center of the map, equidistant from the conservative and becoming zones. Its range spans from -1.0 to 1.0 with zero at the midpoint.

```gdscript
# phi_slider — the disposition control
@export var min_value: float = -1.0
@export var max_value: float = 1.0
@export var default_value: float = 0.0

signal phi_changed(new_value: float)

func _on_slider_moved(normalized_position: float):
    _current_value = lerp(min_value, max_value, normalized_position)
    phi_changed.emit(_current_value)
    _update_artifacts(_current_value)
    _update_color(_current_value)
```

The slider broadcasts to all four artifacts simultaneously. As phi crosses zero, the rigid_sculpture stops restoring and begins wandering. The preserved_pattern stops healing and begins mutating. The fluid_form either stiffens or loosens. The transition is continuous — there is no discontinuity at zero, only a reversal of tendency. The system does not jump between modes. It rotates through them.

The color gradient encodes the disposition:

```gdscript
func _get_phi_color(value: float) -> Color:
    if value < 0.0:
        var t := abs(value)
        return Color(0.4, 0.5, 0.9).lerp(Color(0.2, 0.3, 0.7), t)  # Cool blues
    else:
        var t := value
        return Color(0.9, 0.5, 0.4).lerp(Color(0.9, 0.2, 0.6), t)  # Warm magentas
```

Blue for conservative. Magenta for becoming. Not the red of the lambda slider — that signaled entropy quantity. Magenta signals entropy disposition, the system's relationship to change rather than the amount of change present. The color distinction is deliberate. Lambda and phi are different parameters operating on different aspects of the formula, and the learner should never confuse them.

## The Split Architecture and the Political Term

The map_data defines a 10x12 grid split into two zones. The left side holds `rigid_sculpture` and `preserved_pattern` — the conservative artifacts under signage reading "phi < 0" and "RESIST." The right side holds `fluid_form` and `transforming_pattern` — the becoming artifacts under "phi > 0" and "EMBRACE." The phi_slider occupies the central column.

```
Left zone (conservative)     Center     Right zone (becoming)
  rigid_sculpture          phi_slider     fluid_form
  "phi < 0"                              "phi > 0"
  "RESIST"                               "EMBRACE"
  preserved_pattern                      transforming_pattern
```

The spatial arrangement is the argument. The learner stands in the center, slider in reach, and turns left to see conservation or right to see transformation. Physical orientation becomes conceptual orientation. The slider hand moves the parameter; the head turns to witness the consequence.

Two teleporters at the south edge — `phi_conservative` and `phi_queer` — offer deeper immersion into each regime. The naming is explicit. The formula's political dimension surfaces in the teleporter labels.

Lambda is strategic — how much entropy does the system tolerate? It describes a policy, a resource allocation between structure and freedom. Phi is dispositional — how does the system respond when conditions change? It describes a temperament, an orientation toward time itself.

Every institution has a phi value. A bureaucracy that resists procedural change operates at negative phi — perturbations trigger correction, deviation triggers enforcement, the original rules reassert. A research lab that rewards unexpected findings operates at positive phi — perturbations trigger investigation, deviation triggers excitement, the current state is always provisional.

Every identity has a phi value. A self-concept that maintains rigid boundaries against external influence operates at negative phi — challenges to the model trigger defense, the self returns to its prior shape. A self-concept that treats challenges as material for transformation operates at positive phi — disruption is incorporated, the self extends into new configurations.

The QFEP does not declare positive phi universally better. A bridge with positive phi would be catastrophic — infrastructure requires conservative dynamics. A mind with exclusively negative phi would calcify. The formula describes; the learner evaluates. But the curriculum has a thesis, surfacing here: creative systems, adaptive systems, living systems operate at positive phi within the edge-of-chaos lambda band.

The map places phi > 0 on the right side, the side associated with forward motion in left-to-right reading cultures. The teleporter labeled "phi_queer" leads forward in the sequence, toward QFEP_Edge_Of_Chaos. The teleporter labeled "phi_conservative" does not advance. The spatial grammar argues for positive phi without declaring it. The architecture is the pedagogy.

## The Compound Term: Phi Times Delta E

Neither phi nor delta E(S,t) operates alone. The product is the meaningful quantity. A system with phi = 1.0 and delta E = 0.0 contributes nothing to QFE — high sensitivity applied to zero change produces zero signal. A system with phi = 0.0 and delta E = 100.0 also contributes nothing — massive change that the system ignores is invisible to the formula.

```gdscript
func compute_phi_contribution(phi: float, delta_entropy: float) -> float:
    return phi * delta_entropy

# Cases:
# phi = -1.0, delta_E = +0.5  -> -0.5 (resist rising entropy)
# phi = -1.0, delta_E = -0.5  -> +0.5 (reinforce falling entropy)
# phi = +1.0, delta_E = +0.5  -> +0.5 (amplify rising entropy)
# phi = +1.0, delta_E = -0.5  -> -0.5 (resist falling entropy)
# phi = 0.0, delta_E = any    ->  0.0 (indifferent to change)
```

The sign combinations reveal the full logic. Negative phi with rising entropy produces a negative contribution — the system works to reduce QFE, pulling back toward order. Negative phi with falling entropy produces a positive contribution — the system reinforces consolidation. Positive phi inverts this: rising entropy is rewarded, falling entropy is resisted. The multiplication encodes a complete disposition toward temporal process in a single arithmetic operation.

The compound nature explains why lambda and phi require separate sliders. Lambda weights entropy against structure in the present moment. Phi weights the direction of entropy over time. A system can have high lambda but negative phi — stable chaos that fights perturbation. Or low lambda with positive phi — a structured system actively seeking transformation. The two parameters span a plane, not a line.

## The Ambient Field and the Sequences Behind

The map's lighting tells the phi story through color temperature. Ambient color at `(0.25, 0.2, 0.3)` — a cool purple that does not commit to the blue of conservation or the warmth of becoming. Directional light at `(0.9, 0.85, 1.0)` — near-white with a violet cast. The audio preset `becoming_ambient` carries a different character than the structured hum of the F-term or the noise_wash of the E-term. It pulses. It breathes. The rate of the pulsation maps to the phi slider value — faster under positive phi, slower under negative, still at zero.

The grid animation uses `split_reveal` with `center_out` order — tiles emerge from the center of the map outward, the split between conservative and becoming zones materializing as the floor builds itself. The easing is `ease_out`: fast at first, decelerating at the edges. The floor itself performs the map's argument: beginning at the center (the slider, the zero point) and radiating outward into the two regimes.

Forces taught accumulation — small impulses compounding into trajectories. Phi accumulates entropic velocity the same way. Wavefunctions taught operators on states — phi operates on entropic direction, amplifying or inverting the signal. Cellular Automata taught that fixed rules produce complex behavior at critical lambda. Phi is the meta-rule: not how the system behaves, but how the system responds to changes in its own behavior. The phi term is where the formula becomes reflexive. F describes the system's model of the world. E(S) describes uncertainty. Lambda describes tolerance. Phi describes the system's relationship to its own evolution — the term that looks inward.

The exit teleporter reads "Find the Edge" with the description "Now: the sweet spot where lambda and phi create life." The phrasing is precise. Not lambda alone — the Lambda Spectrum already demonstrated what lambda does in isolation. Not phi alone — this map just demonstrated that. Lambda AND phi. The edge of chaos is not a single parameter value. It is a region in the two-dimensional parameter space where lambda falls between 0.3 and 0.5 and phi tilts positive — enough structure to cohere, enough entropy to explore, and a disposition that leans into transformation rather than away from it.

The next map, QFEP_Edge_Of_Chaos, is where Turing patterns emerge, where Langton's critical lambda produces computation, where the formula's terms balance productively. The learner arrives there having felt both extremes of phi: the satisfaction of a form that resists destruction, and the exhilaration of a form that refuses to hold still. The edge will ask them to hold both at once.

## Possible Artifacts

**phi_momentum_trail** — A particle trail that visualizes the phi * delta_E contribution over time. Each frame emits a particle colored by the sign of the compound term: blue for negative contribution (resisting change), magenta for positive (amplifying change), transparent at zero. The trail accumulates behind the learner as a visible history of disposition in action. Dragging the slider produces dramatic color shifts, connecting parameter adjustment to temporal consequence.

**disposition_mirror** — A reflective surface at the map center that renders a distorted version of whichever zone the learner faces. Face the conservative zone and the mirror shows it melting. Face the becoming zone and the mirror shows it crystallizing. The distortion scales with the phi slider: clear at zero, maximally transformed at the extremes.

**entropic_velocity_graph** — A real-time plot of delta E(S,t) as a waveform with the phi slider value overlaid as a colored band that thickens with magnitude. The learner sees the raw signal and the amplified signal simultaneously, grasping the multiplicative relationship between disposition and trajectory.

**phase_portrait_floor** — The map floor as a two-dimensional phase portrait with lambda on one axis and phi on the other. The learner's physical position maps to a (lambda, phi) coordinate pair. Colored regions mark the dark room (low lambda, negative phi), dissolution (high lambda, positive phi), and the narrow diagonal band where the edge of chaos lives. The learner finds the edge by finding where to stand.
