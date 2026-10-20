# Which of these is the lamp?

A sphere, a cube and a sofa wear the same pink circles. Mint light gathers toward their edges. Above them, chairs hang in pearl rings and a sheet of water forms a ceiling. You have met most of these operations before. Here they are being made to agree on a room.

<!-- @shader_composition_stage -->

Start at the bench. Take DOTS down to zero. The marks leave; the bodies remain. Remove RIM, then GLOW. Put one back. You can find the contribution again without having to undo the whole appearance. There is a difference between knowing a recipe's ingredients and being able to decide how much of each belongs here.

Walk around the sphere and cube. The sphere offers a curved band to your eye. On the cube, a face can become the band. A single material does not give every body the same appearance: it encounters different normals, addresses and proportions. The sofa receives the circles through a room-based projection because its source mesh has no UV coordinates. Even sharing a rule requires a decision about how that rule reaches a body.[^recipe]

Press SETTING. The suspended chairs and water ceiling disappear; the backdrop becomes grey. The three main bodies keep their material, positions and lamps. Then bring the surroundings back. The circles may feel quieter or louder, cheaper or more ceremonial. Which change belongs to the object, and which to the place you have given it?

PALE makes another kind of comparison. It changes the ground colour and roughness as well as removing the three additions. You cannot attribute its whole effect to the absence of glow. Return to one slider when you want to isolate a contribution. Return to the whole room when you want to compose.

The small study nearby puts those decisions into the point you have carried through the book. Its position chooses three amounts. Trigger removes the additions without erasing that choice; trigger again and they return. Nothing has become more solid or less solid. The recipe displaces no vertices. This time the material change belongs entirely to the surface's response.

So, which of these is the lamp? The material can add visible brightness without a lamp shining on it. That does not make it a light source for the sofa beside it. In this comparison, emission brightens the surface that owns it; the separate lamps supply incident light. The mint edge is not proof of a hidden lamp behind the body. It is a relation between a normal and your eye.[^light]

Pink does not settle what the room means. Neither does excess. A body can be brightly dressed and tightly prescribed; a changeable appearance can still be offered through a very small menu. Here you can inspect some of that menu, refuse a preset, keep an awkward combination. Those permissions are concrete. What you make of them remains open.

<!-- @shader_12_pinkextravaganza -->

The older collection has no control bench. A title in pink capitals floats above a sagging sphere, a ring, a black cube, an enormous sphere and a sheet of water on the floor. Its notes promise numbers pushed past their intended ranges. Hold that claim. First look at what the surfaces actually do.

The floor water comes to your ankles and passes through your shins. Its notes say it refracts wrong on purpose. Look at the floor through the water, at the edge where the sheet ends. Nothing is bent by a refraction calculation. Three sines move its height; noise and a view-dependent colour help it read as liquid. The separate water overhead uses the same shader. Neither sheet has the bathhouse toys' buoyancy, and neither remembers a splash. At the project's clock wrap, their phases jump.[^water]

The large sphere swirls, glitters and breathes. Some of its colour responds to the lamps; some is added as emission. The sagging sphere asks each vertex how far down it should be at this moment. Its surface looks yielding, but no weight pulls the sag. The pearl ring adds shifting colour. The black cube gives its nearly edge-on faces a rainbow. Their titles invite bodily and material associations; their operations answer only part of each invitation.

Now the claim about excess. The collection's builder loads those five shaders without setting their material uniforms. The mesh sizes and placements have been arranged, but the materials begin at their declared defaults.[^defaults] The excess was already chosen by whoever wrote those defaults. Taste did not arrive afterward to judge an innocent calculation. It was there in the first numbers.

There is also a small motion with accumulated state. The turning objects bob because their script adds a displacement every frame. An earlier addition remains in the next position, and the size of that bob depends on the frame rate. This differs from asking a shader for a position directly from the clock. It is a reminder that not every persistence is a carefully designed memory. Some are consequences of how a line was written.

<!-- @dark_sphere -->

The dark sphere pulses in a room where so much else already pulses. A retained counter, a held recipe, an accumulated position: each keeps something different. None of these keeps an evolving field to supply to its own next update.

<!-- @reference_plural_body -->

Six limbs unfold around three heads. The pose opens without becoming another inventory. A pink edge catches the light; a silver loop holds a space beside the body.

The Peaches and Pussykrew reference brings bodily excess into this return to familiar primitives and shaders. Our assembly makes an attachment changeable. That is a technical permission, with limits: a larger menu of parts cannot by itself promise a freer life. Let the pose remain unresolved. The body does not owe the room a single final outline.

<!-- @ -->

Take a chosen combination into the next room. There the question changes: what if the surface must keep what happened to it, rather than simply recompute the appearance you asked for?

[^recipe]: The composition stage shares one material across its sphere, cube and existing sofa prefab. Three-plane projection uses positions in the stage's frame and weights from the surface normal. DOTS mixes pigment; RIM adds a view-angle contribution; GLOW adds the mixed pigment as emission. Its primary recipe has no clock. The smaller learner version uses mesh UVs on the carried point and cube; it does not reconstruct the sofa projection.

[^light]: SETTING changes the backdrop and the visibility of suspended scenery. It preserves the primary recipe, meshes, transforms and lamps. That scenery has shadow casting and GI contribution disabled. Emission can contribute to indirect illumination in other renderer configurations; visible brightness alone does not establish that behaviour here.

[^water]: The existing `queer_water.gdshader` uses three clock-driven displacements with amplitudes 0.05, 0.04 and 0.03 m. It adds emission and partial transparency, but no screen refraction, updated water normals, collider or fluid state. The floor plane starts 0.1 m above its anchor; its theoretical displacement bound reaches 0.12 m either way. Its phase rates do not complete whole turns at the configured 30-second shader-clock wrap. These facts describe the older dream-water shader, not the preceding hall's held-phase, normalized field.

[^defaults]: `shader_12_pinkextravaganza.gd` loads the collection materials without setting shader parameters. Its map token changes geometry and placement, not those material defaults. The newer composition stage does set uniforms and exposes them through controls. The older collection's bob adds a clock-sampled displacement each frame without multiplying that addition by frame duration; its rotations, separately, do use frame duration.
