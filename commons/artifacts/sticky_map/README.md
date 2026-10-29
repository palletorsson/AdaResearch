# Sticky map

A contextual map of sticky notes on a cork pinboard, joined by threads. One file is the truth:
`commons/data/sticky_maps/<map>.json` (notes with a title, the short text on the paper, the full text,
a kind and a position in metres on the board; bare needles (`pins`) stuck in the cork; links between
notes and needles, `thread` or `traverses`, with an optional `color` (red, black, blue, yellow, white
or a hex), marked `by: source` when the source text makes the relation and `by: proposed` when it is
an organisation offered for revision).

- **Web:** `/sticky-map` in the encyclopedia draws the board in three.js, lists every note's full
  text, and edits everything on the board itself; there is no form beside it. Four tools: *Select /
  move* (click a sticker, needle or thread, drag to move, pull the blue grip on the frame's top right
  corner to resize the board), *Sticker* (click the cork to stick one of the chosen kind and write on
  it at once), *Needle* (stick a bare needle), *Thread* (click stickers or needles in turn to run a
  thread through them in the chosen colour; a click on empty cork sticks a needle there and ties to
  it; right-click or Esc ends the thread). A card hangs over whatever is selected and follows it as
  the board turns: a sticker's kind, its title, short and full text (Write, or double-click), a
  needle's head colour, a thread's words, colour and kind, *Thread from here*, Delete. Delete removes
  the selection and its threads, Ctrl+Z undoes (one step for a text typed). The save route
  (`/api/sticky-map`) bumps the map's `revision` and refuses a save from a stale one (409).
- **VR:** the artifact `sticky_map` (config `map`, default `ai_assemblage`) draws the same board in
  Godot by the same rules: the numbers in `sticky_map.gd` are copied from
  `ada_encyclopedia/src/lib/sticky-map.ts` (note sizes and colours by kind, the pin, the threads, a
  small turn per note hashed from its id, the face drawn 512 px wide in 2D and worn as the note's
  front, needles as a steel shaft and a coloured head, threads behind the paper). It watches its file once a second and redraws when a save changes it (464-529 ms in the
  probe). It reads `user://sticky_maps/<map>.json` first, where a headset's copy will land.
- **Probe:** `commons/testing/probe_sticky_map.gd [-- <map>]` (windowed) photographs the board from
  the web page's own Board camera, counts notes and needles, and tests the watch with a copy it then
  removes; `ada_run/sticky_map/`.

**Flat or a half-cylinder.** `board.shape: "arc"` with a `radius` bends the board round a vertical axis
`radius` in front of its middle; the toolbar's *Half-cylinder* makes one as long as the flat board was wide
(radius = width / pi) and its slider changes the radius. A note's `x` is its distance along the board, so
the same notes stand on either shape. The middle stays where a flat board's is and the ends come round
towards the viewer; the stickers bend with the cork, and the threads, tied head to head, cross the air
inside it. *Stand inside* puts the camera at the axis with a wide eye. The blue corner then sets how far
round the board goes, short of a full circle. Both pictures bend by one rule, `bend()` in `sticky-map.ts`
and `sticky_map.gd`. A thread between the two ends of a half-cylinder passes through the axis, where a
visitor would stand.

Not yet: the live path to the standalone Quest (res:// is read-only in an export, so the watch finds
nothing there; the bridge needs a command that carries the map to `user://sticky_maps/`), reading a
note's full text in VR, and building the map in VR (moving and adding notes there, written back to
the file). Origin on the floor under the middle of the board; the notes face +Z.
