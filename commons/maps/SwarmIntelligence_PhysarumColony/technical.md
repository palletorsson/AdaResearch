# Agents deposit trail on a grid, sense forward, turn toward concentration — a network emerges that no agent planned

Cellular automata established a principle: local rules on a grid produce global pattern. Each cell read its neighbors, applied a function, wrote its next state. But the cells never moved. The patterns were spatial, the computation stationary.

Forces established another principle: agents move. A particle with position and velocity responds to acceleration — drifts, collides, orbits. But those agents left no trace. A particle that passed through a region of space changed nothing about that region. The space was passive — a stage, not a medium.

Physarum polycephalum — a single-celled slime mold — collapses this divide. It moves through space like a force-driven agent. It modifies space like a cellular automaton updating its grid. It deposits chemical trail wherever it travels, then senses that trail to decide where to travel next. The agent writes to the environment. The environment writes to the agent. The feedback loop between motion and medium produces networks that approximate optimal solutions — shortest paths, Steiner trees connecting multiple food sources. No neuron, no centralized planner. Just agents, trail, and time.

This is stigmergy — coordination through environmental modification. Ants do it with pheromones. Termites with mud pellets. Physarum with chemical gradients on its own body. The simulation that follows models this process: thousands of virtual agents on a 2D trail map, each executing the same sense-turn-deposit loop, producing emergent networks from nothing but local interaction.

## The Agent

A Physarum agent is minimal. Position in 2D. Heading angle. That is the complete state.

```gdscript
var agent_x: PackedFloat32Array     # x positions for all agents
var agent_y: PackedFloat32Array     # y positions for all agents
var agent_angle: PackedFloat32Array # heading in radians

var num_agents: int = 5000
var trail_width: int = 256
var trail_height: int = 256
var trail_map: PackedFloat32Array   # 2D grid stored flat

func _ready() -> void:
    agent_x.resize(num_agents)
    agent_y.resize(num_agents)
    agent_angle.resize(num_agents)
    trail_map.resize(trail_width * trail_height)
    trail_map.fill(0.0)

    for i in num_agents:
        # Spawn agents in a central cluster
        agent_x[i] = trail_width * 0.5 + randf_range(-20.0, 20.0)
        agent_y[i] = trail_height * 0.5 + randf_range(-20.0, 20.0)
        agent_angle[i] = randf() * TAU
```

Flat arrays instead of an array of structs — structure-of-arrays keeps memory access coherent across thousands of updates per frame. The trail map is a single flat array indexed as `y * trail_width + x`. Every cell starts at zero. The agents begin clustered at the center, facing random directions, and the network must self-organize from this undifferentiated mass.

The initial condition shapes transient dynamics. A uniform scatter produces diffuse, slow-forming networks. A tight cluster forces agents outward simultaneously — tendrils radiate, compete, merge. But the steady-state network converges to similar topologies regardless. The trail feedback dominates.

## Sensing: Three Samples, One Decision

Each agent carries three virtual sensors — forward-left, forward-center, forward-right. The sensors are not at the agent's position. They are offset ahead, at a fixed distance along the sensing direction. The agent samples the trail map at each sensor location and compares concentrations.

```gdscript
var sensor_angle: float = PI / 4.0    # 45 degrees from heading
var sensor_offset: float = 9.0        # pixels ahead

func sense(i: int) -> Vector3:
    # Sample trail at three forward-offset positions
    var angle_l: float = agent_angle[i] - sensor_angle
    var angle_c: float = agent_angle[i]
    var angle_r: float = agent_angle[i] + sensor_angle

    var fl: float = sample_trail(
        agent_x[i] + cos(angle_l) * sensor_offset,
        agent_y[i] + sin(angle_l) * sensor_offset)
    var fc: float = sample_trail(
        agent_x[i] + cos(angle_c) * sensor_offset,
        agent_y[i] + sin(angle_c) * sensor_offset)
    var fr: float = sample_trail(
        agent_x[i] + cos(angle_r) * sensor_offset,
        agent_y[i] + sin(angle_r) * sensor_offset)

    return Vector3(fl, fc, fr)

func sample_trail(x: float, y: float) -> float:
    var ix: int = wrapi(int(x), 0, trail_width)
    var iy: int = wrapi(int(y), 0, trail_height)
    return trail_map[iy * trail_width + ix]
```

Three samples. Three floats. The sensor angle determines the agent's field of view — wide angles produce broad, exploratory networks; narrow angles produce tight, efficient paths. The sensor offset determines how far ahead the agent looks — long offsets create smoother curves, short offsets create jittery branching.

`wrapi` handles boundary conditions. The trail map wraps toroidally — same topological choice as the cellular automaton grid. Borderless space. No edge artifacts.

Three sensors is the minimum that supports directional choice. Two samples cannot distinguish "more trail ahead" from "more trail to the side." Three — left, center, right — spans the decision space: continue straight, veer left, veer right. The entire navigational intelligence reduces to comparing three numbers.

## Turning and Depositing: The Perception-Action Loop

