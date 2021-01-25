#' Auto Run the Pipeline
#'
#' If cfg environment variable is set, this function will autorun the pipeline.
#' @param check.yaml.interval seconds before checking config.yaml file for updates
#' @param check.basespace.interval seconds before checking basespace to see if a run has updated
#'
#' @export
autoRun=function(check.yaml.interval=30, check.basespace.interval=600, syncToShared=T, writeCurrentResultsTable=F){
    if(!exists("cfg")) { print('please run buildEnvironment() before autoRun()'); return(NULL)}

    if(!file.exists(cfg$yaml.cfg.file))  {
        print(paste(cfg$yaml.cfg.file, 'not found'))
        return(NULL)
    }

    inc=0  
    before=tools::md5sum(cfg$yaml.cfg.file)
    after="" #before
    while(TRUE){
        if(inc%%10==0){print(Sys.time()) }
        if( (after!=before) | inc%%(check.basespace.interval/check.yaml.interval)==0) {
            #before=md5sum(cfg$yaml.cfg.file)
            print('syncing config.yaml')
            syncRuns()
            #after=md5sum(cfg$yaml.cfg.file)
            print('downloading BCLs')
            downloadRuns()
            #before=md5sum(cfg$yaml.cfg.file)
            print('converting to fastq.gz')
            bcl2fastqRuns() 
            #after=md5sum(cfg$yaml.cfg.file)

            print('demultiplexing runs and counting amplicons')
            demuxRuns() 

            #before=md5sum(cfg$yaml.cfg.file)
            print('matching sequencing runs to key files')
            lookUpKeys()

            print('matching samples to observed indices')
            addIdentifiers()

            print('generating reports')
            syncReports(syncToShared=syncToShared, writeCurrentResultsTable=writeCurrentResultsTable)
            print(paste('Done, pausing for ', check.basespace.interval, 'seconds'))
        }
        before=tools::md5sum(cfg$yaml.cfg.file)
        Sys.sleep(check.yaml.interval)
        after=tools::md5sum(cfg$yaml.cfg.file)
        inc=inc+1

   }
}

#' Read config.yaml and convert to table
#'
#' If cfg environment variable is set, this function will read the config.yaml table for downstream analysis.
#'
#' @export
getRunTableStatus=function(...) {  return(read_yaml_cfg(cfg)) }


#' Download runs from basespace
#'
#' If cfg environment variable is set, this function download bcls from basespace.
#'
#' @export
downloadRuns=function(...) {
    rTable = getRunTableStatus()
    for(r in 1:nrow(rTable)) {
        runName=rTable$Name[r] 
        runID=rTable$ID[r]
        runHname=rTable$Hname[r]
        if(!rTable$Downloaded[r]){
            #note bcl.dir is different here than other functions
            downloadStatus=BaseSpaceDownload(runID, runName,runHname, cfg$bcl.dir )
            if(downloadStatus) {   
                rTable$Downloaded[r]=T  
                write_yaml_cfg(rTable,cfg)
            }
        }
    }
}

