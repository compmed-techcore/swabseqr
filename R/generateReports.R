#' Given Demuxed data, add in sample barcode information
#'
#' If cfg environment variable is set, this function will merge sample ID info onto amplicon count tables.
#'
#' @export
addIdentifiers=function(...) {
    rTable = getRunTableStatus()
    #initalize run status
    for(r in 1:nrow(rTable)) {
        runName=rTable$Name[r] 
        #bcl.dir is different here
        bcl.dir=paste0(cfg$bcl.dir, runName, '/')
        odir=paste0(cfg$seq.run.dir, runName)
        if(rTable$Downloaded[r] & rTable$Bcl2fastq[r] & rTable$Demuxed[r] & !rTable$Analyzed[r]){
           results.list=buildResultsList(rTable, r, odir,cfg)
           if(!is.null(results.list)){
                 rmarkdown::render(
                        input=system.file("rmd", "qc_report.Rmd", package="swabseqr"),
                        #input = "/data/Covid/swabseqr/inst/qc_report.Rmd paste0(cfg$basedir.dir, "pkg/v2_qc_report.Rmd"),
                        output_file = paste0(rTable$Experiment[r],".html"),
                        output_dir = paste0(odir, '/results/'),
                        params = results.list,
                        envir = new.env(parent = globalenv())
                 )
                 orders.files=getOrders(cfg)
                 cur.date=format(Sys.Date(), format="%m%d%Y")
                 results.list$dwide %>% dplyr::filter(results.list$samples_to_report)  %>%
                                    dplyr::select(-matrix_tube_present) %>%
                                    tibble::add_column(date_analyzed=cur.date, .before="S2")  %>% 
                                    tibble::add_column(sequencingRunName=rTable$Name[r], .before="Sample_ID") %>%
                                    tibble::add_column(experimentName=rTable$Experiment[r], .before="Sample_ID") %>%
                                    dplyr::left_join(orders.files,"Barcode") %>% 
                                    dplyr::mutate_at(dplyr::vars(Organization), ~tidyr::replace_na(.,'Missing')) %>%
                                    dplyr::arrange(dplyr::desc(result), orders_file, Barcode) %>%
                                    #EDIT HERE make sure this doesn't get fancy with scientific notation!
                                    utils::write.csv(paste0(odir,'/results/', rTable$Experiment[r],'_report.csv'), row.names=F)
                 
                 #add column with illumina run name 
                 #add coulumn with experiment name               
                rTable$Analyzed[r]=T  
                write_yaml_cfg(rTable,cfg)

           }
        }
    }
}






