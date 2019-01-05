FROM phusion/baseimage:0.10.2
#
# !Use squash build!
# It's imperative that you use squash build as the image is optimized for readability
#
# Useful links to borrow updates from:
# https://gitlab.com/nvidia/cuda/blob/ubuntu16.04/9.2/base/Dockerfile
# https://gitlab.com/nvidia/cuda/blob/ubuntu16.04/9.2/runtime/cudnn7/Dockerfile

CMD ["/sbin/my_init"]

ENV LC_ALL en_US.UTF-8
ENV CUDA_VERSION 9.2.148
ENV CUDA_PKG_VERSION 9-2=$CUDA_VERSION-1
ENV CUDNN_VERSION 7.4.1.5
ENV MINICONDA3_VERSION 4.5.12
ENV GOOFYS_VERSION v0.19.0

# Additional PPAs for Node (for Jupyter plugins) and Java (for Scala/Spark)
RUN curl -sL https://deb.nodesource.com/setup_11.x | bash - && \
    echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
    add-apt-repository -y ppa:webupd8team/java


# Basics needed further on in derivative images (do not cleanup up just yet)
RUN apt-get update && \
    apt-get install -y nodejs wget curl vim fuse build-essential gfortran git oracle-java8-installer graphviz


# Install Miniconda3 (do not cleanup up just yet)
RUN wget --quiet https://repo.continuum.io/miniconda/Miniconda3-$MINICONDA3_VERSION-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    /opt/conda/bin/conda update -y conda && /opt/conda/bin/conda update -y python


# Install Goofys for S3/GCS mounting for data and notebook storages
RUN wget https://github.com/kahing/goofys/releases/download/$GOOFYS_VERSION/goofys -P /usr/bin/ && \
    chmod u+x /usr/bin/goofys

# CUDA + CUDNN for running DL
RUN NVIDIA_GPGKEY_SUM=d1be581509378368edeec8c1eb2958702feedf3bc3d17011adbf24efacce4ab5 && \
    NVIDIA_GPGKEY_FPR=ae09fe4bbd223a84b2ccfce3f60f4b3d7fa2af80 && \
    apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/7fa2af80.pub && \
    apt-key adv --export --no-emit-version -a $NVIDIA_GPGKEY_FPR | tail -n +5 > cudasign.pub && \
    echo "$NVIDIA_GPGKEY_SUM  cudasign.pub" | sha256sum -c --strict - && rm cudasign.pub && \
    echo "deb http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64 /" > /etc/apt/sources.list.d/cuda.list && \
    echo "deb http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list && \
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


ENV MKL_THREADING_LAYER=GNU
ENV PATH=$PATH:/opt/conda/bin

ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64:/usr/local/cuda-9.2/targets/x86_64-linux/include/

# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV NVIDIA_REQUIRE_CUDA "cuda>=9.2"
