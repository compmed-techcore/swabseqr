# Base image https://hub.docker.com/u/rocker/
#FROM rocker/r-base:4.1.0
FROM rocker/verse:4.1.0

WORKDIR /data/Covid/swabseqr

COPY . .
COPY ./default.cfg /root/.basespace/default.cfg

## This part sets up basespace
RUN wget "https://launch.basespace.illumina.com/CLI/latest/amd64-linux/bs" -O /usr/bin/bs
RUN chmod u+x /usr/bin/bs

RUN git clone https://github.com/igorbarinov/bcl2fastq.git
#RUN rpm -i /bcl2fastq/bcl2fastq2-v2.17.1.14-Linux-x86_64.rpm
RUN bcl2fastq/install-2.17.sh

RUN apt-get install rsync

RUN    Rscript ./install_packages.R

CMD ["Rscript","examples/mainSharedDrive.R"]

# Interactive Shell
# CMD ["bash"]
# CMD ["R"]

