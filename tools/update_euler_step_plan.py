"""Record P1 evidence while keeping later work packages editable proposals."""
from pathlib import Path
R=Path(__file__).resolve().parents[1];P=R/'doc/book/course/uncertainty-plan'
def edit(path,old,new):
 s=path.read_text(encoding='utf-8')
 if old in s:path.write_text(s.replace(old,new),encoding='utf-8')
 else:assert new in s,(path,old)
edit(P/'PLAN.md','The six original packages remain proposed additions.','P1, the first original package, is now built; P2–P6 remain proposed additions.')
edit(P/'PLAN.md','with the six original packages still proposed. It supplies an additional starting point; the original P1 time-step comparison remains proposed.','with P1 now built and P2–P6 still proposed. P1 follows as a separate time-step comparison in Launch.')
edit(P/'PLAN.md','### P1 — The same throw, different steps\n','''### P1 — The same throw, different steps

**Built 9 October in VFM_05_Launch.** The existing registered Euler artifact selects a new step-study child with `lesson:step_study`; one bay beside the launch chamber, all prior works retained. Complete code and explanations are printed in the hall tutorial; three reflective paragraphs extend final.md. 53 native core checks, 51 checks on fresh printed-code reconstruction, two rejected mutations and 22 museum checks pass. The museum checks include endpoint retention after rendered frames, five pointer buttons, the held XRTools step slider and a supported approach. Default small-board geometry remains; its unsupported tunnelling caption is corrected. Physical headset and independent learner tests remain open. [Images, full texts and receipts](../../iterations/2026-10-09-the-same-throw-different-steps/index.html). The contract below remains available for revision.
''')
edit(P/'PLAN.md','The first prototype is P1. Finish its comparison, tutorial and two views before promoting another primary experiment. Keep every other package editable as a proposal.','P1 is built with comparison, complete tutorial and native views. P3 (sample budget on the existing Monte Carlo dartboard) is next in the execution queue. Keep the other packages editable as proposals; inspect each current host before implementation.')
edit(P/'PLAN.md','## File-level handoff for the first prototype','## P1 implementation record and reusable procedure')
edit(P/'PLAN.md','P1-P6stillproposed.','P1BUILT:53core+51printed+2mutants+22museum;P2-P6proposed.')
edit(P/'PLAN.md','P1nextoriginalpackage.','P3nextoriginalpackage;P1endpointprojectiontestedafterrender.')
edit(P/'NOISE_TESTS.md','P1, the original same-throw comparison, remains the next original work package; its own hall inspection precedes implementation.','P1, the original same-throw comparison, is now built in Launch with its own native receipts. P3 sample budget is next; its current hall and dartboard must be inspected before implementation.')
edit(P/'NOISE_TESTS.md','P1nextoriginalpackage.','P1built;P3nextoriginalpackage.')
edit(P/'SEQUENCES.md','**P1 primary.** One sphere throw, reference arc and stepped trace.','**P1 built, optional Launch comparison.** The carried point, a reference arc and explicit Euler trace; same one-second flight at 10/20/40 steps. 53core+51printed checks, two rejected faults, 22museum checks. The launch encounter remains primary.')
edit(P/'INVENTORY.md','The CA lesson, G0, G1 and G2 have separate native test receipts.','The CA lesson, G0, G1, G2 and P1 have separate native test receipts.')
p=P/'INVENTORY.md';s=p.read_text(encoding='utf-8');lines=s.splitlines()
for i,line in enumerate(lines):
 if line.startswith('| [euler_drift]'):
  lines[i]='| [euler_drift](../../../../algorithms/forces/euler_drift/README.md) — source, registered, placed and tested | Opt-in explicit Euler comparison with a constant-acceleration reference; original small geometry retained | Launch bay: 10/20/40-step hand slider, one step, fire/pause, replay, other throw, reset | **P1 built.** Same duration, signed error, independent launch, bounded trace and rendered endpoint checked. Legacy caption corrected: visual marker, no tunnelling proof. [Receipt](../../iterations/2026-10-09-the-same-throw-different-steps/index.html) |'
s='\n'.join(lines)+'\n';s=s.replace('- A measured, hand-operated numerical step comparison with a valid reference.','- P1 now supplies a measured step comparison. Spring stability and actual collision/tunnelling remain separate future questions.')
p.write_text(s,encoding='utf-8')
p=R/'tools/build_uncertainty_plan.py';s=p.read_text(encoding='utf-8')
s=s.replace('G1 built; P1 still proposed','G1 and P1 built; further returns proposed')
s=s.replace('G0 geometry-noise, G1 pendulum and G2 observation installed; P1–P6 remain proposed','G0 geometry-noise, G1 pendulum, G2 observation and P1 stepping installed; P2–P6 remain proposed')
s=s.replace('G0, G1 and G2 have their own native test receipts.','G0, G1, G2 and P1 have their own native test receipts.')
s=s.replace('G0, G1 and G2 built · six original packages proposed','G0, G1, G2 and P1 built · five original packages proposed')
s=s.replace('The next original package remains <a href="#p1-the-same-throw-different-steps">P1: one sphere, one arc, different time steps</a>.','<a href="../../iterations/2026-10-09-the-same-throw-different-steps/index.html">P1: The same throw, different steps</a> is installed beside the launch chamber. Next is P3: sample budget on the existing dartboard.')
s=s.replace('G0 geometry-noise, G1 pendulum and G2 observation built; original P1–P6 remain proposed.','G0 geometry-noise, G1 pendulum, G2 observation and P1 stepping built; P2–P6 remain proposed.')
s=s.replace('G0/G1/G2 runtime receipts','G0/G1/G2/P1 runtime receipts');p.write_text(s,encoding='utf-8')
print('P1 recorded as built; remaining packages and 25-sequence spine retained.')
