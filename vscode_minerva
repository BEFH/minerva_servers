#!/usr/bin/env zsh

###############################################################################
#                                                                             #
#  Script to run on a local computer to start a VSCode server on Minerva and  #
#  connect to it with a local browser                                         #
#                                                                             #
#  Main author     : Brian Fulton-Howard                                      #
#  Original author : Samuel Fux                                               #
#  Contributions   : Wei Guo, Gene Fluder, Lili Gai                           #
#                  : Andreas Lugmayr, Mike Boss                               #
#  Date            : October 2021                                             #
#  Location        : Mount Sinai (originally ETH Zurich)                      #
#  Version         : 0.8.9                                                    #
#  Change history  :                                                          #
#                                                                             #
#  04.05.2024    Include .Rprofile allowing R integration from other envs     #
#  04.05.2024    Do not print lsof warnings                                   #
#  16.04.2024    Script works in zsh and bash. Zsh is now default             #
#  16.04.2024    Back up config files when updating; more flexible confs;     #
#                give instructions for first run                              #
#  15.04.2024    Move singularity image paths                                 #
#  05.04.2024    Automated local port selection for remote start,             #
#                editable config files, improved messages, and fixes to       #
#                vscode configuration script                                  #
#  24.03.2024    Adapt to run vscode server in a container environment        #
#  21.03.2024    Isolation by default without isolation in terminal           #
#  20.03.2024    Only log at debug level in Rstudio if --debug; Allow use     #
#                of Github Copilot                                            #
#  20.03.2024    Remove attempts at lsf and lmod; allow breaking out of       #
#                sandbox onto Minerva by typing "minerva" in the terminal     #
#                optionally followed by bsub arguments; allow running on      #
#                cluster as well as locally; improve speed and robustness;    #
#                add --debug mode; guess himem and lsf partition;             #
#                Guess LSF account better; allow multiple LSF resources       #
#  17.11.2022    include session name in lsf lognames and allow long jobs     #
#  03.10.2022    Native client compatibility with Apple Silicon               #
#  29.09.2022    Allow differnt hostnames on different clients                #
#  23.09.2022    Internet on Minerva. Remove for other clusters               #
#  23.09.2022    Fix conda env and isolated operation                         #
#                specify img, speed, verbosity, print password                #
#  13.09.2022    Isolation working, validate successful startup,              #
#                specify img, speed, verbosity, print password                #
#  08.09.2022    fix authentication, non-working isolated environments,       #
#                enable module system (with setting var) and conda lmod       #
#  08.09.2022    Moved working files to workdir, bugfixes, img download       #
#  07.09.2022    Allow resource specification,                                #
#                integrate of rstudio,                                        #
#                automatically use first project unless specified,            #
#                and colorize outputs                                         #
#  07.07.2022    Fix launching outside of home directory and                  #
#                more robust token grabbing                                   #
#  07.07.2022    Fix browser opening on Mac and support WSL                   #
#  04.07.2022    Locks have potential fix but are disabled for now            #
#  30.06.2022    Locks and free ports on remote, improved native              #
#                remote storage of reconnect info, improved messages          #
#  22.06.2022    Allow simultaneous sessions and specifying folder            #
#  22.06.2022    Automatic multiplexing and check for code-server             #
#  22.06.2022    Allow and validate longer walltimes                          #
#  16.06.2022    Adapt for minerva and add autorestart support                #
#  19.05.2022    JOBID is now saved to reconnect_info file                    #
#  28.10.2021    Initial version of the script based on Jupyter script        #
#                                                                             #
###############################################################################

###############################################################################
# Configuration options, initalising variables and setting default values     #
###############################################################################

# Version
S_VERSION="0.8.9"

# Script directory
S_SCRIPTDIR=$HOME

# hostname of the cluster to connect to
if [ -d /etc/lsb-release.d ]; then
  S_HOSTNAME="minervarun"
elif grep -q 'Host minerva[[:space:]]*$' $HOME/.ssh/config > /dev/null 2>&1; then
  S_HOSTNAME="minerva"
elif grep -q 'Host chimera[[:space:]]*$' $HOME/.ssh/config > /dev/null 2>&1; then
  S_HOSTNAME="chimera"
fi

# Queue to use
S_QUEUE="auto"

# LSF Account
S_ACCT="acc_null"

# Custom job session name
S_SESSION=""

# order for initializing configuration options
# 1. Defaults values set inside this script
# 2. Command line options overwrite defaults
# 3. Config file options  overwrite command line options

# Configuration file default    : $HOME/.vsc_config
S_CONFIG_FILE="$HOME/.vsc_config"

# Number of CPU cores default   : 4 CPU cores
S_NUM_CPU=4

# Runtime limit default         : 12:00 hour
S_RUN_TIME="12:00"

# Memory default                : 4000 MB per core
S_MEM_PER_CPU_CORE=4000

# Waiting interval default      : 30 seconds
S_WAITING_INTERVAL=30

# Default resources             : none
S_RESOURCE="null"

# Default env                   : shell default
S_CONDAENV="null"

# Default image                 : "default" means dl to /sc/arion/work/$USER/
S_IMAGE="default"

# Debugging mode
S_DEBUG=0

# Update vscode server
S_UPDATE=0

# Do not open browser by default
S_OPEN_BROWSER=0

# Remote start
S_REMOTE_START="null"

###############################################################################
# Text coloring                                                               #
###############################################################################

echoinfo () {
  # Green
  echo -e "\033[32m[INFO] $@\033[0m"
}

echoerror () {
  # Red
  echo -e "\033[31m[ERROR] $@\033[0m"
}

echoalert () {
  # Blinking blue
  echo -e "\033[34;5m[INFO] $@\033[0m"
}

echowarn () {
  # Yellow
  echo -e "\033[33m[WARNING] $@\033[0m"
}

echodebug () {
  if [[ $S_DEBUG -eq 1 ]]; then
    # Magenta
    echo -e "\033[35m[DEBUG] $@\033[0m"
  fi
}

###############################################################################
# Usage instructions                                                          #
###############################################################################

function display_help {
cat <<-EOF
$0: Script to start a VSCode server on Minerva from a local computer

Usage: $(basename "$0") [options]

Options:

  -P | --project    1st available    LSF project name

Optional arguments:

  -n | --numcores   4                Number of CPU cores to be used on
                                      the cluster
  -q | --queue      guess            Queue to be used on the cluster
  -W | --runtime    12               Run time limit for the server in hours
                                      and minutes H[H[H]]:MM
  -m | --memory     4000             Memory limit in MB per core
  -R | --resource                    Extra resource request like "himem"
  -b | --browser                     Open browser automatically
  -c | --config     ~/.vsc_config    Configuration file for specifying options
  -h | --help                        Display help for this script and quit
  -i | --interval   30               Time interval (sec) for checking if the job
                                      on the cluster already started
  -v | --version                     Display version of the script and exit
  -s | --server     minerva          SSH arguments for connecting to the server:
                                      Will default to "minerva", then "chimera".
                                      server name from .ssh/config, or e.g.
                                      user@minerva.hpc.mssm.edu
  -S | --session                     Session name to run multiple servers
  -C | --conda      shell default    Conda env for running VSCode
       --isolated   none             Run VSCode server without home directory
                                      or environment variables (deprecated)
       --isolation  none             Amount of container isolation: if 'full',
                                      run VSCode server without home directory
                                      or environment variables. If 'partial',
                                      same as full but open shell outside of
                                      sandbox. If 'none', do not isolate.
  -I | --image      dload to work    Singularity image to use for the server.
                                      Downloaded automatically if not specified.
  --debug                            Print debug messages
  --update                           Update vscode and singularity image
  --remote-start                     Connect to job started from cluster

Examples:

  $(basename $0) -n 4 -W 04:00 -m 2048

  $(basename $0) --numcores 2 --runtime 01:30 --memory 2048

  $(basename $0) -c $HOME/.vsc_config

Format of configuration file:

S_NUM_CPU=1               # Number of CPU cores to be used on the cluster
S_RUN_TIME="01:00"        # Run time limit for the server in hours and
                            #   minutes H[H[H]]:MM
S_MEM_PER_CPU_CORE=1024   # Memory limit in MB per core
S_WAITING_INTERVAL=60     # Time interval to check if the job on the cluster
                            #   already started
S_QUEUE="premium"         # LSF queue to be used on the cluster
S_SESSION=""              # Session name to run multiple servers
S_ACCT="acc_SOMETHING"    # LSF account to be used on the cluster
S_HOSTNAME="minerva"      # SSH host or username@host for connection

You should have SSH ControlMaster enabled in your ~/.ssh/config file for this to
work fully on the cluster. The script will manually multiplex otherwise, but
this is not recommended.

See https://en.wikibooks.org/wiki/OpenSSH/Cookbook/Multiplexing

EOF
exit 1
}

