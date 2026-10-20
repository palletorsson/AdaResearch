# Non-Euclidean space — feasibility instruments

11 October 2026. These are original Godot 4.6 research probes. They establish mathematical and rendering capabilities for an expansion of the existing Endless Museum hall. They are **not seven completed VR encounters**, a new starter world, or a ghost-student pass. The existing museum and published lesson are unchanged.

Open this folder's `project.godot` separately to avoid museum autoloads during renderer experiments. F6 `probe.tscn` shows the stencil instrument. The geometry viewer uses `curved.tscn`; select a mode with command-line arguments:

```powershell
& 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe' --path 'C:/Users/palle/Documents/GitHub/AdaResearch_46/doc/book/studies/noneuclid-research' res://curved.tscn -- --mode=inside
```

Modes: `disk`, `sphere`, `ball`, `product`, `inside`. Left/right changes a triangle vertex in disk mode, or the observer's horizontal isometry in the three scaffold modes. Sphere mode shows a fixed parallel-transport circuit. Escape/window close exits normally. Add `--capture` to save a PNG and quit. The displayed curves are finite line samples of analytical paths; intrinsic measurements use the geometry kernel.

- `disk`: genuine H² geodesics in a Poincaré model; equal intrinsic steps compress near the display boundary.
- `sphere`: a tangent transported around a spherical octant returns rotated 90°.
- `ball`: an external Poincaré-ball view of a finite H³ geodesic scaffold.
- `product`: first-person central projection in H² × R, using the product log map.
- `inside`: first-person central projection of H³ after recentering by a Lorentz isometry.

The 25-column scaffold is a finite test graph, **not a regular hyperbolic tiling**. The H² × R and H³ versions interpret the same seed coordinates differently; they are not isometric copies. These views are monoscopic. They have no player collision, body-coherent XR tracking, curved lighting, grabbable study objects, or museum portal crossings yet. Arrow keys test horizontal movement only. Full H³ vertical movement is covered numerically, not offered as a completed player interaction.

`geometry_kernel.gd` uses curvature radius 1 and small bounded examples. Vector4 storage has finite precision. Large-distance traversal needs recentered cell coordinates rather than unlimited growth in one global frame. Antipodal spherical transport and ball-boundary inputs are explicitly outside the kernel's domain. Godot positions are display coordinates; Jolt does not become a hyperbolic physics solver.

Run the reproducible probes from the Ada repository root:

```powershell
python -X utf8 tools/test_noneuclid_research.py
```

The runner checks process status, Godot errors, JSON assertions, and output images. It retains each run and records source hashes. The published report includes the latest successful run. These are author feasibility tests, not an independent reconstruction from tutorial prose.
