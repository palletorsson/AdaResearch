# Floor108 / turn a boundary

The existing lattice-gas occurrence now has a roughly seven-metre visible field
(44×22 cells at 0.16 m) and a reachable handwheel. The ivory plate, witness pulleys
and actual capsule-shaped solid-cell boundary read the same wheel angle, limited
to ±80°. The connecting belt is an ideal 1:1 linkage; torque and belt slip are not
simulated. The obstacle mask is discretized on the original lattice.

The original four-direction injection, opposing-pair collision and bounce/stream
methods are inherited unchanged. A separate unmodified source object reproduces
the adapter's state exactly at an equal update budget. The field colours show
density and reverse occupancy; four direction marks read actual state bits.
RUN, STEP and RESET use native input. STEP advances two original updates. RESET
repeats seed24108 with 50 settling updates, retaining the chosen obstacle angle.
The rightward-bounce count is a discrete proxy, not calibrated aerodynamic drag.
The source's horizontal wrapping is retained. This is not a continuum CFD model.

Native evidence inspected: 19 desktop and 21 synthetic-XR assertions, including
actual held mouse dragging, native grip pickup/tracked movement/release, real
mask changes, plate-angle equality, all3872 occupancy-mark slots, empty solid
cells, equal-budget angle comparisons, negative-floor moved/rotated placement,
glass collision, complete geometry bounds and open shaft centres. The actual
desktop player walks the front, both ends and rear bypass. No engine errors in
the final runs. Existing Jolt solver-bias and an unrelated Rule30 scene UID
fallback warning remain. Synthetic VR is not physical-headset acceptance;
headset comfort and performance remain untested.

The first synthetic-XR attempt is archived under attempt01-xr: the probe assumed
a fixed name for a dynamically created collision shape. That test path was
corrected; no grip implementation change was needed. An explicit vertex colour,
two-sided arrow material and thin state tiles were added for visual legibility;
final desktop screenshots and receipts are from the updated renderer.

Main108 retains all six original occurrences; only the wind-tunnel occurrence's
pose, source-backed adapter config and presentation change. The other five,
construction and other main floors are preserved by a fresh revision-checked API
merge. The machine stands in the east bay, facing west, clear of both shafts.
Its complete bounds fit the standard42×18 floor and six-metre storey. It has
concrete feet, a cabinet/glass collision and a supported low control wheel.

All six source-backed objects have actual parsed GLBs. Production editor
copy/move/rotate functions and the save validator are checked using disposable
copies; the test does not overwrite the visitor arrangement. The tunnel is a
whole coupled object in the editor; generated gas cells are not individual
parts. Copies retain the live-study config and starting angle. The editor shows
actual static snapshot geometry; Godot desktop and VR run the same rooms.json
with live behaviour. No other sequence or physical-headset acceptance is claimed.

Evidence: ada_run/wind-tunnel-108/review.json and referenced native, engine,
export, publish and editor receipts. Original source digest is unchanged.
