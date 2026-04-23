<<<ADA_BUNDLE>>>
sequence: array_tutorial
file: summary.md
maps: 7
skipped_passing: 1
created: 2026-04-23T19:21:13
only_failing: true
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: Tutorial_Pattern>>>
# Tutorial Pattern — Summary

Tutorial_Pattern is the sixth map in the Array Tutorial sequence. It shifts the learner's relationship with the grid: where earlier maps used indices to navigate, this one uses indices to generate visible pattern. The grid becomes a canvas for arithmetic.

Four small tile stations sit around the room. Each station holds a tiny grid — four by four, eight by eight — and a rule that assigns a colour to every cell. The first rule is a checkerboard: colour the cell black when (x + y) is even, white when it is odd. The second rule is a wave: colour scales with sin(x). The third combines x and y multiplicatively. The fourth exposes the full expression as an editable string, so the learner can write their own rule and watch the tiles respond.

A large preview board on the wall takes whichever rule is active and tiles it across a much bigger surface, so the local pattern can be read at global scale. A mode toggle switches between direct tiling and mirrored tiling, turning simple rules into kaleidoscopic variants.

A side panel names the move explicitly. Arrays hold data; patterns are data that rhymes. Within the sequence, Tutorial_Pattern is the transition from structural navigation to computational rhyming. Array_Patterns, which has already passed, will next push the same move into full wallpaper-group symmetries.

<<<MAP: Tutorial_Single>>>
# Tutorial Single — Summary

Tutorial_Single is the second map in the Array Tutorial sequence. It reduces the entire interaction to the smallest possible act: one object, one destination. The map's job is to teach the learner how to use their hands in VR before any concept from the rest of the sequence lands.

A small platform — four cells by three — floats in empty space. A single cube sits at its centre. A teleporter pad sits at the far end. That is the whole map. The learner reaches out, closes a hand around the cube, and carries it to the pad, or leaves the cube where it is and walks to the pad empty-handed. Either path exits the map.

A small diagram on a nearby stand shows the hand-tracking contract in three frames: open hand near object, closed hand triggers a grab, release re-opens. The diagram is the entire curriculum delivered inside the map. There is no additional artifact and no additional rule.

Within the sequence, Tutorial_Single is the scalar before the array. Before a corridor, before a grid, before a volume, the learner needs to be able to pick something up. The single cube is a scalar value; the remaining maps will extend the operation into one, two, and three dimensions. Tutorial_Row comes next.

<<<MAP: Tutorial_Row>>>
# Tutorial Row — Summary

Tutorial_Row is the third map in the Array Tutorial sequence. It introduces the first dimension. After Tutorial_Single reduced the interaction to a scalar, this map opens the space along a single axis and asks the learner to traverse it.

The room is a corridor. Seven columns wide, nine rows deep, the space is deliberately under-furnished: one lane runs forward through the centre, and the remaining cells serve as buffer and orientation. There is no branching. Forward and back are the only meaningful directions, because the data structure under the corridor is one-dimensional.

A rig along the central lane constrains the learner's movement to the Z axis. A simple counter on the wall shows their current index along the lane, incrementing as they step forward and decrementing as they step back. The array-like structure of the corridor is made explicit: each cell has an index, and walking updates the index.

A small wall panel shows the equivalent code: `cell = row[i]`, with `i` tied to the live counter. As the learner moves, the code's highlight moves too, so traversal and indexing share a display.

Within the sequence, Tutorial_Row is the first array dimension. Tutorial_2D_Build will next add the second.

<<<MAP: Tutorial_2D_Build>>>
# Tutorial 2D Build — Summary

Tutorial_2D_Build is the fourth map in the Array Tutorial sequence. It adds the second dimension. Where the previous map was a corridor, this one is a grid: four cells by four cells, small enough to comprehend at a glance and large enough to require a systematic addressing scheme.

The grid lies flat on the floor. Each cell is labelled with its row and column indices. A row helper and a column helper sit at two sides of the grid; pressing the row helper highlights every cell in a chosen row, and pressing the column helper highlights every cell in a chosen column. The two helpers decompose the two-index address into its components, so the learner can see why a coordinate pair matters before being asked to use one.

