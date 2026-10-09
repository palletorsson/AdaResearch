# The same difference, somewhere else

Can something move without its vector changing?

We have given points addresses, transformed shapes, made patterns and followed changes through time. Now keep two addresses together. One names a beginning; the other names an end. What can we carry forward from their relation?

<!-- @VectorBasics -->

At the first bench, move either pin of the small arrow. Watch the large wall. Two yellow arrows respond: an elevation view, XY, and a floor-plan view, XZ. They are two projections of the same displacement. Predict which view will change most before moving the tip again.

Press **SHORT**, then **LONG**. The displacement changes from a quarter metre to one metre without changing its direction. Look between the hand-sized arrow and the wall. The pictures have different display scales; their shared input is the difference between the pins in world coordinates.

Press **SHIFT**. Both pins move together by twenty centimetres along the bench. Their addresses change. Does the wall have anything new to report? Press again to return them. An unchanged picture can be evidence that the machine is doing exactly what we asked.

Only now press **PARTS**. The components and magnitude appear on the console; coloured legs make the components visible in each projection.

```gdscript
var displacement = end.global_position - start.global_position
```

Subtraction keeps the difference and discards the two original addresses. This is a free displacement vector: it can be represented at another origin without changing its direction or length. Later, where a force is applied will matter. We should not carry this freedom into every physical question without testing it.

The wall keeps the world axes fixed. Turning the bench changes how its local directions relate to that frame. A screen on a wall is another arrangement inside the room, not a transparent window onto mathematics. One projection leaves out Z; the other leaves out Y. Neither alone tells the whole displacement.

Now press **ZERO**. The pins coincide, and the displacement has length zero. There is no direction for the yellow arrow to show. If you press SHORT or LONG from this state, the interface chooses the direction (1,1,1), normalised. That direction is a convention supplied by the control, not information rescued from zero.

The wall samples the pins twenty times a second. An update can reach the small arrow before it reaches the large picture. If a projection exceeds the drawing window, the wall limits its drawn length and labels the clipping; the component numbers retain the measured displacement. The representation has a capacity, and it says where that capacity ends.

<!-- @ -->

The coordinate frame, route courier and length lantern remain nearby as supporting encounters. A path has an origin and a history even when a displacement summary does not keep them. What was useful to discard for this question may be necessary for the next one.

<!-- @vector_normalize_demo -->

At the second primary, compare the input vector with its normalised companion. Change the input direction and length. Which changes reach the companion? Which do not?

The operation divides a nonzero vector by its own magnitude:

```gdscript
var magnitude = v.length()
var unit = v / magnitude if magnitude > 0.001 else Vector3.ZERO
```

Length is removed while direction is retained. The sphere and rings provide the diagram's reference for unit length; they are part of the display's scale. A long input can become shorter and a short input longer. Normalisation is not simply shrinking.

This implementation also chooses a threshold: magnitudes at or below 0.001 return zero. It does not normalise every tiny nonzero input. The boundary keeps the calculation usable while treating a neighbourhood around zero as having no available direction. The numeric output now reports the computed length, including zero, rather than always printing one.

<!-- @ -->

We have made something reusable by leaving information behind. First the two addresses, then the magnitude. Reuse is powerful because of these reductions; the reductions also need to remain open to inspection.

Next, in **VFM_02_Operations**, vectors meet. We will compare a composed displacement with its separate contributions before asking a force to change a body's movement. The arrow on the wall can eventually become an instruction to the room. Today it describes; it does not push.
