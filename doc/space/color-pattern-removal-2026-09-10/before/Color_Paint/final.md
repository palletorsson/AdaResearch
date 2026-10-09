# Before the hand

<!-- @ball_painting_demo -->

A coloured ball is already moving across the canvas. Wait before taking anything. The line changes direction, and the pigment changes colour as it travels. A painting is underway without your hand.

The machine's path comes from two oscillations with different rates. Neither one describes the whole curve alone.

```gdscript
var uv := Vector2(0.5+0.43*sin(elapsed*0.71),0.5+0.4*sin(elapsed*1.13+0.6))
```

The surface receives the line between successive samples. At most thirty updates arrive each second. The moving ball makes the sampling visible; wet paint continues to change the image after a mark is made.

The other pigment balls remain available to take. Try adding a gesture while the automatic painter continues. Your mark and the machine's mark reach the same drawing surface. They arrive by different paths, but neither owns a separate canvas.

<!-- @albers_wall_gallery -->

Turn from that accumulating surface to the Albers studies. Let one coloured area hold your attention, then include its surround. The comparison changes again. Here the arrangement offers a condition to look into; at the canvas, marks keep changing that condition while you look.

Return to the painting. Some of what happened while you looked away is still visible. Some has already flowed into something else.

<!-- @ -->
