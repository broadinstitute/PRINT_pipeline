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

ARG CONDA_PYTHON_VERSION=3
ARG CONDA_DIR=/opt/conda
ARG USERNAME=docker
ARG USERID=1000

# Instal basic utilities
RUN apt-get update && \
    apt-get install -y --no-install-recommends git wget unzip bzip2 sudo build-essential ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install miniconda
ENV PATH $CONDA_DIR/bin:$PATH
RUN wget --quiet https://repo.continuum.io/miniconda/Miniconda$CONDA_PYTHON_VERSION-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    echo 'export PATH=$CONDA_DIR/bin:$PATH' > /etc/profile.d/conda.sh && \
    /bin/bash /tmp/miniconda.sh -b -p $CONDA_DIR && \
    rm -rf /tmp/*

# Create the user
RUN useradd --create-home -s /bin/bash --no-user-group -u $USERID $USERNAME && \
    chown $USERNAME $CONDA_DIR -R && \
    adduser $USERNAME sudo && \
    echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER $USERNAME
WORKDIR /home/$USERNAME

# Install mamba
RUN conda install -y mamba -c conda-forge

# ADD ./environment.yml .
# RUN mamba env update --file ./environment.yml && conda clean -tipy

# For interactive shell
# RUN conda init bash
# RUN echo "conda activate base" >> /home/$USERNAME/.bashrc

# Copy the entire repo
# RUN mkdir /scratch/PRINT
# COPY ./code /scratch/PRINT

# COPY ./data /scratch/PRINT
# Rscript /scratch/PRINT/code/run_PRINT.R --help

