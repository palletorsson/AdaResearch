DRAFT 2026-10-01. Unreviewed; this hall is in no sequence. Every count below was read back from the built hall on that day.

# A body as a list of operations

<!-- @mesh_grammar -->

Five bodies stand across the entrance: an icosahedron, a cube, a sphere, a disk, and a disk cut into rings. Nothing has been done to any of them. Each is a seed, the mesh a grammar is handed before its first rule, and one word in the map chooses between them.

Count the triangles on the cube. There are twelve. The icosahedron has 20 and the sphere 352. Before any rule has run, the seed has already settled how many places a rule will find to act.

<!-- @ -->

<!-- @mesh_grammar_bench -->

The bench behind them shows where this is supposed to lead: a box that has grown boxes. It is rebuilt from chance at every visit, so the one in front of you has not stood here before. It is made by a shorter program than the rest of the hall uses, a box that calls itself. Take it as a picture of the claim, apply a rule and apply it again, and walk on to see the claim taken apart.

<!-- @ -->

<!-- @mesh_grammar_artifact -->

Now one icosahedron stands fourteen times, in seven rows. Read each row from your left to your right.

Every body here is a file of a few lines: a seed, a number of generations, and a list of rules. A rule has three parts.

```json
{"op": "extrude", "selector": "up", "params": {"distance": 0.3, "scale": 0.7}}
```

The selector says which faces. The operation says what happens to them. The parameters are the numbers the operation needs. The grammar applies the list from top to bottom, once for each generation, and keeps a copy of the body after every generation, the seed included. Nothing in this hall lets you step back through those copies, which is why the steps stand side by side on plinths.

Station 01 has an empty list. Station 02 has one rule, split: every triangle becomes four through the midpoints of its edges. Look for the difference from across the aisle and you will not find one. The outline is the same and the twenty planes are the same. Twenty faces have become eighty and nothing has moved. A split only gives later rules more to hold.

03 and 04 change the outline and the surface. Extrude pushes the upward faces out along their normals and narrows them, and a second rule pushes again whatever the first one tagged as a top: six spires. Inset draws a smaller triangle inside every face and leaves it lying in the same plane. The outline has not changed, but each face now has a middle that a later rule can ask for by name.

05 uses that name. Inset the upward faces, then extrude the faces tagged `inset`: six blocks rise, each from the middle of its face, with a shoulder around it. 06 holds the same two rules and the same numbers in the other order. Nothing rises. When the extrude runs, no face carries the tag it asks for, so it selects nothing and does nothing; the inset that follows draws six plots that are never built on. The program did not fail. The two files differ only in which line comes first, and one body has 92 faces and the other 56.

07 pushes every vertex along its normal by the value of a noise field at that point. The seed has twelve vertices, so twelve points move, and the result is an icosahedron with its corners out of place. Compare it with 01; you may need to. 08 splits twice and then applies the same push from the same field: 320 faces, 162 vertices, a stone. The field did not change. What changed is how many places it was given to act.

The application this project began from names this in one line: "the trade-off between several polygons (polycount) and the possibility of deforming a body smoothly." Here it can be counted. The smooth body costs sixteen times the triangles of the stiff one, on every frame, for each eye. Then look into the hollows of 08. No rule in its list checks whether the surface has been pushed through itself, and a view from outside will not tell you.

09 extrudes and then deletes what it has just made. The tops are gone and six open chimneys remain. Look in: there is nothing inside, because the body was a skin from the start. 10 replaces each upward face with a tube. 11 adds a rule that asks for the faces the first one tagged as tips. A tip is a fan of five triangles, so each tube receives five thinner ones, thirty in all, lying close because their faces point the same way. The bend of each tube is drawn from chance at every build. Which faces grow is not.

12 is the list of 05 run for two generations. In the second, the selector asks again which faces point upward. This time the tops of the six blocks answer, and eight triangles on their sides. The thirty-six slivers of shoulder are inset again and then left as they are: the extrude skips any face smaller than a hundredth of a square metre, a threshold that is in the operation's code and in none of these files. The rule keeps no memory of what it built. It is given a body and a direction. The station stops at two generations because the placeable artifact caps the count at two, a limit set for the headset's frame time and not for the form.

The last row holds one operation under two selectors. In 13 every face of a once-split seed is extruded: eighty studs. In 14 only the upward faces are: twenty-four studs and a bare underside. The word in the file is `up`. What it means is in the code that reads the file:

```gdscript
"up":        return MeshSelector.by_normal_direction(Vector3.UP, 60.0)
```

Someone chose sixty degrees. Someone chose that up is the world's up and not the body's, and that a face is either in or out. Eight of the fourteen stations select by that word. The decision is in none of their files.

<!-- @ -->

<!-- @mesh_grammar_room -->

Walk into the tower. It has no collider, so you pass through it. Like the bench it is a box that calls itself, six levels deep, and it will be a different tower the next time.

Use it to ask what none of the fourteen lists can say. A rule in this grammar selects faces and replaces them with more faces. It can grow a tube and cannot join two tubes. It cannot close a ring or make a handle. It cannot notice that two parts occupy the same space. It has no way to bring in a part that was never a face of the seed. Every body on the plinths is one skin that has been divided, pushed and cut, and bodies made this way resemble each other more than they resemble anything outside the grammar.

A list of operations is also a record. It says what was done, in which order and with which numbers. Someone who was not there can read it, change one line and run it again. Few bodies offer that. What the list does not record is why sixty degrees, why upward, why these operations and no others. Before you take the exit, choose one station and say what you would have to add, to its file or to the code that reads it, for it to grow something its list cannot.

<!-- @ -->
