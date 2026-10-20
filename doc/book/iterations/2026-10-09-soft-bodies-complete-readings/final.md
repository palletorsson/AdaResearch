# Soft Bodies — complete reflective sequence

9 October 2026 · Nine halls in canonical spine order.


---

<!-- hall:SoftBodies_Soft_Body_Deformation -->

# What holds a cube together?

<!-- @jelly_cube -->

The cube gives way. A small arm holds one point at its top; the rest of its green surface can move. Follow the indentation as it spreads beyond the place you touched. You have not told each point where to go.

In the last sequence, a body followed from a description, a field or a sample. Here the description also includes conditions under which a body may keep changing. Its surface retains its connections. The positions those connections join are no longer still.

Before changing a setting, decide what you mean by softer. A body that yields farther? One that settles slowly? One that no longer recovers the shape you expected? The room offers separate controls for stiffness, damping and pressure. Your word has gathered several possible observations into one.

Reach toward it. The cube can deform against your hand, but it cannot push your tracked hand out of position. This museum rig places the collision hand at the controller's position.[^hand] One body must accommodate the meeting; the other has already been placed.

The gold attachment remains. The visible arm makes that condition legible, but its appearance alone could not hold a simulated point. A particular vertex has been pinned. We have made a freedom to yield and a place where yielding stops.

The closed surface responds through the engine’s soft-body rules. Turn pressure down to zero and wait. What can the surface keep when inflation no longer helps it?

The mesh has a resolution; the simulation also has a work budget. We can change either. What feels like a quality of matter depends partly on these choices.[^solver] A convincing wobble does not tell us which calculation produced it, or how that calculation would change under another demand.

Restore the settings while the cube is moving. It continues from where it has arrived. The numbers return sooner than the body. If you want the beginning again, more must be restored than the control panel admits.

<!-- @ -->

<!-- @softmill -->

Turn toward the mill. Its moving apparatus brings a repeated encounter to a soft sphere. Stop the drive. The sphere's physics continues; something the mechanism has set in motion outlasts the mechanism's movement.

The cube exposes its coefficients. The mill exposes a source of disturbance. The room supplies further conditions: contact, support, gravity and the points required to stay. Which of these belongs to the object when we call the object soft?

Its changing outline can tempt us to call it free. Yet this surface cannot tear, grow an opening or choose new neighbours through these controls. The freedom is specific. In the next room, we move one of its edges: which points must stay?

<!-- @ -->

