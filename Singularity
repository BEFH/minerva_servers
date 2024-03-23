Bootstrap: docker
From: alpine:latest

%post
    apk update && \
    apk add --no-cache bash wget less openssh exa fish zsh curl
    wget -O Miniforge3.sh "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh" && \
    bash Miniforge3.sh -b -p /opt/conda && \
    rm Miniforge3.sh && \
    echo "done"

%environment
    . /opt/conda/etc/profile.d/conda.sh && \
    . /opt/conda/etc/profile.d/mamba.sh
    export S_CONDAENV=${S_CONDAENV:-$CONDA_DEFAULT_ENV}

%apprun code
    alias ll='ls -l' && \
      conda activate $S_CONDAENV && \
      echo "starting server" && \
      exec code "${@}"

%apprun bash
    alias ll='ls -l' && \
      echo "activating env $RS_CONDAENV" && \
      conda activate $RS_CONDAENV && \
      echo "starting BASH" && \
      /bin/bash

%runscript
    alias ll='ls -l' && \
      conda activate $S_CONDAENV && \
      echo "starting server" && \
      exec code "${@}"