###############################################################################
# Parse configuration options                                                 #
###############################################################################

# Check that the BASH version is at least 5.0 and exit if not
runshell=$(ps -o args= -p $$ | grep -Em 1 -o '\w{0,5}sh')
if [[ ${BASH_VERSION%%.*} -lt 5 ]] && [[ $runshell != zsh ]]; then
  echoerror "This script requires BASH version 5.0 or higher"
  exit 1
elif [[ $runshell == zsh ]]; then
  setopt BASH_REMATCH
fi

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
    display_help
    ;;
    -v|--version)
    echo -e "vscode_minerva version: $S_VERSION\n"
    exit
    ;;
    -n|--numcores)
    S_NUM_CPU=$2
    shift; shift
    ;;
    -s|--server)
    S_HOSTNAME=$2
    shift; shift
    ;;
    -q|--queue)
    S_QUEUE=$2
    shift; shift
    ;;
    -P|--project)
    S_ACCT=$2
    shift; shift
    ;;
    -W|--runtime)
    S_RUN_TIME=$2
    shift; shift
    ;;
    -m|--memory)
    S_MEM_PER_CPU_CORE=$2
    shift; shift
    ;;
    -c|--config)
    S_CONFIG_FILE=$2
    shift; shift
    ;;
    -i|--interval)
    S_WAITING_INTERVAL=$2
    shift; shift
    ;;
    --isolation)
    if [[ $2 == "full" ]]; then
      S_ISOLATED=2
    elif [[ $2 == "partial" ]]; then
      S_ISOLATED=1
    elif [[ $2 == "none" ]]; then
      S_ISOLATED=0
    else
      echowarn "ignoring unknown isolation option $2 \n"
    fi
    shift; shift
    ;;
    --isolated)
    S_ISOLATED_CLASSIC=1
    shift
    ;;
    -R|--resource)
    if [[ $S_RESOURCE == "null" ]]; then
      S_RESOURCE="$2"
    else
      S_RESOURCE+=" -R $2"
    fi
    shift; shift
    ;;
    -S|--session)
    S_SESSION="_$2"
    shift; shift
    ;;
    -C|--conda)
    S_CONDAENV="$2"
    shift; shift
    ;;
    -I|--image)
    S_IMAGE="$2"
    shift; shift
    ;;
    --debug)
    S_DEBUG=1
    shift
    ;;
    -b|--browser)
    S_OPEN_BROWSER=1
    shift
    ;;
    --update)
    S_UPDATE=1
    shift
    ;;
    --remote-start)
    S_REMOTE_START=$2
    shift; shift
    ;;
    *)
    echowarn "ignoring unknown option $1 \n"
    shift
    ;;
  esac
done

###############################################################################
# Check key configuration options                                             #
###############################################################################

find_port() {
  echoinfo "Determining free port on local computer" 1>&2
  PRT=$1
  while ( lsof -Pni :$PRT 2> /dev/null | grep -q LISTEN); do
    PRT=$((PRT+1))
  done
  echo $PRT
}

if [[ $S_REMOTE_START != "null" ]]; then
  # find free local port
  S_LOCAL_PORT=$(find_port 18890)
  S_REMOTE_IP=$(echo $S_REMOTE_START | cut -d: -f1)
  S_REMOTE_PORT=$(echo $S_REMOTE_START | cut -d: -f2)
  S_REMOTE_TOKEN=$(echo $S_REMOTE_START | cut -d: -f3)
  echoinfo "Connecting to remote session at $S_REMOTE_IP:$S_REMOTE_PORT"
  ssh $S_HOSTNAME -L $S_LOCAL_PORT:$S_REMOTE_IP:$S_REMOTE_PORT -fNT
  if [[ $? -ne 0 ]]; then
    echoerror "Failed to connect to remote session"
    exit 1
  fi
  echoinfo "Please open the following URL in your browser:"
  echoinfo "http://localhost:$S_LOCAL_PORT?tkn=$S_REMOTE_TOKEN"
  exit 0
fi

# check if user has a configuration file and source it to initialize options
if [ -f "$S_CONFIG_FILE" ]; then
  echoinfo "Found configuration file $S_CONFIG_FILE"
  echoinfo "Initializing configuration from file ${S_CONFIG_FILE}:"
  cat "$S_CONFIG_FILE"
  source "$S_CONFIG_FILE"
fi

# check isolation mode

if [[ $S_ISOLATED_CLASSIC -eq 1 ]]; then
  # check if S_ISOLATED is set
  if ! [ -z ${S_ISOLATED+x} ]; then
    echoerror "Cannot use both --isolated and --isolation. Please try again\n"
    display_help
  fi
  echowarn "The --isolated option is deprecated. VSCode is now mostly isolated"
  echowarn "by default. Use --isolation to specify the amount of isolation."
  echowarn "The equivalent of --isolated is '--isolation full' and the old"
  echowarn "default is '--isolation none'."
  echowarn "The --isolated option will be removed in a future version."
  S_ISOLATED=2
  echoinfo "Running with full container isolation"
fi

if [ -z ${S_ISOLATED+x} ]; then
  S_ISOLATED=0
  echoinfo "Running with default no container isolation"
elif [[ $S_ISOLATED -eq 0 ]]; then
  echoinfo "Running without container isolation"
elif [[ $S_ISOLATED -eq 1 ]]; then
  echoinfo "Running with partial container isolation"
elif [[ $S_ISOLATED -eq 2 ]]; then
  echoinfo "Running with full container isolation"
fi

# Check hostname
get_hostinfo() {
    awk -v hrx="[Hh][Oo][Ss][Tt][[:space:]]+$1[[:space:]]*$" \
   '$0 ~ "[Hh]ost[[:space:]]" {a = 0} $0 ~ hrx {a = 1; next} a == 1 {print}' \
   $HOME/.ssh/config | sed -E 's/^[[:blank:]]*|[[:blank:]]*$//g'
}

if [ -z ${S_HOSTNAME+x} ]; then
  echoerror "Hostname is not set. Please specify with --server option.\n\n"
  display_help
elif [[ "$S_HOSTNAME" == "minervarun" ]]; then
  echoinfo "Running locally on Minerva\n\n"
elif [[ "$S_HOSTNAME" =~ "@" ]]; then
  echoinfo "Valid username and server $S_HOSTNAME selected\n\n"
elif ! [ -f $HOME/.ssh/config ]; then
  echoerror "Username not specified and .ssh/config does not exist.\n\n"
  display_help
elif ! [[ $(get_hostinfo $S_HOSTNAME | wc -l) -gt 0 ]]; then
  echoerror "Username not specified and host not in .ssh/config.\n\n"
  display_help
elif ! get_hostinfo $S_HOSTNAME | grep -iq HostName; then
  echoerror "Hostname not specified in .ssh/config.\n\n"
  display_help
elif ! get_hostinfo $S_HOSTNAME | grep -iq User; then
  echoerror "Hostname not specified in .ssh/config.\n\n"
  display_help
else
  echoinfo "Connecting with the following settings:\n"
  get_hostinfo $S_HOSTNAME | grep -iE "HostName|User"
  echo
fi

# Check if multiplexing is enabled, otherwise warn and compensate
cm_enabled=$({[ -f $HOME/.ssh/config ] &&
              grep -q "ControlPath" $HOME/.ssh/config > /dev/null 2>&1} &&
             echo 1 || echo 0)
if ! [[ "$S_HOSTNAME" == "minervarun" || cm_enabled -eq 1 ]]; then
  echoalert "You should enable ControlMaster in your .ssh/config.\n"
  echoalert "See https://en.wikibooks.org/wiki/OpenSSH/Cookbook/Multiplexing\n"
  if ! [ -d $HOME/.ssh/cm_socket ]; then
    mkdir -p $HOME/.ssh/cm_socket
  fi
  S_MANUAL_MULTIPLEX=true
  ssh -M -S ~/.ssh/cm_socket/%r@%h:%p -o "ControlPersist=10m" $S_HOSTNAME echo -e "Logged in as \$USER\n"
  S_HOSTNAME="-S ~/.ssh/cm_socket/%r@%h:%p $S_HOSTNAME"
