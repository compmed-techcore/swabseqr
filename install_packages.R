install.packages("devtools",repos='http://cran.rstudio.com/')
install.packages(c("devtools", 'rqdatatable', 'data.table', 'plater', 'XML',
                    'seqinr', 'rquery', 'DT', 'tidyr', 'dplyr', 'readr', 'wrapr', 
                    'rmarkdown', 'ggplot2', 'matrixStats'
                    ),repos='http://cran.us.r-project.org')

if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

BiocManager::install("Biobase")
BiocManager::install("S4Vectors")
BiocManager::install("ShortRead")
BiocManager::install("savR")

# Shell script used to find global variables
# ./start.sh | grep -E ".*no visible binding for global variable (.[a-zA-z0-9_.]*.)" |\
# sed -E 's/.* .([a-zA-z0-9_.]*)./"\1",/g' | sort | uniq > global_variables.txt;

globalVariables(c("Barcode",
"Col",
"Col96",
"Count",
"Experiment.x",
"Experiment.y",
"Keyfile.x",
"Keyfile.y",
"Organization",
"Plate",
"Plate_384",
"Plate_384_BC",
"Plate_96_BC",
"Plate_ID",
"Pos96",
"RPP30",
"Row",
"Row96",
"S2",
"S2_spike",
"Sample_ID",
"Sample_Well",
"amplicon",
"cfg",
"currLowPos",
"experimentName",
"index",
"index2",
"mergedIndex",
"orders_file",
"quadrant_96",
"result",
"sequencingRunName",
"status"))