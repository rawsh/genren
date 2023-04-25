# FROM nvidia/cuda:11.1-devel-ubuntu20.04
FROM nvidia/cuda:11.1.1-devel-ubuntu20.04

# Remove any third-party apt sources to avoid issues with expiring keys.
RUN rm -f /etc/apt/sources.list.d/*.list

# Install some basic utilities.
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    sudo \
    git \
    bzip2 \
    libx11-6 \
    wget \
 && rm -rf /var/lib/apt/lists/*

# ENV CONDA_DIR /anaconda3

# # system dependencies
# RUN apt-get update -q
# RUN DEBIAN_FRONTEND="noninteractive" TZ=America/New_York apt-get -y install tzdata
# RUN apt-get install -q -y freeglut3-dev wget zip ffmpeg

# # install anaconda
# RUN wget --quiet https://repo.anaconda.com/archive/Anaconda3-2020.11-Linux-x86_64.sh; \
#     chmod +x ./Anaconda3-2020.11-Linux-x86_64.sh; \
#     ./Anaconda3-2020.11-Linux-x86_64.sh -b -p $CONDA_DIR; \
#     rm ./Anaconda3-2020.11-Linux-x86_64.sh
# ENV PATH=$CONDA_DIR/bin:$PATH

# Download and install Micromamba.
RUN curl -sL https://micro.mamba.pm/api/micromamba/linux-64/1.1.0 \
  | sudo tar -xvj -C /usr/local bin/micromamba
ENV MAMBA_EXE=/usr/local/bin/micromamba \
    MAMBA_ROOT_PREFIX=/home/user/micromamba \
    CONDA_PREFIX=/home/user/micromamba \
    PATH=/home/user/micromamba/bin:$PATH

# Set up the base Conda environment by installing PyTorch and friends.
COPY . /workspace

# setup conda env 
RUN micromamba create -qy -n genren -f /workspace/genren.yml \
 && micromamba shell init --shell=bash --prefix="$MAMBA_ROOT_PREFIX" \
 && micromamba clean -qya

RUN cd /workspace
# RUN conda env create -f /workspace/genren.yml
#RUN . /anaconda3/etc/profile.d/conda.sh; conda activate lasr; cd /workspace/SoftRas; python setup.py install

# notes: need https://github.com/ShichenLiu/SoftRas
# torchvision=0.11.3=py38_cu111
# pytorch=1.8.2=py3.8_cuda11.1_cudnn8.0.5_0

# SHELL ["conda", "run", "-n", "genren", "/bin/bash", "-c"]
# RUN cd /workspace/SoftRas; python setup.py install

#RUN conda init bash
#RUN echo "conda activate genren" >> ~/.bashrc
#ENV PATH /opt/conda/envs/genren/bin:$PATH
#ENV CONDA_DEFAULT_ENV $genren

WORKDIR /workspace

RUN bash