fi

###############################################################################
# Set up directories and files                                                #
###############################################################################

if [[ "$S_HOSTNAME" == "minervarun" ]]; then
  echoinfo "Running locally on Minerva"
  S_USERNAME=$USER
  # make a function to run heredoc locally
  eval_heredoc() {
    bash -s
  }
else
  echoinfo "Connecting to $S_HOSTNAME"
  S_USERNAME=$(ssh -n $S_HOSTNAME 'echo "$USER"')
  eval_heredoc() {
    ssh $S_HOSTNAME 'bash -s'
  }
fi

echoinfo "Setting up directories and files"
S_WORKDIR="/hpc/users/$S_USERNAME/minerva_jobs/code_container"
S_TMP=/tmp/${S_USERNAME}${S_SESSION}_VSCode

S_BASE_RECONNECT=".reconnect_info_vsc$S_SESSION"
S_FILE_RECONNECT="$S_WORKDIR/$S_BASE_RECONNECT"
S_FILE_JOB="$S_WORKDIR/code$S_SESSION.lsf"
S_FILE_IP="$S_WORKDIR/vscip$S_SESSION"
S_FILE_BASHPROF="$S_WORKDIR/bash_profile"
S_FILE_BASHRC="$S_WORKDIR/bashrc"
S_FILE_FISHCONFIG="$S_WORKDIR/config.fish"
S_FILE_ZSHRC="$S_WORKDIR/zshrc"
S_FILE_RPROFILE="$S_WORKDIR/Rprofile"
declare -A S_FILES_SHELLCONF
S_FILES_SHELLCONF[bash_profile]="$S_FILE_BASHPROF"
S_FILES_SHELLCONF[bashrc]="$S_FILE_BASHRC"
S_FILES_SHELLCONF[fishconf]="$S_FILE_FISHCONFIG"
S_FILES_SHELLCONF[zshrc]="$S_FILE_ZSHRC"
S_FILES_SHELLCONF[rprofile]="$S_FILE_RPROFILE"
SVSC_DIR_CONFIG="/hpc/users/$S_USERNAME/.config/CodeContainer"
SVSC_DIR_CONFIG_DOTVSC="$S_WORKDIR/serverconf"
SVSC_APP="$S_WORKDIR/code"

###############################################################################
# Check directories, files, image, and password                               #
###############################################################################

echoinfo "Checking directories, files, image, and password"

eval_heredoc <<EOF
if [[ ! -d $S_WORKDIR ]]; then
  echo $(echoinfo "Creating working directory")
  mkdir -p $S_WORKDIR
fi
if [[ ! -d $SVSC_DIR_CONFIG ]]; then
  echo $(echoinfo "Creating config directory and files")
  mkdir -p $SVSC_DIR_CONFIG
fi
if [[ ! -d $SVSC_DIR_CONFIG_DOTVSC ]]; then
  echo $(echoinfo "Creating config directory and files")
  mkdir -p $SVSC_DIR_CONFIG_DOTVSC
fi
if [[ ! -f $S_WORKDIR/.config_template.json ]] || [[ $S_UPDATE -eq 1 ]]; then
  echo $(echoinfo "Creating config template file")
  remote_shell=\$(getent passwd \$USER | awk -F: '{print \$7}' | xargs basename)
  cat <<EOFF > $S_WORKDIR/.config_template.json
{
    "terminal.integrated.profiles.linux": {
        "bash": {
            "path": "bash",
            "icon": "terminal-bash",
            "args": ["--rcfile", "~/.bash_profile"]
        },
        "bash-minerva": {
            "path": "bash",
            "icon": "terminal-bash",
            "args": ["-c", ". ~/.bash_profile; minerva"]
        },
        "zsh-minerva": {
            "path": "zsh",
            "args": ["-c", ". ~/.zshrc; minerva"]
        },
        "fish": {
            "path": "fish"
        },
        "fish-minerva": {
            "path": "fish",
            "args": ["-c", "minerva"]
        }
    },
    "terminal.integrated.scrollback": 100000,
    "r.bracketedPaste": true,
    "r.rpath.linux": "/myhome/.launch_r.sh",
    "r.rterm.linux": "/myhome/.launch_radian.sh",
    "r.rterm.option": [],
    "vsicons.dontShowNewVersionMessage": true,
    "terminal.integrated.defaultProfile.linux": "\$remote_shell",
}
EOFF
fi
if [[ ! -f $S_WORKDIR/.recommended_packages.txt ]] || [[ $S_UPDATE -eq 1 ]]; then
  echo $(echoinfo "Creating recommended packages file")
  cat <<EOFF > $S_WORKDIR/.recommended_packages.txt
formulahendry.code-runner
REditorSupport.R
janisdd.vscode-edit-csv
grapecity.gc-excelviewer
yzhang.markdown-all-in-one
ms-python.python
ms-toolsai.jupyter
quarto.quarto
snakemake.snakemake-lang
vscode-icons-team.vscode-icons
donjayamanne.python-environment-manager
pnp.polacode
ms-vsliveshare.vsliveshare
github.remotehub
donjayamanne.githistory
ms-toolsai.datawrangler
onnovalkering.vscode-singularity
EOFF
fi
if [[ ! -f $S_WORKDIR/.setup_vscode.sh ]] || [[ $S_UPDATE -eq 1 ]]; then
  echo $(echoinfo "Creating setup script")
  cat <<'EOFF' > $S_WORKDIR/.setup_vscode.sh
#!/usr/bin/env bash
echo "Installing recommended extensions"
while read -r line; do
  code --install-extension "\$line"
done < ~/.recommended_packages.txt

echo "To set up the configuration for VSCode, open the command palette with"
printf "Cmd+Shift+P and type Preferences: Open Remote Settings \x28JSON\x29\n"
echo "Then copy and paste the following:"
sed "s|/myhome|\$HOME|" ~/.config_template.json 
EOFF
  chmod +x $S_WORKDIR/.setup_vscode.sh
fi
EOF

echodebug "Checking shell config files"

S_BSUBCMD=/hpc/lsf/10.1/linux3.10-glibc2.17-x86_64/bin/bsub

