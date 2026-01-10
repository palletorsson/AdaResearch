**The Torus**
Donut Topology

The torus as a surface of revolution with dual radii

---

## Two Radii Define the Ring
AXIOM 1: A torus requires two radii.
Code

```
var torus = TorusMesh.new()
torus.inner_radius = 2.0  # Major radius (center to tube center)
torus.outer_radius = 0.5  # Minor radius (tube thickness)
```

Donut shape: big ring + small tube
Concepts: inner_radius, outer_radius, major, minor, donut

---

## Ring Segments
AXIOM 2: Ring segments define tube smoothness.
Code

```
torus.ring_segments = 32

More segments = smoother tube
Each segment = one slice of the tube
```

Concepts: ring_segments, tube, smoothness, cross-section

---

## Radial Segments
AXIOM 3: Radial segments define ring smoothness.
Code

```
torus.radial_segments = 16

More segments = smoother circular path
Each segment = one slice around the ring
```

Concepts: radial_segments, circular path, revolution, smoothness

---

## Tessellation Combined
AXIOM 4: Total triangles = ring_segments x radial_segments x 2
Code

```
torus.ring_segments = 32
torus.radial_segments = 16
# Creates 1024 triangles
```

Low resolution reveals structure High resolution appears smooth
Concepts: tessellation, triangles, resolution, structure