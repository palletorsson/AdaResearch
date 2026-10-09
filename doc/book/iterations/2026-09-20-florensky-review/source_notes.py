"""Correct present-tense lookup identities; retain earlier dated DNA design notes."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[4]
updates={
'commons/interfaces/foundations/florensky_sphere.gd':'''# @identity
# essence: Florensky-inspired antinomy staged on a double-sided sphere. A visual metaphor, not a logical calculus or quantum simulation.
# desire: stay with two readings before asking for a verdict.
# critical_parameter: hold_both keeps A AND not-A visible without observation/cycling collapse. current_state is the legacy four-state visual selector. seam chooses none, hairline, gap, scaffold or field geometry.
# triggers: in hold_both mode, no state-changing input; otherwise legacy desktop observation and cycling. No tracked-hand state control is wired here.
# emerges: a comparison between sustained interpretation and the demand for a settled answer; the visual does not prove a true contradiction.
# needs: double-sided material, inner core, readable state label; optional seam geometries.
# relationships: compare with both_true_gate's report store; distinguish both from the quantum visual toys. Florensky's religious antinomies have multiple contested interpretations.
# truth: rendering both sides of a mesh stages two readings. It does not establish that a proposition and its negation are true.

''',
'commons/artifacts/schrodinger_box/schrodinger_box.gd':'''# @identity
# essence: a scripted illustration of a sealed box and a revealed outcome, not a quantum simulation.
# desire: compare the visible opening with what the program actually decides.
# critical_parameter: remainder and vantage choose visual presentation; auto_reset_time sets the reveal duration.
# triggers: desktop click picks a random ALIVE/DEAD result, animates the lid, then resets on a timer. Tracked-hand opening is not implemented.
# emerges: a question about what a visual metaphor does and does not demonstrate.
# needs: desktop opening exists; tracked-hand interaction remains missing.
# relationships: shares remainder/vantage vocabulary with superposition_display; neither demonstrates logical contradiction.
# truth: this implementation samples an ordinary random outcome. It does not model amplitudes, entanglement or quantum measurement.

''',
'commons/artifacts/superposition_display/superposition_display.gd':'''# @identity
# essence: three forms and a quantum-state expression; two opacities cycle in opposite phase. A visual toy, not a state-vector simulator.
# desire: see the animation and inspect what its resemblance to superposition leaves out.
# critical_parameter: remainder and vantage choose visual presentation; speed sets the opacity cycle.
# triggers: XR slider changes pace. No measurement/collapse operation is implemented.
# emerges: a useful comparison whose visual form is not a proof of its caption.
# needs: existing horizontal speed slider.
# relationships: shares remainder/vantage vocabulary with schrodinger_box; distinguish their quantum references from logical contradiction.
# truth: complementary opacities are not normalized quantum amplitudes; the display performs no measurement.

'''}
for name,identity in updates.items():
 p=ROOT/name; s=p.read_text(encoding='utf-8')
 start=s.index('# @identity\n')
 end=s.index('signal state_observed',start) if 'florensky_sphere' in name else s.index('# ─',start)
 s=s[:start]+identity+s[end:]
 if 'florensky_sphere' in name:
  start=s.index('extends Node3D')
  s='# florensky_sphere.gd\n# Florensky-inspired antinomy: a visual study, not a formal logic.\n\n'+s[start:]
 elif 'schrodinger_box' in name:
  s=s.replace('# The box holds superposition until observed','# This toy chooses a random outcome on desktop click.')
 p.write_text(s,encoding='utf-8')
