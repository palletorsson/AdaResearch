# Artifact reactions

An opt-in component for existing artifacts. It adds reversible tool responses without replacing the artifact's script, base class, pickable body or teaching logic. This accommodates both plain Node3D studies and XRTools RigidBody3D pickables.

## Enable an instance

Both the ordinary grid loader and the endless museum read these token settings:

```
line#reactive:break#rebuild:8
walk_this_line_marking#reactive:colour#rebuild:8
line_black_box#reactive:break#rebuild:8#reaction_target:LineStudy
```

Only explicitly opted-in instances participate. The rebuild interval is seconds, clamped to 2–60. Eight seconds is the Point Lines pilot's chosen short delay.

For code-created artifacts:

```gdscript
const Reactions = preload("res://commons/interactables/artifact_reactions/router.gd")

func _ready() -> void:
    Reactions.attach(self, {"reactive": "break", "rebuild": 8})
```

Call after constructing the study's children. A compound exhibition can implement `get_artifact_reaction_targets() -> Array` to return separately affected bodies. The four-view line gallery uses this to let individual rods/marks react. Alternatively, `reaction_target` selects a child by NodePath. Keep architecture, essential controls and recovery infrastructure outside that target.

The component lives beside its target, so hiding or pausing the study leaves the restoration clock running. Installing twice is idempotent. Removing the component restores a surviving target and removes its hit proxies.

## Tools and response

| Tool | Shared response in this pilot |
| --- | --- |
| Catalyst projectile, including mode variants | Temporary colour; the `reacted` signal includes the mode ID. |
| Pink gun | Temporary colour, using the existing catalyst projectile. |
| Held laser, configured with `burns` | Break after its existing dwell interval. An unattended laser cannot repeatedly burn these studies. |
| Sledgehammer | Three accepted strikes break a study; a 250 ms guard rejects duplicate melee contacts. |
| A future axe or other tool | Use the same `melee` dispatch shown below. No separate axe implementation was found in the project. |

`reactive:colour` permits colour responses but never breaks the target. Colour and accumulated damage recover after the configured interval since the latest accepted hit.

```gdscript
var receiver := Reactions.receiver(hit_body)
if receiver != null:
    receiver.react(&"melee", hit_position)
```

Full receiver signature: `react(tool: StringName, at: Vector3, colour: Color, strength: float, mode: StringName) -> bool`, with defaults for the last three arguments. Signals: `reacted(tool, world_point, mode)`, `broken()`, `rebuilt()`. `restore()` supports explicit reset. An optional target hook `artifact_reaction_attached(component)` supports existing artifact contracts; the barrier uses it to retain its original break notification.

On break, the original pickup API drops held bodies, the target is hidden and processing/collision are suspended. Rebuild restores the saved body poses, physics freeze states, processing, collision masks and material overlays. Physical restoration waits while a player on layer 20 occupies a returning collision shape. Grab again afterwards through the original XRTools pickup API.

## Geometry and boundaries

Each mesh gets an approximate local bounding-box tool collider on physics **layer 24** (`1 << 23`), with mask zero. These follow moving meshes. They do not add player support or block the visitor. Do not include that layer in the player collision mask. The project settings' layer-name field is unchanged.

Mesh bounds and visibility refresh four times per second. Deleted procedural meshes are removed from the lookup list. Private SubViewports are excluded: a filmed scene behind a monitor is not another body in the hall. Raycasts inside a target exclude its own proxies. Fast catalyst shots use continuous collision detection to meet thin line surfaces.

The fragments are sixteen bounded, animated slivers. **This is reversible disappearance with illustrative debris, not mesh fracture or CSG cutting.** Catalyst mode-specific shrink/physics effects do not run against invisible proxies; this pilot gives them a common colour response and preserves the mode ID for later artifact-specific development. Unconfigured receivers retain their old callbacks and mode behaviour.

Dynamic scenes that rebuild themselves externally, custom processing loops, unusual colliders and new compound studies still need a scoped pilot. Enabling this across the whole museum has not been tested.

## Point Lines coverage and evidence

34 study placements are configured. The line gallery expands into individual targets: 115 components and 454 mesh proxies in the measured museum load. Seven tool/service placements retain native behaviour: player trace, three lasers, the sledgehammer, health station and health cross. The walk stripe and street talker are colour-only; the black-box shell, passages and reset remain outside the line's response.

Native probe:

```
python tools/run_encounter_probe.py Point_Lines --sequence primitives --render --probe doc/book/iterations/2026-09-29-line-tool-reactions/probe.gd
```

The recorded run passed 73 checks: real projectile collisions, two catalyst modes, laser dwell and hammer dispatch, timed restoration, occupied-space delay, actual re-grabbing, ordinary-grid attachment, component removal and legacy callbacks, plus the prior line/route tests. The existing audio-bus UID warning remains. No headset or Quest performance claim; the collider count should be profiled there before wider rollout.

Review and frozen evidence: `doc/book/iterations/2026-09-29-line-tool-reactions/`.