#add sample identifiers to index.key 
parseKeyAndMerge=function(index.key, sample.key.file.local) {

    qA=apply(expand.grid(toupper(letters[seq(1,16,2)]), sprintf("%02d",seq(1,24,2))),1, paste0, collapse='')
    qB=apply(expand.grid(toupper(letters[seq(1,16,2)]), sprintf("%02d",seq(2,24,2))),1, paste0, collapse='')
    qC=apply(expand.grid(toupper(letters[seq(2,16,2)]), sprintf("%02d",seq(1,24,2))),1, paste0, collapse='')
    qD=apply(expand.grid(toupper(letters[seq(2,16,2)]), sprintf("%02d",seq(2,24,2))),1, paste0, collapse='')
    index.key$quadrant_96=''
    index.key$quadrant_96[index.key$Sample_Well %in% qA]='A'
    index.key$quadrant_96[index.key$Sample_Well %in% qB]='B'
    index.key$quadrant_96[index.key$Sample_Well %in% qC]='C'
    index.key$quadrant_96[index.key$Sample_Well %in% qD]='D'
    #-----------------------------------------------------------------

    # setup experiment key ---------------------------------------------------------
    #plate_ID will always refer to index plate location
    #Plate_384 will be a sample specific name
    experiment.key=plater::read_plates(sample.key.file.local, well_ids_column='Sample_Well')
    experiment.key=tidyr::gather(experiment.key, Plate_384_long, Barcode, 3:ncol(experiment.key))
    experiment.key$Barcode[experiment.key$Barcode=='#REF!']=''
    experiment.key$Barcode=gsub('\"', '', experiment.key$Barcode) 
    experiment.key$Plate_384_long=gsub("::", ": : ", experiment.key$Plate_384_long)

    #plate #, barcode, primer set"
    #PLATE 1:12346:1:TS01399002:TS01399030::
    ekd=data.table::tstrsplit(experiment.key$Plate_384_long, ':', names=c('Plate_384','Plate_384_BC', 'Plate_ID', 'Q1', 'Q2','Q3','Q4'))
    # annoyingly, Plate_ID gets an extra space if 384_BC entry is blank, this causes havoc downstream if user forgets to scan 384-well plate barcode
    ekd$Plate_ID=gsub(' ', '', ekd$Plate_ID)
    ekd$Plate_ID=paste0('Plate', ekd$Plate_ID)
    ekd$Q1[ekd$Q1==" "]=""
    ekd$Q2[ekd$Q2==" "]=""
    ekd$Q3[ekd$Q3==" "]=""
    ekd$Q4[ekd$Q4==" "]=""
    experiment.key$Plate_ID=ekd$Plate_ID
    experiment.key$Sample_ID=paste0(experiment.key$Plate_ID,'-',experiment.key$Sample_Well)
    experiment.key$Plate_384=ekd$Plate_384
    experiment.key$Plate_384_BC=ekd$Plate_384_BC
    experiment.key$Plate_96_BC=''
    experiment.key$Q1=ekd$Q1
    experiment.key$Q2=ekd$Q2
    experiment.key$Q3=ekd$Q3
    experiment.key$Q4=ekd$Q4

    experiment.key= experiment.key %>%dplyr::select(-Plate, -Sample_Well, -Plate_ID) %>% dplyr::right_join(index.key, by='Sample_ID')
    #head(data.frame(experiment.key))

    for(p in unique(experiment.key$Plate_384)){
        experiment.key$Plate_96_BC[((experiment.key$Plate_384 %in% p) & (experiment.key$quadrant_96 %in% 'A'))]=
        experiment.key$Q1[((experiment.key$Plate_384 %in% p) & (experiment.key$quadrant_96 %in% 'A'))]
        
        experiment.key$Plate_96_BC[((experiment.key$Plate_384 %in% p) & (experiment.key$quadrant_96 %in% 'B'))]=
        experiment.key$Q2[((experiment.key$Plate_384 %in% p) & (experiment.key$quadrant_96 %in% 'B'))]

        experiment.key$Plate_96_BC[((experiment.key$Plate_384 %in% p) & (experiment.key$quadrant_96 %in% 'C'))]=
        experiment.key$Q3[((experiment.key$Plate_384 %in% p) & (experiment.key$quadrant_96 %in% 'C'))]

        experiment.key$Plate_96_BC[((experiment.key$Plate_384 %in% p) & (experiment.key$quadrant_96 %in% 'D'))]=
        experiment.key$Q4[((experiment.key$Plate_384 %in% p) & (experiment.key$quadrant_96 %in% 'D'))]
    }
   
    experiment.key$Plate_ID=as.factor(experiment.key$Plate_ID)
    experiment.key$Plate_ID=factor(experiment.key$Plate_ID, levels(experiment.key$Plate_ID)[order(as.numeric(gsub('Plate', '', levels(experiment.key$Plate_ID))))])  
 
    experiment.key$Col=as.factor(gsub('^.', '', experiment.key$Sample_Well))
    #assumes 384-well plate layout
    experiment.key$Row=factor(gsub('..$', '', experiment.key$Sample_Well), levels=rev(toupper(letters[1:16])))

    experiment.key$Row96=experiment.key$Row
    for(l in c('A','B','C','D')){
        y=droplevels(experiment.key$Row[experiment.key$quadrant_96==l])
        levels(y)=toupper(rev(letters[1:8]))
        experiment.key$Row96[experiment.key$quadrant_96==l]=y
    }
    experiment.key$Col96=experiment.key$Col
    for(l in c('A','B','C','D')){
        y=droplevels(experiment.key$Col[experiment.key$quadrant_96==l])
        levels(y)=sprintf('%02d', 1:12)
        experiment.key$Col96[experiment.key$quadrant_96==l]=y
    }
    experiment.key$Pos96=paste0(experiment.key$Row96,experiment.key$Col96)
    experiment.key$mergedIndex=paste0(experiment.key$index, experiment.key$index2)

    sample_sheet_info=experiment.key %>% dplyr::select(Plate_ID,Barcode,Plate_96_BC, quadrant_96, Row96, Col96, Pos96,  
                                                 Plate_384_BC, Plate_384, Row, Col,  Sample_Well, 
                                                 Sample_ID,index,index2, mergedIndex)
    return(sample_sheet_info)
}


