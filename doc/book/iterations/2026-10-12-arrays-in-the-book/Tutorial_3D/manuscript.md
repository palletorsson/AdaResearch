# Tutorial 3D — another index

**Learning elements**

- Layers of independently stored rows
- Displayed XYZ and stored YZX addresses
- Converting the earlier XZ plane
- Reading and collecting one cell without shifting its neighbours

Find `[1, 2, 0]` at the flight console. The selected cube is above you. Its address gives the program a way to find it; the flight enclosure gives your body a way to reach it. These are separate provisions.

Our construction continues with the cube and its contact sensor from Array. A third loop places copies at different heights. The important change is how we keep and read their addresses.

## Keep the plane; add layers

Save the previous lesson. Its four-by-four version stored values as `grid_data[x][z]`. After collecting `[1, 2]`, its second readout line was `[1, 1, 0, 1]`. Copy those four lines into `plane` below, surrounded by the outer brackets. The supplied value reproduces that result. You may instead copy your own four lines, keeping their order.

This is an explicit copy of the record. Leaving the hall does not automatically deliver a live array to another script. We keep the copied plane unchanged and use it to initialize the bottom layer of a new volume. The upper layers begin occupied.

| Displayed address | Previous plane | New volume |
| --- | --- | --- |
| `[1, 0, 2]` | `plane[1][2]` | `values[0][2][1]` |
| `[1, 2, 0]` | No height index yet | `values[2][0][1]` |

The display says X, Y, Z. Storage opens a layer Y, then a row Z, then an entry X. This is the convention used by this museum volume. The lists themselves do not name those directions.

Attach the complete script to a new empty `Node3D`, `VolumeStudy`, in your editable copy of the museum hall. Keep its origin at floor level and its scale at one. It needs about six metres along each axis. Use a clear area within the existing flight region to reach upper cells; flight is supplied by the museum, not by these arrays. Do not place the study through the installed cubes or enclosure. Face its labels from local positive Z. Its only external interaction dependency is the same declared museum player body as Array.

<!-- include:lesson.gd -->

## Read the loops from outside in

The Y loop appends an empty layer. Within that layer, the Z loop appends a fresh row. The X loop writes one value and, when it is one, makes a cube. Each enclosing list is constructed during its own loop visit. A change in one row therefore cannot silently change another row through a shared list.

At height zero, `plane[x][z]` supplies the value. Appending it inside the Y, Z, X loops gives it the new address `values[y][z][x]`. This copies integer values, not references to the plane's inner lists. The missing cube from the previous lesson stays missing in the bottom layer. Its address label is still built. Higher layers remain full.

`place` names the relation between an address and a local position. It multiplies three indices by spacing and lifts the cube centre 0.8 metres above its layer. The array index is still an integer; the position is measured in metres. The parent can place the complete study elsewhere in the museum without changing any address.

## Collect a named cell

The translucent box marks `selected`, initially `[1, 2, 0]`. Collection uses the same sensor and group check as before. The only change in `.bind` is the extra Y index. The signal sends a body; the bound X, Y, Z values identify this sensor's cell.

Approach the marker through the flight enclosure. The cube leaves, the marker and label remain, and the readout becomes zero. `values[2][0][1]` changed. `values[0][2][1]`, the gap copied from the plane, is a different address. Neither collection shifts a row or moves another cube.

The `valid` function checks the layer before reading its rows, then the row before reading its entries. `and` stops as soon as a condition is false. An invalid address is rejected before it can index a missing list. The next condition makes collecting an already empty slot harmless. These are the same responsibilities as Array, extended through another enclosing list.

## Choose another address

Change `selected` to another valid address with unequal numbers. Predict the corresponding `values[y][z][x]` entry and its position before running. Collect it and check that the adjacent cells remain. Then change spacing to `2.0`: the addresses and copied gap should stay the same while the volume spreads out. Each run constructs a fresh volume from `plane`; it does not remember collections made during an earlier run.

The open structures and suspended fragments elsewhere in this hall extend the question of what a site can hold. They remain available in the reflective text. For this lesson, carry one exact relation: an address selects a stored value, and a placement rule gives that address a location. In Floor, an address will choose a turn instead of an occupant.

<details>
<summary>Optional returns already in the museum</summary>

In **A rule takes up space**, change `(column + row) % 5` to `column` in `form_at()` in `commons/artifacts/spine_studies/open_rules.gd`. The supplied station handles the comparison. In **A place still held**, change the multiplier on `offset` in `commons/artifacts/reference_studies/suspension.gd`: the loops still place 75 fragments. These are source studies, not additional complete learner programs. [Open structures](/book-review/doc/book/iterations/2026-10-01-lewitt-reading-a-rule/index.html) · [Suspension](/book-review/doc/book/iterations/2026-10-01-hatoum-grid-under-load/index.html).

</details>
