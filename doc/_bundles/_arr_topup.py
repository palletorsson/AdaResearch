from pathlib import Path

adds = {
    'Tutorial_Single': '\n## Save State\n\nNo save state is needed for the tutorial — it is a pass-through map. The learner enters, practises the grab, walks to the teleporter, and continues. Returning later starts the interaction fresh, which is appropriate for a motor-skill calibration map.\n\n## Performance\n\nOne cube, one platform, one teleporter. The scene is trivial to render; the map runs at any practical frame rate on any supported VR device.',
    'Tutorial_Row': '\n## Save State\n\nThe corridor does not record progress. Re-entering starts at the beginning; the index counter resets. This is deliberate — the map is a motor-skill calibration for traversal, not a puzzle with persistent state.\n\n## Alternative Representations\n\nThe same 1D array could be rendered as a vertical tower, a spiral, or a circular ring. Each representation teaches a different intuition about linear indexing. The corridor is the simplest to traverse in VR and is what the map uses.',
    'Tutorial_2D_Build': "\n## Save State\n\nThe agent's traversal and helper selections do not persist across sessions. The map is a calibration for 2D indexing intuition; persistence is unnecessary.",
}

for m, a in adds.items():
    p = Path('commons/maps/' + m + '/technical.md')
    p.write_text(p.read_text(encoding='utf-8').rstrip() + a, encoding='utf-8')

print('done')
