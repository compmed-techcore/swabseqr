## swabseqr: SwabSeq Analysis R package for the swabseq covid detection assay

### Installation

The swabseqr package can be downloaded and installed by running the following command from the R console:

```r
devtools::install_github("joshsbloom/swabseqr" ,ref="main")
```

Make sure you have the `rsync` command line tool available and `pandoc` installed. Consider using `devtools::install_version()` if you encounter dependency issues'

Additionally you must install `bcl2fastq` ,for converting bcl to fastq.gz files, and `bs` , the Basespace CLI tool

The `bs` CLI config file in ~/.basespace/default.cfg should be setup and workspaces can be made accessible with:
`bs auth --scopes "BROWSE GLOBAL,READ GLOBAL,CREATE GLOBAL,MOVETOTRASH GLOBAL,START APPLICATIONS,MANAGE APPLICATIONS" --force`

### Usage
see [main.R](examples/main.R) for example usage

### Additional Background
see [medrxiv preprint](https://www.medrxiv.org/content/10.1101/2020.08.04.20167874v2) and [Octant Notion SwabSeq page](https://www.notion.so/Octant-SwabSeq-Testing-9eb80e793d7e46348038aa80a5a901fd) for information about technology and licensing

### Directory Structures

#### Remote directory structure for shared drive: `remote.dir`
```bash
.
├── completed
│   ├── 2021-01-22_current_results.csv
│   ├── 2021-01-23_current_results.csv
│   └── 2021-01-23_current_results.csv
├── duketracking
├── exportedorders
├── missing
│   ├── 2021-01-21_orders_not_accessioned.csv
│   ├── 2021-01-22_orders_not_accessioned.csv
│   ├── 2021-01-23_orders_not_accessioned.csv
│   └── reformatted
├── precisemdx_sftp_orders
├── precisemdx_sftp_results
├── receivedsamples
│   ├── 01122021_JC_PM_MA_2.csv
│   ├── 01132021_JC_AM_N_2.csv
│   ├── 01132021_JC_PM_MC_1.csv
│   └── parsed
├── rosemaryDir
├── seq
│   ├── config.yaml
│   ├── config.yaml.backup_210120
│   ├── runs
│   └── water_tubes
├── swabseqsampletracking
│   ├── 01182021_JC_AM_N_1
│   ├── 01192021_AK_PM_MA_1
│   ├── 01192021_JC_AM_MC_1
│   ├── 01202021_JC_AM_N_1
│   ├── 01202021_JC_PM_MA_1
│   ├── 01212021_JC_AM_N_1
│   ├── 01212021_JC_PM_MB_1
│   ├── 01222021_JC_AM_N_1
│   ├── 01222021_JC_PM_MB_1
│   └── 01222021_MA_MD_MA_1
│       ├── 01222021_MA_MD_MA_1.csv
│       ├── 01222021_MA_MD_MA_1.xlsx
│       ├── 01235005.csv
│       ├── 01235022.csv
│       ├── 01235034.csv
│       ├── 01235192.csv
│       ├── 10104958B1.csv
│       ├── 10105016B1.csv
│       ├── 10105363B1.csv
│       ├── 10106718B1.csv
│       ├── 10106791B1.csv
│       ├── 10107040B1.csv
│       ├── 10107395B1.csv
│       ├── 10108322B1.csv
│       ├── 10108347B1.csv
│       ├── 10109577B1.csv
│       ├── 10109768B1.csv
│       ├── flowcell_barcode_MA.txt
│       ├── LACAN037.csv
│       ├── results
│       ├── TapeStation T73.JPG
│       └── uploaded
└── test
```

#### Directory structure for BCLs `bcl.dir`
```bash
.
├── 210122_MN01371_0034_A000H3F7MF
│   ├── Config
│   ├── Data
│   ├── InstrumentAnalyticsLogs
│   ├── InterOp
│   ├── out
│   │   ├── Reports
│   │   ├── Stats
│   │   ├── Undetermined_S0_I1_001.fastq.gz
│   │   ├── Undetermined_S0_I2_001.fastq.gz
│   │   └── Undetermined_S0_R1_001.fastq.gz
│   ├── Recipe
│   ├── RTAComplete.txt
│   ├── RTAConfiguration.xml
│   ├── RTALogs
│   ├── RTARead1Complete.txt
│   ├── RTARead2Complete.txt
│   ├── RTARead3Complete.txt
│   ├── RunInfo.xml
│   ├── RunParameters.xml
│   ├── SampleSheet.csv
│   └── T73_200169982.json
└── 210122_NB552456_0043_AHM5M5AFX2
    ├── Config
    ├── Data
    ├── InstrumentAnalyticsLogs
    ├── InterOp
    ├── out
    │   ├── Reports
    │   ├── Stats
    │   ├── Undetermined_S0_I1_001.fastq.gz
    │   ├── Undetermined_S0_I2_001.fastq.gz
    │   └── Undetermined_S0_R1_001.fastq.gz
    ├── Recipe
    ├── RTAComplete.txt
    ├── RTAConfiguration.xml
    ├── RTALogs
    ├── RTARead1Complete.txt
    ├── RTARead2Complete.txt
    ├── RTARead3Complete.txt
    ├── RunInfo.xml
    ├── RunParameters.xml
    ├── SampleSheet.csv
    ├── T72_200170974.json
    └── Thumbnail_Images
```


