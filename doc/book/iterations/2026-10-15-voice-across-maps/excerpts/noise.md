Two rings stand upright on a bench. There is room to stop and see both before moving closer. One wears its variation as small folds. The other keeps a round outline while colour travels across it. The columns behind us asked where change enters a body. Here the question becomes more intimate: could these two surfaces be receiving the same thing?

![The upright relief and colour rings seen together from the standing approach inside the museum.](/book-images/figures/Noise_One/standing-pair.png)

Watch a bright patch arrive. Then press FREEZE. The rings hold that moment; the museum carries on. Two pale markers indicate matching coordinates. SAMPLE moves them together around the rings. Before reading the plate, look for a place where the folded ring turns inward and its coloured neighbour goes dark.

The plate gives a signed value. A negative number can become an inward movement. What would negative brightness look like?

At first this colour rule makes every negative sample black. Values that differ on the plate share the same darkness. Their differences have reached the display and been folded together there.

Press REMAP. Some of the dark surface returns. The number at the marker does not change. Neither does the relief. A different reading has made room for something that was already being computed.

```gdscript
func colour_of(value: float) -> float:
	return (value + 1.0) * 0.5 if _remap else maxf(value, 0.0)
```

Read the two invitations inside that line. `maxf(value, 0.0)` gives every negative value the same destination. `(value + 1.0) * 0.5` carries the interval from minus one to one into the interval from zero to one. Minus one becomes black, zero becomes halfway, and one becomes full brightness. The colour channel had room for the difference once we changed its address.

This is a small freedom with a specific mechanism. No hidden body has been rescued whole. We have changed what the display distinguishes. Lighting, the changing hue, screen precision and our eyes will still mediate what becomes visible. The plate reports the brightness factor before those further encounters.
