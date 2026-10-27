"""Continue placement-first: remaining ML plus two Foundations Crisis maps."""
import prepare_void_transfer_batch as base
base.OUT=base.ROOT/'doc/void-transfer/2026-10-21-batch-33'
base.JOBS={'machinelearning_03':'Codex','foundationscrisis_02':'Codex'}
base.SOURCE_SELECTIONS={
 'machinelearning_03':{'sequence':'machinelearning','maps':['ML_Sequence_Memory','ML_Generative','ML_Synthesis']},
 'foundationscrisis_02':{'sequence':'foundationscrisis','maps':['Russell_Paradox','Godel_Incompleteness']},
}
if __name__=='__main__':base.main()
