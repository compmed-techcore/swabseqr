revcomp=function (x) {    toupper(seqinr::c2s(rev(seqinr::comp(seqinr::s2c(x)))))}

#initialize tables from sample sheet and set counts for expected amplicons to 0
initAmpliconCountTables=function(index.key, amplicons) {
    #Munginging sample sheet-------------------------------------------------------------------
    ss=index.key
    ss$mergedIndex=paste0(ss$index, ss$index2)

    # this code would be obviated if indices designate wells, for most analyses here there are different indices for s2/s2spike and rpp30
    # subset of indices for S2/S2 spike
    if(sum(grepl('-1$', ss$Sample_ID))==0){
        ssS=ss
        ssR=ss
    } else {
        ssS=ss[grep('-1$', ss$Sample_ID),]
        #subset of indices for RPP30
        ssR=ss[grep('-2$', ss$Sample_ID),]
    }

    #initalize output count tables ------------------------------------------------------------
    count.tables=list()
    for(a in names(amplicons)){
        if(grepl('^S',a)){    count.tables[[a]]=ssS   } 
        if(grepl('^R',a)){    count.tables[[a]]=ssR   } 
            count.tables[[a]]$Count=0
            count.tables[[a]]$amplicon=a
    }
    return(count.tables)
}


generateExpectedIndices=function(diri) {
    xmlinfo=XML::xmlToList(XML::xmlParse(paste0(diri, '/RunParameters.xml')))
    chemistry=xmlinfo$Chemistry
    #MiniSeq High / MiniSeq Rapid High / NextSeq Mid / NextSeq High
    #don't reverse comp i5 for miniseq rapid or miseq 
    i5RC.toggle=TRUE
    if(chemistry=="MiniSeq Rapid High" | chemistry=="MiSeq") {i5RC.toggle=F} 

    ## for 1536 UDI setup ----------------------------------------------------
    #i7s=plater::read_plates(cfg$i7_plate_key_file, well_ids_column="Sample_Well")
    #i7s=tidyr::gather(i7s, Plate_ID, index, 3:ncol(i7s))
    #i7s$index=as.vector(sapply(i7s$index, revcomp))
    #i7s$Plate_ID=paste0('Plate', i7s$Plate_ID)
    #i7s$Sample_ID=paste0(i7s$Plate_ID,'-', i7s$Sample_Well)

    #i5s=plater::read_plates(cfg$i5_plate_key_file, well_ids_column="Sample_Well")
    #i5s=tidyr::gather(i5s, Plate_ID, index2, 3:ncol(i5s))
    #if(i5RC.toggle) { i5s$index2=as.vector(sapply(i5s$index2, revcomp)) }
    #i5s$Plate_ID=paste0('Plate', i5s$Plate_ID)
    #i5s$Sample_ID=paste0(i5s$Plate_ID,'-', i5s$Sample_Well)

    #i5s= i5s %>% dplyr::select(Sample_ID, index2)
    #######i7s$bc_set='N1_S2_RPP30'
    #index.key=dplyr::right_join(i7s,i5s,by='Sample_ID') %>% dplyr::select(-Plate) %>% dplyr::select(Plate_ID,Sample_Well,Sample_ID,index,index2)
    #return(index.key)
    ## -----------------------------------------------------------------------------


    ## for 6144 semi-UDI setup ----------------------------------------------------
    i7s=plater::read_plates(cfg$i7_plate_key_file, well_ids_column="Sample_Well")
    i7s=tidyr::gather(i7s, Plate_ID, index, 3:ncol(i7s))
   
    i5s=plater::read_plates(cfg$i5_plate_key_file, well_ids_column="Sample_Well")
    i5s=tidyr::gather(i5s, Plate_ID, index2, 3:ncol(i5s))
  

    #r=i7
    #f=i5
    semi.key.i7=c(c(1,2,3,4),c(2,3,4,1),c(3,4,1,2), c(4,1,2,3))
    semi.key.i5=rep(seq(1,4),4)

    i7ss=split(i7s, i7s$Plate_ID)
    i5ss=split(i5s, i5s$Plate_ID)


    i7ss=data.table::rbindlist(i7ss[semi.key.i7])
    i5ss=data.table::rbindlist(i5ss[semi.key.i5])
    
    i7ss$Plate_ID=rep(seq(1,16),each=384)
    i5ss$Plate_ID=rep(seq(1,16),each=384)

    i7ss$Plate_ID=paste0('Plate', i7ss$Plate_ID)
    i7ss$Sample_ID=paste0(i7ss$Plate_ID,'-', i7ss$Sample_Well)
    i7ss$index=as.vector(sapply(i7ss$index, revcomp))


    i5ss$Plate_ID=paste0('Plate', i5ss$Plate_ID)
    i5ss$Sample_ID=paste0(i5ss$Plate_ID,'-', i5ss$Sample_Well)
    if(i5RC.toggle) { i5ss$index2=as.vector(sapply(i5ss$index2, revcomp)) }


    i5ss= i5ss %>% dplyr::select(Sample_ID, index2)
    #i7s$bc_set='N1_S2_RPP30'
    index.key=dplyr::right_join(i7ss,i5ss,by='Sample_ID') %>% dplyr::select(-Plate) %>% dplyr::select(Plate_ID,Sample_Well,Sample_ID,index,index2)
    ## -------------------------------------------------------------------


}

