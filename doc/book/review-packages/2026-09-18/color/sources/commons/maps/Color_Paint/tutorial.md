# Enter an ongoing painting

Watch the moving pigment ball before taking a manual one. Pick up a colour from the two-row tray, aim at the canvas, and move through part of the automatic line. Release it. The ball returns and stops making marks; the automatic painter continues.

The manual route is hit-specific:

```gdscript
var hit_surface := collider.get_node_or_null("PaperDrawSurface") as MeshInstance3D
var uv: Vector2 = paper_surface.get_uv_from_world_pos(hit_position)
```

The contacted drawing area supplies the receiver. The surface converts the hit using its actual PlaneMesh dimensions. For this canvas these are 4 by 2.5 metres. The manual brush smooths successive UV positions, snaps them to its configured resolution, and draws points or connecting lines.

The automatic route supplies UV directly:

```gdscript
var uv := Vector2(0.5+0.43*sin(elapsed*0.71),0.5+0.4*sin(elapsed*1.13+0.6))
surface.draw_line(previous,uv,color,12,256)
```

Both reach the same canvas brush layer. The automatic caller runs at most thirty times per second. The wet shader updates on rendered frames, sampling the previous image and four neighbours before fading toward white. It does not retain a stroke list.

Compare this evolving image with a fixed arrangement in the Albers gallery. Continue into Color_Walls with the difference between a colour value, its neighbours and its receiving surface in mind.
