usethis::use_pipe(export =TRUE)
####@importFrom magrittr "%>%"
#'
#' Build SwabSeq environment variable
#'
#' This function creates an env() containing information about directory structures and key run parameters.
#'
#' @export
buildEnvironment=function(basedir.dir, remote.dir, localmirror.dir, bcl.dir, threads=8, lbuffer=30e6, fastqcr=F, i7_plate_key_file=NULL, i5_plate_key_file=NULL) {
    cfg = new.env(parent=emptyenv())
    path_to_bs=tryCatch(system('command -v bs', intern=T), error=function(e) {return(NULL)})
    path_to_bcl2fastq=tryCatch(system('command -v bcl2fastq', intern=T), error=function(e) {return(NULL)})
    bs_config_present=file.exists(paste0(Sys.getenv("HOME"),'/.basespace/default.cfg'))
    if(is.null(path_to_bs)) {print('bs CLI tool not found in PATH')}
    if(is.null(path_to_bcl2fastq)) {print('bcl2fastq not found in PATH')}
    if(!(bs_config_present)) {print('basespace cfg file not found at ~/.basespace/default.cfg')}

    #i7_plate_key_file=    paste0(basedir.dir, 'reference/s2_r.csv')
    #i5_plate_key_file =   paste0(basedir.dir, 'reference/s2_f.csv')
    
    if(is.null(i7_plate_key_file)){
    i7_plate_key_file =  system.file("keys", "s2_r.csv", package="swabseqr")
    }
    if(is.null(i5_plate_key_file)){
    i5_plate_key_file =  system.file("keys", "s2_f.csv", package="swabseqr")
    }

    cfg$i7_plate_key_file=i7_plate_key_file
    cfg$i5_plate_key_file=i5_plate_key_file

# Directory structures on samba share -------------------------------- 
    # seq.dir is path to location of yaml, summary stats for each run, and reports
    seq.dir=paste0(remote.dir, 'seq/')
    seq.run.dir=paste0(remote.dir, 'seq/runs/')
    #seq.dir=paste0(basedir.dir, 'remote/seq/runs/')
    #path to swabseq remote file share sample tracking folder
    
    sampleTracking.dir=paste0(remote.dir, 'swabseqsampletracking/')
    #sampleTracking.dir=paste0(basedir.dir, 'remote/completed/1_Jan4/' )

    #path to swabseq remote file share preceiseQ orders 
    incomingOrders.dir=paste0(remote.dir,  'precisemdx_sftp_orders/')

    #location of tracking water tubes 
    waterTubesKeyDir=paste0(seq.dir, 'water_tubes/')
    yaml.cfg.file=paste0(seq.dir, 'config.yaml')
#---------------------------------------------------------------------

# Directory structures for local mirroring bits of samba share ------
    localMirrorSeq.dir=paste0(localmirror.dir, 'seq/')
    localMirrorSeq.run.dir=paste0(localmirror.dir, 'seq/runs/')
    #mirror incoming orders locally
    localIncomingOrders.dir=paste0(localmirror.dir, 'precisemdx_sftp_orders/')
    #mirror sample tracking locally
    localTracking.dir=paste0(localmirror.dir, '/swabseqsampletracking/')

    cfg$basedir.dir=basedir.dir
    cfg$remote.dir=remote.dir
    cfg$localmirror.dir=localmirror.dir
    cfg$seq.dir=seq.dir
    cfg$seq.run.dir=seq.run.dir
    cfg$bcl.dir=bcl.dir
    cfg$tracking.dir=sampleTracking.dir
    cfg$localtracking.dir=localTracking.dir
    cfg$localMirrorSeq.dir=localMirrorSeq.dir
    cfg$localMirrorSeq.run.dir=localMirrorSeq.run.dir
    cfg$incomingOrders.dir=incomingOrders.dir
    cfg$localIncomingOrders.dir=localIncomingOrders.dir
    cfg$yaml.cfg.file=yaml.cfg.file
    cfg$waterTubesKeyDir=waterTubesKeyDir

    cfg$path_to_bs=path_to_bs
    cfg$path_to_bcl2fastq= path_to_bcl2fastq
    cfg$bs_config_present=bs_config_present

    cfg$coreVars=setAnalysisVariables(threads=threads,lbuffer=lbuffer,fastqcr=fastqcr)
#-------------------------------------------------------------------------
    return(cfg)
}

#' Set Analysis Variables
#'
#' This function is called by buildEnvironment() and sets key analysis parameters, exposed here for user overwriting.
#'
#' @export
setAnalysisVariables=function(versi=2, diversifiedSpike=T,lbuffer=30000000, threads=8,fastqcr=F){
    if(versi==1) {
        flagLowPositive=F
        diversifiedSpike=F
        Stotal=500
        Rpp=10
        Ratio=0.003
    }
    if(versi==2){
        flagLowPositive=F
        diversifiedSpike=T
        Stotal=500
        Rpp=10
        Ratio=0.05 #was 0.03
    }
    if(diversifiedSpike) {
        amplicons=list(
            S2=         'TATCTTCAACCTAGGACTTTTCTATT',
            S2_spike000='ATAGAACAACCTAGGACTTTTCTATT',
            S2_spike001='GTGTATCTCACGAAGCGACCCTTTGG',
            S2_spike002='CCTCGCTAGGACGTCGCTATGACGCC',
            S2_spike003='AGCACGACTTGATCTAACTGACACTA',
            S2_spike004='TAAGTAGGACTTCGATTGGATGGAAT',
            RPP30      ='CGCAGAGCCTTCAGGTCAGAACCCGC'
        )
    } else {
        amplicons=list(
        S2=      'TATCTTCAACCTAGGACTTTTCTATT',
        S2_spike='ATAGAACAACCTAGGACTTTTCTATT',
        RPP30='CGCAGAGCCTTCAGGTCAGAACCCGC'
        #RPP30_spike='GCGTCAGCCTTCAGGTCAGAACCCGC'
        )
    }
    if(fastqcr) {
        if(!file.exists('~/bin/FastQC')) { fastqcr::fastqc_install() }
    }
    
    return(list(
            versi=versi,
            lbuffer=lbuffer,
            threads=threads,
            fastqcr=fastqcr,
            flagLowPositive=flagLowPositive,
            diversifiedSpike=diversifiedSpike,
            Stotal=Stotal,
            Rpp=Rpp,
            Ratio=Ratio,
            amplicons=amplicons,
            empty_well_set=c('', 'TBET', 'No Tube', 'NO TUBE', 'Empty', 'EMPTY', ' ', 'NA') 
            ))
}