declare -A S_CONFIG_CONTENTS
S_CONFIG_CONTENTS[rprofile]=$(cat <<EOF
if (interactive() && Sys.getenv("RSTUDIO") == "") {
  Sys.setenv(TERM_PROGRAM = "vscode")
  source(file.path(Sys.getenv("HOME"), ".vscode-R", "init.R"))
}

## Default repo
local({
  r <- getOption("repos")
  r["CRAN"] <- "https://cran.us.r-project.org"
  options(repos = r)})
EOF
)
S_CONFIG_CONTENTS[bash_profile]=$(cat <<EOF
# Set prompt to standard bash prompt instead of the one from the image
export PS1='\u@\h:\w\$ '
source \$HOME/.bashrc
minerva() {
  if [[ \$PWD == "/myhome" ]]; then
    minervadir='\$HOME'
  else
    minervadir=\$PWD
  fi
  ssh -o StrictHostKeyChecking=accept-new -t \$(hostname -f) \\
    "conda activate \$S_CONDAENV; ml proxies; cd \$minervadir; bash"
  exit 0
}
if [[ -d "/sc/arion/projects/load/scripts" ]]; then
  export PATH="/sc/arion/projects/load/scripts:\$PATH"
fi
alias bblame='ssh -t li03c04 bblame'
alias ijob='ssh -t li03c04 ijob'
alias regjob='ssh -t li03c04 regjob'
alias ll='ls -l'
EOF
)
S_CONFIG_CONTENTS[bashrc]=$(cat <<EOF
bsub() {
    bsubcmd=$S_BSUBCMD
    if module is-loaded lsf && module is-loaded CPAN &> /dev/null; then
        \$bsubcmd \$@ 2> >(grep -v "Perl_xs_version_bootcheck" >&2)
    else
        echo "Please enable LSF by running 'lsf_enable'"
    fi
}

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="\$('/opt/conda/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ \$? -eq 0 ]; then
    eval "\$__conda_setup"
else
    if [ -f "/opt/conda/etc/profile.d/conda.sh" ]; then
        . "/opt/conda/etc/profile.d/conda.sh"
    else
        export PATH="/opt/conda/bin:\$PATH"
    fi
fi
unset __conda_setup

if [ -f "/opt/conda/etc/profile.d/mamba.sh" ]; then
    . "/opt/conda/etc/profile.d/mamba.sh"
fi
# <<< conda initialize <<<

export PROMPT_COMMAND=""
conda activate \$S_CONDAENV

alias lsf_enable="ml lsf CPAN"
alias lsf_disable="ml -lsf -CPAN"
EOF
)
S_CONFIG_CONTENTS[fishconf]=$(cat <<EOF
if status is-interactive
    # Commands to run in interactive sessions can go here
end

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f /opt/conda/bin/conda
    eval /opt/conda/bin/conda "shell.fish" "hook" \$argv | source
else
    if test -f "/opt/conda/etc/fish/conf.d/conda.fish"
        . "/opt/conda/etc/fish/conf.d/conda.fish"
    else
        set -x PATH "/opt/conda/bin" \$PATH
    end
end

if test -f "/opt/conda/etc/fish/conf.d/mamba.fish"
    source "/opt/conda/etc/fish/conf.d/mamba.fish"
end
# <<< conda initialize <<<
function minerva
  if test \$PWD = "/myhome"
    set minervadir '\$HOME'
  else
    set minervadir \$PWD
  end
  ssh -o StrictHostKeyChecking=accept-new -t (hostname) \\
    "conda activate \$S_CONDAENV; ml proxies; cd \$minervadir; fish"
  exit 0
end

function bsub
  set bsubcmd $S_BSUBCMD
  if type -q module; and module is-loaded lsf; and module is-loaded CPAN
    bash -c "\$bsubcmd \$argv 2> >(grep -v 'Perl_xs_version_bootcheck' >&2)"
  else
    echo "Please enable LSF by running 'lsf_enable'"
  end
end

if test -d "/sc/arion/projects/load/scripts"
  set -x PATH "/sc/arion/projects/load/scripts" \$PATH
end

alias bblame 'ssh -t li03c04 bblame'
alias ijob 'ssh -t li03c04 ijob'
alias regjob 'ssh -t li03c04 regjob'
alias lsf_enable="ml lsf CPAN"
alias lsf_disable="ml -lsf -CPAN"

conda activate \$S_CONDAENV
EOF
)
S_CONFIG_CONTENTS[zshrc]=$(cat <<EOF
bsub() {
    bsubcmd=$S_BSUBCMD
    if module is-loaded lsf && module is-loaded CPAN > /dev/null 2>&1; then
        \$bsubcmd \$@ 2> >(grep -v "Perl_xs_version_bootcheck" >&2)
    else
        echo "Please enable LSF by running 'lsf_enable'"
    fi
}

# Set prompt to standard zsh prompt instead of the one from the image
export PROMPT_COMMAND=""
export PROMPT='%n@%m:%~%# '

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="\$('/opt/conda/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ \$? -eq 0 ]; then
    eval "\$__conda_setup"
else
    if [ -f "/opt/conda/etc/profile.d/conda.sh" ]; then
        . "/opt/conda/etc/profile.d/conda.sh"
    else
        export PATH="/opt/conda/bin:\$PATH"
    fi
fi
unset __conda_setup

if [ -f "/opt/conda/etc/profile.d/mamba.sh" ]; then
    . "/opt/conda/etc/profile.d/mamba.sh"
fi
# <<< conda initialize <<<

minerva() {
  if [[ \$PWD == "/myhome" ]]; then
    minervadir='\$HOME'
  else
    minervadir=\$PWD
  fi
  ssh -o StrictHostKeyChecking=accept-new -t \$(hostname -f) \\
    "conda activate \$S_CONDAENV; ml proxies; cd \$minervadir; zsh"
  exit 0
}

if [[ -d "/sc/arion/projects/load/scripts" ]]; then
  export PATH="/sc/arion/projects/load/scripts:\$PATH"
fi
alias bblame='ssh -t li03c04 bblame'
alias ijob='ssh -t li03c04 ijob'
alias regjob='ssh -t li03c04 regjob'
alias ll='ls -l'
alias lsf_enable="ml lsf CPAN"
alias lsf_disable="ml -lsf -CPAN"

conda activate \$S_CONDAENV
EOF
)

if [[ $S_UPDATE -eq 1 ]]; then
  echoinfo "Updating config files"
  eval_heredoc <<EOF
  [ -f $S_FILE_BASHPROF ] && mv $S_FILE_BASHPROF $S_FILE_BASHPROF.bk
  mv $S_FILE_BASHRC $S_FILE_BASHRC.bk
  mv $S_FILE_FISHCONFIG $S_FILE_FISHCONFIG.bk
  mv $S_FILE_ZSHRC $S_FILE_ZSHRC.bk
EOF
fi

S_ABSENT_FILES=$(eval_heredoc <<EOF
[ -f $S_FILE_BASHPROF ] || echo bash_profile
[ -f $S_FILE_BASHRC ] || echo bashrc
[ -f $S_FILE_FISHCONFIG ] || echo fishconf
[ -f $S_FILE_ZSHRC ] || echo zshrc
[ -f $S_FILE_RPROFILE ] || echo rprofile
EOF
)
if [[ $S_ABSENT_FILES != "" ]]; then
  echodebug "Copying configfiles"
  echo "$S_ABSENT_FILES" | while read file; do
    fname="${S_FILES_SHELLCONF[$file]}"
    echodebug "Copying $file to $fname"
    echodebug "${S_CONFIG_CONTENTS[$file]}"
    if [[ "$S_HOSTNAME" == "minervarun" ]]; then
      echoinfo "Locally copying $file on minerva"
      echo "${S_CONFIG_CONTENTS[$file]}" > $fname
    else
      echoinfo "Copying $file to $S_HOSTNAME"
      ssh -T $S_HOSTNAME "cat > $fname" <<< "${S_CONFIG_CONTENTS[$file]}"
    fi
  done
  echodebug "Done copying configfiles"
fi

echoinfo "Checking for VSCode Server image and app"

if [[ $S_IMAGE =~ ^(rocky|default)$ ]]; then
  echoinfo "Using default Rocky image"
  S_IMAGE="/sc/arion/work/$S_USERNAME/vscode_rocky_latest.sif"
  S_IMAGE_URL="library://befh/minerva_servers/vscode_rocky:latest"
  S_DISTRO=rocky
  echodebug "Using image $S_IMAGE"
elif [[ $S_IMAGE == "ubuntu" ]]; then
  echoinfo "Using Ubuntu image"
  S_IMAGE="/sc/arion/work/$S_USERNAME/vscode_ubuntu_latest.sif"
  S_IMAGE_URL="library://befh/minerva_servers/vscode_ubuntu:latest"
  S_DISTRO=ubuntu
  echodebug "Using image $S_IMAGE"
else
  echoinfo "Using custom image $S_IMAGE"
  S_DISTRO=custom
fi

VSC_URL="https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64"
eval_heredoc <<EOF
if [[ $S_UPDATE -eq 1 || ! -e $S_IMAGE ]]; then
  if [[ $S_DISTRO == "custom" ]]; then
    echo $(echoerror "Specified image \"$S_IMAGE\" does not exist")
    exit 1
  else
    echo $(echoinfo "Pulling the default image $S_IMAGE_URL")
    echo $(echoinfo "Pulling image to $S_IMAGE")
    ml singularity/3.6.4
    singularity pull -F --name $S_IMAGE --arch amd64 $S_IMAGE_URL
  fi
fi
if [[ $S_UPDATE -eq 1 || ! -e $SVSC_APP ]]; then
  echo $(echoinfo "Downloading the latest VSCode app version")
  wget -q -O vscode.tar.gz "$VSC_URL"
  tar xf vscode.tar.gz
  mv code $SVSC_APP
  rm vscode.tar.gz
fi
EOF

if [[ $? -ne 0 ]]; then
  exit 1
fi

###############################################################################
# Check for leftover files                                                    #
###############################################################################

# check for reconnect_info in the current directory on the local computer

macos_open () {
  if open -n -a 'Google Chrome' --args "--app=http://localhost:$1" 2> /dev/null ; then
    echoinfo "Opened in Chromeless Google Chrome"
  else
    echoinfo "Opening in default browser"
    open "http://localhost:$1"
  fi
}

instructs_mrun() {
  echoinfo "Choose an available port on your local computer and replace"
  echoinfo "LOCAL_PORT in the following command with the chosen port:"
  echoinfo "$S_FWDCMD"
  echoinfo "Run that command in a terminal to establish the SSH tunnel."
  echoinfo "Replace LOCAL_PORT in the following url with the chosen port:"
  echoinfo "http://localhost:LOCAL_PORT?tkn=$S_REMOTE_TOKEN"
  echoinfo "Open the url in your browser and use the password to log in."
  echoinfo "Or run the following command:"
  echoinfo "vscode_minerva --remote-start $S_REMOTE_IP:$S_REMOTE_PORT:$S_REMOTE_TOKEN"
}

