"""Continue placement-first with remaining QFEP laboratory maps."""
import prepare_void_transfer_batch as base
base.OUT=base.ROOT/'doc/void-transfer/2026-10-21-batch-35'
base.JOBS={'qfeplaboratory_03':'Codex'}
base.SOURCE_SELECTIONS={
 'qfeplaboratory_03':{'sequence':'qfeplaboratory','maps':['QFEP_Lambda_Spectrum','QFEP_Phi_Term','QFEP_Edge_Of_Chaos','QFEP_Sandbox','QFEP_Synthesis']},
}
if __name__=='__main__':base.main()
