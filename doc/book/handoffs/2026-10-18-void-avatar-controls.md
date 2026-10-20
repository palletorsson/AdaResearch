# Void avatar and controls

User asks for base.tscn avatar/hands and a good move/grab/shoot/jump arrangement.

- `commons/void/avatar.gd` mounts actual base left/right hand scenes with the same hand script, blend trees and poses, plus PlayerCustomization (IK arms + progression wardrobe). Hand ownership is required for XRTools grab-driver discovery. This is appearance reuse; Void retains one body and its three movement providers.
- `game.gd`: A-only jump; grip pickup with base offsets; trigger belongs to held tools or the existing two-hand catalyst. Removes unconditional left-trigger shot. C remains desktop inspection only. The shared earned ability keeps its unlock; no live progress granted. Recovery clears form/shots and suspends ability; exit restores previous processing.
- Hand nail scripts now look up optional GameManager at runtime; full-project saved colours/signals still work, isolated real-source scenes no longer require the global symbol at parse time.
- No floor/editor/rooms JSON changed.

Controls: left stick move; right stick 30-degree snap; grips hold/release; trigger use held object / send formed catalyst; right A jump; right B retry; left Y roof; left X menu.

Recommendation: two hands together is a deliberate catalyst action. Consider a later two-hand formation followed by one-hand aim if fast encounters expose difficulty. This alternative is not implemented.

Native test: `python tools/test_void_avatar.py --capture` — 20 checks passed. Uses actual production hand/arm/wardrobe, real XRTools grip/movement, and actual first catalyst with synthetic controller poses. Probe unlocks only its own isolated ability, never user saves. Real Mobile capture in `doc/book/iterations/2026-10-18-void-avatar-controls/hands-point.png`. No headset comfort/performance claim.

Report: http://localhost:3003/book-review/doc/book/iterations/2026-10-18-void-avatar-controls/index.html

Regression: `python tools/test_void_game.py --reuse --trace --out=doc/book/iterations/2026-10-18-void-avatar-controls/trace-regression` — 48/48 passed, including Trace → Grid preservation and desktop/synthetic-XR shaft descent. This is a focused regression, not the older complete layout suite (which has known failures against user-edited placements).
