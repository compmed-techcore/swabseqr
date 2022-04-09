library(swabseqr)
basedir.dir='/mnt/e/swabseq2/' 
# location of shared drive
remote.dir=paste0(basedir.dir, 'remote/')
# location of mirror 
#localmirror.dir=paste0(basedir.dir, 'localmirror/')
#move to wsl2 filesystem for better performance    
localmirror.dir='/home/swabseq/swabseq2/localmirror/'
#bcl.dir is path to location to save bcls (keep off shared drive), 
#can download bcls manually here and script will auto-recognize them
bcl.dir=paste0(basedir.dir, 'bcls/')

#store the many global variables somewhere
#cfg = new.env(parent=emptyenv())
#variables are optimized here for the windows workstation in chs
#attempt to further reduce memory usage

# This will only run part 2 onwards
autoRunLabOnly()