echoinfo "Checking if reconnection is possible\n"

if [ -z ${S_MANUAL_MULTIPLEX+x} ] && ! [[ "$S_HOSTNAME" == "minervarun" ]]; then
  scp $S_HOSTNAME:$S_FILE_RECONNECT $S_SCRIPTDIR/ > /dev/null 2>&1
  echodebug "Downloaded reconnect_info file from $S_HOSTNAME:$S_FILE_RECONNECT"
fi

S_RCI=$S_SCRIPTDIR/$S_BASE_RECONNECT
if [ -f $S_RCI ]; then
  RC_BJOB=$(sed -nE 's/^BJOB[a-zA-Z ]+: (.+)/\1/p' $S_RCI)
  S_CHECKJOB="bjobs | grep -q $RC_BJOB && echo running || echo done"
  echodebug "S_CHECKJOB: $S_CHECKJOB"
  if [[ "$S_HOSTNAME" == "minervarun" ]]; then
    RC_JOBSTATE=$(eval "$S_CHECKJOB")
  else
    RC_JOBSTATE=$(ssh $S_HOSTNAME $S_CHECKJOB)
  fi
  echodebug "RC_JOBSTATE: $RC_JOBSTATE"
  if [[ $RC_JOBSTATE == "running" ]]; then
    echo
    cat $S_RCI
    echo

    if [[ "$S_HOSTNAME" == "minervarun" ]]; then
      S_FWDCMD=$(sed -nE 's/^SSH tunnel +: (.+)/\1/p' $S_RCI)
      S_REMOTE_TOKEN=$(sed -nE 's/^Remote token[a-zA-Z ]+: (.+)/\1/p' $S_RCI)
      S_REMOTE_IP=$(sed -nE 's/^Remote IP address +: (.+)/\1/p' $S_RCI)
      S_REMOTE_PORT=$(sed -nE 's/^Remote port +: (.+)/\1/p' $S_RCI)
      instructs_mrun
      exit 0
    fi

    RC_PRT_REMOTE=$(sed -nE 's/^Remote port +: (.+)/\1/p' $S_RCI)
    RC_IP_REMOTE=$(sed -nE 's/^Remote IP address +: (.+)/\1/p' $S_RCI)
    RC_URL=$(sed -nE 's/^URL[a-zA-Z ]+: (.+)/\1/p' $S_RCI)
    RC_PRT=$(sed -nE 's/^Local[a-zA-Z ]+: (.+)/\1/p' $S_RCI)
    RC_SSH="ssh $S_HOSTNAME -L $RC_PRT:$RC_IP_REMOTE:$RC_PRT_REMOTE -fNT"

    # reconnect if linux-gnu, darwin, or msys (regex check)
    if [[ "$OSTYPE" =~ ^(linux-gnu|darwin|msys) ]]; then
      echoinfo "Connecting to the server"
      lsof -Pni :$RC_PRT &> /dev/null || eval "$RC_SSH"
    else
      S_OPEN_BROWSER=0
      echowarn "Your OS does not allow starting browsers automatically."
      echoinfo "Please open $RC_URL in your browser."
      echoinfo "check if port $RC_PRT is forwarded first."
    fi

    if [[ $S_OPEN_BROWSER -eq 1 ]]; then
      echoinfo "Starting browser and connecting it to the server"
      echoinfo "Connecting to url $RC_URL"
      if [[ "$OSTYPE" == "linux-gnu" ]]; then
        if which wlslview 2>1 > /dev/null; then
          wslview $S_URL # USING Windows Subsystem for Linux
        elif ! [ -z ${WSLENV+x} ]; then
          echoalert "Your are using Windows Subsystem for Linux,"
          echoalert "but wslu is not available.\n"
          echoalert "Install wslu for automatic browser opening.\n"
          echoinfo "Please open $RC_URL in your browser."
        else
          xdg-open $RC_URL
        fi
      elif [[ "$OSTYPE" == "darwin"* ]]; then
        macos_open $RC_PRT
      elif [[ "$OSTYPE" == "msys" ]]; then
        start $RC_URL
      fi
    fi
    exit 0
  else
    echowarn "Job expired; checking for left over files from previous sessions"
    echoinfo "Found local session file, deleting it ..."
    rm $S_RCI
  fi
else
  echoinfo "Checking for left over files from previous sessions"
fi

# check for log files from a previous session in the home directory of the cluster
eval_heredoc <<EOF
if [[ -f $S_FILE_RECONNECT ]]; then
  echo $(echoinfo "Found old remote session file, deleting it ...")
  rm $S_FILE_RECONNECT
fi

if [[ -f $S_FILE_IP ]]; then
  echo $(echoinfo "Found old IP file, deleting it ...")
  rm $S_FILE_IP
fi

if [[ -f $S_FILE_JOB ]]; then
  echo $(echoinfo "Found old job file, deleting it ...")
  rm $S_FILE_JOB
fi
EOF


###############################################################################
# Check configuration options                                                 #
###############################################################################

echoinfo "Validating command line options\n"

# check number of CPU cores

# check if S_NUM_CPU an integer
if ! [[ "$S_NUM_CPU" =~ ^[0-9]+$ ]]; then
  echoerror "$S_NUM_CPU -> Incorrect format. Please specify number of CPU cores as an integer and try again\n"
  display_help
fi

# check if S_NUM_CPU is <= 64
if [ "$S_NUM_CPU" -gt "64" ]; then
  echoerror "$S_NUM_CPU -> Larger than 64. No distributed memory supported, therefore the number of CPU cores needs to be smaller or equal to 64\n"
  display_help
fi

if [ "$S_NUM_CPU" -gt "0" ]; then
  echoinfo "Requesting $S_NUM_CPU CPU cores for running the server"
fi

if [[ "$S_RUN_TIME" == "max" ]]; then
  echoinfo "Run time limit set to maximum"
  if [[ $S_QUEUE == "auto" ]]; then
    S_QUEUE="long"
    S_RUN_TIME="336:00"
    echodebug "Long queue selected"
  elif [[ $S_QUEUE == "long" ]]; then
    S_RUN_TIME="336:00"
  elif [[ $S_QUEUE == "premium" || $S_QUEUE == "gpu" ]]; then
    S_RUN_TIME="144:00"
  elif [[ $S_QUEUE == "express" ]]; then
    S_RUN_TIME="12:00"
  elif [[ $S_QUEUE == "gpuexpress" ]]; then
    S_RUN_TIME="15:00"
  fi
fi

# check if S_RUN_TIME is provided in HH:MM format
if [[ "$S_RUN_TIME" =~ ^([0-9]{1,3}):([0-9]{2})$ ]]; then
  if [[ $runshell == zsh ]]; then
    S_HOURS=${BASH_REMATCH[2]}
    S_MIN=$(echo ${BASH_REMATCH[3]} | sed 's/^0\(.\)$/\1/')
  else
    S_HOURS=${BASH_REMATCH[1]}
    S_MIN=$(echo ${BASH_REMATCH[2]} | sed 's/^0\(.\)$/\1/')
  fi
  S_MIN_TOT=$((S_MIN + 60 * S_HOURS))
  if [[ $S_MIN_TOT -gt 20160 ]]; then
    echoerror "$S_RUN_TIME -> Runtime limit is too long. Please try again\n"
    display_help
  fi
  if [[ $S_QUEUE == "auto" ]]; then
    if [[ $S_MIN_TOT -gt 8640 ]]; then
      S_QUEUE="long"
      echodebug "Long queue selected"
    elif [[ $S_MIN_TOT -gt 720 ]]; then
      S_QUEUE="premium"
      echodebug "Premium queue selected"
    else
      S_QUEUE="express"
      echodebug "Express queue selected"
    fi
  elif [[ $S_QUEUE == "gpu" && $S_MIN_TOT -gt 8640 ]]; then
    echoerror "$S_RUN_TIME -> Runtime limit is too long for the GPU queue. Please try again\n"
    display_help
  elif [[ $S_QUEUE == "gpuexpress" && $S_MIN_TOT -gt 900 ]]; then
    echoerror "$S_RUN_TIME -> Runtime limit is too long for the GPU express queue. Please try again\n"
    display_help
  elif [[ $S_QUEUE == "premium" && $S_MIN_TOT -gt 8640 ]]; then
    echoerror "$S_RUN_TIME -> Runtime limit is too long for the premium queue. Please try again\n"
    display_help
  elif [[ $S_QUEUE == "express" && $S_MIN_TOT -gt 720 ]]; then
    echoerror "$S_RUN_TIME -> Runtime limit is too long for the express queue. Please try again\n"
    display_help
  fi
  echoinfo "Run time limit set to $S_RUN_TIME"