#use savR to get some run stats 
getsavRStats=function(bcl.dir, amp.match.summary.table){
    sav=savR::savR(bcl.dir)
    tMet=savR::tileMetrics(sav)
    phiX=mean(tMet$value[tMet$code=='300'])
    clusterPF=mean(tMet$value[tMet$code=='103']/tMet$value[tMet$code=='102'], na.rm=T)
    clusterDensity=mean(tMet$value[tMet$code=='100']/1000)
    clusterDensity_perLane=sapply(split(tMet, tMet$lane), function(x) mean(x$value[x$code=='100']/1000))    
    seq.metrics=data.frame("totalReads"=format(sum(amp.match.summary.table),  big.mark=','),
                       "totalReadsPassedQC"=format(sum(amp.match.summary.table[!(names(amp.match.summary.table) %in% 'no_align')]), big.mark=','),
                       "phiX"=paste(round(phiX,2), "%"), "clusterPF"=paste(round(clusterPF*100,1), "%"),
                       "clusterDensity"=paste(round(clusterDensity,1), 'K/mm^2'), 
                       "clusterDensity_perLane"=paste(sapply(clusterDensity_perLane, round,1),collapse=' '))
}

#get some stats about observed reads matching expected amplicons and index sequences
getAmpMatchStats=function(amp.match.summary.table, results){
    amplicon.matching.stats=data.frame(read1_only=amp.match.summary.table, read1_ind1_ind2=c(sapply(results, function(x) sum(x$Count)), NA))
    amplicon.matching.stats=rbind(amplicon.matching.stats, apply(amplicon.matching.stats,2,sum, na.rm=T))
    rownames(amplicon.matching.stats)[nrow(amplicon.matching.stats)]='total'
    amplicon.matching.stats$percent_indexed=paste0(format(100*amplicon.matching.stats[,2]/amplicon.matching.stats[,1],digits=3), "%")
    amplicon.matching.stats[,1]=format(amplicon.matching.stats[,1], big.mark=',')
    amplicon.matching.stats[,2]=format(amplicon.matching.stats[,2], big.mark=',')
    return(amplicon.matching.stats)
}






getLooKeys=function(cfg){
     waterTubeFiles=list.files(cfg$waterTubesKeyDir, pattern='csv', full.names=T)
     loo.key=data.table::rbindlist(lapply(waterTubeFiles,readr::read_csv, col_names=F, col_types=readr::cols(.default='c')))
     names(loo.key)=c('type','Pos96', 'ID')
     return(loo.key)
}

makeWideResultTable=function(resultsLong, cfg){
       dfs= resultsLong %>%dplyr::filter(grepl('^S2', amplicon) ) %>%  
             dplyr::count(Sample_ID, wt=Count, name='Stotal') %>%
             dplyr::right_join(resultsLong) 
       
       dfs= dfs %>% dplyr::count(Sample_ID, wt=Count, name='well_total') %>%   dplyr::right_join(dfs)
       #modify code to track indices
       s2.indices=dfs %>% dplyr::filter(amplicon=='S2') %>% dplyr::select(Sample_ID, index,index2)
       names(s2.indices)[c(2,3)]=paste0('S_', names(s2.indices)[c(2,3)])
       rpp.indices=dfs%>%dplyr::filter(amplicon=='RPP30')%>% dplyr::select(Sample_ID, index,index2)
       names(rpp.indices)[c(2,3)]=paste0('R_', names(rpp.indices)[c(2,3)])
       df.i=dplyr::right_join(s2.indices, rpp.indices)
       dfs=dfs %>% 
          dplyr::select(-mergedIndex,  -index, -index2 ) %>% dplyr::right_join(df.i) %>%
          tidyr::spread(amplicon, Count) %>%
          dplyr::mutate(S2_spike=S2_spike000+S2_spike001+S2_spike002+S2_spike003+S2_spike004) %>%
          dplyr::mutate(S2_normalized_to_S2_spike=(S2+1)/(S2_spike+1))%>%
          dplyr::mutate(RPP30_Detected=RPP30>cfg$coreVars$Rpp) %>%  
          dplyr::mutate(result=S2_normalized_to_S2_spike>cfg$coreVars$Ratio)
       dfs$result[!dfs$RPP30_Detected & !dfs$result]='Inconclusive'
       dfs$result[dfs$Stotal < cfg$coreVars$Stotal]='Inconclusive' 
       dfs$result[dfs$result=='TRUE']='Positive'
       dfs$result[dfs$result=='FALSE']='Negative'
       if(cfg$coreVars$flagLowPositive) {   dfs$result[dfs$result=='TRUE' & dfs$S2<100]='Positive (low S2)'    }
       return(dfs)
}