The agent compares sensor readings and adjusts its heading. The logic is a conditional cascade — not a smooth gradient computation, but a discrete decision tree.

```gdscript
var turn_angle: float = PI / 4.0     # maximum turn per step
var random_turn: float = PI / 6.0    # stochastic wander component

func turn(i: int, sensors: Vector3) -> void:
    var fl: float = sensors.x
    var fc: float = sensors.y
    var fr: float = sensors.z

    if fc > fl and fc > fr:
        # Center is strongest — continue straight
        pass
    elif fc < fl and fc < fr:
        # Both sides stronger than center — pick randomly
        if randf() < 0.5:
            agent_angle[i] -= turn_angle
        else:
            agent_angle[i] += turn_angle
    elif fl > fr:
        # Left is strongest — turn left
        agent_angle[i] -= turn_angle
    elif fr > fl:
        # Right is strongest — turn right
        agent_angle[i] += turn_angle

    # Add small random perturbation
    agent_angle[i] += randf_range(-random_turn, random_turn) * 0.1
```

When the center sensor reads highest — continue straight. When both sides exceed the center — the agent is in a trough, picks randomly, breaks symmetry. When one side dominates — turn toward it. The turn angle is fixed, not proportional to concentration difference. A bang-bang controller, not a PID. Proportional turning produces smoother paths but weaker network formation. The fixed-angle snap creates sharper branches and faster convergence.

The random perturbation prevents deadlock. Without noise, agents in uniform trail fields march in straight lines forever. The stochastic nudge introduces diffusion at the agent level — wandering that becomes exploration at the population level. Too much noise and the network dissolves. Too little and it crystallizes prematurely.

After turning, the agent moves forward one step and deposits trail at its new position.

```gdscript
var move_speed: float = 1.0
var deposit_amount: float = 5.0

func move_and_deposit(i: int) -> void:
    agent_x[i] += cos(agent_angle[i]) * move_speed
    agent_y[i] += sin(agent_angle[i]) * move_speed

    agent_x[i] = fposmod(agent_x[i], float(trail_width))
    agent_y[i] = fposmod(agent_y[i], float(trail_height))

    var ix: int = int(agent_x[i])
    var iy: int = int(agent_y[i])
    var idx: int = iy * trail_width + ix
    trail_map[idx] += deposit_amount
```

The deposit is the agent's only output. No communication between agents — they never read each other's position or heading. They communicate exclusively through the trail map. Agent A deposits. Agent B senses that deposit ten steps later. The trail is the message. The grid is the channel. Ten thousand agents coordinate without any agent knowing any other agent exists.

The deposit amount controls coupling strength. High deposit means strong positive feedback — trails attract agents that deposit more trail that attracts more agents. Low deposit means weak coupling — trails fade before reinforcement occurs. The transition is sharp. Below a critical deposit rate, no network forms. Above it, networks snap into existence within a few hundred frames — a phase transition in an information-processing system.

## Trail Processing: Diffusion, Decay, and the Grid as Medium

Trail does not stay where it was deposited. It spreads. Each frame, every cell in the trail map averages with its neighbors — a 3x3 box blur that simulates chemical diffusion.

```gdscript
var diffuse_rate: float = 0.2  # blend factor toward neighbor average
var decay_rate: float = 0.95   # multiply each cell each frame

func diffuse_trail() -> void:
    var temp: PackedFloat32Array = trail_map.duplicate()

    for y in trail_height:
        for x in trail_width:
            var sum: float = 0.0
            for dy in range(-1, 2):
                for dx in range(-1, 2):
                    var nx: int = wrapi(x + dx, 0, trail_width)
                    var ny: int = wrapi(y + dy, 0, trail_height)
                    sum += temp[ny * trail_width + nx]
            var avg: float = sum / 9.0
            var idx: int = y * trail_width + x
            trail_map[idx] = lerpf(temp[idx], avg, diffuse_rate)

func decay_trail() -> void:
    for i in trail_map.size():
        trail_map[i] *= decay_rate
```

The 3x3 kernel reads nine cells — the center and its eight Moore neighbors. The average replaces the center value, blended by `diffuse_rate`. The useful range is 0.1 to 0.3, where trail spreads enough to create smooth gradients but retains spatial structure. Diffusion widens the trail's area of influence and smooths discrete deposits into continuous concentration landscapes. The agents sense a gradient field, not a scatterplot of points.

This is the same operation as the cellular automaton's neighbor averaging — a Moore neighborhood read, a function applied, a value written back. The trail map is a cellular automaton running in parallel with the agent simulation. Agents write to the grid. The grid processes itself. Agents read from the grid.

Without decay, trail accumulates without bound — old paths pollute the gradient field with irrelevant history. Decay is forgetting, and forgetting is essential. Every cell loses 5% per frame. Active paths maintain concentration through continuous reinforcement. Abandoned paths fade. The network self-prunes.

Decay rate is the system's memory parameter. High decay (0.99) means long memory — established paths dominate. Low decay (0.8) means short memory — the network flickers and reforms. High deposit with low decay produces rigid networks. Low deposit with high decay produces formless wandering. The interesting regime sits between.