else
  echoerror "$S_RUN_TIME -> Incorrect format. Please specify runtime limit in the format H:MM, HH:MM, or HHH:MM and try again\n"
  display_help
fi

# check if S_MEM_PER_CPU_CORE is an integer
if ! [[ "$S_MEM_PER_CPU_CORE" =~ ^[0-9]+$ ]]; then
  echoerror "$S_MEM_PER_CPU_CORE -> Memory limit must be an integer, please try again\n"
  display_help
else
  echoinfo "Memory per core set to $S_MEM_PER_CPU_CORE MB"
  S_MEM_TOTAL=$((S_MEM_PER_CPU_CORE * S_NUM_CPU))
  echoinfo "Total memory set to $S_MEM_TOTAL MB"
  if [[ $S_MEM_TOTAL -gt 190000 ]]; then
    if [[ $S_RESOURCE == "null" ]]; then
      S_RESOURCE="himem"
      echoinfo "Requesting himem resources"
    elif ! [[ $S_RESOURCE =~ himem ]]; then
      S_RESOURCE+=" -R himem"
      echoinfo "Requesting himem resources"
    fi
  fi
fi

# check if S_WAITING_INTERVAL is an integer
if ! [[ "$S_WAITING_INTERVAL" =~ ^[0-9]+$ ]]; then
  echoerror "$S_WAITING_INTERVAL -> Waiting time interval [seconds] must be an integer, please try again\n"
  display_help
else
  echoinfo "Setting waiting time interval for checking the start of the job to $S_WAITING_INTERVAL seconds"
fi

# check if project is usable

echoinfo "Checking LSF project"

if [[ $S_HOSTNAME == "minervarun" ]]; then
  S_BALANCE=$(mybalance)
else
  S_BALANCE=$(ssh $S_HOSTNAME mybalance)
fi

if [[ $S_ACCT == "acc_null" ]]; then
  S_ACCT_ONE=$(echo "$S_BALANCE" | awk '$2 ~ /acc_/ { print $2; exit}')
  S_ACCT_CATS=$(echo "$S_BALANCE" | awk '$3 == "Yes" { print $2; exit}')
  if [[ $S_ACCT_ONE == "" ]]; then
    echoerror "You don't have any project assigned, please contact HPC administrator"
    exit 2
  elif echo "$S_BALANCE" | grep -q acc_LOAD; then
    S_ACCT=acc_LOAD
  elif [[ $S_ACCT_CATS != "" ]]; then
    S_ACCT=$S_ACCT_CATS
  else
    S_ACCT=$S_ACCT_ONE
  fi
  echoinfo "Project not specified. Using $S_ACCT."
elif ! echo "$S_BALANCE" | grep -q "$S_ACCT"; then
  echoerror "You must specify a valid LSF project or use the default, please try again"
  display_help
fi

###############################################################################
# Start VSCode on the cluster                                                 #
###############################################################################

echoinfo "Computing conda environment"

if [[ $S_HOSTNAME == "minervarun" ]]; then
  S_CONDAINFO=$(conda info 2> /dev/null)
else
  S_CONDAINFO=$(ssh $S_HOSTNAME "conda info" 2> /dev/null)
fi