#' Run BCl2FASTQ 
#'
#' If cfg environment variable is set, this function will convert bcls to fastq.gz files.
#'
#' @export
bcl2fastqRuns=function(...) {
    rTable = getRunTableStatus()
    currentWorkingDir=getwd() 
    for(r in 1:nrow(rTable)) {
        runName=rTable$Name[r] 
        bcl.dir=paste0(cfg$bcl.dir, runName, '/')
        odir=paste0(cfg$seq.run.dir, runName)
        dir.create(odir)

        if(rTable$Downloaded[r] & !rTable$Bcl2fastq[r]){
            
            if(file.exists(paste0(bcl.dir, 'RTAComplete.txt')) & file.exists(paste0(bcl.dir, 'RTARead3Complete.txt')) ) { 
                setwd(bcl.dir)
                # if fastqs don't exist run bcl2fastq to generate them 
                fastqR1  <- paste0(bcl.dir, 'out/Undetermined_S0_R1_001.fastq.gz')
                status=0
                if(!file.exists(fastqR1)) { 
                    # run bcl2fastq to generate fastq.gz files (no demux is happening here)
                    #note, reduce threads if necessary
                    status=system(paste("bcl2fastq --runfolder-dir . --output-dir out/ --create-fastq-for-index-reads  --ignore-missing-bcl --use-bases-mask=Y26,I10,I10 --processing-threads",
                                 cfg$coreVars$threads,
                                 "--no-lane-splitting --sample-sheet /dev/null"))
                    if(cfg$coreVars$fastqc) {fastqcr::fastqc(fq.dir=paste0(bcl.dir, 'out/'), qc.dir=paste0(odir, '/'), threads=3) }

                }
                if(file.exists(fastqR1) & status==0){
                    system(paste0('cp ',  bcl.dir, 'RunParameters.xml', ' ', odir))
                    system(paste0('cp ',  bcl.dir, 'RunInfo.xml', ' ', odir))
                    system(paste0('cp -R ',  bcl.dir, 'InterOp/', ' ', odir))
                    rTable$Bcl2fastq[r]=T
                    write_yaml_cfg(rTable,cfg)
                }
                #reset working directory
                setwd(currentWorkingDir)
            }
        }
    }
}


#' Run BCl2FASTQ 
#'
#' If cfg environment variable is set, this function will demux amplicons given key files in $basedir.dir/reference/.
#'
#' @export
demuxRuns=function(...) {
    rTable = getRunTableStatus()
    #initalize run status
    for(r in 1:nrow(rTable)) {
        runName=rTable$Name[r] 
        #bcl.dir is different here
        bcl.dir=paste0(cfg$bcl.dir, runName, '/')
        odir=paste0(cfg$seq.run.dir, runName)
        dir.create(odir)
        if(rTable$Downloaded[r] & rTable$Bcl2fastq[r] & !rTable$Demuxed[r]){
            index.key=generateExpectedIndices(odir)
            status=countAmplicons(rTable, index.key, bcl.dir, odir, cfg$coreVars)
            if(status) { rTable$Demuxed[r] = T  
                         write_yaml_cfg(rTable,cfg)
            }
       }
    }
}


#' Sync config.yaml file 
#'
#' If cfg environment variable is set, this function will sync config.yaml with updates from basespace
#'
#' @export
syncRuns=function(first.run=F) {
    dir.create(cfg$seq.run.dir, recursive=T)
    dir.create(cfg$bcl.dir, recursive=T)
    dir.create(cfg$localtracking.dir, recursive=T)
    dir.create(cfg$localIncomingOrders.dir, recursive=T)
    
    for(dmirror in list.dirs(cfg$tracking.dir, recursive=F, full.name=F)){
        dir.create(paste0(cfg$localtracking.dir, dmirror, '/'))
        #sync samba share with local mirror, this ends up being more efficient for iterating through sample tracking folders 
        #don't include results folders!
         system(paste0("rsync  -ahe --update --exclude '*/' ",  cfg$tracking.dir, dmirror, '/', ' --delete ', cfg$localtracking.dir, dmirror, '/'))
    }

    rTable=getBaseSpaceRuns()

    if(first.run==T) { 
        initializeRuns(rTable,cfg, first.run=first.run)    
        rTable=getBaseSpaceRuns()
    }
    
    #allow manual intervention by copying output of sequencer in outputs/ to cfg$bcl.dir 
    lbcl.dirs=list.dirs(cfg$bcl.dir, recursive=F, full.names=F)
    if(!identical(lbcl.dirs, character(0))){
         fcells=gsub('^.*_A', '',lbcl.dirs)
         fcells=gsub('^000', '',fcells)
         cur.bcls.dirs=data.frame(Name=lbcl.dirs, Flowcell=fcells, Downloaded=T, stringsAsFactors=F)
         local_bcl_dirs=dplyr::anti_join(cur.bcls.dirs, rTable,by='Flowcell')
         if(nrow(local_bcl_dirs)>0){        rTable=rquery::natural_join(rTable, local_bcl_dirs, by="Flowcell",jointype='FULL') }
    }
    rTable.existing=getRunTableStatus()
    rTable=rquery::natural_join(rTable,rTable.existing, by='Name', jointype='LEFT')
    rTable$Downloaded[is.na(rTable$Downloaded)]= F
    rTable$Bcl2fastq[is.na(rTable$Bcl2fastq)]= F
    rTable$Demuxed[is.na(rTable$Demuxed)]= F
    rTable$Analyzed[is.na(rTable$Analyzed)]= F
    rTable$Reported[is.na(rTable$Reported)]= F
    
    write_yaml_cfg(rTable,cfg)
}