The full simulation loop runs each frame:

```gdscript
func _process(delta: float) -> void:
    for i in num_agents:
        var sensors: Vector3 = sense(i)
        turn(i, sensors)
        move_and_deposit(i)

    diffuse_trail()
    decay_trail()
    update_display()
```

Sense, turn, move, deposit — per agent. Diffuse, decay — per grid cell. The agent loop is inherently serial — each deposit changes the map the next agent senses. The grid operations are inherently parallel — every cell's diffusion depends only on the previous frame's values. The double-buffer pattern from cellular automata applies to diffusion but not to agent motion. Two computational styles in one loop.

## The Emergent Network

Run the simulation. The first hundred frames show chaos — agents spraying trail in random directions, a diffuse cloud expanding from the center. Then structure appears. Filaments. Thick trunks where many agents travel the same corridor, thin tendrils probing empty space. Tendrils that find nothing fade. Trunks that carry heavy traffic thicken.

By frame 500, a stable network connects regions of high agent density with efficient paths. Add food sources — cells with elevated trail that never decays — and the network restructures to connect them. The resulting topology approximates a Steiner tree: the minimum-total-length network connecting all food points, allowing branch nodes that are not themselves food sources.

The Steiner tree problem is NP-hard. Physarum does not guarantee optimality. But it consistently finds solutions within a few percent of optimal through purely local operations. No agent knows where the food sources are. No agent has a map of the network. Each follows its nose — turning toward higher concentration, depositing where it walks. The global optimum emerges from local greed.

Cellular automata showed that local rules produce global pattern, but cells were fixed. Force-driven particles showed that agents move, but they left no mark on space. Physarum agents move through space and rewrite it. The trail map is both output of computation and input to the next step. The medium is the message.

## Parameter Sensitivity

Six parameters control the simulation. Each bends the network's character.

**Sensor angle** — the spread between left and right sensors. At 0 degrees, sensors overlap and agents wander randomly. At 90 degrees, peripheral vision dominates — networks become wide and web-like. The sweet spot near 22.5 to 45 degrees produces characteristic vein-like patterns.

**Sensor offset** — how far ahead the sensors sample. Short offsets produce tight branching. Long offsets produce sweeping curves and sparse networks. The planning horizon of the agent.

**Turn angle** — maximum heading change per step. Interacts with sensor angle: if the turn angle is smaller than the sensor angle, the agent cannot fully respond to its own sensory input.

**Deposit rate** — coupling strength. Below a threshold, no network forms. Above it, thicker trunks and stronger path-locking. Very high deposit overwhelms diffusion, creating narrow pixel-wide trails.

**Decay rate** — temporal memory. Slower decay means a conservative network — reluctant to reorganize. Faster decay means constant exploration, quick rerouting.

**Diffusion kernel** — spatial spread of chemical signal. Wider kernels (5x5, 7x7) create broader gradient fields, increasing the effective communication range between agents.

These parameters do not combine linearly. The parameter space contains ridges, valleys, and phase boundaries. Sweeping one parameter while holding others fixed reveals which combinations produce networks, which produce chaos, and which produce frozen lattices of agents marching in circles.

## Stigmergy and the Free Energy Principle

Physarum agents minimize surprise. Each agent expects trail — its sensors are tuned to detect and follow chemical concentration. Low trail means high prediction error. The agent turns away, seeking regions where expectation matches reality. When it finds trail, prediction error drops. It follows. It deposits more, reinforcing the pattern it expects to find.

This is active inference at the swarm scale. Agents do not passively observe — they actively construct. Every deposit reduces future prediction error for the depositing agent and for every other agent that later senses that trail. The trail map is a shared model of the world, written collectively, read individually. The network that emerges is the swarm's best explanation of its own sensory history.

The free energy framework does not need to be invoked for the simulation to work. The GDScript runs without variational inference. But the correspondence is structural. The sense-turn-deposit loop is a perception-action cycle. The trail map is a generative model encoded in the environment. The decay rate is a precision parameter — how quickly prior beliefs are forgotten. The deposit rate is the strength of active inference — how aggressively agents reshape the world to match expectations.

## Possible Artifacts

**food_source_configurator** — Click to place food sources on the trail map. Watch the Physarum network reorganize to connect them. Each food source emits constant trail that does not decay, acting as an attractor. A sidebar computes the Steiner tree for the current configuration and overlays it on the Physarum network, with a cost metric comparing total network length to the Steiner optimum. Adding or removing a single food source restructures the entire topology.

**parameter_sweep_panel** — Six sliders, one per parameter. The simulation runs live as sliders move. A phase diagram plots the current combination against known regimes — network, chaos, frozen, dissolved. Preset buttons load configurations that reproduce known biological Physarum behaviors.

**trail_map_inspector** — Renders the raw trail map as a heatmap, independent of agent positions. Toggling between agent view and trail view reveals the duality — agents are sparse, discrete points; the trail is a continuous, smooth field. The network exists in the trail, not in the agents.
