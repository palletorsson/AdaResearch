# What can a cell receive?

<!-- @rd_artifact -->

Two small squares wait on the tables. Behind them, the same squares wait on curved walls. The room has already enlarged their answer, although neither field has taken a step.

At the side desk, find W. It lies just outside the seeded square. Its V reading is zero in both fields. Press STEP once. On the left, a little arrives. On the right, nothing. Look back at the pictures: can you find that difference without the numbers?

Press +100 and let the local clock complete its hundred updates. The fields begin to part. They began with the same values, at the same addresses. They have the same reaction. What has the right-hand square been denied?

EXCHANGE B turns its neighbourhood exchange on and restores both beginnings. Advance again. The two fields now agree. Switch exchange off, replay, and look for the first place where they differ. We can locate the missing relation before giving the result a name.

In the previous hall a neighbour above half health counted as one contribution to recovery. Here a cell stores two concentrations, U and V. It receives differences in concentration from the four sites beside it. For each field, the sum is its neighbours minus four copies of itself:

```gdscript
return a[y*N+(x+N-1)%N]+a[y*N+(x+1)%N]+a[((y+N-1)%N)*N+x]+a[((y+1)%N)*N+x]-4.0*a[y*N+x]
```

The repeated subtraction matters. If all five values agree, this part of the update contributes zero. A higher neighbour can send a positive contribution; a lower neighbourhood can draw one away. No neighbour has to cross a health threshold to count. How much it differs is now part of what it can offer. Two choices have changed: a cell holds two fractions instead of one bit, and what it consults is not a count but a difference.

There is also a reaction at the address itself. The product U × V × V removes some U and adds some V. A feed term replenishes U; another term removes V. The installation uses the same arithmetic as the project's existing Gray–Scott generator,[^ca-gray-scott] now exposed one update at a time:

```gdscript
var uvv:float=a*b*b
```

```gdscript
next_u[i]=clampf(a+coupling*0.16*lap_u-uvv+FEED*(1.0-a),0.0,1.0)
next_v[i]=clampf(b+coupling*0.08*lap_v+uvv-(KILL+FEED)*b,0.0,1.0)
```

With exchange off, the right-hand field still reacts. But at an unseeded address V is zero, so U × V × V is also zero. Nothing in that local reaction can make its first V arrive. The left-hand field can receive it. This difference is small enough to calculate and large enough to alter the wall. Even the right-hand square's seeded cells cannot keep their V: at feed .037 and kill .060 the reaction alone has no resting state other than full U and no V, so by the end of the first hundred updates that square has nearly faded.

Keep that distinction in hand. “Soft” is not a promise that the rule is gentle or that every boundary has disappeared. Both fields still occupy a 32-by-32 grid. The arithmetic writes into separate next arrays before swapping them into the present. Values are clamped between zero and one. At an edge, the remainder operator wraps the neighbour index to the opposite side. The wall has a visible border that the calculation does not share.

Use VIEW U/V. Another distribution appears without a single new update. The initial view doubles V before mapping it into colour; the U view has its own palette. A colour can saturate while the stored value still has room to change. An image is already an interpretation of the field.

Now walk between the two curved displays. Find a patch on a wall, then look for it on the table. Each pair shares the same texture. At the desk you could take in the small field; here you turn within its enlarged image.

Press COAT. The colour surfaces disappear while the table fields continue. Bring them back. The fixed museum floor carries you through both views.[^ca-soft-coating] The field has become something the room can wear. Perhaps you would keep it here, or want it closer, as a lining against a body. What would you change for that other use?

Try INJECT. Both fields receive the same small second patch. Let it run. We are no longer only watching a prepared beginning; we have entered another event into its history. REPLAY can restore that beginning. It cannot make our first encounter with the difference happen again.

<!-- @the_clockmaker_of_rules -->

Further on, the clockmaker has laid out trays, stencils and small worlds. The brass shapes make reading and writing almost look like trades we could perform with our hands. Find the fractional ring. It is a still radial diagram. Its graded appearance does not demonstrate a running Lenia field,[^ca-lenia] and the ornamental crank cannot advance it.

Compare that invitation with the walls we have just left. Both offer pleasure in a patterned body; their means of producing it differ. We need neither reject the ornament nor grant it an operation it does not have. A diagram can help us imagine the machine, then leave us with something still to build.

<!-- @ -->

The local study holds after 2,400 updates. The museum goes on. We have watched a field change and a room wear its image. Carry a question from those surfaces: could a similar form have another way of becoming?

[^ca-soft-coating]: COAT toggles the wall display meshes. Their geometry stays fixed and has no collision shapes; the museum floor supplies support. Sharing a field texture does not create a sensing or growing body. Those would require additional operations.

[^ca-gray-scott]: The reaction is Peter Gray and Stephen Scott's (*Chemical Engineering Science* 39, 1984), diffused across a grid; the feed .037 and kill .060 the readout prints lie in the range John Pearson mapped in “Complex patterns in a simple system” (*Science* 261, 1993).

[^ca-lenia]: Lenia (Bert Wang-Chak Chan, *Complex Systems* 28, 2019) is a continuous automaton: its cells hold fractions, read a ring-shaped neighbourhood weighted by distance, and grow by a smooth function of what they find there. The still ring on the tray pictures that neighbourhood; nothing in it is being updated.
