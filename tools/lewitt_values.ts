// The lab side of tools/address_rules_crosscheck.py --lewitt: the incomplete open cubes the
// spatial lab enumerates (ada_encyclopedia/src/lib/colour-study.ts), canonical masks as JSON.
import {incompleteOpenCubes} from '../../ada_encyclopedia/src/lib/colour-study';

process.stdout.write(JSON.stringify({rotations: incompleteOpenCubes(false), mirrors: incompleteOpenCubes(true)}));