S_CONDADIRS=$(echo "$S_CONDAINFO" | awk '
  $0 ~ "envs directories" {a = 1; print $4; next} \
  $0 ~ ":" {a = 0} a == 1 {print $1}')

if [[ $S_CONDAENV == "null" ]]; then
  echoinfo "Conda environment not specified; detecting default."
  if [[ $S_HOSTNAME == "minervarun" ]]; then
    S_CONDAEP="$CONDA_DEFAULT_ENV $CONDA_PREFIX"
  else
    echodebug "Getting conda default environment and prefix"
    S_CONDAEP=$(ssh $S_HOSTNAME -t 'bash -lc "echo \$CONDA_DEFAULT_ENV \$CONDA_PREFIX"' 2> /dev/null)
  fi
  S_CONDANF=$(echo $S_CONDAEP | awk '1 {print NF}')
  if [[ $S_CONDANF -ne 2 ]]; then
    echoerror "Conda not functioning on Minerva"
    exit 1
  fi
  S_CONDAENV=$(echo $S_CONDAEP | awk '1 {print $1}' | tr -d '\r')
  S_PREFIX=$(echo $S_CONDAEP | awk '1 {print $2}' | tr -d '\r')
elif [[ $S_CONDAENV =~ "/" ]]; then
  S_PREFIX=$S_CONDAENV
elif [[ $S_HOSTNAME == "minervarun" ]]; then
  echodebug "Getting conda environment list"
  S_PREFIX=$(conda info --envs |
             awk -v env=$S_CONDAENV '$1 == env {print $2}')
else
  echodebug "Getting conda environment list"
  S_PREFIX=$(ssh $S_HOSTNAME "conda info --envs" |
             awk -v env=$S_CONDAENV '$1 == env {print $2}')
fi

echoinfo "Using environment $S_CONDAENV at $S_PREFIX"

VSC_LOG_LEVEL="info"
if [[ $S_DEBUG -eq 1 ]]; then
  echodebug "VSCode Log level set to debug"
  VSC_LOG_LEVEL="debug"
fi

echoinfo "Building LSF jobscript"

#ssh $S_HOSTNAME "cat > $S_FILE_JOB" <<<cat <<EOF
S_CONTENTS_JOB=$(cat <<EOF
#!/usr/bin/env bash
#BSUB -J vscode$S_SESSION
#BSUB -P $S_ACCT
#BSUB -q $S_QUEUE
#BSUB -n $S_NUM_CPU
#BSUB -R span[hosts=1]
#BSUB -W $S_RUN_TIME
#BSUB -R rusage[mem=$S_MEM_PER_CPU_CORE]
#BSUB -oo $S_WORKDIR/vscode$S_SESSION_%J.out
#BSUB -eo $S_WORKDIR/vscode$S_SESSION_%J.err
#BSUB -L /bin/bash
EOF
)

echodebug "Adding resource requirements to job script"

# split S_RESOURCE, using " -R " as delimiter, and loop over the elements
if [[ $S_RESOURCE != "null" ]]; then
  for r in $(echo $S_RESOURCE | tr " -R " "\n"); do
    S_CONTENTS_JOB+="$(printf "\n#BSUB -R %s\n" $r)"
  done
fi

echodebug "Done adding resource requirements to job script"

S_CONTENTS_JOB+=$(cat <<EOF


export http_proxy=http://172.28.7.1:3128
export https_proxy=http://172.28.7.1:3128
export all_proxy=http://172.28.7.1:3128
export ftp_proxy=http://172.28.7.1:3128
export rsync_proxy=http://172.28.7.1:3128
export no_proxy=localhost,*.chimera.hpc.mssm.edu,172.28.0.0/16

SINGULARITY_SHELL=/bin/bash

#export XDG_RUNTIME_DIR="\$HOME/vsc_runtime"
S_IP_REMOTE="\$(hostname -i)"
echo "Remote IP:\$S_IP_REMOTE" >> $S_FILE_IP

module load singularity/3.6.4

for lf in \$lockfiles; do
  if [[ -d \$lf ]]; then
    owner=\$(stat -c "%U" \$lf)
    if [[ \$USER != \$owner ]]; then
      echo "Status:BUSY" > $S_FILE_IP
      echo "HOSTNAME:\$HOSTNAME" >> $S_FILE_IP
      echo "OWNER:\$owner" >> $S_FILE_IP
      exit 1
    else
      rm -rf \$lf
      echo "Lock cleaned"
      echo
    fi
  fi
done

local_used_ports=\$(netstat -4 -ltn | grep LISTEN | awk '{ print \$4 }' | awk -F":" '{ print \$2 }' )

for p in {8850..9000}; do
  if [[ \$local_used_ports != *\$p* ]]; then
    echo "Using local available port \$p"
    S_PORT_REMOTE=\$p
    break
  fi
done

echo "Remote Port:\$S_PORT_REMOTE" >> $S_FILE_IP

## Start VSCode ##

# Set-up temporary paths
if [[ -d $S_TMP ]]; then
  rm -rf $S_TMP/*
fi
mkdir -p $S_TMP/{home,tmp}

cat > $S_TMP/home/.launch_radian.sh <<EOFF
#!/usr/bin/env bash
if which radian > /dev/null; then
  LC_ALL=C.UTF-8 radian \\\$@
else
  LC_ALL=C.UTF-8 R \\\$@
fi

exit 0
EOFF
chmod +x $S_TMP/home/.launch_radian.sh

cat > $S_TMP/home/.launch_r.sh <<EOFF
#!/usr/bin/env bash
LC_ALL=C.UTF-8 R \\\$@
EOFF
chmod +x $S_TMP/home/.launch_r.sh

log_vscode="$S_WORKDIR/vscode$S_SESSION_\$LSB_JOBID.vscode.log"

echo "Starting VSCode server on port \$S_PORT_REMOTE ..."
singularity run \\
  --bind /sys/fs/cgroup/:/sys/fs/cgroup/:ro \\
  --bind $SVSC_APP:/usr/local/bin/code \\
  --bind ${S_PREFIX}:${S_PREFIX} \\
  --bind $S_TMP/tmp:/tmp \\
  --bind /opt/hpc:/opt/hpc:ro \\
  --app code \\
  --env S_CONDAENV=$S_CONDAENV \\
  --env USER=$S_USERNAME \\
EOF
)

echodebug "Adding conda and module binds to job script"

S_CONTENTS_JOB_CONDA=$(eval_heredoc <<EOF
  echo
  for i in $(echo "$S_CONDADIRS" | tr '\n' ' '); do
    if test -e "\$i"; then
      echo "  --bind \$i "
    fi
  done
  if test -e "\$HOME/.condarc"; then
    echo "  --bind \$HOME/.condarc:/etc/conda/condarc "
  fi
EOF
)

S_CONTENTS_JOB+=$(echo "$S_CONTENTS_JOB_CONDA" | sed '/./ s|$|\\|')

if [[ $S_ISOLATED -gt 0 ]]; then
  S_CONTENTS_JOB+="$(cat <<EOF

  --cleanenv \\
  --no-home \\
  --home $S_TMP/home:/myhome \\
  --bind $S_TMP/home:/myhome \\
  --bind $SVSC_DIR_CONFIG_DOTVSC:/myhome/.vscode-server \\
  --bind $S_FILE_BASHPROF:/myhome/.bash_profile \\
  --bind $S_FILE_BASHRC:/myhome/.bashrc \\
  --bind $S_FILE_FISHCONFIG:/myhome/.config/fish/config.fish \\
  --bind $S_FILE_ZSHRC:/myhome/.zshrc \\
  --bind $S_FILE_RPROFILE:/myhome/.Rprofile \\
  --bind \$HOME/.ssh:/myhome/.ssh \\
  --bind $S_WORKDIR/.setup_vscode.sh:/myhome/.setup_vscode.sh \\
  --bind $S_WORKDIR/.recommended_packages.txt:/myhome/.recommended_packages.txt \\
  --bind $S_WORKDIR/.config_template.json:/myhome/.config_template.json \\
  --bind \$HOME/.gitconfig:/myhome/.gitconfig \\
EOF
)"
else
  S_CONTENTS_JOB+="$(cat <<EOF

  --bind $S_FILE_BASHPROF:/hpc/users/$S_USERNAME/.bash_profile \\
  --bind $S_FILE_BASHRC:/hpc/users/$S_USERNAME/.bashrc \\
  --bind $S_FILE_FISHCONFIG:/hpc/users/$S_USERNAME/.config/fish/config.fish \\
  --bind $S_FILE_ZSHRC:/hpc/users/$S_USERNAME/.zshrc \\
  --bind $S_FILE_RPROFILE:/hpc/users/$S_USERNAME/.Rprofile \\
  --bind $SVSC_DIR_CONFIG_DOTVSC:/hpc/users/$S_USERNAME/.vscode-server \\
  --bind $S_WORKDIR/.setup_vscode.sh:/hpc/users/$S_USERNAME/.setup_vscode.sh \\
  --bind $S_WORKDIR/.recommended_packages.txt:/hpc/users/$S_USERNAME/.recommended_packages.txt \\
  --bind $S_WORKDIR/.config_template.json:/hpc/users/$S_USERNAME/.config_template.json \\
  --bind $S_TMP/home/.launch_r.sh:/hpc/users/$S_USERNAME/.launch_r.sh \\
  --bind $S_TMP/home/.launch_radian.sh:/hpc/users/$S_USERNAME/.launch_radian.sh \\
  --bind /hpc/lsf:/hpc/lsf \\
  --bind /hpc/packages:/hpc/packages \\
EOF
)"
fi

S_CONTENTS_JOB+="$(cat <<EOF

  $S_IMAGE serve-web --host \${S_IP_REMOTE} --port \$S_PORT_REMOTE \\
  --user-data-dir ~/.config/Code/User --accept-server-license-terms \\
  --log $VSC_LOG_LEVEL > \$log_vscode &

echo VSCode started...

## Done ##

sing_pid=\$!
sing_stat=\$?

if [[ "$S_DEBUG" -eq 1 ]]; then
  /usr/bin/env > $S_WORKDIR/jobenv$S_SESSION.txt
fi
echo Writing log to \$log_vscode

for i in {3..1}; do
  echo "Checking \$i, next check in 5 seconds."
  if ps -p \$sing_pid; then
    sleep 5
  else
    echo "Status:DEAD" >> $S_FILE_IP
    echo
    exit 1
  fi
done

if [[ \$sing_stat -ne "0" ]]; then
  echo "Status:FAIL" >> $S_FILE_IP
  echo "Code:\$sing_stat" >> $S_FILE_IP
  exit 1
else
  echo "Status:GOOD" >> $S_FILE_IP
  if [[ $S_ISOLATED -gt 0 ]]; then
    token=\$(cat $S_TMP/home/.vscode/cli/serve-web-token)
  else
    token=\$(cat /hpc/users/\$USER/.vscode/cli/serve-web-token)
  fi
  echo "Token:\$token" >> $S_FILE_IP
  echo Server Token: \$token
fi

cleanup () {
  echo "Job is ending, cleaning up session."
  for lf in \$lockfiles; do
    if [[ -d \$lf ]] && [[ \$USER = \$(stat -c %U \$lf) ]]; then
        echo "Removing lockfile \$lf"
        rm -rf \$lf
    fi
  done
  kill -0 \$sing_pid
}

trap cleanup SIGTERM SIGQUIT SIGINT
wait
cleanup

EOF
)"

echodebug "Job script contents:"
if [[ $S_DEBUG -eq 1 ]]; then
  echo "$S_CONTENTS_JOB"
fi

if [[ $S_HOSTNAME == "minervarun" ]]; then
  # Store the docstring in $S_FILE_LOGCONF locally
  echodebug "Locally copying job file on minerva"
  echo "$S_CONTENTS_JOB" > "$S_FILE_JOB"
else
  # Copy the docstring to $S_FILE_LOGCONF remotely
  echodebug "Copying job file to $S_HOSTNAME"
  ssh -T $S_HOSTNAME "cat > '$S_FILE_JOB'" <<< "$S_CONTENTS_JOB"
fi
echodebug "Done copying job file"

TRY=1
SUCCESS=0

while ( [ $TRY -lt 4 ] && [ $SUCCESS -eq 0 ] ); do
  # run the job on Minerva and save the ip of the compute node in the home directory of the user
  echo
  echoinfo "Connecting to $S_HOSTNAME to start the server in a batch job"
  echodebug "Try $TRY to start the server"
  if [[ $S_HOSTNAME == "minervarun" ]]; then
    S_BJOB_OUT=$(bsub < $S_FILE_JOB)
  else
    S_BJOB_OUT=$(ssh $S_HOSTNAME "bsub < $S_FILE_JOB")
  fi
  S_BJOB_ID=$(echo $S_BJOB_OUT | awk '/is submitted/{print substr($2, 2, length($2)-2);}')
  
  # wait until batch job has started, poll every $S_WAITING_INTERVAL seconds to check if IP file exists
  # once the file exists and is not empty the batch job has started
  echoinfo "Waiting for job to start\n"
  if [[ $S_HOSTNAME == "minervarun" ]]; then
    while ! [ -e $S_FILE_IP -a -s $S_FILE_IP ]; do
      echo "Waiting for job to start, sleep for $S_WAITING_INTERVAL sec"
      sleep $S_WAITING_INTERVAL
    done
  else
    ssh -T $S_HOSTNAME bash <<ENDSSH
      while ! [ -e $S_FILE_IP -a -s $S_FILE_IP ]; do
        echo 'Waiting for job to start, sleep for $S_WAITING_INTERVAL sec'
        sleep $S_WAITING_INTERVAL
      done
ENDSSH
  fi
  echo
  
  echoinfo "Waiting for server to start\n"
  if [[ $S_HOSTNAME == "minervarun" ]]; then
    wait_time=0
    while [[ $wait_time -lt 25 ]] && ! grep -q "Status" $S_FILE_IP; do
      let wait_time+=5
      echo 'Waiting for server to start, sleep for 5 sec'
      sleep 5
    done
  else
    ssh -T $S_HOSTNAME bash <<ENDSSH
      wait_time=0
      while [[ \$wait_time -lt 25 ]] && ! grep -q "Status" $S_FILE_IP; do
        let wait_time+=5
        echo 'Waiting for server to start, sleep for 5 sec'
        sleep 5
      done
ENDSSH
  fi

  # get remote ip, port and token from files stored on Minerva
  if [[ $S_HOSTNAME == "minervarun" ]]; then
    S_CONTENTS_IP=$(cat $S_FILE_IP)
  else
    S_CONTENTS_IP=$(ssh $S_HOSTNAME "cat $S_FILE_IP")
  fi

  echodebug "Contents of the IP file:"
  if [[ $S_DEBUG -eq 1 ]]; then
    echo "$S_CONTENTS_IP"
  fi

  if ! echo "$S_CONTENTS_IP" | grep -q Status; then
    echoerror "Server did not report status"
    exit 1
  fi

  S_REMOTE_STATUS=$(echo "$S_CONTENTS_IP" | grep -m1 'Status' | cut -d ':' -f 2)
  if [[ $S_REMOTE_STATUS == "GOOD" ]]; then
    echoinfo "Receiving ip and port from the server"
    S_REMOTE_IP=$(echo "$S_CONTENTS_IP" | grep -m1 'Remote IP' | cut -d ':' -f 2)
    S_REMOTE_PORT=$(echo "$S_CONTENTS_IP" | grep -m1 'Remote Port' | cut -d ':' -f 2)
    S_REMOTE_TOKEN=$(echo "$S_CONTENTS_IP" | grep -m1 'Token' | cut -d ':' -f 2)
    SUCCESS=1
  elif [[ $S_REMOTE_STATUS == "BUSY" ]]; then
    hostname=$(echo "$S_CONTENTS_IP" | grep -m1 'HOSTNAME' | cut -d ':' -f 2)
    owner=$(echo "$S_CONTENTS_IP" | grep -m1 'OWNER' | cut -d ':' -f 2)
    if [ $TRY -eq 3 ]; then
      echoerror "$owner is running a session on $hostname, therefore execution is blocked..."
      echoerror "Please resubmit your job to get your job dispatched to another node. "
      echoerror "Change your arguments like -n -M -W slightly."
      exit 1
    else
      echoalert "Attempt $TRY failed due to $owner running a session on $hostname:"
      echoalert "Trying again"
      if [[ $S_HOSTNAME == "minervarun" ]]; then
        rm $S_FILE_IP
      else
        ssh $S_HOSTNAME "rm $S_FILE_IP"
      fi
    fi
  elif [[ $S_REMOTE_STATUS == "DEAD" ]]; then
    echoerror "Server died while starting"
    exit 1
  elif [[ $S_REMOTE_STATUS == "FAIL" ]]; then
    S_REMOTE_EXIT=$(echo "S_CONTENTS_IP" | grep -m1 'Code' | cut -d ':' -f 2)
    echoerror "Server died with the exit code $S_REMOTE_EXIT"
    exit $S_REMOTE_EXIT
  fi
  let TRY+=1
done

# check if the IP, the port and the token are defined
if  [[ "$S_REMOTE_IP" == "" ]]; then
echoerror "remote ip is not defined. Terminating script."
echoerror "* Please check login to the cluster and check with bjobs if the batch job on the cluster is running and terminate it with bkill."
exit 1
fi

if [[ $S_HOSTNAME == "minervarun" ]]; then
  S_LOCAL_PORT=LOCAL_PORT
elif ! [ -z ${S_SESSION+x} ]; then
  S_LOCAL_PORT=$(find_port 8890)
else
  S_LOCAL_PORT=$(find_port 8899)
fi

S_FWDCMD="ssh $S_HOSTNAME -L $S_LOCAL_PORT:$S_REMOTE_IP:$S_REMOTE_PORT -fNT"

if ! [[ $S_HOSTNAME == "minervarun" ]]; then
  # setup SSH tunnel from local computer to compute node via login node
  echoinfo "Setting up SSH tunnel for connecting the browser to the server"
  eval "$S_FWDCMD"
  
  # SSH tunnel is started in the background, pause 3 seconds to make sure
  # it is established before starting the browser
  sleep 3
else
  S_FWDCMD=$(echo $S_FWDCMD | sed "s/minervarun/minerva/")
fi

# print information about IP, ports and token
echoinfo "Server info:"
echo
echo -e "LSF Job ID         : $S_BJOB_ID"
echo -e "Remote IP address  : $S_REMOTE_IP"
echo -e "Remote port        : $S_REMOTE_PORT"
echo -e "Local port         : $S_LOCAL_PORT"
echo -e "SSH tunnel command : $S_FWDCMD"
echo -e "URL                : http://localhost:$S_LOCAL_PORT?tkn=$S_REMOTE_TOKEN"
echo -e "Remote token       : $S_REMOTE_TOKEN"
echo

# write reconnect_info file
cat <<EOF > $S_RCI
Restart file
Remote IP address : $S_REMOTE_IP
Remote port       : $S_REMOTE_PORT
Local port        : $S_LOCAL_PORT
SSH tunnel        : $S_FWDCMD
URL               : http://localhost:$S_LOCAL_PORT?tkn=$S_REMOTE_TOKEN
BJOB ID           : $S_BJOB_ID
Remote token      : $S_REMOTE_TOKEN
EOF

# Copy connection information to the remote machine
if [[ $S_HOSTNAME == "minervarun" ]]; then
  cp $S_RCI $S_FILE_RECONNECT
elif [ -z ${S_MANUAL_MULTIPLEX+x} ]; then
  scp $S_RCI $S_HOSTNAME:$S_FILE_RECONNECT > /dev/null 2>&1
fi

eval_heredoc <<EOF
if [[ ! -e "$SVSC_DIR_CONFIG_DOTVSC/data/CachedProfilesData" ]]; then
  printf "\033[32m"
  cat <<EOFF
[INFO] It looks like this is the first time you are running VSCode
       Open a terminal in VSCode (CTRL+SHIFT+\\\`) and run the following command:
         ~/.setup_vscode.sh
EOFF
printf "\033[0m"
fi
EOF

eval <<EOF
if [[ ! -e "$SVSC_DIR_CONFIG_DOTVSC/data/CachedProfilesData" ]]; then
  echo foo
fi
EOF

if [[ $S_HOSTNAME == "minervarun" ]]; then
  instructs_mrun
elif [[ $S_OPEN_BROWSER -eq 0 ]]; then
  echoinfo "Please open the following URL in your browser:"
  echoinfo "http://localhost:$S_LOCAL_PORT?tkn=$S_REMOTE_TOKEN"
else
  # save url in variable
  S_URL=http://localhost:$S_LOCAL_PORT
  echoinfo "Starting browser and connecting it to the server"
  echoinfo "Connecting to url $S_URL"
  
  # start local browser if possible
  if [[ "$OSTYPE" == "linux-gnu" ]]; then
    if which wlslview 2>1 > /dev/null; then
      wslview $S_URL # USING Windows Subsystem for Linux
    elif ! [ -z ${WSLENV+x} ]; then
      echowarn "Your are using Windows Subsystem for Linux, but wslu is not "
      echowarn "available.\n"
      echowarn "Install wslu for automatic browser opening.\n"
      echoinfo "Please open $S_URL in your browser."
    else
      xdg-open $S_URL
    fi
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    macos_open $S_LOCAL_PORT
  elif [[ "$OSTYPE" == "msys" ]]; then # Git Bash on Windows 10
    start $S_URL
  else
    echowarn "Your OS does not allow starting browsers automatically."
    echoinfo "Please open $S_URL in your browser."
  fi
fi
