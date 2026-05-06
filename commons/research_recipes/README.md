# Research Recipes

Per-artifact render overrides for `tools/render_principle_slice.py`.

When the auto-research pipeline classifies an artifact and tries to
render it, it uses sensible defaults: oblique camera, AABB-fit framing,
3-second animation wait. About 90% of artifacts render correctly that
way. The remaining ~10% need adjustments — usually:

- **Longer wait** for slow-converging simulations (ant colony optimization
  needs ~10s before pheromones become visible)
- **Top-down camera** for grid-based or 2D-ish patterns
- **Manual look_at** for scenes that build geometry far from origin
- **Scene props** (export overrides) to set the right initial conditions

## File naming

`<topic>__<artifact>.json` — same pattern as the gallery entry IDs.

## Recognized keys

```json
{
  "wait":       10.0,                  // override default 3.0s
  "camera":     "top",                 // "top" | "front" | "oblique"
  "distance":   12.0,                  // override AABB-fit, used only if auto_fit=false
  "auto_fit":   false,                 // disable AABB-fit, use distance
  "look_at":    [0, 1.5, 0],           // manual focus point
  "fov":        50,
  "scene_props": {                     // set @export properties before _ready
    "iteration_count": 8,
    "speed": 2.0
  }
}
```

## Using

Drop a JSON in this directory; re-run:

```
python tools/render_principle_slice.py --principle stochastic --force
```

The renderer picks up the override automatically.
