############################################################
# Dockerfile for PRINT
# Based on Debian slim
############################################################

# Use the official TensorFlow image as parent
FROM tensorflow/tensorflow:2.8.2-gpu

LABEL maintainer = "Zhijian Li"
LABEL software = "PRINT: multi scaling TF footprinting"
LABEL software.version="0.0.1"
LABEL software.organization="Broad Institute of MIT and Harvard"
LABEL software.version.is-production="No"
LABEL software.task="multi scaling TF footprinting"

## Create new user 
ENV USER=shareseq
WORKDIR /home/$USER
RUN groupadd -r $USER && \
    useradd -r -g $USER --home /home/$USER -s /sbin/nologin -c "Docker image user" $USER &&\
    chown $USER:$USER /home/$USER

#key signing issue with cuda repo can be fixed by removing from apt sources and re-adding in apt-get update 
RUN rm /etc/apt/sources.list.d/cuda.list

# Install some basic utilities
RUN apt-get update --fix-missing && \
    apt-get install -y --allow-unauthenticated wget bzip2 ca-certificates curl git jq libcairo2 libpango-1.0-0 libpangocairo-1.0-0 libgdk-pixbuf2.0-0 libffi-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
    
# Install Miniconda with Python 3.9 into /opt
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-py39_24.1.2-0-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh

# Enable Conda and alter bashrc so the Conda default environment is always activated
RUN ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc 

# Attach Conda to PATH
ENV PATH /opt/conda/bin:$PATH

# Install R packages
RUN conda install -y python=3.10 r-base=4.3 -c conda-forge
RUN conda install -y conda-forge::r-scales
RUN conda install -y conda-forge::r-dplyr
RUN conda install -y conda-forge::r-reticulate
RUN conda install -y conda-forge::r-ggplot2
RUN conda install -y conda-forge::r-gtools
RUN conda install -y conda-forge::r-hdf5r
RUN conda install -y conda-forge::r-getopt
RUN conda install -y conda-forge::r-optparse
RUN conda install -y bioconda::bioconductor-genomicranges
RUN conda install -y bioconda::bioconductor-summarizedexperiment

RUN conda clean -tipy

# Install Python packages
RUN pip install keras

# Copy the entire repo
RUN mkdir -p /home/$USER/PRINT/code
RUN mkdir -p /home/$USER/PRINT/shared_data

COPY ./code /home/$USER/PRINT/code
COPY ./shared_data /home/$USER/PRINT/shared_data

