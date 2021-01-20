## UCLA SwabSeq Aanlysis R package swabseqr for automated processing pipeline
___

## R package wrapper for swabseq covid detection assay

## Installation

The swabseqr package can be downloaded and installed by running the following command from the R console:

```r
devtools::install_github("joshsbloom/swabseqr")
```

Make sure you have the `rsync` command line tool available.

Additionally you must install `bcl2fastq` ,for converting bcl to fastq.gz files, and `bs` , the Basespace CLI tool

The `bs` CLI config file in ~/.basespace/default.cfg should be setup and workspaces can be made accessible with:
`bs auth --scopes "BROWSE GLOBAL,READ GLOBAL,CREATE GLOBAL,MOVETOTRASH GLOBAL,START APPLICATIONS,MANAGE APPLICATIONS" --force`

see [main.R](examples/main.R) for example usage

