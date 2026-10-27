// The TypeScript side of tools/address_rules_crosscheck.py: every address rule of the spatial
// lab (ada_encyclopedia/src/lib/colour-study.ts RULES) evaluated on the grids the cross-check
// names, printed as JSON. Run by the cross-check with tsx; the encyclopedia is the sibling repo.
import {readFileSync} from 'fs';
import {RULES} from '../../ada_encyclopedia/src/lib/colour-study';

type Case = {rule: string; size: number; n: number; a: number; b: number};
const cases: Case[] = JSON.parse(readFileSync(process.argv[2], 'utf-8'));   // a file: the grid is too long for a Windows command line
const out = cases.map(c => {
  const states: number[] = [];
  for (let x = 0; x < c.size; x++) for (let z = 0; z < c.size; z++) states.push(RULES[c.rule].f(x, z, c.n, c.size, c.a, c.b));
  return {...c, states};
});
process.stdout.write(JSON.stringify({rules: Object.keys(RULES), cases: out}));
