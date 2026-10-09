# WaveFunctions 3D Wave Propagation — Technical

The map fills a volume with spherical waves emanating from multiple sources. Each source emits a wavefield with distance-dependent attenuation and phase delay. Where fields overlap, they superpose.

```gdscript
class_name WaveSource extends Node3D

@export var frequency: float = 2.0       # Hz
@export var amplitude: float = 1.0
@export var attenuation: float = 1.0     # falloff exponent (2.0 = inverse-square)
@export var speed: float = 5.0           # propagation speed (units/sec)

func amplitude_at(point: Vector3, time: float) -> float:
    var distance: float = global_position.distance_to(point)
    if distance < 0.01: return amplitude
    var delay: float = distance / speed
    var phase: float = 2.0 * PI * frequency * (time - delay)
    var falloff: float = 1.0 / pow(distance, attenuation)
    return amplitude * falloff * sin(phase)
```

## Superposition

Multiple sources' fields add. Constructive interference produces maxima; destructive interference produces nodes.

```gdscript
class_name WaveField extends Node3D

var sources: Array = []  # array of WaveSource

func field_at(point: Vector3, time: float) -> float:
    var total: float = 0.0
    for src in sources:
        total += src.amplitude_at(point, time)
    return total
```

## Visualising the Field

A lattice of small markers samples the field at discrete points. Each marker's brightness or scale reflects the local amplitude.

```gdscript
class_name MarkerLattice extends MultiMeshInstance3D

@export var resolution: int = 12
@export var extent: float = 10.0

var field: WaveField

func _ready() -> void:
    multimesh = MultiMesh.new()
    multimesh.transform_format = MultiMesh.TRANSFORM_3D
    multimesh.use_custom_data = true
    multimesh.instance_count = resolution * resolution * resolution
    # position each instance

func _process(_delta: float) -> void:
    var t: float = Time.get_ticks_msec() / 1000.0
    var idx := 0
    for ix in range(resolution):
        for iy in range(resolution):
            for iz in range(resolution):
                var p := instance_position(ix, iy, iz)
                var amplitude := field.field_at(p, t)
                multimesh.set_instance_custom_data(idx, Color(amplitude, amplitude, 1.0, 1.0))
                idx += 1
```

## Complexity

The field at a single point is O(S) for S sources. The full lattice update is O(R³ · S) per frame for resolution R. At R=12, S=4, that is 6912 source evaluations per frame, or about 410,000 per second at 60 fps — trivial on modern CPUs but expensive enough that the map caps resolution.

GPU evaluation via a compute shader reduces this dramatically: the same lattice can be updated at 128³ resolution in under a millisecond on modern hardware. The map uses CPU for pedagogical readability.

## Damping

Real wavefields lose energy over time and distance through viscous damping and scattering. A damping term in the propagation reduces amplitude as a function of time:

```gdscript
func damped_amplitude(amplitude: float, damping: float, time: float) -> float:
    return amplitude * exp(-damping * time)
```

The map uses minimal damping so the wavefields persist long enough to observe interference patterns.

## Interference Geometry

For two sources separated by distance d with the same frequency, maxima form hyperbolas where the path-length difference is an integer multiple of the wavelength. The hyperbolas' asymptotes make an angle with the line between sources that depends on the wavelength-to-separation ratio.

Within the sequence, 3D_Wave_Propagation is where oscillation acquires spatial extent. The subsequent maps treat waves as fields rather than as point oscillators.

## Wave Equation Derivation

The scalar wave equation for propagation is ∂²u/∂t² = c²∇²u, where c is the propagation speed. Finite-difference discretisation produces a stable update rule: u(x, t+dt) = 2u(x,t) - u(x,t-dt) + (c·dt/dx)²(u(x+dx,t) + u(x-dx,t) + ... - 6u(x,t)) in 3D. The Courant-Friedrichs-Lewy (CFL) condition requires c·dt/dx ≤ 1/sqrt(3) in 3D for stability.

```gdscript
class_name WaveSim extends Node3D

@export var grid_size: Vector3i = Vector3i(32, 32, 32)
@export var dx: float = 0.25
@export var dt: float = 0.05
@export var c: float = 1.0

var u_now: PackedFloat32Array
var u_past: PackedFloat32Array

func step() -> void:
    var u_next := PackedFloat32Array()
    u_next.resize(u_now.size())
    var coef: float = pow(c * dt / dx, 2)
    # Inner cells only; boundary cells are zero-damped
    for x in range(1, grid_size.x - 1):
        for y in range(1, grid_size.y - 1):
            for z in range(1, grid_size.z - 1):
                var i: int = idx(x, y, z)
                var laplacian: float = u_now[idx(x+1,y,z)] + u_now[idx(x-1,y,z)] + u_now[idx(x,y+1,z)] + u_now[idx(x,y-1,z)] + u_now[idx(x,y,z+1)] + u_now[idx(x,y,z-1)] - 6.0 * u_now[i]
                u_next[i] = 2.0 * u_now[i] - u_past[i] + coef * laplacian
    u_past = u_now
    u_now = u_next
```

The field lattice renderer samples u_now at each marker position. Grid-based wave simulation is O(N³) per step for an N×N×N grid.

## Absorbing Boundaries

Simulating infinite space in a finite grid requires boundary conditions that absorb outgoing waves without reflection. The simplest is a damping zone near the grid edges where amplitudes are multiplied by a factor less than 1 each step. More sophisticated approaches use Perfectly Matched Layers (PML) that absorb at all angles.
