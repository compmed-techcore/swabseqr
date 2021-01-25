setwd("/data/Covid/swabseqr")
devtools::check()
devtools::document()
devtools::load_all()
devtools::install()

library(swabseqr)

# basedir.dir is path to github directory
#basedir.dir=Sys.getenv("BASEDIR")

basedir.dir='/data/Covid/swabseq2/'
# location of shared drive
remote.dir=paste0(basedir.dir, 'remote/')
# location of mirror 
localmirror.dir=paste0(basedir.dir, 'localmirror/')
    
#bcl.dir is path to location to save bcls (keep off shared drive), 
#can download bcls manually here and script will auto-recognize them
bcl.dir=paste0(basedir.dir, 'bcls/')

#store the many global variables somewhere
#cfg = new.env(parent=emptyenv())
cfg = buildEnvironment(remote.dir, 
                       localmirror.dir, 
                       bcl.dir, 
                       #for beefier workstation, otherwise use defaults
                       threads=16, lbuffer=60e6, readerBlockSize=1e8, 
                       fastqcr=F
                    )
#default usage
autoRun()


#if you don't want it to update completed/
autoRun(writeCurrentResultsTable=F)


#first run
#syncRuns(cfg, first.run=T)


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
#fail here
demuxRuns() 

#before=md5sum(cfg$yaml.cfg.file)
print('matching sequencing runs to key files')
lookUpKeys()

print('matching samples to observed indices')
addIdentifiers()

print('generating reports')
syncReports( syncToShared=F)



#library(swabseqr)
#autoRun()
setwd("/data/Covid/swabseqr")
devtools::document()
devtools::load_all()
devtools::install()




#depends
library(rqdatatable)

#imports
library(tools)
library(data.table)
library(plater)
library(XML)
library(seqinr)
library(yaml)
library(rquery)
library(knitr)
library(DT)

#actual tidyverse packages used 
#library(tidyverse)
library(tidyr)
library(magrittr)
library(dplyr)
library(tibble)
library(readr)
library(rmarkdown)
library(ggplot2)

#Bioconductor packages
library(ShortRead)
library(savR)

#suggests
library(fastqcr)
library(devtools)
library(roxygen2)

codedir.dir=paste0('/data/Covid/swabseqr/')
# load accessory functions
source(paste0(codedir.dir,'R/buildEnvironment.R'))
source(paste0(codedir.dir,'R/countAmplicons.R'))
source(paste0(codedir.dir,'R/autoPullSeq.R'))
source(paste0(codedir.dir,'R/generateReports.R'))
source(paste0(codedir.dir,'R/makeCSVReports.R'))

