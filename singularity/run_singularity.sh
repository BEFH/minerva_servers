#!/bin/bash

# See also https://www.rocker-project.org/use/singularity/

# Main parameters for the script with default values
export RSTUDIO_PORT=${RSTUDIO_PORT:-8787}
export RSTUDIO_USER=$(whoami)
export RSTUDIO_PASSWORD=${RSTUDIO_PASSWORD:-notsafe}
export RSTUDIO_TMPDIR=${RSTUDIO_TMPDIR:-tmp}
export RSTUDIO_CONDA_PREFIX=$CONDA_PREFIX
CONTAINER="/sc/arion/work/$USER/rstudio_latest.sif"  # path to singularity container (will be automatically downloaded)

# Set-up temporary paths
export RSTUDIO_TMP="${RSTUDIO_TMPDIR}/$(echo -n $CONDA_PREFIX | md5sum | awk '{print $1}')"
mkdir -p $RSTUDIO_TMP/{run,var-lib-rstudio-server,local-share-rstudio,tmp,srvrdr}

export RSTUDIO_R_BIN=$CONDA_PREFIX/bin/R
export RSTUDIO_PY_BIN=$CONDA_PREFIX/bin/python

if [ ! -f $CONTAINER ]; then
	singularity pull $CONTAINER oras://ghcr.io/befh/rstudio-server-conda:latest
fi

if [ -z "$CONDA_PREFIX" ]; then
  echo "Activate a conda env or specify \$CONDA_PREFIX"
  exit 1
fi

echo $RSTUDIO_TMP

echo "Starting rstudio service on port $RSTUDIO_PORT ..."
singularity run \
	--bind $RSTUDIO_TMP/run:/run \
	--bind $RSTUDIO_TMP/var-lib-rstudio-server:/var/lib/rstudio-server \
	--bind /sys/fs/cgroup/:/sys/fs/cgroup/:ro \
	--bind database.conf:/etc/rstudio/database.conf \
	--bind rsession.conf:/etc/rstudio/rsession.conf \
	--bind $RSTUDIO_TMP/local-share-rstudio:/home/rstudio/.local/share/rstudio \
	--bind ${CONDA_PREFIX}:${CONDA_PREFIX} \
`#  --bind ${RSTUDIO_TMP}/tmp:/tmp/rstudio-server` \
	--bind $HOME/.config/rstudio:/home/rstudio/.config/rstudio \
	--bind /hpc/packages
	$CONTAINER  --auth-none 0 --auth-pam-helper-path=pam-helper \
	--www-port $RSTUDIO_PORT --server-data-dir=$RSTUDIO_TMP/srvrdr \
	--rsession-which-r=$RSTUDIO_WHICH_R \
	--rsession-ld-library-path=$CONDA_PREFIX/lib \
	--server-user $USER

#old args:

#  --www-address=127.0.0.1 \
#        --www-port=$PORT \
#        --rsession-which-r=$RSTUDIO_WHICH_R \
#        --rsession-ld-library-path=$CONDA_PREFIX/lib \
#        `# optional: old behaviour of R sessions` \
#        --auth-timeout-minutes=0 --auth-stay-signed-in-days=30  \
#        `# activate password authentication` \
#        --auth-none=0  --auth-pam-helper-path=pam-helper \
#        --server-user $USER