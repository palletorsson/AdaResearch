# An open laboratory where every slider is unlocked and the formula responds in real time to the learner's parameter choices

The Edge of Chaos locked lambda at 0.4 and asked the learner to witness. The Turing patterns breathed, the edge_core pulsed, the ring particles orbited — all without intervention. The locked slider was the map's argument: the edge is not where you put it; it is where the mathematics puts it. Now the argument inverts. The Sandbox unlocks everything. Lambda, phi, and the reactive environment respond to the learner's choices in real time. The formula is no longer architecture to walk through. It is an instrument to play.

## The Control Console: Lambda and Phi Together

The map places `lambda_slider` at grid position (2,2) and `phi_slider` at (10,2), flanking the entrance corridor. Both default to 0.5 — the center of their respective ranges. Neither is locked. The learner reaches both within seconds of spawning.

```gdscript
# lambda_slider at default 0.5 — midpoint of the order-chaos gradient
lambda_slider:0:0.5

# phi_slider at default 0.5 — midpoint of the conservative-becoming gradient
phi_slider:0:0.5
```

The two sliders span a plane, not a line. Lambda controls the balance between F and E(S) — where the system sits on the order-chaos spectrum. Phi controls the system's disposition toward temporal change — whether rising entropy is amplified or dampened. Together they define a two-dimensional parameter space:

```
lambda (x-axis): 0.0 ────── 0.5 ────── 1.0
                  crystal    edge       chaos

phi (y-axis):   -1.0 ────── 0.0 ────── 1.0
                 conservative neutral   becoming
```

Four corners of this space produce four qualitatively distinct regimes:

1. **Low lambda, negative phi** (crystal + conservative): Rigid, homeostatic, the dark room with active resistance to perturbation. The system minimizes F and resists any entropic change. Frozen.

2. **Low lambda, positive phi** (crystal + becoming): Structured but seeking transformation. The system maintains order while amplifying any movement toward entropy. Unstable — the positive phi eventually pushes it out of the crystal regime. A spring-loaded trap waiting to trigger.

3. **High lambda, negative phi** (chaos + conservative): Dissolved but resisting further dissolution. The system is already at high entropy but dampens any temporal change. Stagnant chaos — not the dynamic scatter of the E_Term but a frozen fog. Noise that refuses to evolve.

4. **High lambda, positive phi** (chaos + becoming): Maximum dissolution with maximum amplification of change. The system cascades — entropy rises and the positive phi accelerates the rise. Runaway dissolution. The formula's output swings wildly.

The edge of chaos with positive phi — lambda near 0.4, phi positive — occupies the center-right of this plane. It is the regime the curriculum has been building toward: enough structure to cohere, enough entropy to explore, and a disposition that leans into transformation. Finding it requires working both axes simultaneously.

## The QFEP Reactor: The System That Responds

The `qfep_reactor` sits at grid position (6,5) on the elevated central platform (height 3). It is the Sandbox's core artifact — a reactive simulation engine that takes lambda and phi as continuous inputs and produces visible system behavior as output.

```gdscript
# qfep_reactor — the formula made interactive
@export var reactor_radius: float = 1.5
@export var particle_count: int = 200
@export var update_rate: float = 60.0

var _current_lambda: float = 0.5
var _current_phi: float = 0.5
var _entropy_history: Array[float] = []

func _on_lambda_changed(value: float) -> void:
    _current_lambda = value
    _update_reactor_state()

func _on_phi_changed(value: float) -> void:
    _current_phi = value
    _update_reactor_state()
```

The reactor listens to both sliders. Any change triggers `_update_reactor_state()`, which recomputes the QFE value and adjusts the visible simulation:

```gdscript
func _update_reactor_state() -> void:
    var F := _compute_structural_order()
    var E := _compute_current_entropy()
    var delta_E := _compute_delta_entropy(E)
    var QFE := F - _current_lambda * E + _current_phi * delta_E

    _update_particle_behavior(_current_lambda, _current_phi)
    _update_visual_regime(QFE)
    _update_formula_display(F, E, _current_lambda, _current_phi, delta_E, QFE)
```

The function chain: compute F from structural order, compute E from current entropy, compute the temporal derivative delta_E from the entropy history, combine them according to the formula, then update three output channels — particle behavior, visual regime, and the formula display.

The `_compute_current_entropy()` function divides the reactor volume into spatial bins and computes Shannon entropy over the particle distribution:

```gdscript
func _compute_current_entropy() -> float:
    var bin_counts := {}
    for particle_pos in _particle_positions:
        var bin := _position_to_bin(particle_pos)
        bin_counts[bin] = bin_counts.get(bin, 0) + 1

    var total := float(_particle_positions.size())
    var entropy := 0.0
    for count in bin_counts.values():
        var p := count / total
        if p > 0.0:
            entropy -= p * log(p) / log(2.0)
    return entropy
```

This is the same Shannon entropy from QFEP_E_Term, now computed over a live particle distribution rather than a theoretical array. The entropy is empirical — it measures what the particles are actually doing, not what a model says they should do. As the learner adjusts lambda, particles redistribute, bin populations shift, and entropy changes in real time.

## Reactive Particles: The Visible Formula

Two instances of `reactive_particles` sit at grid positions (4,7) and (8,7), flanking the reactor on the height-3 platform. They provide the visual field that the reactor modulates:

