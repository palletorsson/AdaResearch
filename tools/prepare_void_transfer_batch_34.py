"""Continue placement-first with remaining Foundations Crisis and entropy."""
import prepare_void_transfer_batch as base
base.OUT=base.ROOT/'doc/void-transfer/2026-10-21-batch-34'
base.JOBS={'foundationscrisis_03':'Codex','qfeplaboratory_02':'Codex'}
base.SOURCE_SELECTIONS={
 'foundationscrisis_03':{'sequence':'foundationscrisis','maps':['Escher_Impossible','Brouwer_Intuitionism','Florensky_Paraconsistent','Crisis_Synthesis']},
 'qfeplaboratory_02':{'sequence':'qfeplaboratory','maps':['QFEP_E_Term']},
}
if __name__=='__main__':base.main()
