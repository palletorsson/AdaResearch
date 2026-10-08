# Encounters removed from the Trace hall — 29 September 2026

Preserved manuscript passages for the stick, head projection and automatic-writing desk. These artifacts are no longer placed in Point_Trace; their source scenes remain available for later use.

## Move the place that draws

<!-- @draw_stick -->

Take the stick. Keep your fist nearly still and turn your wrist. The tip travels an arc. This tool uses the same recorder, but puts the sampling point at the end of a rod. A small turn can become a large mark.

The recording rule is unchanged. We moved the place it observes. Your wrist can stay in one place while the line describes a journey.


## A line you did not hold

<!-- @head_trace_projection -->

Put the tool down. Enter the outlined square beside the plinths. Lean a little, lower your head, then rise. Step outside the square and look back.

A pink line hangs where your head has been. A cyan line lies beneath it. Find the place where you lowered yourself. Can you find that movement in both?

The hand needed a tool. Here the point being followed is in the headset. You were making a line while looking for one.

Both views use the same retained positions. For the floor version, each position gives up its height:

```gdscript
return Vector3(p.x, FLOOR_Y, p.z)
```

`p` is a position measured relative to the square. X and Z remain; the floor height takes Y's place. Positions above one another meet on the same spot below. The line can keep where you went across the room while losing how low you bent.

Walk around what remains. Neither line has shoulders, a face, or a reason for leaning. Yet you may recognise something you just did. You know the movement from inside; another observer has these marks.

Return to the square to begin again. Try giving the floor line a bend. Then try moving without extending it. The same body can make more than one account of its passage.


## The pause leaves a line

<!-- @automatic_writing_desk -->

Come close to the small writing desk. Let the nib cross a little paper while you hold still. Lower your head, wait there, then rise. Your hands can remain empty.

Look for the waits in the writing. A level stretch can keep something the drawing dot left out.

At this desk, time moves the pen across the page. The height of your headset moves the mark above or below the row. The height at which you arrived becomes its starting level. Small movements still belong to the recording; stillness need not be perfectly straight.

```gdscript
_elapsed += delta
```

Each update adds the elapsed time. The nib keeps travelling while a measured height stays the same. Lower yourself and the line bends; stay lower and another level stretch can appear. We have given waiting a length.

The page can also have blanks. When measured input disappears, the clock can carry on without a mark. A horizontal line and an empty interval make different claims about what the instrument received.

A completed page waits. Step away and return to begin another. Give one pause more room than the last. Your reason for waiting stays with you.