```gdscript
# reactive_particles respond to lambda and phi
func update_from_parameters(lambda: float, phi: float) -> void:
    # Spread: tight at low lambda, omnidirectional at high
    _material.spread = lerp(15.0, 180.0, lambda)

    # Gravity: strong at low lambda (particles fall, structure),
    # zero at high (particles float, entropy)
    _material.gravity = Vector3(0, lerp(-2.0, 0.0, lambda), 0)

    # Speed: influenced by phi — positive phi increases kinetic energy
    var speed_factor := 1.0 + phi * 0.5
    _material.initial_velocity_max = lerp(0.5, 3.0, lambda) * speed_factor

    # Count: more particles as entropy increases
    _particles.amount = int(lerp(50, 300, lambda))

    # Color: blue at low lambda, green at edge, red at high
    var color := _get_regime_color(lambda)
    _mesh_material.albedo_color = color
    _mesh_material.emission = color
```

Five parameters modulated simultaneously:
- **Spread**: 15 degrees at lambda 0 (tight beam) to 180 degrees at lambda 1 (omnidirectional)
- **Gravity**: -2.0 at lambda 0 (strong downward pull, particles constrained) to 0.0 at lambda 1 (free float)
- **Speed**: Base speed scales with lambda, then multiplied by a phi factor — positive phi accelerates, negative phi decelerates
- **Count**: 50 particles at low lambda to 300 at high — the visual density of entropy
- **Color**: The familiar blue-green-red gradient

The phi contribution to speed is the key interaction effect. At the same lambda value, positive phi makes particles faster (amplifying entropic motion) while negative phi makes them slower (dampening it). The learner sees this immediately: drag phi positive and the particles accelerate; drag phi negative and they decelerate — without changing their structural distribution.

## The Formula Display: Live Arithmetic

The `qfep_formula_3d` at grid position (5,12) renders the complete equation near the southern exit. In the Sandbox, it updates live:

```gdscript
func update_live(F: float, E: float, lambda: float,
                 phi: float, delta_E: float, QFE: float) -> void:
    _terms["F"].scale = Vector3.ONE * lerp(0.8, 1.2, clamp(F, 0, 1))
    _terms["E_S"].scale = Vector3.ONE * lerp(0.6, 1.4, lambda)

    var pulse := sin(Time.get_ticks_msec() * 0.001 * lerp(0.5, 4.0, abs(phi)))
    _set_term_emission("delta_E",
        Color(0.6, 0.4, 0.8).lerp(Color(1.0, 0.8, 1.0), (pulse + 1.0) * 0.5))

    _qfe_readout.text = "QFE = %.2f" % QFE
    _qfe_readout.modulate = _get_regime_color(lambda)
```

The F term scales with structural order. The E(S) term scales with lambda. The delta_E term pulses at a rate determined by phi magnitude. The QFE readout displays the computed value in the gradient color. The learner sees the formula as a dynamic system: symbols responding to inputs, the equation breathing with the parameters.

## The Two-Dimensional Search

The map layout supports exploration of the full lambda-phi plane. The elevated center platform (height 3, spanning rows 3-9 and columns 3-10) provides an arena large enough to walk while adjusting sliders. The surrounding walkway (height 1) offers distance perspective — step back from the reactor to see the particle field from outside.

Two teleporters at grid positions (2,10) and (10,10) lead to different post-Sandbox destinations: `qfep_mastery` and `qfep_queer`. The naming suggests two orientations toward the formula — technical mastery and queer application — both legitimate, both available.

The grid animation uses `radial_center` ordering and `scale_up` type: the floor materializes from the center outward, the reactor's position generating the visible terrain. The easing is `ease_out` — fast start, gradual settling — matching the Sandbox's theme of initial energy followed by patient exploration.

## Finding Your Edge

The Sandbox is the QFEP sequence's exam, but the exam has no grade. There is no target lambda, no optimal phi, no score displayed at the end. The learner explores the two-dimensional parameter space and discovers which configurations feel alive — where the reactive_particles neither freeze nor scatter, where the qfep_reactor produces emergent structure, where the formula's QFE output oscillates without diverging.

The answer, discovered through exploration, is lambda approximately 0.3-0.5 and phi slightly positive. The edge of chaos with a disposition toward becoming. But the discovery matters more than the answer. A learner who arrives at lambda 0.4 through systematic sweep of the parameter space understands the edge differently from one who arrives through intuition, or through the body's response to particle behavior, or through the audio's shift from clean tone to rich harmonics to noise. The Sandbox supports all paths. The formula responds the same way regardless of how the learner found it.

The QFE computation runs every frame. The entropy history maintains a 30-frame sliding window. The temporal derivative captures approximately half a second of trajectory. The system is always computing, always responding, always ready for the next parameter change. The learner's relationship to the formula shifts from analytical (understanding each term in isolation) to synthetic (manipulating all terms simultaneously) — from the earlier maps' dissection to the Sandbox's integration.

The formula display near the exit is the final check: does the number match the feel? Does the QFE readout confirm what the body senses? The convergence of numerical output and embodied experience is the QFEP's pedagogical goal. When the number and the feeling agree, the formula is understood not as abstraction but as description — a compressed encoding of what the learner already knows how to navigate.
