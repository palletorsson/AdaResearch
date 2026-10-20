"""Record G1 as built while retaining the original proposals and sequence order."""
from pathlib import Path
R=Path(__file__).resolve().parents[1];P=R/'doc/book/course/uncertainty-plan'
def change(p,old,new):
 s=p.read_text(encoding='utf-8')
 if old not in s:
  assert new in s,(p,old);return
 p.write_text(s.replace(old,new,1),encoding='utf-8')
change(P/'PLAN.md','The later authorised geometry-noise experiment is recorded as built below','The later authorised geometry-noise and pendulum experiments are recorded as built below')
change(P/'PLAN.md','separates this implemented study from the still-proposed pendulum, navigator and six original packages','records G0 and G1 as built, with the navigator and six original packages still proposed')
change(P/'PLAN.md','All 16 selected registry entries, including the newly built G0','All 17 selected registry entries, including the newly built G0 and G1')
change(P/'PLAN.md','G1pendulum/G2navigatorproposed.','G1pendulum_noise BUILT Vectors_Act4b_Oscillation;43core+21museum;G2navigatorproposed.')
change(P/'INVENTORY.md','16 selected entries, including the newly installed geometry-noise experiment','17 selected entries, including the newly installed geometry-noise and pendulum experiments')
change(P/'INVENTORY.md','The CA lesson and G0 have separate native test receipts.','The CA lesson, G0 and G1 have separate native test receipts.')
row='| [pendulum_noise](../../../../commons/artifacts/pendulum_noise/README.md) — newly built, placed and tested | Fixed-step angular model; forty saved horizontal forces; paired off/on and same-input/different-damping comparisons | Vectors_Act4b_Oscillation; constrained held points, force/drag sliders, five local buttons | **G1 built.** 43 core checks;21 installed-room checks. Same inherited point class; analytic rod constraint, not a Jolt joint. Physical headset remains untested. [Receipt](../../iterations/2026-10-09-pendulum-a-recorded-push/index.html) |\n'
p=P/'INVENTORY.md';s=p.read_text(encoding='utf-8')
if '| [pendulum_noise]' not in s:s=s.replace('| [geometry_noise]',row+'| [geometry_noise]',1);p.write_text(s,encoding='utf-8')
change(P/'SEQUENCES.md','Springs later prepare measured response. Keep stack','**G1 built:** a paired point pendulum compares recorded force off/on, then matched input with different damping. Springs remain the primary lesson. Keep stack')
change(P/'NOISE_TESTS.md','## Next two apparatuses, still proposed','## G1 built; G2 still proposed')
p=P/'NOISE_TESTS.md';s=p.read_text(encoding='utf-8')
start=s.index('**G1 — A pendulum receives a disturbance.**');end=s.index('\n\n**G2',start)
s=s[:start]+'''**G1 — The same release / a recorded push. Built in Vectors_Act4b_Oscillation.** Pull either inherited point to set the pair's release angle. OFF/ON matches drag and changes only the external input; SAME INPUT matches the saved force and changes B's drag. Forty saved Gaussian values, each held0.1s, provide four seconds of horizontal force. The angle model runs at120Hz for20s, stores a30Hz history, and reports peak absolute angle and a terminal settling window. There is no contact solver or Jolt hinge in this small study. The fixed-length projection follows existing constrained hand controls; the angular equation extends the museum's existing pendulum model. Springs remain the hall's primary reconstruction.

43 native core checks and21 installed-room checks pass, including actual controls, supplied XR point/slider poses,176 supported capsule samples and native captures. The first headless teardown crashed after assertions; stopping the child handles and waiting through a physics frame before freeing the manually driven rig resolved it. Its log remains in the review. Headset and independent learner assessment remain open. [Images, full code, text and evidence](../../iterations/2026-10-09-pendulum-a-recorded-push/index.html); [artifact contract](../../../../commons/artifacts/pendulum_noise/README.md).

This supplies a measured response, not closed-loop control, adaptation or stochastic resonance. The next P2 return still needs an explicit output measurement feeding a controller.''' + s[end:]
s=s.replace('G1pendulum/G2navigatorproposed.','G1pendulum_noise installedForcesOscillation:43core+21museum;G2navigatorproposed.')
p.write_text(s,encoding='utf-8')
change(R/'tools/audit_uncertainty_plan.py',"'resolution_colonnade','geometry_noise']","'resolution_colonnade','geometry_noise','pendulum_noise']")
change(R/'tools/audit_uncertainty_plan.py','runtime receipts for G0 and CA','runtime receipts for G0, G1 and CA')
p=R/'tools/build_uncertainty_plan.py';s=p.read_text(encoding='utf-8')
s=s.replace("'G0 built; further returns proposed' if source['id']=='noise' else 'proposed'","{'noise':'G0 built; further returns proposed','forces':'G1 built; P1 still proposed'}.get(source['id'],'proposed')")
s=s.replace('G0 geometry-noise prototype installed; P1–P6 and G1–G2 remain proposed','G0 geometry-noise and G1 pendulum installed; P1–P6 and G2 remain proposed')
s=s.replace('G0 has its own native test receipts.','G0 and G1 have their own native test receipts.')
s=s.replace('25 sequences retained · G0 built · six original packages proposed','25 sequences retained · G0 and G1 built · six original packages proposed')
s=s.replace('Pendulum and navigator experiments remain proposals, alongside','<a href="../../iterations/2026-10-09-pendulum-a-recorded-push/index.html">G1: The same release / a recorded push</a> is installed in the Forces oscillation hall. The navigator remains proposed, alongside')
s=s.replace('G0 geometry-noise prototype built; original P1–P6 and next G1–G2 remain proposed.','G0 geometry-noise and G1 pendulum built; original P1–P6 and next G2 remain proposed.')
s=s.replace('G0 runtime receipts are in the separate geometry-noise review','G0/G1 runtime receipts are in their separate museum reviews')
p.write_text(s,encoding='utf-8')
print('Plan records two built prototypes; further packages remain proposed.')
