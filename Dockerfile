# FROM nvidia/cuda:11.1-devel-ubuntu20.04
FROM nvidia/cuda:11.1.1-devel-ubuntu20.04

ENV CONDA_DIR /anaconda3

# system dependencies
RUN apt-get update -q
RUN DEBIAN_FRONTEND="noninteractive" TZ=America/New_York apt-get -y install tzdata
RUN apt-get install -q -y freeglut3-dev wget zip ffmpeg

# install anaconda
RUN wget --quiet https://repo.anaconda.com/archive/Anaconda3-2020.11-Linux-x86_64.sh; \
    chmod +x ./Anaconda3-2020.11-Linux-x86_64.sh; \
    ./Anaconda3-2020.11-Linux-x86_64.sh -b -p $CONDA_DIR; \
    rm ./Anaconda3-2020.11-Linux-x86_64.sh
ENV PATH=$CONDA_DIR/bin:$PATH

COPY SoftRas /workspace/SoftRas
COPY lasr.yml /workspace/lasr.yml

# setup conda env 
RUN cd /workspace
RUN conda env create -f /workspace/lasr.yml
#RUN . /anaconda3/etc/profile.d/conda.sh; conda activate lasr; cd /workspace/SoftRas; python setup.py install

# notes: need https://github.com/ShichenLiu/SoftRas
# torchvision=0.11.3=py38_cu111
# pytorch=1.8.2=py3.8_cuda11.1_cudnn8.0.5_0

COPY . /workspace

RUN conda init bash
RUN echo "conda activate lasr" >> ~/.bashrc
ENV PATH /anaconda3/envs/lasr/bin:$PATH
ENV CONDA_DEFAULT_ENV $lasr

WORKDIR /workspace

RUN bash
