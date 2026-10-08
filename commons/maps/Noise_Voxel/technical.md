# Noise Voxel: from a field to an occupied set

This account describes the four authored works in the current museum placement. The previous account and scene/map sources are preserved under `doc/space/voxel-review-2026-09-13/before/`. The original lattice, threshold, height-bias, MultiMesh, SurfaceTool and connectivity arguments remain; the sampler, dimensions, controls and collision claims below follow the implemented hall.

## One sampled field

`perlin_terrain_sculptor#stand:lattice#seed:31415` is the source. The map supplies a reproducible initial seed. It constructs FastNoiseLite with TYPE_PERLIN, FRACTAL_FBM, three octaves and frequency `noise_scale * 0.1`, initially `4.0 * 0.1 = 0.4`. Both model and receiver use the same helper:

```gdscript
static func contract_noise(seed_value: int, scale: float, octaves: int) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_PERLIN
	n.fractal_type = FastNoiseLite.FRACTAL_FBM
	n.frequency = scale * 0.1
	n.fractal_octaves = octaves
	n.seed = seed_value
	return n
```

Each axis has 24 samples. An integer address becomes `index / 23.0`, then the helper multiplies by CONTRACT_SPAN = 9.6. These are field coordinates, distinct from the physical centres of the displayed cubes. The endpoints sample 0 and 9.6; the frequency configured on FastNoiseLite then affects its evaluation. The field is continuous in its mathematical construction; the implementation computes finite-precision values at selected positions.

In volume mode the receiver is also 24³, so every index denotes the same sample in both works. The earlier 24³/32³ pairing covered the same coordinate domain but sampled different intermediate positions. Matching domains alone cannot establish matching cells.

The receiver formerly accepted the Perlin contract and then reset its sampler to Simplex in `_configure_noise()` during rebuilding. That function now preserves the contract. Legacy receivers without the contract keep their original Simplex path. Shared seed alone was insufficient: algorithm, coordinates, frequency, octave settings and decision rule must also agree.

## Classification and vertical preference

Let `v = y / 23`. Bias is `(v - 0.5) * 0.5`. The decision is strictly `field - bias > threshold`. At equality the answer is empty. The bottom bias is −0.25, helping occupancy; the top bias is +0.25, hindering it. This subtraction introduces a vertical preference. It does not simulate gravity, falling fragments or a physical soil process.

At a fixed seed, sampling and bias, increasing the threshold produces a subset of the previous occupied set. The five button positions are −0.20, −0.10, 0.00, +0.10, +0.20, followed by a wrap to −0.20. The wrap increases occupancy and must not be mistaken for a counterexample to monotonicity. The initial position is 0.00.

The recorded seed-31415 comparison is:

| Threshold | Occupied cells | Face-connected pieces | Largest piece |
|---|---:|---:|---:|
| −0.20 | 11,040 | 4 | 11,028 |
| −0.10 | 9,176 | 15 | 9,085 |
| 0.00 | 6,767 | 25 | 6,661 |
| +0.10 | 4,582 | 21 | 4,498 |
| +0.20 | 2,685 | 32 | 2,577 |

These are measured outcomes of this configuration, not counts promised for a new seed. Occupancy falls monotonically. The component count can rise when a connection is removed and fall when an entire component disappears. The flood fill treats six face neighbours as adjacent; edge and corner contact alone do not join two components. It counts connected components of the occupied cells, not cavities, traversable routes or a general entropy measure.

## Four controls with different scopes

THRESHOLD changes classification and broadcasts the source settings to the hall's volume. CELL cycles five selected coordinates and changes the screen's horizontal layer, the large volume's yellow section perimeter and its selected-cell outline. This selection update is scoped to the same hall and does not rebuild either body. The receiver's link opt-out also disables selection updates. SEED generates a new named five-digit seed and rebuilds the field. CUT hides cells with `z > grid_size / 2` in the model's MultiMesh while retaining `_voxels`, all occupancy counts, the receiver and the screen section. With 24 indices this keeps 0–12 visible; the cut is not exactly half the index range.

The lattice mode now omits the legacy slider case and floating labels in favour of its four-button panel and cased readout. The legacy standalone sculptor still offers its own controls. The lattice panel is enlarged and tilted; the model stands on a low solid plinth with a clear northern approach. The source now occupies map cell (13,7), avoiding the retained raised platform near its former controls.

The source discovers its museum ancestor and broadcasts only to receiver descendants of that hall. A receiver in another streamed hall is outside the update. The screen similarly finds its own hall's lattice source; if none exists it returns an empty data record and displays source-unavailable information, not an invented substitute field.

## Model, screen and full-size volume

The model allocates a MultiMesh for up to 13,824 instances and draws only occupied, currently visible cells. Its centres are `(index - 11.5) * 0.04`. Each BoxMesh is 95% of that spacing: 0.038 m. The little visual gaps expose the lattice; they do not change the component-count adjacency rule. The selected marker now uses the same cell centre. The bench model is a visual instrument, not an individually collidable cube world.

