# set base image (host OS)
# Digest from TensorFlow nightly-gpu on 2024-07-25 
#FROM tensorflow/tensorflow@sha256:c73a8dafeb4254896fd9fc8db7f5e748a6bbb4242937a7a14c9e09feb49cdcdc
FROM tensorflow/tensorflow:2.16.1-gpu
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ffmpeg \
    libsm6 \
    libxext6 \
    git \
    wget \
    numactl \
    nvidia-modprobe \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Install CUDA 12.5
RUN wget https://developer.download.nvidia.com/compute/cuda/12.5.0/local_installers/cuda_12.5.0_530.30.02_linux.run && \
    sh cuda_12.5.0_530.30.02_linux.run --silent --toolkit && \
    rm cuda_12.5.0_530.30.02_linux.run

# Install cuDNN 8.9
RUN wget https://developer.download.nvidia.com/compute/redist/cudnn/v8.9.0/cudnn-8.9.0.131_cuda12.5-archive.tar.xz && \
    tar -xvf cudnn-8.9.0.131_cuda12.5-archive.tar.xz && \
    cp cudnn-8.9.0.131_cuda12.5-archive/include/* /usr/local/cuda/include/ && \
    cp cudnn-8.9.0.131_cuda12.5-archive/lib64/* /usr/local/cuda/lib64/ && \
    rm -rf cudnn-8.9.0.131_cuda12.5-archive.tar.xz cudnn-8.9.0.131_cuda12.5-archive

# Copy the script to modify NUMA nodes
COPY modify_numa.sh /usr/local/bin/modify_numa.sh

# Make the script executable
RUN chmod +x /usr/local/bin/modify_numa.sh

# Run the script during the build process
RUN /usr/local/bin/modify_numa.sh

# set the working directory in the container
WORKDIR /code

# copy the dependencies file to the working directory
COPY requirements.txt .

# Install jaxlib with CUDA support
RUN pip install --upgrade "jax[cuda12_pip]" -f https://storage.googleapis.com/jax-releases/jax_cuda_releases.html

# Set environment variables for CUDA and cuDNN
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64:$LD_LIBRARY_PATH
ENV CUDA_HOME=/usr/local/cuda
ENV XLA_FLAGS=--xla_gpu_cuda_data_dir=/usr/local/cuda

# install dependencies
RUN pip install -r requirements.txt

# copy code
COPY src/ .
