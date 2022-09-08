#!/bin/bash

# See also https://www.rocker-project.org/use/singularity/

# Main parameters for the script with default values
export S_PORT_REMOTE=${S_PORT_REMOTE:-8787}
export RSTUDIO_PASSWORD=${RSTUDIO_PASSWORD:-notsafe}
export RSTUDIO_TMP=${RSTUDIO_TMP:-tmp}
export RS_CONDAENV="null"

if [[ $RS_CONDAENV == "null" ]] || [[ $RS_CONDAENV == \$CONDA_DEFAULT_ENV ]]; then
  export RS_PREFIX=$CONDA_PREFIX
elif [[ $RS_CONDAENV =~ "/" ]]; then
  export RS_PREFIX=$RS_CONDAENV
else
  export RS_PREFIX=$(conda info --envs | awk -v env=$RS_CONDAENV '\$1 == env {print \$2}')
fi

CONTAINER="/sc/arion/work/$USER/rstudio_latest.sif"  # path to singularity container (will be automatically downloaded)

# Set-up temporary paths
export RS_TMP="${RSTUDIO_TMP}/$(echo -n $CONDA_PREFIX | md5sum | awk '{print $1}')"
mkdir -p $RS_TMP/{run,var-lib-rstudio-server,local-share-rstudio,tmp,log}

export RSTUDIO_R_BIN=$RS_PREFIX/bin/R
export RSTUDIO_PY_BIN=$RS_PREFIX/bin/python

if [ ! -f $CONTAINER ]; then
  singularity pull $CONTAINER oras://ghcr.io/befh/rstudio-server-conda:latest
fi

if [ -z "$RS_PREFIX" ]; then
  echo "Activate a conda env or specify \$CONDA_PREFIX"
  exit 1
fi

echo $ES

echo "Starting rstudio service on port $S_PORT_REMOTE ..."
singularity run \
  --bind $RS_TMP/var-lib-rstudio-server:/var/lib/rstudio-server \
  --bind /sys/fs/cgroup/:/sys/fs/cgroup/:ro \
  --bind database.conf:/etc/rstudio/database.conf \
  --bind rsession.conf:/etc/rstudio/rsession.conf \
  --bind $RS_TMP/local-share-rstudio:/home/rstudio/.local/share/rstudio \
  --bind ${RS_PREFIX}:${RS_PREFIX} \
  --bind $HOME/.config/rstudio:/home/rstudio/.config/rstudio \
  --bind /hpc/packages \
  --bind $RS_TMP/run:/serverdir \
  --bind $RS_TMP/log:/var/log/rstudio/rstudio-server \
  --bind logging.conf:/etc/rstudio/logging.conf \
  $CONTAINER  --auth-none 0 --auth-pam-helper-path=pam-helper \
  --www-port $S_PORT_REMOTE --server-data-dir=/serverdir \
  --rsession-which-r=$RSTUDIO_R_BIN \
  --rsession-ld-library-path=$RS_PREFIX/lib \
  --server-user $USER
