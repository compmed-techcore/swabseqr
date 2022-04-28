# devtools::check()
# devtools::document()
devtools::load_all()
devtools::install()
library(swabseqr)

# basedir.dir='/mnt/e/swabseq2/' 
basedir.dir='/data/Covid/swabseq2/' 
# location of shared drive
remote.dir=paste0(basedir.dir, 'remote/')
# location of mirror 
#localmirror.dir=paste0(basedir.dir, 'localmirror/')
#move to wsl2 filesystem for better performance    
# localmirror.dir='/home/swabseq/swabseq2/localmirror/'
localmirror.dir='/data/Covid/swabseq2/localmirror/'
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
print(names(cfg))
print(cfg$localMirrorSeq.run.dir)
print(cfg$bcl.dir)
print(cfg$waterTubesKeyDir)
print(cfg$incomingOrders.dir)
print(cfg$seq.run.dir)
print(cfg$coreVars)
print(cfg$localIncomingOrders.dir)
print(cfg$path_to_bs)
print(cfg$bs_config_present)
print(cfg$localMirrorSeq.dir)
print(cfg$yaml.cfg.file)
print(cfg$seq.dir)
print(cfg$localtracking.dir)
print(cfg$i7_plate_key_file)
print(cfg$path_to_bcl2fastq)
print(cfg$i5_plate_key_file)
print(cfg$remote.dir)
#  [2] "bcl.dir"                 "yaml.cfg.file"          
#  [4] "waterTubesKeyDir"        "seq.dir"                
#  [6] "incomingOrders.dir"      "localtracking.dir"      
#  [8] "seq.run.dir"             "i7_plate_key_file"      
# [10] "coreVars"                "path_to_bcl2fastq"      
# [12] "localIncomingOrders.dir" "localmirror.dir"        
# [14] "path_to_bs"              "i5_plate_key_file"      
# [16] "bs_config_present"       "remote.dir"             
# [18] "localMirrorSeq.dir"     
# This will only run part 2 onwards

print("AUTORUN")
autoRun()
print("DONE")
