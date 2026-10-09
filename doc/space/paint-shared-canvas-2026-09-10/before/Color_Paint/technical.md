# A painting already in progress — implementation

The room places `ball_painting_demo` with `#automated:true`. `commons/context/drawingboard/ball_painting_automation.gd` targets this scene's own `DrawingArea3D/PaperDrawSurface`, so it cannot accidentally paint another canvas in the museum.

```gdscript
var uv := Vector2(0.5+0.43*sin(elapsed*0.71),0.5+0.4*sin(elapsed*1.13+0.6))
var color := Color.from_hsv(fposmod(elapsed*0.035,1.0),0.85,0.95)
surface.draw_line(previous,uv,color,12,256)
```

Elapsed time advances in `_process(delta)`. Painting is limited to at most thirty updates per second, with a bounded brush operation per update. The previous and current UV positions become a stroke through the existing canvas implementation. The moving ball is an indicator of this programmed brush; it is not a projectile that must collide before paint appears. Manual pigment balls still use their existing drawing interaction.

Automation is opt-in. Museum placements remove the demo's preview camera and environment so they do not replace the museum view or lighting.

The former tutorial is archived under `doc/space/color-recovery-2026-09-09/before/commons/maps/Color_Paint`.