The science screen explicitly uses `mode:voxel_slice`. It shows a 24 × 24 horizontal layer at the selected y. It recalculates the field values from the source sampler and reads the actual stored `_voxels[x][y][z]` booleans. The left heatmap maps the biased scalar through a fixed colour range; the right map displays occupancy. Two yellow outlines identify the same selected x,z address. The screen is a 2D rendering carried by a 3D stand. Its cache includes source identity, seed, frequency, octaves, threshold, cell and grid size. CUT does not change its data.

`voxelnoise:180#stand:volume#cell_size:1#flight_box:true` faces the same way as the bench and uses 1.00 m spacing and cubes which meet at their faces. The stage occupies 24.4 × 24.4 m around a 24 m cube domain. A 28 m glass enclosure leaves a two-metre margin on each horizontal side and four metres above the domain. The occupied mask is computed first; a second pass emits only faces with an empty or out-of-bounds neighbour. Each exposed square contributes two triangles. Shared interior faces need no rendering or collision. This preserves the occupied set while reducing mesh construction cost. The boundary includes cavity surfaces, not just the outside silhouette.

The same triangle array constructs the ConcavePolygonShape3D. Rebuilding removes the preceding mesh and collider before adding their replacement. A fully empty result creates neither. A matching collider establishes a physical boundary, but does not certify that a player can climb through the volume. The chamber's surrounding museum route remains available independently of the volume's changing occupancy. The 33 × 44 m source hall has a clear flight court and open roof. The old interior structure and utilities shift nine cells in x; side/end boundaries expand. Both raised cells and old openings are retained. The four artifacts remain; the model and screen move with that x offset, the volume moves to (16,24), and the orb to (5,8).

## What survives a representation change

The model and volume have the same scalar samples and occupancy at different physical spacings. Their finishes, block margins, render methods and collision behaviour differ. The screen exposes a selected section; it cannot show the whole 3D connectivity at once. The dark sphere retains its independent sine-driven emission, rotation and halo. It does not receive the voxel controls.

Sampling resolution, display scale and threshold are distinct. More samples cost more evaluations: doubling all three dimensions multiplies the cell count by eight. More geometry does not by itself provide better access, clearer reading or a more desirable body. Here the deliberately modest lattice allows the reader to inspect a decision and its consequences without making every address a separate Godot node.

## Verification and limits

The accepted rendered museum run passed 61 checks: all 13,824 scalar values and occupancy decisions agree at each of five thresholds; the screen's 576 decisions agree with the stored layer; boundary face counts and collision triangles agree; physical rays hit sampled roofs; empty-volume cleanup and CUT separation pass; all four buttons respond through the project's desktop interaction pointer. Broadcasts exclude an unrelated receiver. The museum reports no severed route for this hall.

This uses synthetic mouse events through the real desktop pointer rig. It is not a human walkthrough or headset test. Headset reach, comfort, step traversal and Quest frame cost remain pending. Mesh rebuilding is still synchronous and a threshold change can produce a hitch; the desktop timing record is not a headset performance guarantee.

## Shared section in the room — 25 September

The volume's section perimeter is 24.1 m wide around the 24 m field domain. Its centre height is `(selected_y + 0.5) * 1.00`; the authored five-cell cycle visits 12.5, 8.5, 6.5, 17.5 and 12.5 m. The small wire box follows the same x,y,z address, including empty cells. Both markers are depth-tested, unshaded observations with no collider; solid neighbours can occlude the address marker. Sixteen BoxMesh bars are reused as the selection moves. No field, threshold, occupancy, boundary generation or collision rule changes. The frame's fixed label is readable from either approach.

The preceding 0.20 m staging check injected press/release PointerEvent objects into the actual buttons; it does not test ray aiming or hand tracking. It compares all 13,824 field samples and decisions at five thresholds, checks unchanged mesh identity while selecting cells, matching mesh/collision triangles, CUT isolation, receiver opt-out and separation from another hall. Controlled walking paths go around the bench corner; a failed direct diagonal is retained in the review. That earlier check and photographs remain at `doc/book/iterations/2026-09-25-voxel-correspondence/`; the one-metre flight revision is at `doc/book/iterations/2026-09-25-voxel-flight/`. The older 61-check report above remains the earlier verification record.

## One-metre cells and local flight

The `cell_size` placement setting defaults to 0.20 m for existing volume placements; this hall explicitly selects 1.0. The number of addresses, normalized sampler, seed, threshold and occupied set are unchanged. Boundary vertices and collision now fall on the metre grid. Stage, captions and yellow section markers derive their size from the spacing. The miniature remains at 0.04 m.

The opt-in `flight_box` uses the existing museum_flight_box.gd and XR movement adapter. Its new `edge_length` setting is assigned before it enters the tree. Existing Menger and Array boxes retain their 12 m default, controls and speed. This hall uses 28 m; door openings retain their human-scale 3 m width and 2.6 m height. Flight is selected from the body's position, ends outside the envelope and does not remove voxel collision. Neutral input hovers; combined velocity is bounded at 2.4 m/s. The threshold and CELL buttons do not replace the flight enclosure.

The glass floor, sides and roof are physical, with two ground-level doors. No room-wide free-flight toggle persists after departure. Desktop and synthetic XR checks exercise the real museum movement/provider; headset comfort, tracking, reach and Quest performance remain unverified.