buildResultsList=function(rTable, r, odir,cfg){ 
     sample.key.dir=paste0(cfg$localtracking.dir, rTable$Experiment[r], '/')
     sample.key.file=paste0(sample.key.dir, rTable$Keyfile[r]) 
 
     sample.key.file.formatted=paste0(odir, '/',   'keyfile.csv')
     counts.file=paste0(odir, '/', 'countTable.RDS')
     counts.summary.file=paste0(odir, '/', 'ampCounts.RDS')

     # ADD HERE put final report somewhere and delete existing ones if there are already ones there!

      #reformat keyfile
      if(file.exists(sample.key.file) & file.exists(counts.file) & file.exists(counts.summary.file) ){
          dir.create(paste0(odir, '/results/'))
       
         #new.key.file=paste0(zipdir, 'keyfile.csv')
         system(paste("sed 1d", sample.key.file, "| cut -f1 -d ',' --complement - >", sample.key.file.formatted))
       
         index.key=generateExpectedIndices(odir)
         index.key=parseKeyAndMerge(index.key, sample.key.file.formatted)
         
         #read back in count tables 
         amp.match.summary.table=readRDS(counts.summary.file) #paste0(odir, '/ampCounts.RDS'))
         results=readRDS(counts.file) #paste0(odir, '/countTable.RDS'))
         resultsMerged=lapply(results, function(x) {
                  x%>% dplyr::select(-Plate_ID, -Sample_ID, -Sample_Well, -index, -index2) %>%   
                  dplyr::left_join(index.key, by='mergedIndex')
              })
         saveRDS(resultsMerged, file=paste0(odir, '/countTableWithIDs.RDS'),version=2) 
        
         # use savR to get some runs stats
         seq.metrics=getsavRStats(paste0(odir, '/'), amp.match.summary.table)
         # get some stats about observed reads matching expected amplicons and index sequences
         amplicon.matching.stats=getAmpMatchStats(amp.match.summary.table, resultsMerged)
         loo.key=getLooKeys(cfg)

         resultsLong=data.table::rbindlist(resultsMerged)
         resultsLong$amplicon=factor(resultsLong$amplicon, level=names(cfg$coreVars$amplicons))
        
         dwide=makeWideResultTable(resultsLong, cfg) 
         dwide=dwide%>%tibble::add_column(id_tubes=dwide$Barcode %in% loo.key$ID, .before='S2')
         
         #samples with matrix tube ids
         samples_with_ids=!(dwide$Barcode%in% cfg$coreVars$empty_well_set | is.na(dwide$Barcode))
         # samples to report have matrix tube IDs and aren't in set of tubes scanned as water tubes
         samples_to_report= !(dwide$Barcode%in% cfg$coreVars$empty_well_set | is.na(dwide$Barcode) | (dwide$Barcode %in% loo.key$ID) )
         dwide=dwide%>%tibble::add_column(matrix_tube_present=samples_with_ids, .after='id_tubes')

         params <- list(
                  experiment = paste(rTable$Experiment[r], rTable$Hname[r]), 
                  bcl.dir = paste0(odir,'/'),                    
                  amp.match.summary = amplicon.matching.stats,
                  seq.metrics=seq.metrics,
                  samples_with_ids=samples_with_ids,
                  samples_to_report=samples_to_report,
                  dlong=resultsLong,
                  dwide=dwide
           )
         return(params)
      } else { return(NULL) }
}





