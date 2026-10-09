from pathlib import Path
import hashlib,json
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[4]
changes={
'algorithms/randomness/seed_replay/seed_replay_demo.gd':[
('# Same seed always produces the exact same pattern.','# Replay repeats a pattern when the generator, seed and draw procedure are held fixed.'),
('# essence: deterministic chaos — identical seeds yield identical worlds','# essence: a seeded pseudorandom stream, replayed with or without one discarded draw'),
('# emerges: the grid looks random but is perfectly repeatable — chaos and order coexist','# emerges: the same seed can dress the grid differently when draw consumption changes'),
('# truth: Pseudorandomness is determinism wearing a mask — the seed is the face underneath.','# truth: Nothing in a draw says that it is red; the program assigns that role by where the draw falls.')],
'commons/artifacts/shannon_entropy_meter/shannon_entropy_meter.gd':[
('# desire: to make the abstract "amount of randomness" a thing on a wall the player can read like a thermometer','# desire: to make a sample’s symbol-frequency entropy inspectable beside the ordered record it does not measure'),
('# triggers: continuous re-sampling of a random stream, frequency histogram bars updating, entropy bar climbing toward log₂(N)','# triggers: a seeded sample is measured at build; ledger controls sort its display, compare a second sample and disclose the measurement'),
('# emerges: the visual fact that uniform distributions have HIGHER entropy than skewed ones — randomness IS evenness; at disclosure:oracle the same H arrives with the histogram gone, and the gauge asks to be believed instead of read','# emerges: equal symbol shares maximize this categorical entropy; sorting leaves it unchanged, while disclosure:oracle withholds the histogram behind the same reading'),
('# truth: information IS uncertainty resolved — H = -Σ p(x) log₂ p(x) is the formula for "how surprised should you be?"','# truth: This H averages surprise from the observed symbol shares; it does not inspect neighbours, spatial disorder or thermodynamic entropy.')],
'algorithms/randomness/dice_throw/dice_throw.gd':[
('# Roll a 6 → 100 balls rain from the sky. Roll a 1 → 1 ball.','# At the default16balls per pip, a6releases96balls and a1releases16.'),
('# Demonstrates discrete uniform distribution and expected value.','# Compares a record of physical throws with the equal-probability model.'),
('# QFEP: Equiprobability — each face equally likely. Fairness as symmetry.','# QFEP: Cube symmetry offers a fairness hypothesis; the throwing procedure remains part of the experiment.'),
('# essence: P(X=k) = 1/6 for k ∈ {1,...,6} — discrete uniform distribution','# essence: six physical faces, an orientation readout and an empirical record; P(X=k)=1/6 is the comparison model'),
('# emerges: the histogram converges to E[X]=3.5 — fairness is not felt in one throw but in the accumulation','# emerges: face counts and the running mean retain outcomes beyond one spectacular throw; convergence to3.5is not guaranteed by this apparatus'),
('# truth: Fairness is not a single outcome — it is the symmetry of the generating process.','# truth: A symmetric body does not by itself establish equally likely outcomes under every way of throwing it.'),
('# argument — the canonical FAIR source, trusted not because it explains itself\n# but because of two properties you can check with your eyes before it is\n# thrown: it is a CUBE (symmetric under 24 rotations, so no face is privileged)','# argument — a familiar candidate for a fair source, whose equal-face model\n# draws on two properties visible before it is thrown: it is a CUBE (its\n# shape has24rotational symmetries; a launch need not share them)'),
('# counts still accumulate internally at every rung, and P(X=k) is still 1/6.','# counts still accumulate internally at every rung; the equal-face model remains a hypothesis.')],
'algorithms/randomness/generative/tenprintantmaze/ten_print_maze.gd':[
('#   grid, drawn as one of two diagonals, and nothing else. Four bytes of entropy per cell,\n#   repeated until the screen fills.','#   grid, drawn as one of two diagonals. One unbiased binary choice has one bit\n#   of Shannon entropy; that is distinct from its storage representation.'),
('# 10 PRINT CHR$(205.5+RND(1)); : GOTO 10 is the most famous four bytes of\n# generative art, and its whole claim lives in ONE decision: what a single','# 10 PRINT CHR$(205.5+RND(1)); : GOTO 10 makes generative art from one\n# repeated decision: what a single')]
}
for rel,replacements in changes.items():
    path=ROOT/rel;before=(HERE/'before-source'/rel).read_bytes()
    current=path.read_bytes();assert current==before,rel+' changed since snapshot'
    text=current.decode('utf-8-sig'); newline='\r\n' if '\r\n' in text else '\n';text=text.replace('\r\n','\n')
    for old,new in replacements:
        assert text.count(old)==1,(rel,old)
        text=text.replace(old,new,1)
    # Preserve original BOM and newline convention.
    path.write_bytes((b'\xef\xbb\xbf' if current.startswith(b'\xef\xbb\xbf') else b'')+text.replace('\n',newline).encode('utf-8'))
print('Guarded source identity corrections:',len(changes))
