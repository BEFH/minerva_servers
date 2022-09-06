#!/bin/bash

# See also https://www.rocker-project.org/use/singularity/

# Main parameters for the script with default values
RSTUDIO_PORT=${RSTUDIO_RSTUDIO_PORT:-8787}
RSTUDIO_USER=$(whoami)
RSTUDIO_PASSWORD=${RSTUDIO_PASSWORD:-notsafe}
RSTUDIO_TMPDIR=${RSTUDIO_TMPDIR:-tmp}
CONTAINER="/sc/arion/work/$USER/rstudio_latest.sif"  # path to singularity container (will be automatically downloaded)

# Set-up temporary paths
RSTUDIO_TMP="${RSTUDIO_TMPDIR}/$(echo -n $RSTUDIO_CONDA_PREFIX | md5sum | awk '{print $1}')"
mkdir -p $RSTUDIO_TMP/{run,var-lib-rstudio-server,local-share-rstudio}

RSTUDIO_R_BIN=$RSTUDIO_CONDA_PREFIX/bin/R
RSTUDIO_PY_BIN=$RSTUDIO_CONDA_PREFIX/bin/python

if [ ! -f $CONTAINER ]; then
	singularity pull $CONTAINER oras://ghcr.io/befh/rstudio-server-conda:latest
fi

if [ -z "$RSTUDIO_CONDA_PREFIX" ]; then
  echo "Activate a conda env or specify \$CONDA_PREFIX"
  exit 1
fi

echo "Starting rstudio service on port $RSTUDIO_PORT ..."
singularity run \
	--bind $RSTUDIO_TMP/run:/run \
	--bind $RSTUDIO_TMP/var-lib-rstudio-server:/var/lib/rstudio-server \
	--bind /sys/fs/cgroup/:/sys/fs/cgroup/:ro \
	--bind database.conf:/etc/rstudio/database.conf \
	--bind rsession.conf:/etc/rstudio/rsession.conf \
	--bind $RSTUDIO_TMP/local-share-rstudio:/home/rstudio/.local/share/rstudio \
	--bind ${RSTUDIO_CONDA_PREFIX}:${RSTUDIO_CONDA_PREFIX} \
	--bind $HOME/.config/rstudio:/home/rstudio/.config/rstudio \
        `# add additional bind mount required for your use-case` \
	--bind /data:/data \
	rstudio_latest.sif