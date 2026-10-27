"""Prepare the remaining five CA maps as independent, uncurated Void floors."""
import prepare_void_transfer_batch as base

base.OUT = base.ROOT / 'doc/void-transfer/2026-10-21-batch-26'
base.JOBS = {'cellularautomata_03': 'Codex'}
base.SOURCE_SELECTIONS = {'cellularautomata_03': {
    'sequence': 'cellularautomata',
    'maps': ['CA_BeyondBinary', 'CA_ExpandingSpace', 'CA_SoftRules',
             'CA_AgentsCircuits', 'CA_EdgeOfChaos'],
}}

if __name__ == '__main__':
    base.main()
