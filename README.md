### swabseqr: SwabSeq Analysis R package for the swabseq covid detection assay

#### Installation

The swabseqr package can be downloaded and installed by running the following command from the R console:

```r
devtools::install_github("joshsbloom/swabseqr" ,ref="main")
```

Make sure you have the `rsync` command line tool available and `pandoc` installed. Consider using `devtools::install_version()` if you encounter dependency issues'

Additionally you must install `bcl2fastq` ,for converting bcl to fastq.gz files, and `bs` , the Basespace CLI tool

The `bs` CLI config file in ~/.basespace/default.cfg should be setup and workspaces can be made accessible with:
`bs auth --scopes "BROWSE GLOBAL,READ GLOBAL,CREATE GLOBAL,MOVETOTRASH GLOBAL,START APPLICATIONS,MANAGE APPLICATIONS" --force`

#### Usage
see [main.R](examples/main.R) for example usage

#### Additional Background
see [medrxiv preprint](https://www.medrxiv.org/content/10.1101/2020.08.04.20167874v2) and [Octant Notion SwabSeq page](https://www.notion.so/Octant-SwabSeq-Testing-9eb80e793d7e46348038aa80a5a901fd) for information about technology and licensing

#### Directory Structure


```bash
├── bcls
│   ├── 210104_MN01371_0023_A000H3CW2Y
│   ├── 210104_NB552456_0029_AHJ53KAFX2
│   ├── 210105_MN01365_0022_A000H3CWJT
│   ├── 210105_MN01371_0024_A000H3CTGC
│   ├── 210105_NB552456_0030_AHJ3JGAFX2
│   ├── 210105_NB552456_0031_AHJ3TCAFX2
│   ├── 210106_MN01365_0023_A000H3CWC3
│   ├── 210106_MN01371_0025_A000H3CWHM
│   ├── 210106_NB552456_0032_AHJ3N5AFX2
│   ├── 210107_MN01365_0024_A000H3FH2T
│   ├── 210107_MN01371_0026_A000H3CVFK
│   ├── 210107_NB552456_0033_AHJ5NHAFX2
│   ├── 210108_MN01365_0025_A000H3FH3K
│   ├── 210108_MN01368_0002_A000H3FH2G
│   ├── 210108_MN01371_0027_A000H3FGYC
│   ├── 210108_NB552456_0034_AHJ3CCAFX2
│   ├── 210111_MN01368_0003_A000H3FH2V
│   ├── 210111_MN01371_0028_A000H3FGYM
│   ├── 210112_MN01371_0029_A000H3FGY5
│   ├── 210112_NB552456_0035_AHJ5K2AFX2
│   ├── 210113_MN01368_0004_A000H3FGWT
│   ├── 210113_MN01368_0005_A000H3FH2L
│   ├── 210113_NB552456_0036_AHJ352AFX2
│   ├── 210114_MN01365_0027_A000H3F7GM
│   ├── 210114_MN01368_0006_A000H3CVGL
│   ├── 210114_MN01368_0007_A000H3CKLW
│   ├── 210114_MN01371_0030_A000H3FKHH
│   ├── 210114_NB552456_0037_AHJ3CHAFX2
│   ├── 210115_MN01368_0008_A000H3F7HF
│   ├── 210115_MN01371_0031_A000H3CWH3
│   ├── 210115_NB552456_0038_AHJ3VJAFX2
│   ├── 210118_NB552456_0039_AHJ3T2AFX2
│   ├── 210119_MN01368_0009_A000H3F7KT
│   ├── 210119_MN01371_0032_A000H3CWL7
│   ├── 210120_MN01371_0033_A000H3CWKY
│   ├── 210120_NB552456_0040_AHJ3JHAFX2
│   ├── 210120_NB552456_0041_AHM3MTAFX2
│   ├── 210121_MN01365_0028_A000H3F7GW
│   ├── 210121_NB552456_0042_AHM3G7AFX2
│   ├── 210122_MN01365_0029_A000H3CW7M
│   ├── 210122_MN01371_0034_A000H3F7MF
│   └── 210122_NB552456_0043_AHM5M5AFX2
├── localmirror
│   ├── precisemdx_sftp_orders
│   ├── seq
│   └── swabseqsampletracking
├── remote
│   ├── completed
│   ├── duketracking
│   ├── exportedorders
│   ├── missing
│   ├── precisemdx_sftp_orders
│   ├── precisemdx_sftp_results
│   ├── receivedsamples
│   ├── rosemaryDir
│   ├── seq
│   ├── swabseqsampletracking
│   ├── temp
│   ├── test
│   └── test2
```