make_hamming1_sequences=function(x) {
    eseq=seqinr::s2c(x)
    eseqs=c(seqinr::c2s(eseq))
    for(i in 1:length(eseq)){
        eseq2=eseq
        eseq2[i]='A'
        eseqs=c(eseqs,seqinr::c2s(eseq2))
        eseq2[i]='C'
        eseqs=c(eseqs,seqinr::c2s(eseq2))
        eseq2[i]='T'
        eseqs=c(eseqs,seqinr::c2s(eseq2))
        eseq2[i]='G'
        eseqs=c(eseqs,seqinr::c2s(eseq2))
        eseq2[i]='N'
        eseqs=c(eseqs,seqinr::c2s(eseq2))

    }
    eseqs=unique(eseqs)
    return(eseqs)
}

#error correct the indices and count amplicons, equivalent base R, faster
errorCorrectIdxAndCountAmplicons=function(rid, count.table, ind1,ind2){
    # get set of unique expected index1 and index2 sequences
    index1=unique(count.table$index)
    index2=unique(count.table$index2)

    i1h=lapply(index1, make_hamming1_sequences)
    names(i1h)=index1
    ih1=Biobase::reverseSplit(i1h)
    ih1.elements=names(ih1)
    ih1.indices=as.vector(unlist(ih1))
    i1m=ih1.indices[S4Vectors::match(ind1[rid],ih1.elements)]

    i2h=lapply(index2, make_hamming1_sequences)
    names(i2h)=index2
    ih2=Biobase::reverseSplit(i2h)
    ih2.elements=names(ih2)
    ih2.indices=as.vector(unlist(ih2))
    i2m=ih2.indices[S4Vectors::match(ind2[rid],ih2.elements)]
    
    idm=paste0(i1m,i2m)
    tS2=table(match(idm, count.table$mergedIndex))
    tbix=match(as.numeric(names(tS2)), 1:nrow(count.table))
    count.table$Count[tbix]=as.vector(tS2)+count.table$Count[tbix]
    return(count.table)
}

