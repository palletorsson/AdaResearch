# Tutorial Row — Summary

Tutorial_Row is the third map in the Array Tutorial sequence. It introduces the first dimension. After Tutorial_Single reduced the interaction to a scalar, this map opens the space along a single axis and asks the learner to traverse it.

The room is a corridor. Seven columns wide, nine rows deep, the space is deliberately under-furnished: one lane runs forward through the centre, and the remaining cells serve as buffer and orientation. There is no branching. Forward and back are the only meaningful directions, because the data structure under the corridor is one-dimensional.

A rig along the central lane constrains the learner's movement to the Z axis. A simple counter on the wall shows their current index along the lane, incrementing as they step forward and decrementing as they step back. The array-like structure of the corridor is made explicit: each cell has an index, and walking updates the index.

A small wall panel shows the equivalent code: `cell = row[i]`, with `i` tied to the live counter. As the learner moves, the code's highlight moves too, so traversal and indexing share a display.

Within the sequence, Tutorial_Row is the first array dimension. Tutorial_2D_Build will next add the second.
