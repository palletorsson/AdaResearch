"""Make a bounded reflective revision; leave canonical chapters untouched."""
import difflib
import json
from build import HERE, ROOT, HALLS, put, sha

EDITS = {
 'Trans_Pre': [
  ('The script chooses a height between two endpoints:', 'The third cube keeps moving up and down.',
   'Each rise and fall takes it through the same heights, at a steady speed on each leg. At the top and bottom it reverses. The shape has kept its dimensions while its place changes.\n\n'),
  ('Point Zero\'s small counter example received', 'The rise and the turn continue together.',
   'The turn keeps pace with elapsed time. A longer interval between updates calls for a larger turn.\n\n'),
  ('```gdscript\nvar size_factor:', 'Beside each moving example,',
   'Its size moves between 0.7 and 1.3 times the starting size. All three dimensions change together, so it keeps its cube shape.\n\n'),
 ],
 'Trans_Introduction': [
  ('The transport script moves the cube', 'Step off at the far bank.',
   'For each small displacement of the cube, the program moves the supported rider by the same amount. The bank recedes while the surface beneath you stays close. Moving the cube alone would leave you behind.\n\n'),
  ('The cube grows from half a metre', 'The centre sits below the floor',
   'The cube grows from half a metre to three metres on each side. Its visible surface and the collision box that supports your feet grow together. What you see arriving becomes something you can stand on.\n\n'),
  ('The step-and-pause rotation code', 'From the bank, follow one end',
   'The visible plank and its collision body turn together between zero and ninety degrees, with a four-second pause at each end. The plank is three metres long, one metre wide and twenty centimetres thick. Its upper face stays level with the floor; its ends meet the banks when aligned.\n\n'),
  ('The landing uses a translation too:', '<!-- @ -->\n\nBring the landing back',
   'The landing travels along its rails, taking its visible surface and support with it. You can move it up to one metre from its starting place. The side aisles let you return to the control while the gap stays open.\n\n'),
 ],
 'Trans_Translation': [
  ('The transport script calculates a destination', 'On the upper route,',
   'A starting position, a direction and a distance determine each destination. Three metres up and three metres forward use the same relation with different directions.\n\n'),
  ('The carrier brings your body to a pickup', '<!-- @ -->\n\nAt the last crossing',
   'Each small displacement of the carrier moves your supported body with it. The pickup detects your arrival and disappears. Ride back to its place. The carrier can repeat the journey; the cube is gone.\n\n'),
 ],
 'Trans_Rotation': [
  ('The X-axis ride\'s arc, before that sideways offset,', 'The sideways ride\'s blade',
   'The platform carries you until you step off or jump.\n\n'),
  ('```gdscript\nvar degrees := float(cube.get_meta', 'The row supplies the angle;', ''),
 ],
 'Trans_Scale': [
  ('The arrival on the plate is another operation.', 'Follow the plates down.',
   'The arrival on the plate is another operation. Scaling the room would not put you there. The program finds the top plate in the enlarged world, then places your feet eight centimetres above it. The room has changed size, and you have been given a new place from which to meet it.\n\n'),
 ],
 'Trans_Body': [
  ('Within reach, the distance part of the rule', 'Someone has chosen that width,',
   'The opening responds to two distances: along the wall from each slat to you, and out from the wall to where you stand. The response weakens towards the limits of its reach. Neighbouring slats turn with the ones closest to you, making room for more than a point.\n\n'),
  ('```gdscript\nvar t: float = clampf(sqrt(_dist2', 'All nine blocks are still there.',
   'Each block answers the nearest body within its reach. It shrinks smoothly to about a third of its full size. The visible block and its collision box change together, lowering as they shrink to keep their feet on the floor. Their places in the horizontal grid stay fixed.\n\n'),
 ],
 'Trans_Pit': [
  ('The script keeps a fraction, `_t`,', 'Each block travels two metres,', ''),
  ('```gdscript\nmesh_instance.rotation_degrees', 'The collision follows the visible angle.', ''),
  ('For this floor-anchored configuration,', '![At its smallest,',
   'All three cubes move from thirty centimetres to three and a half metres on a side, then return together. Their shared rhythm leaves different amounts of floor available around them.\n\n'),
  ('The door keeps a fraction of its opening,', 'Walk through. The door stays open',
   'The three movements overlap in time. Each leaf turns across the doorway\'s face and ends at thirty-four percent of its original size. Its collision shape changes with it: the visible opening is also an opening your body can use.\n\n'),
 ],
}

report = []
for hall in HALLS:
    source = ROOT / 'commons/maps' / hall / 'final.md'
    original = source.read_text(encoding='utf-8')
    result = original
    for start, end, replacement in EDITS[hall]:
        assert result.count(start) == 1, (hall, start)
        assert result.count(end) == 1, (hall, end)
        a, b = result.index(start), result.index(end)
        assert b > a
        result = result[:a] + replacement + result[b:]
    put(HERE / hall / 'final.md', result)
    put(HERE / hall / 'final.diff', ''.join(difflib.unified_diff(original.splitlines(keepends=True), result.splitlines(keepends=True), fromfile='canonical/' + hall + '/final.md', tofile='review-draft/' + hall + '/final.md')))
    report.append({'map': hall, 'source_sha256': sha(source), 'draft_sha256': sha(HERE / hall / 'final.md'), 'words_before': len(original.split()), 'words_after': len(result.split()), 'code_blocks_before': original.count('```gdscript'), 'code_blocks_after': result.count('```gdscript'), 'bounded_replacements': len(EDITS[hall])})
put(HERE / 'reflection-revision.json', json.dumps(report, indent=2) + '\n')
print(json.dumps(report, indent=2))