A small grid agent stands at one corner. Starting it triggers a programmatic traversal: the agent visits every cell in row-major order, then in column-major order, then in a diagonal. Its steps are visible, and a side panel names each step as an update to a pair of indices. The traversal is the first algorithmic movement the learner has seen; previous maps moved under the learner's feet, and this map moves under an agent's.

A wall panel shows the corresponding code alongside the live grid. Within the sequence, Tutorial_2D_Build is the jump from line to grid. Tutorial_3D will next add the third dimension.

<<<MAP: Tutorial_3D>>>
# Tutorial 3D — Summary

Tutorial_3D is the fifth map in the Array Tutorial sequence. It completes the dimensional ladder begun in Tutorial_Single and extended through Tutorial_Row and Tutorial_2D_Build. The map is built around a four-by-four-by-four volume — sixty-four cells addressed by three indices — and the learner has to move through all three axes to read it.

Stepped platforms rise along the north and west sides of the arena, providing physical access to the upper layers of the cube. Lifts at two corners give a more direct vertical shortcut. The volume itself is partially transparent, so the learner can see layers above and below their current height while standing on any given platform.

A small helper at the entrance walks the learner through the addressing convention. Three sliders set row, column, and layer independently; adjusting any one of them moves a highlight cube to the corresponding cell inside the volume. The learner can see that the same indexing logic scales: one index gave a row, two gave a grid, three give a volume.

A side wall shows the code `cell = grid[x][y][z]` alongside the live sliders, so each numerical change highlights the corresponding bracket. Within the sequence, Tutorial_3D is the payoff of the dimensional progression. Tutorial_Pattern will next shift the grid from a data container to a pattern generator.

<<<MAP: Tutorial_Disco>>>
# Tutorial Disco — Summary

Tutorial_Disco is the seventh and final map in the Array Tutorial sequence. It scales the array from the small, comprehensible grids of the earlier maps to a floor large enough to get lost in, and it adds time as a new dimension.

The dance floor is seventeen cells on a side. Each tile is an address — row, column, and a local state — and stepping on a tile activates a response. The responses are coordinated by a step sequencer that runs along one wall. The sequencer divides a short loop into steps and advances one step at a time; the pattern a learner steps out on the floor is captured, cell by cell, into the sequencer's state, and the sequencer plays it back at a steady tempo.

A set of mode buttons changes what the sequencer does with that state. One mode triggers a sound per active tile; another lights the tile for one beat; another propagates the active tile to its neighbours. The floor becomes a two-dimensional array whose third index is time.

A wall panel names the move: the previous maps showed arrays as spatial addressing; this map adds the temporal dimension and hands the learner a grid they can compose on. Within the sequence, Disco is the playful capstone. The next encounter in the curriculum, the Wavefunctions sequence, picks up on the temporal pattern the dance floor hints at.

<<<MAP: Chamber_Arrays>>>
# Chamber Arrays — Summary

Chamber_Arrays is the catalyst chamber for the Array Tutorial sequence. It is the only catalyst chamber in the curriculum that does not hand the learner a projection tool. Instead, the chamber is observational: a grid agent traverses the floor, and the learner arranges obstacles for it to adapt around.

The chamber is small. A grid covers the floor, labelled by row and column. A grid_agent:copy moves through the grid according to a simple traversal rule — row-major scan, with detours around obstacles. The learner carries a set of small blocks they can place on any cell. Each placement forces the agent to find a new path.

A science screen on the wall reads out the agent's current plan as a sequence of cell indices. As obstacles are added, the plan updates, and the screen highlights which indices changed. A second display tracks how many extra steps each new obstacle costs, so the learner can see their placements as increments to the agent's path length.

Within the sequence, Chamber_Arrays reframes the catalyst practice as arrangement rather than projection. The lesson is that arrays hold state, and state responds to what is placed within it. The chamber hands the learner back to the Lab with the array catalyst absent by design.
