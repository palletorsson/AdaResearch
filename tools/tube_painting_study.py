"""A later geometry lesson: continue a suspended drawing, inspect its construction."""
REVIEW = '2026-10-02-tube-painting-a-line-takes-room'
HALL = 'LSystems_Grammars_And_Curves'
SPECS = [('tube_painting','tube',HALL,'lsystems',23,23,0,
          'A line takes up room','Ada / drawing in space',
          ['trace','mesh','refinement','rotation','array','sweep'],
          'Change the middle ring side count from twelve to eight. Keep the path and radius; compare the skin.',REVIEW)]
READINGS = {'tube_painting': '''Someone has already begun. Three bent lines hang in front of a pale wall. Their ends are within reach. Take one and continue it.

The part you inherited stays where it was. Your hand adds to its end. Let go: the new length remains in the air, carrying the turn you just made. Bring another end towards the wall and it settles against the surface. A drawing begins to make its own partition.

There is a pen for starting elsewhere. But beginning again is no longer the only invitation. You can accept the shape already here, prolong it, or make its unfinished edge lead somewhere its first gesture did not suggest.

Choose VIEW. The coloured skin disappears. A path remains; then rings appear along it. Choose again and the faces return between them. What looked like a single flowing body keeps a count of the decisions that made it.

These lines do not sag. Their suspension is something the program grants. The wall is a place to meet, not a support they need. Leave one end unattached. For once, an unfinished thing does not have to fall.

Choose NETWORK. A white pipe holds an opening through its middle; a black cable hangs between two supports; the pink tube keeps the turn of a hand. Bring an end to another run. An amber marker offers a joint. Release, and the two share a connection. A crossing alone is not enough. What looks continuous still needs a decision about where it belongs.

Beside the drawing, three coloured bodies wait above dark wheels. Close the power lever. The wheels turn at unequal rates; each body finds another sway. Pull the motor cord and the figures keep their last pose. The small synthesizer can go on sounding. Its connection is elsewhere.

The cord has the same kind of skin as the lines we have been making. Here its ends also carry an agreement: this output may reach that input. The drawing has acquired a consequence. What would we connect if a line could give something else permission to move?

Look up. Large pink pipes pass over and under one another. Their gloss bends the room back towards us. Change the rule at the small console: the weave becomes ribs, then long returning loops. What fitted in a hand now reaches across the bay. Repetition has given the line the scale of a ceiling. We are standing inside one of its arrangements.'''}
ANCHORS = {HALL:'The floor curves and the volumetric path remain in the collection.'}
EDITS = {'tube_painting':('commons/primitives/pipes/swept_tube.gd',
                        'const SIDE_COUNTS := [6, 8, 24]',
                        'Replace the middle value 12 with 8 in SIDE_COUNTS. Restart the prepared study. Each supplied path still has 41 points and the same radius. A capped tube now has 656 triangles instead of 984. Compare PATH, RINGS and TUBE before drawing your own continuation.')}
