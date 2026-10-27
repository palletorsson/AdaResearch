// The lab side of tools/address_rules_crosscheck.py --disco: the disco floor study's states
// (ada_encyclopedia/src/lib/colour-study.ts discoStates) for the hall console's six RULES patterns
// (commons/artifacts/regularity/disco_controls.gd RULE_PATTERNS), beat by beat, as JSON.
import {readFileSync} from 'fs';
import {discoStates} from '../../ada_encyclopedia/src/lib/colour-study';

type Case = {name: string; settings: Record<string, string | number>; beats: number};
const cases: Case[] = JSON.parse(readFileSync(process.argv[2], 'utf-8'));
process.stdout.write(JSON.stringify(cases.map(c => ({name: c.name, beats: Array.from({length: c.beats}, (_, t) => discoStates(c.settings, t))}))));
