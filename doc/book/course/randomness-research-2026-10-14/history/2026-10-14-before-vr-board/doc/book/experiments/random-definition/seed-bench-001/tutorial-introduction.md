# Keep the values; change their job

This is a continuation of Random Definition's seed lesson. You already have a generator, ordered triples, colour assignments and a carried point. Here the question is yours to test: what does height let you notice that the colour arrangement did not? Predict before pressing a control. A preference for the flat arrangement is a possible result.

The complete printed version is [tutorial.md](tutorial.md). Its code blocks are extracted and executed by the reconstruction check. That checks the printed program; a person rebuilding and explaining it remains a separate test. The supplied record adapter is printed too. You may initially borrow its persistence machinery, but mark that assistance rather than claiming to have understood it.

Run `python doc/book/experiments/random-definition/seed-bench-001/launch.py` from the repository. It prepares a separate museum instance and starts beside the study. The museum supplies its floor, lighting and desktop walker. The installed instrument remains nearby. This launcher uses desktop mode; physical headset operation is still untested. Alternatively, attach `seed_study.gd` to a new Node3D beside the existing instrument, with hall-local position `(10.5, 0, 18.5)`, Y rotation `-90°` and scale `(1, 1, 1)`. Keep the three printed scripts together. The carried point depends on the project's installed XRTools classes; its trigger signal is inherited support.

The left array is a fixed reference. The right array switches between the same flat assignment and the height assignment. Compare the right array before and after as well as across the two trays: their different viewing positions are not identical retinal conditions. Both retain RGB; neither asks for new values while changing height. Unshaded colours make the material assignment identical in both arrays. This is a display study, without a force or cloth model.

Each cell receives three successive draws, `a`, `b`, `c`. There are sixteen cells and forty-eight values. Index `i = 4 * row + column` fixes their order. X and Z use ten-centimetre spacing; each cube is four centimetres wide. A places its centre ten centimetres above the tray. B uses `0.10 + 0.30 * (a + b + c) / 3` metres. Read those two assignments in `cells()`. Everything else in that method stays fixed.

Before running B, work through four invented triples: `(0,0,0)`, `(1,1,1)`, `(1,0,0)`, `(0,1,0)`. Their expected heights are `0.10`, `0.40`, `0.20`, `0.20` metres. These are arithmetic examples, not the first draws from seed 42. Why do the red and green cells have the same height? What information would you need to recover their colours from height alone?

Use this cycle and keep your account beside the exported record:

1. Start at seed 42 and press F1 for flat. Record your prediction and which cell you will follow.
2. Press F2. Describe an observable difference, an absence of interest, or a new question. Do not call the height “more random”: the retained numbers have not changed.
3. Press F3 to KEEP, then F5 to EXPORT. F8 deliberately makes the next seed's draws. F4 replays the kept result. Check the seed, mapping and arrangement return.
4. Press F7 to clear the memory copy, then F6 to import the exported result. Close and reopen the study, then import again. The file is `seed-bench-001.json` in Godot's user data folder; its full location can be found through **Project → Open User Data Folder** in the editor.
5. Rebuild from the printed blocks in a separate folder. Change only the right-hand height formula to use `a`. Predict which equal-height pair separates. This is a proposed next experiment; retain the mean version and give the alternative its own mapping ID before exporting it.
6. Explain which code you understood, borrowed or needed help with. Record assistance and an unsuccessful attempt too. Return your observation to both the tutorial question and the final's “one more agreement” passage. Either may need revision.

Our first automated export/import attempt failed. JSON changed integer field types, and decimal parsing shifted several double values by a tiny amount even with full-precision output. The adapter now validates the entire record before accepting it. Seed and generator state are decimal strings. Exact float bytes are the replay authority; the numeric array remains readable and must agree within `1e-15`. Import restores those bytes and never resumes an RNG. An invalid import leaves the current and kept results intact. KEEP makes a deep copy; clearing it does not delete an exported file.

Replaying these values is different from obtaining a new unpredictable outcome. F8 is another deterministic seeded acquisition. The same-build generator check and the stored-value replay are separate tests; neither establishes the quality of a physical randomness source. Godot documents [RNG state and seeds](https://docs.godotengine.org/en/4.6/classes/class_randomnumbergenerator.html) and [JSON's numeric conversion](https://docs.godotengine.org/en/4.6/classes/class_json.html). The actual failures and repairs are in [observations.md](observations.md).

The following three complete files form this continuation. `seed_record.gd` holds the experiment and persistence rules; `seed_study.gd` builds the visible objects and controls; `point_body.gd` is the unchanged carried-point support from the earlier lesson. The record adapter is deliberately explicit so a hidden persistence failure can become a question about the apparatus.
