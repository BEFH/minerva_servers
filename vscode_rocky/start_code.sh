#!/usr/bin/env bash

# Activate conda and mamba

__conda_setup="$('/opt/conda/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/conda/etc/profile.d/conda.sh" ]; then
        . "/opt/conda/etc/profile.d/conda.sh"
    else
        export PATH="/opt/conda/bin:$PATH"
    fi
fi
unset __conda_setup

if [ -f "/opt/conda/etc/profile.d/mamba.sh" ]; then
    . "/opt/conda/etc/profile.d/mamba.sh"
fi

# Activate the conda environment

conda activate $RS_CONDAENV

# start vscode

exec code "${@}"
