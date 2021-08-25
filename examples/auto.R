library(swabseqr)
basedir.dir='/mnt/e/swabseq2/' 
# location of shared drive
remote.dir=paste0(basedir.dir, 'remote/')
# location of mirror 
localmirror.dir=paste0(basedir.dir, 'localmirror/')
    
#bcl.dir is path to location to save bcls (keep off shared drive), 
#can download bcls manually here and script will auto-recognize them
bcl.dir=paste0(basedir.dir, 'bcls/')

#store the many global variables somewhere
#cfg = new.env(parent=emptyenv())
#variables are optimized here for the windows workstation in chs
#attempt to further reduce memory usage
cfg = buildEnvironment(remote.dir, 
                       localmirror.dir, 
                       bcl.dir, 
                       threads=4, lbuffer=20e6,
                       readerBlockSize=5e7, fastqcr=F)
autoRun() 

