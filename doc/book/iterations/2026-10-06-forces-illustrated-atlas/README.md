# Forces illustrated atlas

Open `index.html`. Each new plate opens a large reading page with previous/next navigation, its teaching purpose, inherited capacity and build status. The gallery also includes the thirteen existing Forces hall plates in canonical order.

- **10 newly generated plates:** eight proposed encounters and two six-panel speculative studies.
- **13 existing plates:** retained as current-hall companions, not counted as new work.
- **No museum runtime, canonical order, tutorial.md or final.md changes.**

## Image method and prompts

The ten new images were made with OpenAI's built-in image-generation tool, then selected after visual review and targeted edits. No programmatic image editing was used. Final PNGs are in `images/`; copied existing plates are in `current-halls/`.

`selected-images.json` records each saved path, original generation prompt, refinement prompts and source output path. `generation-prompts.json` records the original generation set; `prompts.json` is its earlier draft. `images.json` is the earlier selection record. **Use selected-images.json for the final selection.** Captions are editable in `captions.json`.

## Drawing limits

The images propose museum encounters. They are not measurements, screenshots, tested VR layouts or proof of working mechanics. Force, impulse and velocity are distinguished in captions. Arrow lengths are illustrative; the doubled-mass comparison requires half the velocity change for the same impulse. Course guide lines are routes rather than velocity vectors. The spring lesson begins with a one-dimensional guide; the last spring panel explores anchor placement. Two-hand flight is an accepted input design, still requiring implementation.

The beyond pages select twelve visual research directions. Some have existing relatives in the project; they are not an exhaustive source-code inventory or a claim that every pictured idea is new.

## Rebuild and check

In the repository, run `python doc/book/iterations/2026-10-06-forces-illustrated-atlas/build.py`. The script copies available source images without editing pixels, checks the canonical hall order, PNG dimensions, every local HTML link/anchor and ZIP integrity, and writes `manifest.json`. Existing copied images remain usable if generated-image cache paths are unavailable.

The ZIP contains the gallery, all 23 PNGs, captions and prompts. Extract it and open `index.html` without a server. Links to the larger manuscript/proposal use the local encyclopedia server and are separate from the portable atlas.