[^solver]: The placed cube requests simulation precision 5 and four BoxMesh subdivisions per axis. These are different controls. The project currently selects Jolt Physics; earlier notes describing GodotPhysics3D are historical. See the [Godot 4.6 SoftBody3D reference](https://docs.godotengine.org/en/4.6/classes/class_softbody3d.html).

[^hand]: Both collision hands in `commons/scenes/base.tscn` select TELEPORT mode. The component copies the tracked transform directly in that mode; COLLIDE is another supported choice. This is a property of the prepared rig, not a necessary asymmetry in every VR system. It is source evidence, not a completed physical-headset contact test.


---

<!-- hall:SoftBodies_Cloth_Physics -->

# Which points must stay?

<!-- @cloth_straps -->

Eight strips hang in a rank, each a forearm wide and twice your height. Their edges overlap, so from straight on the rank reads as one surface. Walk along the front of it. Walk behind it. Unlike the cube, this surface does not close around an inside. There is no enclosed volume for pressure to inflate.

Stay with one strip long enough to watch it. There is no motor here. The strips were built hanging and have been settling under gravity ever since; a sheet this long can keep stretching and swinging well after it was made. Whatever shape it has now, it has not finished arriving at.

Look up to where it meets the top. That edge does not move at all. Everything loosening below it begins at that stillness.

So something up there is being held. Before naming it, find out what.

Press **SUPPORT**. The gantry the strips appeared to hang from vanishes, and they go on hanging — the held edge in the same place, the rest still free to move. Press it again for a hoop, again for a mast. Three pieces of architecture, and not one of them changes where the cloth is held.

The attachment rule reads the strip’s original coordinates and holds its eight upper points. The frame was built for you to see. You have taken the apparent support away and watched the attachment survive it.

Press **SUPPORT** once more and a wall arrives behind the rank. The opening behind the cloth is now occupied by a solid surface. The pins stay where they were, but the passage changes. The pin rule can ignore a wall that a body must go around.

Now change what is actually holding. **PINS** keeps only the two points where that top row reaches its outer edges: from eight to two. Watch the top edge while it happens. Six points that were held can now sag between the two corners. The edge remains, but its straightness was being maintained.

Then press **RELEASE**, and the last two let go.

The material settings remained the same. Eight points were forbidden to move, then two, then none. What looked like a quality of the cloth belonged partly to the arrangement holding it.

The strips can fall now. **REBUILD** makes a fresh hanging rank. Keep its top row held and try **STIFFNESS**. We can now compare two ways of changing the silhouette: change how strongly the surface resists deformation, or change which of its points may move.

When we call an object compliant, how much of that belongs to the object, and how much to the arrangement holding it?

<!-- @ -->

<!-- @softstopscene -->

Four bodies stand nearby. They began falling when the room loaded, and by the time you reach them their timers may already have stopped them. These are soft spheres kept from the earlier collection, not woven cloth. You can arrive after the event and still meet its shape.

A narrow rail crosses each landing. Look for where a body has come to rest: on the bar, against a post, or on the floor below. Then press **LANDING**. It exchanges the support and starts a new fall; the pan that arrives offers a floor between two walls. Stay for the fall this time.

Their stop raises damping and stiffness. The quiet shape is still a simulated body. Later we will keep a separate record of a surface; here we have changed the conditions under which it moves.

Two questions leave this room together. What makes a body deform, and what makes us stop looking?

The raised cells farther into the hall ask your feet to negotiate another boundary. What the pins hold for the cloth, the floor must supply for you.

<!-- @ -->

<details markdown="1">
<summary>Further encounter — A little give</summary>

<!-- study-spine:tension_membrane -->

<!-- @tension_membrane -->

Four slender posts hold a dark, narrow-waisted surface. Between them it has sunk towards the floor. The pink bead at its edge waits within reach. Pull it towards you. A crease travels back towards an attachment that does not move.

Let go. The bead moves without your hand, passes through a lower position, and comes back more quietly. Stay for the small movements after the large one.

Add a load. A dark weight gathers beneath the middle. Pull again and release. The same four points are held, but the surface now has something more to carry. It settles lower. Removing the load allows another return.

Nengudi's stretched hosiery brings a used material, close to skin, into this question of how far something can give. Our surface has no wearer and no remembered damage. Each return is calculated from lengths that the code has kept intact. To recover here is to approach an arrangement the program still remembers.

The anchors have asked nothing of themselves. We have asked the middle to accommodate another weight.

<!-- @ -->

</details>

Carry the fixed edge into the next hall. There, the support itself moves, and the bodies hanging from it will know.

<!-- @ -->


---

<!-- hall:SoftBodies_Carusell -->

# The support moves

<!-- @revolving_joy_ride -->

Stand where you can see the hub and the hanging bodies together. The ring turns because its angle is advanced by the program. The joints and deforming bodies respond to a support whose motion has already been prescribed. The links meet at pin joints. They hold two attachment positions together while allowing the links to turn; they do not impose a hinge's single axis. The hub is different in kind. Its angle is written each step; the hanging bodies cannot push back on that command. Their response can reach your attention without changing the rate that produced it.

Lower the SPEED. Then REVERSE it. Do the bodies immediately take up the new arrangement? STOP sets the angular rate to zero, but it does not erase velocity, gravity or contact. The support can stop commanding a new angle while its consequences continue. Stopping the instruction is not the same as ending the event.

You have turned a body before. Here the turn reaches other bodies through an attachment. They meet the next movement with whatever the last one has left in them.

Change STIFFNESS or PRESSURE while watching a particular body. We should not attribute every difference to speed when we have also changed material coefficients. The apparatus makes a limited experiment possible, provided we remember what we touched.

This carousel offers an image of freedom through motion. Its moving parts also show how motion can be organized by obligations: a joint, a pin, a driven hub. The question is which relations can move, and which relations move them.

<!-- @ -->

<!-- @cloth_straps -->

The cloth strips nearby retain a fixed support. Return to them after watching the ride. They make the contrast available at the same bodily scale: a surface can respond while its boundary remains still, or respond because its boundary is driven.

The sticks, pick-up cubes, flex pad and soft mushroom remain part of the collection. They are opportunities for further encounters, rather than evidence that every visible object runs the same solver. Begin with one comparison you can follow, then widen it.

In the next room, the enclosing architecture takes on a deformable surface. The distinction between a body and its surroundings becomes harder to maintain by pointing.

<!-- @ -->


---

<!-- hall:SoftBodies_Obsticals -->

# The room has a body

<!-- @breathing_room -->

Two pink slabs make a passage. Stand where their fixed points and moving surfaces remain visible together. The walls receive the same rising and falling pressure, but they do not meet it as identical bodies. Their attachments and material settings were chosen differently. Before entering, watch a complete cycle.

AMPLITUDE changes the range of pressure. RATE changes the pace of its repetition. HOLD DRIVE keeps the last command in place while the surfaces continue responding. A held instruction can have consequences that are still moving. RESET PHASE takes the clock back to the beginning; it cannot take the encounter back with it.

The earlier sine spaces gave a position to each part. Here the wave supplies a condition. The place the surface reaches is produced through that condition, its attachments, gravity, contact and what the preceding movement has left behind. The shape is not waiting inside the sine to be revealed.

Calling this breathing invites a bodily recognition. Nothing here needs air, and no sensor decides when the room should inhale. Yet a change in the space around you can make your own breathing noticeable. The resemblance can affect you without explaining the mechanism.

Change STIFFNESS and return to the same pressure. The command is familiar; its reception has changed. How much room remains is not written on the amplitude control. We have to look at the surface and at the body trying to pass it. What a container permits depends on more than its outline at rest.

<!-- @ -->

<!-- @softbody_gallery_part2 -->

The nearby contact gallery keeps other combinations visible: soft bodies meet rigid obstructions. Look at one named cell before surveying the whole array. The specimen, its support and its settings constitute a particular test; their variety is not a single scale from hard to soft.

The flag dancer remains as another encounter with a driven system. Together these objects begin to distribute softness across the room rather than confine it to one specimen. Yet the floor that carries you through this hall does not deform. A deforming wall and an onward route make different promises.

Next we will hold and replay a contact experiment. A spectacle of differences becomes more useful when we can identify which differences were introduced.

<!-- @ -->


---

<!-- hall:SoftBodies_Obsticals_Part2 -->

# Same fall, another encounter

<!-- @softbody_gallery_part2 -->

Twelve encounters wait in an array. A sphere meets a cube; another body catches a corner. One folds around its support, another falls beside it. The regular spacing makes them look ready to compare. What has actually been kept the same?

Names arrive before contact. High Drag invites us to expect resistance. Vacuum begins with the same zero pressure used as the gallery's default: its name supplies an event the setting has not specified. A familiar word can organise what we see before we have looked at what the body does.

Choose two cells. Their surfaces may differ because of material settings, contact geometry, starting position, or several of these together. The array gives these differences equal places without giving them equal explanations. We can enjoy their abundance and still be precise about the claim a comparison can support.

REPLAY makes another beginning from the declared recipe. It replaces the bodies that fell; it does not persuade their folds to become innocent again. Move a point into the next fall and your hand enters the conditions. What seemed like an inconsistency may be evidence that something else participated.

An awkward fold can hold attention longer than the intended demonstration. There is no need to make it prove a defect in the body. Walk around it. Notice the support, the mesh and the moment at which you started looking. A body can exceed the name we gave its cell while remaining entirely consequential.

To isolate one difference, we temporarily narrow the encounter. That choice makes a question answerable, and leaves other questions outside the experiment. The limit belongs to the comparison. It need not become a demand that every body meet the same conditions or yield the same result.

A number taken at one moment can remain while its subject continues changing. In the next room, the kept result begins to look like the object itself.

<!-- @ -->


---

<!-- hall:SoftBodies_Playground_of_Joy -->

# When does a body become a form?

<!-- @rounded_softbody_test -->

The rounded body continues to respond while an instrument colours its surface. MEASURE changes what is made legible: strain, collision or volume. The body has not acquired a new material because we changed its reading.

Keep the reading on volume and press FEEDBACK. Now the instrument acts back: it adjusts pressure to bring its reading toward the recorded value. Switching it off restores the selected pressure. It does not retrieve the body you had before.

What has been asked to stay the same? This instrument measures the box around the vertices, aligned with the world's axes. It does not measure the space enclosed by the skin. A fold can change the body without changing that box. A number that helped us look has become a number the body is asked to follow.

Put a hand into the body and hold the grip. The surface is pushed away from your hand. Change the strength, or turn that intervention off. Watch the silhouette as well as its colours. The instrument can bring a small difference forward; it can also make its chosen quantity seem like the whole event.

The branching study and field sculpture remain nearby. A branch recipe, a deformed surface and a sampled field may resemble one another without explaining one another.

<!-- @ -->

<!-- @frozen_glass_vessel -->

The glass vessel has already stopped. You have met it before in Form Finding, where a chosen number of steps helped produce its shape. Here DURATION lets you reconstruct it after forty, two hundred or four hundred steps. Keep gravity fixed and change only the stop. There was no final shape waiting for the clock to uncover it. There were successive states, and a decision to keep one.

Last room, a number stayed while a body continued. Here a whole surface can stay. Beside the encounter, the tutorial makes the difference visible: one shape goes on responding while its copy remains. The copy gives you time to look. Its stillness is something we have done to the record.

The connections between its vertices remain. The previous positions, the forces and the successive corrections do not travel with this copy. Its surface bears consequences of the process without supplying a complete account of it. Different histories can arrive at similar shapes. Looking more closely cannot always recover what was not kept.

Walk up to the installed glass skin. Its surface can meet your body; transparency has not made it passable. Look for a mouth. The specimen began as a closed sphere, and deforming it has not cut an opening. Calling it a vessel invites a use its construction has not provided.

A frozen result lets us look longer. It also allows the timing of a decision to disappear into the apparent permanence of a thing. The caption keeps the selected step beside the shape. What else would we need to keep if another person were to question how this object came to stand here?

The row of four shapes lets the stop remain visible as a choice. At another bench, the same stop receives another pull. Beside them, a skin gives way to its triangle edges. Changing the display does not change the recorded positions. It changes what we can notice about them.

The gallery brings back a branch and a cellular rule. Their connections have become something that can bend or hang. A branch recipe supplies an arrangement; it does not tell us how that arrangement will bear its own weight. Switch back to the starting shape. What looked like a finished sculpture becomes one state among others again.

Next, the room offers bodies that look alive. We carry this hesitation with us: a convincing appearance may leave its means of production out of view.

<!-- @ -->


---

<!-- hall:SoftBodies_Affect_Theory_Visualization -->

# What makes this look alive?

<!-- @radiolaria -->

Something bristles. A pale body seems delicate; another looks as though it might catch on your skin. The forms invite recognition before explanation. Their rings and spines recall the visual repertoire of Haeckel's plates, although this program builds its own specimens from geometric recipes.[^haeckel]

Walk between them before touching the controls. There are nine specimens drawn from six families. Repetition can make them look related. It does not mean that one descended from another, or that any of them developed by growing.

Stop ROTATION. The bodies hold their orientations. Turn EFFECTS off and let the particles clear. What remains of the impression that something was happening here? A body need not move to draw a response from you. A static spike may be enough to change how closely you want to approach.

Bring your hand to one. The form does not yield or resist; its visible skin has no contact surface. Earlier, the jelly moved away from your hand. Here your hand passes through. What you expected to feel and what the program supplies come apart.

Place the surface you kept in the previous hall beside this encounter. Give it a second copy with the same saved positions. Let one turn, then change its colour with the turn removed. We have given it a different presence without changing the record from which it was made. Does knowing this settle what it feels like to stand beside it?

The fixed seed makes a construction available again. It lets us ask which difference belongs to a palette and which to another draw. But a repeatable recipe cannot repeat the visitor's response. You bring other encounters with shells, ornaments, infections, toys, bodies you wanted to touch and bodies you were warned against.

A feeling can be real without confirming the explanation that arrived with it. The form has affected you; that does not tell us that it feels. Nor does learning its construction require you to stop caring about it. We can remain attached while becoming more exact about what we have encountered.

This matters when resemblance begins to decide which bodies deserve attention. Familiar signs can make recognition easy; they can also make an unfamiliar body harder to meet. The generator offers a repertoire. We can change that repertoire, and we can notice where our willingness to attend has already narrowed it.

The copied surface can remain after its source has stopped. In the next room, a pattern may need continuing exchanges to persist. What must keep happening for a form to stay recognisable? Carry that question beside the one this room leaves us: what have we learned to see in it?

<!-- @ -->

[^haeckel]: Ernst Haeckel, *Kunstformen der Natur*, [plate 1, Radiolaria](https://www-archiv.fdm.uni-hamburg.de/b-online/haeckel/Tafel_001.html), reproduced by the University of Hamburg. The project's generator identifies Haeckel's illustrations as an inspiration. The resemblance discussed here concerns a visual vocabulary; these specimens are not biological reconstructions.


---

<!-- hall:ProceduralGeneration_Reaction_Diffusion_Systems -->

# What keeps a pattern changing?

<!-- @turing_pattern_generator -->

A small patch interrupts the pale field. Press STEP. Almost nothing seems to happen. Press a hundred steps. The boundary begins to matter. A name such as Spots or Maze may already have told you what to expect, but the field has not promised to become its label.

There is no finished drawing waiting underneath. Each address receives differences from its neighbours while local reactions consume, replenish and remove what is stored there. The pattern is something those operations make possible. The starting disturbance matters too: an entirely uniform field of U = 1 and V = 0 would remain uniform under this rule.[^model]

Last hall, a still surface acquired another presence when it turned or changed colour. Here, what persists may require continuing exchange. A familiar outline can survive while the values supporting it keep changing. A still image cannot tell us whether we have stopped a process, reached a steady state, or caught a brief resemblance.

Pause at the comparison. Both fields receive their neighbours' differences. In one, the local reaction, supply and removal continue; in the other they are absent. The second field has not stopped. Its initial difference spreads. What does the first keep making that exchange alone does not maintain?

The names tempt us to recognise a living skin: spots, stripes, something dividing. Metabolism offers an association with what must continue for a form to persist. The quantities here belong to a limited chemical model; the association asks us to attend to its exchanges.

Still, the encounter changes the question. We have spent several rooms asking what a body keeps when it yields, falls or is recorded. Here we can ask what has to be supplied for a difference to remain. Independence looks less obvious when the conditions of persistence are visible beside the form.

Change a rate, then return to the same beginning. Change the beginning, then keep the rates. Each comparison lets one relation become legible. Even the edge has been arranged: a value leaving one side meets the other. The field’s apparent continuity depends on that return.

<!-- @ -->

<!-- @reaction_diffusion -->

Elsewhere in the room another field runs to its own clock. Similar marks do not make the two displays witnesses of the same event. Nor does a pattern on a surface give that surface the ability to bear your weight. A visible likeness can open an association; following it requires us to say which operation crosses the gap.

Here we have watched what continuing exchanges can sustain. The next hall asks what a rule can reconstruct. We leave these concentrations here: a different field will be evaluated throughout three-dimensional space. Choosing a boundary gives us a surface to move around. Who chooses where it appears?

<!-- @ -->

[^model]: The installed artifact implements a discretized Gray–Scott model. See John E. Pearson, [“Complex Patterns in a Simple System”](https://arxiv.org/abs/patt-sol/9304003), 1993. Its model belongs to the wider study of reaction–diffusion pattern formation; it is not Turing's original set of equations. The uniform-state claim follows directly from this implementation's update with U = 1 and V = 0.


---

<!-- hall:Topology_Entropy_Morphogenesis -->

# Who connected the controls?

<!-- @entropy_morphogenesis -->

Choose an opening in the pale surface. You can see the room through it. Touch S and the opening changes: an edge advances, a neck draws in, another passage comes into view. The single control makes the transformation feel like one decision.

Read the numbers beside your hand. Several things moved together. Someone connected them before you arrived.

The vessel kept a moment as a record. The previous room asked what continuing exchange could sustain. Here the surface waits until a changed description asks it to be built again. Its appearance may suggest growth, but each reconstruction begins from the spatial rule. What we preserve is a way of making the form; that description is also where we can intervene.

Keep the field and move the cut. A different surface appears without the values underneath becoming different. Change the frequency instead and those values change across space. The two actions can produce equally striking images. They ask different things of the system.

This is where the small paired specimens help. One keeps its recipe while the other receives your intervention. A hand can make a complicated change quickly. A comparison can slow that change enough to see what the gesture contained. Neither speed nor hesitation has to belong permanently to the interface.

The source calls its master value entropy. Here the word names a chosen path through settings. No distribution is measured to produce it. We can be drawn to the suggestion of disorder becoming form while still asking what the control actually joins. A name can open an association. It can also make an arrangement seem inevitable.

There is pleasure in leaving that arrangement. Keep the disturbance and change the cut. Keep the cut and change the spacing. Retain a result the default path passed by. An interface that lets you separate its connections makes room for intentions its author did not anticipate.

Now return to the large surface. An opening in an image is not yet a passage for your body. The mesh, its collision surface and your scale have to meet. A finer sampling may describe the boundary differently; it does not promise that the opening will admit you. You must try the relation at the scale where it matters.

Across these rooms, the point has joined a yielding body, held a boundary, moved with a support and helped keep a moment as a sculpture. A surface could seem alive because it turned. A pattern could persist because exchanges continued. Here a control gathered several choices into one movement of your hand.

We leave with those differences still available. The next body need not begin from nothing. We can carry a point, a relation, a saved shape or a rule—and ask which part we are willing to let change.

<!-- @ -->