#main engine, match observed to expected sequences
buildCountTables=function(bcl.dir, nbuffer, readerBlockSize, amplicons, count.tables) {
    
    fastq_dir  <- paste0(bcl.dir, 'out/')
    in.fileI1  <- paste0(fastq_dir, 'Undetermined_S0_I1_001.fastq.gz')
    in.fileI2  <- paste0(fastq_dir, 'Undetermined_S0_I2_001.fastq.gz')
    in.fileR1  <- paste0(fastq_dir, 'Undetermined_S0_R1_001.fastq.gz')
            
    i1 <- ShortRead::FastqStreamer(in.fileI1, nbuffer, readerBlockSize = readerBlockSize, verbose = T)
    i2 <- ShortRead::FastqStreamer(in.fileI2, nbuffer, readerBlockSize = readerBlockSize, verbose = T)
    r1 <- ShortRead::FastqStreamer(in.fileR1, nbuffer, readerBlockSize = readerBlockSize, verbose = T)

    amp.match.summary.table=rep(0, length(amplicons)+1)
    names(amp.match.summary.table)=c(names(amplicons),'no_align')

    repeat{
        rfq1 <- ShortRead::yield(i1) 
        if(length(rfq1) == 0 ) { break }
        rfq2 <- ShortRead::yield(i2) 
        rfq3 <- ShortRead::yield(r1) 
        ind1 <- ShortRead::sread(rfq1)
        ind2 <- ShortRead::sread(rfq2)
        rd1  <- ShortRead::sread(rfq3)
        
        # match amplicons
        amph1=lapply(amplicons, make_hamming1_sequences)
        amph1=Biobase::reverseSplit(amph1)
        amph1.elements=names(amph1)
        amph1.indices=as.vector(unlist(amph1))
        # strategy here is better than reliance on helper functions from stringdist package
        amp.match=amph1.indices[S4Vectors::match(rd1, amph1.elements)]
        no_align=sum(is.na(amp.match))

        #summarize amplicon matches
        amp.match.summary=table(amp.match)
        amp.match.summary=amp.match.summary[match(names(amplicons),names(amp.match.summary))]
        amp.match.summary=c(amp.match.summary, no_align)
        names(amp.match.summary) <- c(names(amp.match.summary[-length(amp.match.summary)]),"no_align")
        amp.match.summary.table=amp.match.summary.table+amp.match.summary

        #convert to indices
        per.amplicon.row.index=lapply(names(amplicons), function(x) which(amp.match==x))
        names(per.amplicon.row.index)=names(amplicons)

        #for each amplicon of interest count up reads where indices match expected samples
        for(a in names(count.tables)){
          count.tables[[a]]= errorCorrectIdxAndCountAmplicons(per.amplicon.row.index[[a]], count.tables[[a]], ind1,ind2)
        }
    }
    close(i1); close(i2); close(r1);
    names(count.tables)=paste0(names(count.tables), '.table')
    return(list(count.tables=count.tables,
                amp.match.summary.table=amp.match.summary.table))
}


countAmplicons=function(rTable,index.key,bcl.dir, odir, coreVars){
    amplicons=coreVars$amplicons
    lbuffer=coreVars$lbuffer
    readerBlockSize=coreVars$readerBlockSize
    count.tables=initAmpliconCountTables(index.key, amplicons)
    #this code block is obviated by checks outside this function for config.yaml status
    #if(!file.exists(paste0(odir, '/countTable.RDS'))) { 
    
        # given expected directory for bcl files, buffer of lines to read, and expected amplicons,
        #find all amplicons that match expected sequences for read1 and the two index sequences within 1 hamming distance for each
        results.list=buildCountTables(bcl.dir, lbuffer, readerBlockSize, amplicons, count.tables)
        results=results.list[['count.tables']]
        amp.match.summary.table=results.list[['amp.match.summary.table']]
        do.call('rbind', results) %>% readr::write_csv(paste0(odir, '/countTable.csv')) 
        saveRDS(results, file=paste0(odir, '/countTable.RDS'),version=2)
        saveRDS(amp.match.summary.table, file=paste0(odir, '/ampCounts.RDS'),version=2)
    #}
    if(file.exists(paste0(odir, '/countTable.RDS'))){return(T)} else {return(F)}
}


