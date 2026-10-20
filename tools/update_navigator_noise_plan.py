"""Record one built G2; keep other proposals and the current spine editable."""
from pathlib import Path
R=Path(__file__).resolve().parents[1]; P=R/'doc/book/course/uncertainty-plan'
def edit(path,old,new):
 s=path.read_text(encoding='utf-8')
 if old in s:s=s.replace(old,new,1);path.write_bytes(s.encode('utf-8'))
 else:assert new in s,(path,old)
edit(P/'PLAN.md','geometry-noise and pendulum experiments are recorded as built below','geometry-noise, pendulum and observation experiments are recorded as built below')
edit(P/'PLAN.md','records G0 and G1 as built, with the navigator and six original packages still proposed','records G0, G1 and G2 as built, with the six original packages still proposed')
edit(P/'PLAN.md','All 17 selected registry entries, including the newly built G0 and G1','All 18 selected registry entries, including the newly built G0, G1 and G2')
edit(P/'PLAN.md','G2navigatorproposed.','G2navigator_noise BUILT SwarmIntelligence_Agent_Based_Modeling_ABM;40core+40printed+2mutants+21museum. P1nextoriginalpackage.')
edit(P/'NOISE_TESTS.md','## G1 built; G2 still proposed','## G1 and G2 built')
p=P/'NOISE_TESTS.md';s=p.read_text(encoding='utf-8')
old='**G2 — A navigator receives an imperfect observation.** Reuse one agent in Swarms after goal-directed movement is understood. Keep the physical obstacle fixed and display true distance, observed distance and the agent\'s command. Add recorded noise first, then dropout as a distinct mode with a declared fallback. Success is reaching the goal before a specified limit without collision. Repeated seeds allow comparisons. No learning/adaptation claim until a separately identified policy update is implemented and tested. Machine Learning can revisit that added capacity later.'
new='''**G2 — A navigator receives an imperfect observation. Built in SwarmIntelligence_Agent_Based_Modeling_ABM.** Two inherited point spheres share an authored course, obstacle, goal, detour, speed and starting pose. One has accurate range; the other receives recorded Gaussian range error or dropout as separate modes. A missing value is null; STOP and HOLD give it different consequences. The fixed20Hz kinematic model checks swept disc contact and course exit, records the decision and actual path, and finishes within20simulated seconds. Known position/direction and waypoints are supplied; this is not a navmesh, learned policy or Jolt simulation. The colony remains primary, and the companion reconstructs this smaller policy explicitly rather than treating earlier ABM fragments as complete.

40core assertions and40checks on freshly extracted printed code pass. Two real mutations—missing-as-zero and endpoint-only contact—fail the expected assertions.21native museum checks include supplied hand poses, six nearby buttons and72supported route samples. Seed1847 with65% missing blocks reaches contact at3.65s under HOLD and the goal at19.15s under STOP. All20paired results from seeds1847–1856 and the actual saved input arrays are retained; no population robustness estimate is claimed. The front-bay placement was rejected for pillar occlusion; the final study occupies the open end of the existing room. Physical headset and independent learner checks remain open. [Images, code and receipts](../../iterations/2026-10-09-navigator-an-imperfect-observation/index.html); [artifact contract](../../../../commons/artifacts/navigator_noise/README.md).

The three G studies now make position, response and observation distinct intervention sites. P1, the original same-throw comparison, remains the next original work package; its own hall inspection precedes implementation. No further generic injection framework is implied.'''
if old in s:s=s.replace(old,new,1)
else:assert new in s
s=s.replace('G2navigatorproposed.','G2navigator_noise installedABM:40core+40printed+2mutants+21museum;P1nextoriginalpackage.')
p.write_bytes(s.encode('utf-8'))
edit(P/'INVENTORY.md','17 selected entries, including the newly installed geometry-noise and pendulum experiments','18 selected entries, including the newly installed geometry-noise, pendulum and observation experiments')
edit(P/'INVENTORY.md','The CA lesson, G0 and G1 have separate native test receipts.','The CA lesson, G0, G1 and G2 have separate native test receipts.')
p=P/'INVENTORY.md';s=p.read_text(encoding='utf-8')
row='| [navigator_noise](../../../../commons/artifacts/navigator_noise/README.md) — newly built, placed and tested | Saved range error or observation dropout; fixed kinematic course and explicit STOP/HOLD decisions | SwarmIntelligence_Agent_Based_Modeling_ABM; lower point sets both starts; one slider and six adjacent buttons | **G2 built.** 40core+40printed checks;2mutants rejected;21museum checks. Supplied waypoints, swept analytic contact; no learning/Jolt claim. [Receipt](../../iterations/2026-10-09-navigator-an-imperfect-observation/index.html) |\n'
if '| [navigator_noise]' not in s:s=s.replace('| [pendulum_noise]',row+'| [pendulum_noise]',1);p.write_bytes(s.encode('utf-8'))
p=P/'SEQUENCES.md';s=p.read_text(encoding='utf-8');lines=s.splitlines()
for i,line in enumerate(lines):
 if '| SwarmIntelligence_' in line and 'G2 built' not in line:
  cells=line.split('|');cells[2]=cells[2] if 'SwarmIntelligence_Agent_Based_Modeling_ABM' in cells[2] else cells[2].rstrip()+'; SwarmIntelligence_Agent_Based_Modeling_ABM ';cells[4]=' **G2 built, optional ABM study:** known course, accurate/noisy range, separate dropout with STOP/HOLD; true observation and command logged. Existing collective encounters remain primary. '+cells[4].strip()+' ';lines[i]='|'.join(cells)
p.write_bytes(('\n'.join(lines)+'\n').encode('utf-8'))
edit(R/'tools/audit_uncertainty_plan.py',"'geometry_noise','pendulum_noise']","'geometry_noise','pendulum_noise','navigator_noise']")
edit(R/'tools/audit_uncertainty_plan.py','runtime receipts for G0, G1 and CA','runtime receipts for G0, G1, G2 and CA')
p=R/'tools/build_uncertainty_plan.py';s=p.read_text(encoding='utf-8')
s=s.replace("'forces':'G1 built; P1 still proposed'","'forces':'G1 built; P1 still proposed','swarmintelligence':'G2 built; further returns proposed'")
s=s.replace('G0 geometry-noise and G1 pendulum installed; P1–P6 and G2 remain proposed','G0 geometry-noise, G1 pendulum and G2 observation installed; P1–P6 remain proposed')
s=s.replace('G0 and G1 have their own native test receipts.','G0, G1 and G2 have their own native test receipts.').replace('G0 and G1 built','G0, G1 and G2 built')
s=s.replace('The navigator remains proposed, alongside','<a href="../../iterations/2026-10-09-navigator-an-imperfect-observation/index.html">G2: An imperfect observation</a> is installed in Agent-Based Modeling. The next original package remains')
s=s.replace('G0 geometry-noise and G1 pendulum built; original P1–P6 and next G2 remain proposed.','G0 geometry-noise, G1 pendulum and G2 observation built; original P1–P6 remain proposed.')
s=s.replace('G0/G1 runtime receipts','G0/G1/G2 runtime receipts');p.write_bytes(s.encode('utf-8'))
print('Three built studies recorded; original packages and25-sequence order retained.')
