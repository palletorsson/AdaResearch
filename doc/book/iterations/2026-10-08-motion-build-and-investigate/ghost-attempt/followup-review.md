# Ghost student follow-up

I read the revised student-packet/lesson.md and updated my comparison using its instructions. I did not inspect teacher or production sources and have not run engine tests. The original predictions.md is unchanged; the predictions still apply.

## My change

comparison.gd keeps each point's initial local position in a start_positions array when it is created. Its caption shows each point's live speed and a distance reading in metres. Until the comparison ends, the distance reading is the length of its current local position minus its saved start. When both clocks first become zero after a press, the code sets snapshot_taken and retains both distance readings. The caption identifies these as the distances when both pushes ended; the speed readings continue updating while the spheres coast.

The started flag prevents the initially zero clocks from capturing a snapshot before the first press. A new press clears snapshot_taken and starts both clocks again. The starting positions remain the original study positions, so the new snapshot on a repeated press measures from those original positions. A fresh comparison requires restarting the study, as Model notes says.

This uses the point's position and its saved start in the same frame. With unit scale and straight, forward paths, the displacement length equals travelled distance. Grabbing a point and making a detour would break that equality; the caption deliberately describes distance from the start, not accumulated path length.

## Gaps resolved by the new text

- **Proportional rule:** Read the change now explicitly gives acceleration as force divided by mass and velocity change as force times duration divided by mass. My 3 kg / 3 s prediction can be calculated directly from the text instead of inferred from the three examples.
- **Indexed clock assignment:** Build another comparison now explains that assigning remaining[i] replaces that clock and that the index must remain paired with its point. This supplies the previously unstated array-editing step.
- **Measuring the distance comparison:** The exercise now requires both speeds and distances, tells me to preserve starting positions, gives the displacement-length operation, and connects it to Lines. I could add that readout without looking elsewhere for a solution.
- **Reading the end of the comparison:** The latest instruction explicitly requests one snapshot when both clocks first reach zero and suggests a boolean flag that a new press clears. This resolves the earlier concern about trying to read a changing distance after the two-second boundary. I can read the retained values during coasting without confusing them with the current positions.
- **Concrete trial location:** Model notes now places PointStudy at (23, 0, 8) in the hall's local coordinates, with zero rotation and unit scale, and asks for four metres of clear +Z space. This resolves where to install the script. I treat it as scene setup rather than assigning that position inside comparison.gd, since the script is attached to the already placed PointStudy.
- **Fresh starts and boundary expectations:** The explicit restart instruction makes the fresh-trial procedure clear. Capturing when both clocks reach zero and allowing a small physics-step difference explains why the retained reading need not exactly equal the ideal calculation.

## Remaining points

- The lesson does not define a numerical tolerance or the exact physics-frame observation point. The new qualitative boundary guidance is enough for the proposed observation, but not for deciding a strict pass/fail numerical threshold. I have not supplied one or adjusted predictions to a measured result.
- The packet still uses course-relative links rather than links to its own flat filenames. README and filenames still make the texts findable, but clicking those references inside this packet is not the stated route.
- Two-clock behavior on another press remains an inference from the reference's button behavior: both remaining values restart, while velocities and positions remain. The new restart instruction makes this manageable for fresh comparisons, so it is not blocking the exercise.

I continue to assume the supplied helper contract, a stationary unit-scale frame, no grabbing or collisions during measurement, and a clear bay. The two paths at X = -1 and X = 1 remain freely moving and separate under those conditions. I have not verified the bay visually or changed any museum scene.

I found no blocker to constructing the requested snapshot from the packet. I implemented the capture in the physics callback after updating both clocks, and retained the lesson's allowance for a small physics-step boundary difference. No engine execution was performed for this adjustment.
