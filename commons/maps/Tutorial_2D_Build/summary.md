# Tutorial 2D Build — Summary

Tutorial_2D_Build is the fourth map in the Array Tutorial sequence. It adds the second dimension. Where the previous map was a corridor, this one is a grid: four cells by four cells, small enough to comprehend at a glance and large enough to require a systematic addressing scheme.

The grid lies flat on the floor. Each cell is labelled with its row and column indices. A row helper and a column helper sit at two sides of the grid; pressing the row helper highlights every cell in a chosen row, and pressing the column helper highlights every cell in a chosen column. The two helpers decompose the two-index address into its components, so the learner can see why a coordinate pair matters before being asked to use one.

A small grid agent stands at one corner. Starting it triggers a programmatic traversal: the agent visits every cell in row-major order, then in column-major order, then in a diagonal. Its steps are visible, and a side panel names each step as an update to a pair of indices. The traversal is the first algorithmic movement the learner has seen; previous maps moved under the learner's feet, and this map moves under an agent's.

A wall panel shows the corresponding code alongside the live grid. Within the sequence, Tutorial_2D_Build is the jump from line to grid. Tutorial_3D will next add the third dimension.
