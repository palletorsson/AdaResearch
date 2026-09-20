# When a line acquires walls

<!-- @lsystem_dungeon -->

Can a line admit you?

Four pale segments lie on the floor. One leads from the entrance to a junction; two turn away from it; the fourth continues ahead. You can already follow them with your eyes. On the flat plan, your feet can also ignore them. There is no wall asking you to choose.

Press BUILD. A low solid base and glass rise along the boundary. Enter beside the control desk, take a side branch and come back. The junction is open; the side branch ends against a wall. The straight continuation has another opening. Those different endings were decisions someone had to supply.

We have brought the turtle's saved position and direction from Growth. The previous hall changed how it read forward. Here we keep one reading and ask what must be added around it. The dungeon's branch rule rewrites F once into this short program:

```text
F[+RF][-RF]F
```

The first F reaches the junction. The bracket saves that position and direction. A turn, a room marker and another F make the first side branch; closing the bracket returns the turtle to the junction. The second bracketed group does the same on the other side. The last F continues the stem. Each movement becomes four metres in this study.

Two Rs appear in the sentence. Find the two places they mark. Follow the brackets carefully before deciding that there must be two rooms.

In the dungeon's actual interpreter, R does this:

```gdscript
rooms.append(pos)
```

It records the current position without moving. Both branches begin at the same saved junction, so both room records have the same address. A list can count two instructions while the floor contains one shared place.

Leave the brass frame and press ROOMS. The junction spreads into a square, 2.8 metres across. Enter again and step away from its centreline. There is now somewhere to pause while another route continues through. The program has acquired a spatial use through the footprint we assigned to a mark. The mark itself did not contain a gathering, a cupboard or a private retreat.

The construction collects the floor cells covered by all corridor and room footprints. Shared cells are kept once. At each cell edge it asks whether another occupied cell lies beyond it:

```gdscript
if occupied.has(cell + direction): continue
```

An internal edge receives no wall. That small refusal keeps the junction open. At exposed edges the builder places walls, except at the two deliberately chosen main entrances. The grammar supplies the records; the construction supplies a boundary policy. Calling the records architecture did not perform this work for us.

Return outside the frame and try WIDTH. The clear width cycles through 2.2 metres, 0.4 metres and back to 1.4. Watch the pale centrelines: they stay where they were. Try entering the narrow version. The desktop body's collision capsule is sixty centimetres across. A forty-centimetre passage cannot admit it even though the line continues without a break. Opening the junction into a room will not repair that narrow entrance.

This gives us two descriptions of connectivity. Every branch still meets the same junction in the plan. The space available to this body has changed. Its size participates in what counts as a passage. A different body would require another test. More branches would not answer the question that width has made concrete.

The controls refuse construction changes while a visitor remains within the study. Leave its frame, then press again. That rule belongs to this space too: the person at the desk cannot silently rebuild the walls around someone inside. We can examine the rule and imagine other arrangements for agreeing to a change.

PLAN removes the built walls and slabs; RESET returns to the opening comparison. The museum floor remains beneath every state. Behind the study, the original miniature dungeon rests on its plinth. Its more elaborate grammar fits into a small display. Look down at it with the narrow entrance still in mind. A plan can be legible to an eye long before it is usable by a body.

<!-- @ -->

The retained orthogonal structure, folded dragon path, seed and mesh studies offer further readings. We will return to them. Next, in Competition, we ask what happens when a rule's next move must meet a world that other growth already occupies.
