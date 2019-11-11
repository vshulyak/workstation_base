FROM phusion/baseimage:0.11
#
# !Use squash build!
# It's imperative that you use squash build as the image is optimized for readability
#
# Useful links to borrow updates from:
# https://gitlab.com/nvidia/cuda/blob/ubuntu16.04/9.2/base/Dockerfile
# https://gitlab.com/nvidia/cuda/blob/ubuntu16.04/9.2/runtime/cudnn7/Dockerfile

# Build-time metadata as defined at http://label-schema.org
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="Workstation Base" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/vshulyak/workstation_base" \
      org.label-schema.schema-version="1.0"

ENV LC_ALL=en_US.UTF-8 \
    CUDA_VERSION=9.2.148 \
    CUDA_PKG_VERSION="9-2=9.2.148-1" \
    CUDNN_VERSION=7.4.1.5 \
    MINICONDA3_VERSION=4.7.12.1 \
    GOOFYS_VERSION=v0.22.0

# Additional PPAs for Node (for Jupyter plugins) and Java (for Scala/Spark)
RUN curl -sL https://deb.nodesource.com/setup_11.x | bash -

# Basics needed further on in derivative images (do not cleanup up just yet)
RUN apt-get update && \
    apt-get install -y nodejs wget curl vim fuse build-essential gfortran git openjdk-11-jdk graphviz


# Install Miniconda3 (do not cleanup up just yet)
RUN wget --quiet https://repo.continuum.io/miniconda/Miniconda3-$MINICONDA3_VERSION-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    /opt/conda/bin/conda update -y conda && /opt/conda/bin/conda update -y python


# Install Goofys for S3/GCS mounting for data and notebook storages
RUN wget https://github.com/kahing/goofys/releases/download/$GOOFYS_VERSION/goofys -P /usr/bin/ && \
    chmod u+x /usr/bin/goofys

# CUDA + CUDNN for running DL
RUN curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1710/x86_64/7fa2af80.pub | apt-key add - && \
    echo "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1710/x86_64 /" > /etc/apt/sources.list.d/cuda.list && \
    echo "deb https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list && \
    apt-get update && apt-get install -y --no-install-recommends \
        cuda-cudart-$CUDA_PKG_VERSION && \
    ln -s cuda-9.2 /usr/local/cuda && \
    apt-get install -y --no-install-recommends cuda-libraries-dev-$CUDA_PKG_VERSION libcudnn7=$CUDNN_VERSION-1+cuda9.2 \
            libcudnn7-dev=$CUDNN_VERSION-1+cuda9.2 && \
    echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

# Cleanup
RUN rm -rf /var/lib/apt/lists/* && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV MKL_THREADING_LAYER=GNU \
    PATH=/usr/local/nvidia/bin:/usr/local/cuda/bin:/opt/conda/bin:${PATH} \
    LD_LIBRARY_PATH=/usr/local/nvidia/lib:/usr/local/nvidia/lib64:/usr/local/cuda-9.2/targets/x86_64-linux/include/ \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility \
    NVIDIA_REQUIRE_CUDA="cuda>=9.2"