#' Lookup experiments and flowcells and merge with basespace information 
#'
#' If cfg environment variable is set, this function will sync basespace runs with the experiment folder, and
#' sample keys from scanning matrix tubes. Merge is performed based on flowcell file in each run directory.
#'
#' @export
lookUpKeys=function(...){
    rTable   = getRunTableStatus()
    Flowcell = getFlowCellIds() 
    Keyfile  = getKeyFiles() 
    if(all.equal(names(Flowcell), names(Keyfile))) {
    sample.lookup=data.frame(Experiment=names(Flowcell), 
                                 Flowcell=unlist(Flowcell),
                                 Keyfile=unlist(Keyfile),
                                 stringsAsFactors=F, row.names=NULL)

     rTable= rTable %>% dplyr::left_join(sample.lookup, by='Flowcell') %>% 
                dplyr::mutate(Experiment=wrapr::coalesce(Experiment.y, Experiment.x),
                         Keyfile=wrapr::coalesce(Keyfile.y, Keyfile.x) ) %>% 
                dplyr::select(-Experiment.x, -Experiment.y, -Keyfile.x, -Keyfile.y)

      #rTable= natural_join(rTable,sample.lookup, by='Flowcell', jointype='LEFT')
      write_yaml_cfg(rTable,cfg)
    } else  {
     print("lookup error")
    }
}

 #find flow cell file
findFlowCellFile=function(rundir, findDir=T){
     dl=list.files(rundir, full=T)
     find.flowcell=grepl('flow.*.txt', dl,ignore.case=T)
     if(sum(find.flowcell)==1){
         if(findDir){
          h=strsplit(dl[find.flowcell],'/')[[1]]
          h=h[h!=""]
          return(h[length(h)-1])
         } else{
          return(gsub('\r|\n', '', system(paste("cat", dl[find.flowcell]), intern=T)))
         }
     }else {
         print("error, more than one flowcell file found")
         #quit(save="no")
     }
}





# initalize seq.dir with files indicating that analysis has completed
# this is to prevent the script re-running all previous runs
#ADD CODE here to sync with existing config file
initializeRuns=function(rTable,cfg, first.run=F){
  for(r in 1:nrow(rTable)) {
        if(first.run) {
                rTable$Downloaded[r]=T
                rTable$Bcl2fastq[r]=T
                rTable$Demuxed[r]=T
                rTable$Analyzed[r]=T
                rTable$Reported[r]=T
        }
   }
   write_yaml_cfg(rTable,cfg)
}


read_yaml_cfg=function(cfg){
    parselist=data.frame(data.table::rbindlist(yaml::read_yaml(cfg$yaml.cfg.file),idcol='Name'), stringsAsFactors=F)
    return(parselist)
}

