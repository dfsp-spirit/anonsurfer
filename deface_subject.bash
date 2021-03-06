#!/bin/bash
# deface_subject.bash -- run mri_deface for all volume files of a subject
#
# This script is part of 'anonsurfer' -- https://github.com/dfsp-spirit/anonsurfer
#
## Note that you can run this from run_deface.bash to apply it to several subjects in parallel.
## You can also call it manually for a single subject, of course.

APPTAG="[DEFACE_SUBJECT]"

# Parse command line arguments
if [ -z "$2" ]; then
  echo "$APPTAG ERROR: Arguments missing. Exiting."
  echo "$APPTAG INFO: Usage: $0 <subject_id> <subjects_dir> [<log_tag>]"
  echo "$APPTAG INFO: This script requires that the FREESURFER_HOME environment variable is configured."
  echo "$APPTAG WARNING: +++++ Running this script will alter parts of your imaging data! +++++ "
  echo "$APPTAG WARNING: +++++       Only run this on an extra copy of your data!         +++++ "
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
LOGFILE="anonsurfer_subject_deface_${SUBJECT_ID}_${DATE_TAG}.log"


#### check some basic stuff first

if [ ! -d "${SUBJECTS_DIR}" ]; then
  echo "$APPTAG ERROR: Parameter 'subjects_dir' points to '${SUBJECTS_DIR}' but that directory does NOT exist. Exiting." >> "${LOGFILE}"
  exit 1
fi


if [ ! -d "${SUBJECTS_DIR}/${SUBJECT_ID}" ]; then
  echo "$APPTAG ERROR: Directory for subject '${SUBJECT_ID}' not found in SUBJECTS_DIR '${SUBJECTS_DIR}'. Exiting." >> "${LOGFILE}"
  exit 1
fi


if [ -z "${FREESURFER_HOME}" ]; then
    echo "$APPTAG ERROR: Environment variable FREESURFER_HOME not set, cannot find deface template volumes. Exiting." >> "${LOGFILE}"
    exit 1
fi

#### Check deface tools
SKULL_TEMPLATE="${FREESURFER_HOME}/average/talairach_mixed_with_skull.gca"
if [ ! -f "${SKULL_TEMPLATE}" ]; then
    echo "$APPTAG ERROR: skull template for defacing not found at '${SKULL_TEMPLATE}'. Exiting." >> "${LOGFILE}"
    exit 1
fi

FACE_TEMPLATE="${FREESURFER_HOME}/average/face.gca"
if [ ! -f "${FACE_TEMPLATE}" ]; then
    echo "$APPTAG ERROR: face template for defacing not found at '${FACE_TEMPLATE}'. Exiting." >> "${LOGFILE}"
    exit 1
fi

#### ok, lets go

SD="${SUBJECTS_DIR}/${SUBJECT_ID}";
echo "$APPTAG INFO: --- Defacing subject '${SUBJECT_ID}' in directory '${SD}'. ---" >> "${LOGFILE}"


# We cannot simply search all volume files, as mri_deface will fail for volumes which do not resemble a full head.
# If you used several T1 images for a subject, you will have to add more files under orig.
VOLUME_FILES_RELATIVE_TO_MRI_DIR="mri/orig.mgz mri/orig_nu.mgz mri/T1.mgz mri/rawavg.mgz mri/orig/001.mgz"

NUM_TRIED=$(echo "${VOLUME_FILES_RELATIVE_TO_MRI_DIR}" | wc -w | tr -d '[:space:]')
NUM_EXISTING=0
NUM_OK=0
NUM_MISSING=0
NUM_FAILED=0
for REL_VOL_FILE in $VOLUME_FILES_RELATIVE_TO_MRI_DIR; do
    VOL_FILE="${SD}/${REL_VOL_FILE}"
    if [ ! -f "${VOL_FILE}" ]; then
        echo "$APPTAG NOTICE: Subject '${SUBJECT_ID} has no file '${VOL_FILE}'. Continuing." >> "${LOGFILE}"
        NUM_MISSING=$((NUM_MISSING+1))
        continue
    fi
    NUM_EXISTING=$((NUM_EXISTING+1))
    DEFACED_FILE="${VOL_FILE}.defaced.mgz"   # temp name for defaced file, will be renamed to original file name later.
    echo "$APPTAG INFO: * Handling subject '${SUBJECT_ID}' volume file '$VOL_FILE'."
    mri_deface "${VOL_FILE}" "${SKULL_TEMPLATE}" "${FACE_TEMPLATE}" "${DEFACED_FILE}" >> "${LOGFILE}" 2>&1
    if [ $? -ne 0 ]; then
        echo "$APPTAG ERROR: mri_deface command failed for subject '${SUBJECT_ID}' file '${VOL_FILE}'. Subject not defaced." >> "${LOGFILE}"
        NUM_FAILED=$((NUM_FAILED+1))
    else
        if [ -f "${DEFACED_FILE}" ]; then
            mv "${DEFACED_FILE}" "${VOL_FILE}"
            if [ $? -ne 0 ]; then
                echo "$APPTAG ERROR: Could not rename subject '${SUBJECT_ID}' defaced file '${DEFACED_FILE}' to '${VOL_FILE}'. Subject not defaced." >> "${LOGFILE}"
                NUM_FAILED=$((NUM_FAILED+1))
            else
                echo "$APPTAG INFO:  Successfully defaced subject '${SUBJECT_ID}' brain volume '${VOL_FILE}'." >> "${LOGFILE}"
                NUM_OK=$((NUM_OK+1))
            fi
        else
            echo "$APPTAG ERROR: Cannot read subject '${SUBJECT_ID}' defaced file '${DEFACED_FILE}' after mri_deface command (even though it returned no error). Subject not defaced." >> "${LOGFILE}"
            NUM_FAILED=$((NUM_FAILED+1))
        fi
    fi
done

if [ ${NUM_OK} -eq ${NUM_EXISTING} ]; then
    STATUS="STATUS_ALL_GOOD"
else
    STATUS="STATUS_CHECK_ISSUES"
fi

echo "$APPTAG INFO: Subject '${SUBJECT_ID}' details: ${NUM_TRIED} volume files checked, ${NUM_EXISTING} found (${NUM_MISSING} missing), ${NUM_OK} successfully defaced, ${NUM_FAILED} failed." >> "${LOGFILE}"

# The following report lines are in a stable format that is designed to be be easily parsable, e.g., using 'grep'.
echo "$APPTAG INFO: [REPORT] Subject '${SUBJECT_ID}' DEFACE_FAIL_COUNT=${NUM_FAILED}" >> "${LOGFILE}"
echo "$APPTAG INFO: [REPORT] Subject '${SUBJECT_ID}' DEFACE_FINAL_STATUS=${STATUS}" | tee -a "${LOGFILE}"
