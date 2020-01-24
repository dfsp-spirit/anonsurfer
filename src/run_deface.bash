#!/bin/bash
# run_deface.bash -- run stuff in parallel over a number of subjects.
#
# This script is part of 'anonsurfer'.
#
# Written by Tim Schaefer, 2020-24-01
#

APPTAG="[RUN_DEFACE]"

if [ -z "$3" ]; then
    echo "$APPTAG Usage: $0 <subjects_file> <subjects_dir> <num_proc>"
    echo "$APPTAG    <subjects_file> : path to a textfile containing one subject per line"
    echo "$APPTAG    <subjects_dir>  : path to the FreeSurfer recon-all output directory (known as FreeSurfer SUBJECTS_DIR)."
    echo "$APPTAG    <num_proc>      : number of processes (subjects) to run in parallel. Set to 0 for max for your machine."
    exit 1
else
    EXEC_PATH_OF_THIS_SCRIPT=$(dirname $0)
    PIPELINE_SCRIPT="${EXEC_PATH_OF_THIS_SCRIPT}/pipelines.bash"
    echo "$APPTAG Running deface pipeline with subjects_file '$1', subjects_dir '$2'. Will use $3 parallel processes."
    ${PIPELINE_SCRIPT} "$1" "$2" deface "$3"
fi

# Note: the `pipeline.bash` script will check some stuff, and then use GNU parallel to run `deface_subject.bash` for each subject.
