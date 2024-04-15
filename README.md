# Run browser applications on Minerva Jobs

There are currently 2 scripts in this repository:

*  ***`vscode_minerva`***: Runs *Microsoft Visual Studio Code* on Minerva
*  ***`rstudio_minerva`*** Runs Posit *RStudio* on Minerva

Both scripts have the following features:

* Run in *Singulatity/Apptainer* environments on Minerva to allow modern applications and isolation
* Start either on Minerva or locally
  * Locally on your computer is simpler (only need to run one command)
  * Remote is faster and allows running in collaborative accounts
    but you must still have the script installed on your computer and run a
    command to forward ports.
* Use Anaconda/Mamba to manage packages
* Run on the Minerva cluster in jobs

## Installation

These scripts will be integrated into the lab setup script.
For now, do the following:

```bash
cd ~/local/src
git clone git@github.com:BEFH/minerva_servers.git
cd minerva_servers
git checkout autoconnect_remote
cd ~/local/scripts
rm vscode_minerva rstudio_minerva
ln -s ../src/minerva_servers/vscode_minerva
ln -s ../src/minerva_servers/rstudio_minerva
cd
```

Make sure `~/local/scripts` is in your `PATH` variable.

You should have SSH ControlMaster enabled in your `~/.ssh/config` file for this
to work fully on the cluster. The script will manually multiplex otherwise, but
this is not recommended.

See https://en.wikibooks.org/wiki/OpenSSH/Cookbook/Multiplexing

### First run of `vscode_minerva`

In order to ease the process of installing extensions and changing VSCode
settings, I have provided a script that installs extensions and provides good
starting settings. When in VSCode, press `⌥ + SHIFT + ~` to open a terminal,
then run `~/.setup_vscode.sh`. The script will provide further instructions.

### Updates

To update the scripts, go to `~/local/src/minerva_servers` and run `git pull`.
Then add `--update` to your command the next time you run each script.

**NOTE:** Any changes you make to the shell configurations for the
`vscode_minerva` script will be overwritten when using `--update`, so make a
backup if you have changed them.

## Running the scripts

To see usage instructions on the command-line run `SCRIPT_NAME -h` or
`SCRIPT_NAME --help`.

### Cluster job resources

Both scripts have identical settings for cluster job submission.
The defaults are as follows:

* 4 cores
* 4000 MB of memory per core (16000 MB total)
* 12 hours of walltime
* LSF accounts are chosen with the following priority:
  1. `acc_LOAD` if available
  2. An account with access to `CATS`
  3. Any other available account

All of these settings can be overridden:

* Use `-n [NUMBER OF CORES]` to set the number of cores to request.
  The maximum number of cores is 64.
* Use `-W H[H[H]]:MM` to set walltime. E.g. `-W 4:00` for 4 hours and
  `-W 336:00` for 336 hours. The maximum walltime is 336 hours.
* Use `-m [MEMORY IN MB]` to set memory per core. The maximum memory request
  is 2 TB, but there are only 2 servers supporting that request. There are 92
  servers supporting up to 1.5 TB, but we recommend keeping your request under
  190,000 MB of *total* memory. Remember that this request is per-core.
* Use `-P [LSF account]` to select a different LSF account.

The scripts will automatically select the optimal queues and resource requests
for most jobs based on memory and time requested. If you need GPU or other
custom requirements, you can add additional resource requests
(see command help). The script will always request `-R himem` when necessary and
ensure all cores are on the same node.

***If you exceed the requested resources, your application will be closed by the
cluster!***

### Other features

* **Anaconda envs:** The servers will run using your default Anaconda
  environment unless otherwise specified using `-C [CONDA ENV]`
  or `--conda [CONDA ENV]`.
* **Session names:**  You can run multiple instances of the servers by adding
  `-S [SESSION NAME]` to the command.
* **Isolation:** The scripts run with an optimal amount of environmental
  isolation by default. You can change that using `--isolation`.
* **Config files:** If a configuration file is specified in `~/.vsc_config` for
  VSCode or `~/.rs_config` for RStudio, specified env variables will override
  the defaults or variables set on the command line. Use this with caution.
  You can also specify configuration files by using `-c` on the command line.

## Usage instructions

### `vscode_minerva --help`

```raw
vscode_minerva: Script to start a VSCode server on Minerva from a local computer

Usage: vscode_minerva [options]

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

  vscode_minerva -n 4 -W 04:00 -m 2048

  vscode_minerva --numcores 2 --runtime 01:30 --memory 2048

  vscode_minerva -c /Users/bfh/.vsc_config

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
```

### `rstudio_minerva --help`

```raw
rstudio_minerva: Script to start a RStudio server on Minerva from a local computer

Usage: rstudio_minerva [options]

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
  -c | --config     ~/.rs_config     Configuration file for specifying options
  -h | --help                        Display help for this script and quit
  -i | --interval   30               Time interval (sec) for checking if the job
                                      on the cluster already started
  -v | --version                     Display version of the script and exit
  -s | --server     minerva          SSH arguments for connecting to the server:
                                      Will default to "minerva", then "chimera".
                                      server name from .ssh/config, or e.g.
                                      user@minerva.hpc.mssm.edu
  -S | --session                     Session name to run multiple servers
  -C | --conda      shell default    Conda env for running rstudio
       --isolated   partial          Run RStudio server without home directory
                                      or environment variables (deprecated)
       --isolation  partial          Amount of container isolation: if 'full',
                                      run RStudio server without home directory
                                      or environment variables. If 'partial',
                                      same as full but open shell outside of
                                      sandbox. If 'none', do not isolate.
  -I | --image      dload to work    Singularity image to use for the server.
                                      Downloaded automatically if not specified.
  --debug                            Print debug messages
  --update                           Update the rstudio server singularity image
  --remote-start                     Connect to job started from cluster

Examples:

  rstudio_minerva -n 4 -W 04:00 -m 2048

  rstudio_minerva --numcores 2 --runtime 01:30 --memory 2048

  rstudio_minerva -c /Users/bfh/.rs_config

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
```