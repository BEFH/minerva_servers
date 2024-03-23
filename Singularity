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
    export S_CONDAENV=${S_CONDAENV:-$CONDA_DEFAULT_ENV}
    [[ -z "$http_proxy" ]] || export http_proxy=$http_proxy
    [[ -z "$https_proxy" ]] || export https_proxy=$https_proxy
    [[ -z "$no_proxy" ]] || export no_proxy=$no_proxy
    [[ -z "$ftp_proxy" ]] || export ftp_proxy=$ftp_proxy
    [[ -z "$all_proxy" ]] || export all_proxy=$all_proxy
    [[ -z "$rsync_proxy" ]] || export rsync_proxy=$rsync_proxy

%apprun code
    . /opt/conda/etc/profile.d/conda.sh && \
    . /opt/conda/etc/profile.d/mamba.sh && \
    alias ll='ls -l' && \
    conda activate $S_CONDAENV && \
    echo "starting server" && \
    exec code "${@}"

%apprun bash
    . /opt/conda/etc/profile.d/conda.sh && \
    . /opt/conda/etc/profile.d/mamba.sh && \
    alias ll='ls -l' && \
    echo "activating env $RS_CONDAENV" && \
    conda activate $RS_CONDAENV && \
    echo "starting BASH" && \
    /bin/bash

%runscript
    . /opt/conda/etc/profile.d/conda.sh && \
    . /opt/conda/etc/profile.d/mamba.sh && \
    alias ll='ls -l' && \
    conda activate $S_CONDAENV && \
    echo "starting server" && \
    exec code "${@}"

