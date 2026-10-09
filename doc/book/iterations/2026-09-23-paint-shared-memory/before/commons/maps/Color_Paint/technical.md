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


## Manual input and spatial corrections, 10 September

The automated studio config places thirty balls in two rows at about 1.2 m, on a tray. Their tips require pickup, so parked balls no longer project unintended marks. Dropped balls return to their own saved tray transforms. Ordinary non-automated spawners keep the existing behaviour.

BallPaintTip resolves PaperDrawSurface from the drawing area hit by its ray, resetting interpolation when the receiver changes. It uses get_uv_from_world_pos rather than a hard-coded square aspect ratio. This also prevents one canvas from receiving gestures aimed at another. The automatic root still targets only its own canvas.

The retained image is viewport feedback, not a stroke-history stack. The shader's five-sample blur, vertical shift and fade toward white are applied per rendered frame; flow_speed is not multiplied by delta. Automatic path time is accumulated from delta, so rendering rate can alter their relationship. This is not a physical pigment or fluid simulation.

The probe moves a real pickable pigment with a supplied grabber, tests its ray against the real canvas, deliberately supplies a wrong cached receiver to verify retargeting, and checks manual pigment in GPU output after release. Brush size and snap resolution are fixed in that fixture for a repeatable comparison; live balls retain varied settings. Tracked-controller usability remains untested.
