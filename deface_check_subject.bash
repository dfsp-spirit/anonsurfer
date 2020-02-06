#!/bin/bash
# deface_check_subject.bash -- generate an image showing faces in all relevant volume files of a subject
#
# In contrast to some other scripts, this one does NOT change any data, it only visualizes brain volumes
# and writes the result to an image file in the current working directory.
#
# This script is part of 'anonsurfer' -- https://github.com/dfsp-spirit/anonsurfer
#
# Note that you can run this from run_deface_check.bash to apply it to several subjects in parallel.
# You can also call it manually for a single subject, of course.
#
# System Requirements:
# This script requires GNU R and the R package 'fsbrain'. Currently the latest dev version is required.
# https://github.com/dfsp-spirit/fsbrain

APPTAG="[DEFACE_CHECK_SUBJECT]"

## IMPORTANT: Configure the path to the facecheck.R script here or set the environment variable 'facecheck_script' before running this.
# - The script is available at the fsbrain Github page (https://github.com/dfsp-spirit/fsbrain).
# - At the time of writing this, the URL is: https://github.com/dfsp-spirit/fsbrain/raw/master/web/examples/facecheck.R
# - You can adapt the volumes you want to visualize directly in the script.
if [ -z "${FACECHECK_SCRIPT}" ]; then
    FACECHECK_SCRIPT="${HOME}/develop/fsbrain/web/examples/facecheck.R"
    RSCRIPT_FROM="script"
else
    RSCRIPT_FROM="env"
fi

## No need to mess with stuff below this line.



# Parse command line arguments
if [ -z "$2" ]; then
  echo "$APPTAG ERROR: Arguments missing. Exiting."
  echo "$APPTAG INFO: Usage: $0 <subject_id> <subjects_dir> [<log_tag>]"
  exit 1
else
  SUBJECT_ID="$1"
  SUBJECTS_DIR="$2"
fi


# Setup logging
if [ -z "$3" ]; then
  DATE_TAG=$(date '+%Y-%m-%d_%H-%M-%S')
else
  DATE_TAG="$3"
fi
LOGFILE="anonsurfer_subject_visdeface_check_${SUBJECT_ID}_${DATE_TAG}.log"

if [ "${RSCRIPT_FROM}" = "script" ]; then
    echo "$APPTAG NOTICE: Environment variable 'FACECHECK_SCRIPT' not set, using path '${FACECHECK_SCRIPT}' from script header in 'deface_check_subject.bash'." >> "${LOGFILE}"
else
    echo "$APPTAG NOTICE: Environment variable 'FACECHECK_SCRIPT' set, using path '${FACECHECK_SCRIPT}' from environment." >> "${LOGFILE}"
fi


if [ ! -x "${FACECHECK_SCRIPT}" ]; then
    echo "$APPTAG ERROR: The facecheck.R script from fsbrain at '${FACECHECK_SCRIPT}' does not exist or is not executable. Please fix or set the correct path in 'deface_check_subject.bash'. Exiting." >> "${LOGFILE}"
    exit 1
fi


#### check some basic stuff first

if [ ! -d "${SUBJECTS_DIR}" ]; then
  echo "$APPTAG ERROR: Parameter 'subjects_dir' points to '${SUBJECTS_DIR}' but that directory does NOT exist. Exiting." >> "${LOGFILE}"
  exit 1
fi


if [ ! -d "${SUBJECTS_DIR}/${SUBJECT_ID}" ]; then
  echo "$APPTAG ERROR: Directory for subject '${SUBJECT_ID}' not found in SUBJECTS_DIR '${SUBJECTS_DIR}'. Exiting." >> "${LOGFILE}"
  exit 1
fi



#### ok, lets go

SD="${SUBJECTS_DIR}/${SUBJECT_ID}";
echo "$APPTAG INFO: --- Visualizing subject '${SUBJECT_ID}' in directory '${SD}'. ---" >> "${LOGFILE}"


echo "$APPTAG INFO: * Visualizing volumes of subject '${SUBJECT_ID}'."

OUTPUT_IMAGE="facecheck_subject_${SUBJECT_ID}.png"
${FACECHECK_SCRIPT} "${SUBJECTS_DIR}" "${SUBJECT_ID}" "${OUTPUT_IMAGE}" >> "${LOGFILE}" 2>&1
if [ $? -ne 0 ]; then
    echo "$APPTAG ERROR: facecheck.R command failed for subject '${SUBJECT_ID}' subjectsdir '${SUBJECTS_DIR}' output image '${OUTPUT_IMAGE}'. Subject not visualized." >> "${LOGFILE}"
else
    if [ -f "${OUTPUT_IMAGE}" ]; then
        echo "$APPTAG INFO: Visualized subject '${SUBJECT_ID}', see output image file '${OUTPUT_IMAGE}'." >> "${LOGFILE}"
    else
        echo "$APPTAG ERROR: Cannot read subject '${SUBJECT_ID}' output image file '${OUTPUT_IMAGE}' after facecheck.R command. Subject not visualized." >> "${LOGFILE}"
    fi
fi
