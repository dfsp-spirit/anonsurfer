#!/bin/bash
# pipelines.bash -- run stuff in parallel over a number of subjects.
#
# This script is part of 'anonsurfer'.
#
# Written by Tim Schaefer, 2020-24-01
#


APPTAG="[PIPELINES]"

##### General settings #####

# Number of consecutive GNU Parallel jobs. Note that 0 for 'as many as possible'. Maybe set something a little bit less than the number of cores of your machine if you want to do something else while it runs.
# See 'man parallel' for details.

if [ -z "$4" ]; then
    echo "$APPTAG ERROR: Must specify subjects_file. Exiting. (This is a text file with 1 subject per line.)"
    echo "$APPTAG Usage: $0 <subjects_file> <subjects_dir> <task> [<num_proc>]"
    echo "$APPTAG    <subjects_file> : path to a textfile containing one subject per line"
    echo "$APPTAG    <subjects_dir>  : path to the FreeSurfer recon-all output (known as FreeSurfer SUBJECTS_DIR)."
    echo "$APPTAG    <task>          : the action to perform, one of 'deface' or 'drop_metadata'."
    echo "$APPTAG    <num_proc>      : number of processes (subjects) to run in parallel. Set to 0 for max for your machine."
    exit 1
fi

## Check some stuff
SUBJECTS_FILE="$1"
## Check for given subjects file.
if [ ! -f "$SUBJECTS_FILE" ]; then
    echo "$APPTAG ERROR: Subjects file '$SUBJECTS_FILE' not found."
    exit 1
fi

# SUBJECTS_DIR must be set
SUBJECTS_DIR="$2"
if [ -z "${SUBJECTS_DIR}" ]; then
    echo "$APPTAG ERROR: Must specify parameter 'subjects_dir'. Exiting."
    exit 1
fi
if [ ! -d "$SUBJECTS_DIR" ]; then
    echo "$APPTAG ERROR: Subjects dir '$SUBJECTS_DIR' does not exist or is no readable directory."
    exit 1
fi

TASK="$3"
if [ -z "${TASK}" ]; then
    echo "$APPTAG ERROR: Must specify parameter 'task'. Exiting."
    exit 1
fi


NUM_CONSECUTIVE_JOBS="$4"



# By default, SUBJECTS_DIR gets set to the FreeSurfer subjects folder, but that makes no sense unless you want to work on example data.
if [ -d "${SUBJECTS_DIR}/bert" ]; then      # 'bert' is a FreeSurfer example subject.
    echo "$APPTAG WARNING: Environment variable SUBJECTS_DIR seems to point at the subjects dir of the FreeSurfer installation: '${SUBJECTS_DIR}'. Configure it to point at your data!"
    echo "$APPTAG NOTE: You can ignore the last warning if you have a subject named 'bert' in your study."
fi

# When ppl install FreeSurfer on a new machine, it is a common error to forgot about the license file you have to manually copy into the installation dir.
# When the file is missing, FreeSurfer will refuse to work and all jobs in the parallel run will die.
# You can get a license.txt file for free by registering on the FreeSurfer website.
if [ ! -f "${FREESURFER_HOME}/license.txt" ]; then
    echo "$APPTAG ERROR: The FreeSurfer license file was not found at '${FREESURFER_HOME}/license.txt'. Run would fail, exiting now. (Get a free license on the Freesurfer website and copy it to that dir to fix this error.)"
    exit 1
fi



# Check for borken line endings (Windows line endings, '\r\n') in subjects.txt file, a very common error.
# This script can cope with these line endings, but we still warn the user because other scripts may choke on them.
NUM_BROKEN_LINE_ENDINGS=$(grep -U $'\015' "${SUBJECTS_FILE}" | wc -l | tr -d '[:space:]')
if [ $NUM_BROKEN_LINE_ENDINGS -gt 0 ]; then
    echo "$APPTAG WARNING: Your subjects file '${SUBJECTS_FILE}' contains $NUM_BROKEN_LINE_ENDINGS incorrect line endings (Windows style line endings)."
    echo "$APPTAG WARNING: (cont.) While this script can work with them, you will run into trouble sooner or later, and you should definitely fix them (use  the 'tr' command or a proper text editor)."
fi

SUBJECTS=$(cat "${SUBJECTS_FILE}" | tr -d '\r' | tr '\n' ' ')    # fix potential windows line endings (delete '\r') and replace newlines by spaces as we want a list
SUBJECT_COUNT=$(echo "${SUBJECTS}" | wc -w | tr -d '[:space:]')


echo "$APPTAG Parallelizing task '${TASK}' over the ${SUBJECT_COUNT} subjects in file '${SUBJECTS_FILE}' using ${NUM_CONSECUTIVE_JOBS} threads."

# We can check already whether the subjects exist.
for SUBJECT in $SUBJECTS; do
  if [ ! -d "${SUBJECTS_DIR}/${SUBJECT}" ]; then
    echo "$APPTAG ERROR: Directory for subject '${SUBJECT}' not found in SUBJECTS_DIR '${SUBJECTS_DIR}'. Exiting."
    exit 1
  fi
done

################### JOB SETTINGS -- adjust this ##################

# Debug: This only prints one subject ID per line.
#echo ${SUBJECTS} | tr ' ' '\n' | parallel "echo {}"


EXEC_PATH_OF_THIS_SCRIPT=$(dirname $0)

if [ "$TASK" = "deface" ]; then
    CARGO_SCRIPT="${EXEC_PATH_OF_THIS_SCRIPT}/deface_subject.bash"
elif [ "$TASK" = "drop_metadata" ]; then
    CARGO_SCRIPT="${EXEC_PATH_OF_THIS_SCRIPT}/dropmd_subject.bash"
else
    echo "$APPTAG ERROR: The parameter 'task' must be exactly one of 'deface' or 'drop_metadata'. Exiting."
    exit 1
fi


if [ ! -x "${CARGO_SCRIPT}" ]; then
    echo "$APPTAG ERROR: Cargo script for task '${TASK}' at ${CARGO_SCRIPT} not found or not executable. Check path and/or run 'chmod +x <file>' on it to make it executable. Exiting."
    exit
fi

############ execution, no need to mess with this. ############
DATE_TAG=$(date '+%Y-%m-%d_%H-%M-%S')
LOGFILE="logfile_${TASK}_${DATE_TAG}.txt"
echo ${SUBJECTS} | tr ' ' '\n' | parallel --jobs ${NUM_CONSECUTIVE_JOBS} --workdir . --joblog "${LOGFILE}" "$CARGO_SCRIPT {} ${SUBJECTS_DIR}"
