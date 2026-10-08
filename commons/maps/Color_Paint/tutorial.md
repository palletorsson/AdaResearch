# Aim, activate, leave a mark

**Learning elements**

- Named actions and interaction states
- Ray targets
- Surface coordinates
- Shared drawing methods
- Interaction feedback

Pick up a colour from the tray. Aim at the canvas without pressing the trigger: your hand moves the can, but leaves no mark. Hold the trigger, make a short pass, then release it while keeping the can in your hand. Finally, let go of the can; it returns to its dock. On desktop, right-click carries or returns a can; holding the left mouse button sprays.

Coordinates taught you to carry an object; Trace made repeated positions visible. Here the moving nozzle must reach a receiving surface with its ray. The local/world transforms and function calls you already know connect the nozzle to that surface.

The museum supplies the can, controller rig, collision shapes, particles and canvas renderer. Open `commons/context/drawingboard/spray_can.gd` to follow the interaction. Its `nozzle` variable references a child created in `_ready()`; its inherited `_current_controller` references the controller holding this can. The excerpts below belong to those existing objects.

**Separate carrying from activation**

The OpenXR action map, `openxr_action_map.tres`, names two inputs: `trigger_click` reports a pressed/released state; `trigger` supplies a scalar value. The pickup function routes `trigger_click` to the held object's `action()` or `action_release()`. These emit the pickable signals connected by the can's `_ready()`.

The press handler sets `_pressed = true`. The release handler clears it and calls `_stop_spray()`. The desktop pointer calls the same action methods from mouse events; its input route is separate from the OpenXR bindings.

This is the opening of the can's existing physics update:

```gdscript
func _physics_process(delta: float) -> void:
    if not (is_picked_up() or _desktop_held) or not _pressed:
        _stop_spray(); return
    var pressure := 1.0
    if is_instance_valid(_current_controller):
        pressure = clampf(_current_controller.get_float("trigger"), 0.0, 1.0)
    if pressure <= 0.02:
        _stop_spray(); return
```

Read the condition aloud: the can must be held **and** its action pressed. `return` ends this update when either condition fails. Pressing starts permission to spray; repeated physics updates keep depositing while the conditions hold. Release stops that repetition. Dropping also clears the action.

The tracked trigger's scalar is polled on each update to adjust pressure. Desktop uses `1.0`. Treat this as one additional input value for now; the state sequence remains docked → held → active → held.

**Find a receiver**

Keep spraying and turn the nozzle beside the canvas. Mist and hiss continue, but your marks stop. `is_spraying` describes the open valve; `is_painting` describes a successful canvas sample. Feedback can confirm different parts of an interaction.

The nozzle's world position supplies `origin`; its rotated local negative Z axis supplies the normalized `direction`. `_sample_nozzle()` begins with this ray query:

```gdscript
var query := PhysicsRayQueryParameters3D.create(
    origin, origin + direction * max_distance, 1, [get_rid()])
query.collide_with_areas = true
var collision := get_world_3d().direct_space_state.intersect_ray(query)
```

The endpoint uses the direction-and-distance calculation from Lines. The `1` selects collision layer 1; the exclusion list contains this can's physics identifier. Areas participate because the canvas receiver is an `Area3D`.

The first eligible hit must belong to `drawing_area` and contain a `PaperDrawSurface` with `draw_spray()`. A nearer collider on that layer blocks the canvas. The code then intersects the visible canvas plane, checks its front-facing angle and rejects points beyond its edges or range. Seeing the canvas does not guarantee that this ray reaches it.

**Convert the hit**

The receiver uses `paper_draw_surface.gd` in the same directory. Its `get_uv_from_world_pos()` first removes the surface's world transform, then measures across its rectangular mesh. This reduced equivalent shows the conversion for the supplied `PlaneMesh`:

```gdscript
var local_hit := surface.to_local(world_hit)
var size := (surface.mesh as PlaneMesh).size
var uv := Vector2(
    local_hit.x / size.x + 0.5,
    local_hit.z / size.y + 0.5)
```

Here `surface` is the accepted `PaperDrawSurface` and `world_hit` is the plane intersection. The mesh lies in its own XZ plane, even though it stands upright in the room. Its centre becomes `(0.5, 0.5)`; each coordinate spans zero to one. The four-by-two-and-a-half-metre mesh needs separate width and height. The renderer converts UV into texture pixels without snapping spray input to grid cells.

**Change one boundary**

Change the exported `max_distance` default in `spray_can.gd` from `3.0` to `1.5`, then reload the encounter. Spray from roughly two metres away, then approach within one metre. Predict which attempt leaves paint. Mist and hiss should continue in both; only the closer aim can reach. Restore `3.0` afterward. This changes manual cans' reach without changing their held/action states.

Now cross the automatic painter's line. It calls the same surface method, `draw_spray()`, with a calculated position; your can supplies a ray hit. Both modify one evolving image. Unlike Trace's ordered position list, this canvas does not keep recoverable gestures. Carry that distinction into Color_Walls: a surface can change what an operation becomes.
