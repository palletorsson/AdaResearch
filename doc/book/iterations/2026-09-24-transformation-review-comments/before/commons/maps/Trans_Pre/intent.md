# Trans_Pre — transformation basics in a Mario-style cube

Palle's correction, 16 September 2026: this is a preliminary lesson. Show the movements that make up a familiar game pickup. The learner should be able to recognise and name translation, rotation and scale, then see them working together.

Keep the cumulative order: still cube → up and down → add turning → add growing and shrinking. Use short code excerpts after observing each addition. Use linear interpolation (`lerp`) between two heights and two sizes. Sine belongs to the later wave lessons. Rotation adds a small turn each frame.

The four pick_up_cube demonstrations remain at (4,2), (4,5), (4,8), (4,11), using motion still / slide / idle / all and hold:demo. The three secondary markers at (6,5), (6,8), (6,11) support recognition. They have independent timing and do not control the demonstrations. The only primary artifact family remains pick_up_cube.

The small level applies the finished animation. Four collectible cubes occupy (4,16), (4,18), (4,19), (4,20); two health crosses remain supporting objects. The existing platform and wedge ramps are retained. Walking to a pickup is a simple way to try the game object.

Questions about the player's body, passage, identity, reference frames and the difference between visual scale and detection size belong to later investigations. They should not become additional learning requirements here. The lesson's success is recognising the three basic operations in the animated cube.

The previous, more elaborate reading is preserved under doc/space/trans-pre-basics-2026-09-16/before/. The follow-up revision uses `motion_curve:lerp` for all eight pickup instances and the scale marker, with continuous rotation on the turning marker. Their placement and roles stay the same. Other halls retain their existing motion defaults.