write_yaml_cfg=function(rTable,cfg){
    yaml::write_yaml(split(rTable[,-match('Name', names(rTable))], rTable$Name),
               cfg$yaml.cfg.file, column.major=T, indent.mapping.sequence=T, indent=5)
}
#ping basespace and get info back about all runs
getBaseSpaceRuns=function(...){
    #get existing basespace runs 
    bs.list.runs=system(paste0('bs list runs'), intern=T)
    bs.list.runs=bs.list.runs[-c(1:3,length(bs.list.runs))]
    parselist=data.table::tstrsplit(bs.list.runs, "\\| ")
    parselist=data.frame(sapply(parselist, function(x) gsub(" ", "", x)), stringsAsFactors=F)[,-1]
    names(parselist)=c('Name', 'ID','Hname', 'Status')
    parselist$Flowcell=gsub('^.*_A', '',parselist$Name)
    parselist$Flowcell=gsub('^000', '',parselist$Flowcell)
    parselist$Status=gsub('\\|', '', parselist$Status)
    parselist$Experiment=NA
    parselist$Keyfile=NA
    parselist$Downloaded=NA
    parselist$Bcl2fastq=NA
    parselist$Demuxed=NA
    parselist$Analyzed=NA
    parselist$Reported=NA
    return(parselist)
}

# check if run is finished, if so download
BaseSpaceDownload=function(runID, runName, runHname, rdir,  pause_time=300){
    #code block from Kyle Kovary ------------------------------------------
    run_finished <- FALSE
       # while(!run_finished){
     check <- system(paste0("bs run contents --id ", runID), intern = T)
     run_finished <- sum(grepl("RTAComplete.txt", check)) > 0
          if(run_finished){
            bcl.save.dir=paste0(rdir,runName, '/')
            status=system(paste0("bs download run --id ", runID, " -o ", bcl.save.dir))
            if(status==0) { status=TRUE }
            message(paste0(runName, " ", runHname, " finished: ", format(Sys.time())))
            #break()
          } else{
            message(paste0(runName, " ", runHname, " not finished: ", format(Sys.time())))
            #check every 5 min for run to finish
            status = FALSE 
            #Sys.sleep(pause_time)
          }
        #}
    return(status)
}

#get flowcell information
getFlowCellIds=function(...) {
    print("finding flowcell information")
    sample.dirs=list.dirs(paste0(cfg$localtracking.dir), recursive=F, full.names=F)
    flowcells=list()
    for(d in sample.dirs){
        #print(d)
        flowcells[[d]]=(findFlowCellFile(paste0(cfg$localtracking.dir, d,'/'),findDir=F))[1]
    }
    #if user adds extra new-line characters to flowcell file, deal with it
    #flowcells=sapply(flowcells, function(x)  gsub('\r', '', x))
    return(flowcells)
}

#check to make sure key files aren't .swp
getKeyFiles=function(...) {
    #Sys.setenv(LC_ALL= "C")
    #Sys.setenv(LC_ALL= "en_US.UTF-8")
    print("finding csv key files")
    sample.dirs=list.dirs(cfg$localtracking.dir, recursive=F, full.names=F)
    currentWorkingDir=getwd() 
    keyfiles=list()
    for(d in sample.dirs){
        #print(d)
        doi=paste0(cfg$localtracking.dir, d,'/')
        setwd(doi)
        #-iR
        #system("grep  -R --exclude='.*' -l ',,1,1,2,2,3,3,4,4,5,5'", intern=T)
        #system('grep  -Rl ",,1,1,2,2,3,3,4,4,5,5"', intern=T)

        key.file=system("grep  -R --exclude='.*' -l ',,1,1,2,2,3,3,4,4,5,5'", intern=T)       
        if(identical(key.file, character(0))){
            keyfiles[[d]]=NA
            print(paste(d, ".csv key file not found"))
            #quit(save="no")
        } else{
            keyfiles[[d]]=key.file
        }
    }
    setwd(currentWorkingDir)
    return(keyfiles)
}

#run tool to count amplicons 
#run='210107_MN01371_0026_A000H3CVFK'
#r=match(run, rTable$Name)

#library("fastqcr")
#fastqc_install()
#qc=qc_read(paste0(odir,'/Undetermined_S0_R1_001_fastqc.zip'))
#qc=qc_read(paste0(odir,'/Undetermined_S0_I1_001_fastqc.zip'))
#qc=qc_read(paste0(odir,'/Undetermined_S0_I2_001_fastqc.zip'))
#qc_plot(qc, "Per sequence quality scores")
#qc_plot(qc, "Per base sequence quality")

