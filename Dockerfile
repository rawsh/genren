# FROM nvidia/cuda:11.1-devel-ubuntu20.04
# FROM nvidia/cuda:11.1.1-devel-ubuntu20.04
FROM nvidia/cuda:11.7.0-devel-ubuntu22.04

# Remove any third-party apt sources to avoid issues with expiring keys.
RUN rm -f /etc/apt/sources.list.d/*.list

# Install some basic utilities.
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    g++-12 \
    gcc-12 \
    curl \
    ca-certificates \
    sudo \
    git \
    bzip2 \
    libx11-6 \
    wget \
    libxml2-dev \
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

# COPY genren.yml /workspace/genren.yml
COPY env.yml /workspace/env.yml

# setup conda env 
# RUN --mount=type=cache,target=/home/user/micromamba/pkgs/ \
#   micromamba create -qy -n genren -f /workspace/genren.yml -v
RUN --mount=type=cache,target=/home/user/micromamba/pkgs/ \
  micromamba create -qy -n genren -f /workspace/env.yml -v
  
RUN micromamba shell init --shell=bash --prefix="$MAMBA_ROOT_PREFIX"
RUN micromamba clean -qya

# RUN cd /workspace
# RUN conda env create -f /workspace/genren.yml
#RUN . /anaconda3/etc/profile.d/conda.sh; conda activate lasr; cd /workspace/SoftRas; python setup.py install

# notes: need https://github.com/ShichenLiu/SoftRas
# torchvision=0.11.3=py38_cu111
# pytorch=1.8.2=py3.8_cuda11.1_cudnn8.0.5_0
# pip install git+https://github.com/kwotsin/mimicry.git

# SHELL ["conda", "run", "-n", "genren", "/bin/bash", "-c"]
# RUN cd /workspace/SoftRas; python setup.py install

#RUN conda init bash
#RUN echo "conda activate genren" >> ~/.bashrc
#ENV PATH /opt/conda/envs/genren/bin:$PATH
#ENV CONDA_DEFAULT_ENV $genren

# Run load
# python loadtest.py Models/model-cars-latest.state_dict.pt recon_test_v img_recon --options_choice cars --imgs_dir car-images --allow_overwrite True

# COPY /home/robert/COMPSCI-591NR-Project/datasets/ShapeNetRenderings /ShapeNetRenderings
# COPY /home/robert/COMPSCI-591NR-Project/datasets/ShapeNetCore.v2_normalized /ShapeNetCore.v2_normalized

# RUN cd /workspace/SoftRas; python setup.py install

# defualt
RUN echo "micromamba activate genren" >> ~/.bashrc
ENV PATH /home/user/micromamba/envs/genren/bin:$PATH

SHELL ["micromamba", "run", "-n", "genren", "/bin/bash", "-c"]
# RUN micromamba install tensorflow-gpu -c defaults
# RUN pip install git+https://github.com/kwotsin/mimicry.git
# RUN pip install geomloss pytorch_msssim nvidia-tensorrt

#COPY . /workspace
#RUN mkdir /workspace
WORKDIR /workspace

#RUN cd SoftRas && pip install .
# RUN micromamba run -n genren "pip install git+https://github.com/kwotsin/mimicry.git; cd SoftRas && pip install ."

RUN bash
