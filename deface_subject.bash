#!/bin/bash
# deface_subject.bash -- run mri_deface for all volume files of a subject
#
# This script is part of 'anonsurfer'
#
## Note that you can run this from run_deface.bash to apply it to several subjects in parallel.
## You can also call it manually for a single subject, of course.

APPTAG="[DEFACE_SUBJECT]"

# Parse command line arguments
if [ -z "$2" ]; then
  echo "$APPTAG ERROR: Arguments missing. Exiting."
  echo "$APPTAG INFO: Usage: $0 <subject_id> <subjects_dir> [<log_tag>]"
  echo "$APPTAG WARNING: +++++ Running this script will alter parts of your imaging data! +++++ "
  echo "$APPTAG WARNING: +++++       Only run this on an extra copy of your data!         +++++ "
  echo "$APPTAG WARNING: +++++ Running this script will alter parts of your imaging data! +++++ "
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
LOGFILE="anonsurfer_deface_${SUBJECT_ID}_${DATE_TAG}.log"


#### check some basic stuff first

if [ ! -d "${SUBJECTS_DIR}" ]; then
  echo "$APPTAG ERROR: Parameter 'subjects_dir' points to '${SUBJECTS_DIR}' but that directory does NOT exist. Exiting." >> "${LOGFILE}"
  exit 1
fi


if [ ! -d "${SUBJECTS_DIR}/${SUBJECT_ID}" ]; then
  echo "$APPTAG ERROR: Directory for subject '${SUBJECT_ID}' not found in SUBJECTS_DIR '${SUBJECTS_DIR}'. Exiting." >> "${LOGFILE}"
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

for REL_VOL_FILE in $VOLUME_FILES_RELATIVE_TO_MRI_DIR; do
    VOL_FILE="${SD}/${REL_VOL_FILE}"
    if [ ! -f "${VOL_FILE}" ]; then
        echo "$APPTAG NOTICE: Subject '${SUBJECT_ID} has no file '${VOL_FILE}'. Continuing." >> "${LOGFILE}"
        continue
    fi
    DEFACED_FILE="${VOL_FILE}.defaced.mgz"
    echo "$APPTAG INFO: * Handling subject '${SUBJECT_ID}' volume file '$VOL_FILE'."
    mri_deface "${VOL_FILE}" "${SKULL_TEMPLATE}" "${FACE_TEMPLATE}" "${DEFACED_FILE}"
    if [ $? -ne 0 ]; then
        echo "$APPTAG ERROR: mri_deface command failed for subject '${SUBJECT_ID}' file '${VOL_FILE}'. Exiting." >> "${LOGFILE}"
        exit 1
    else
        if [ -f "${DEFACED_FILE}" ]; then
            mv "${DEFACED_FILE}" "${VOL_FILE}"
            if [ $? -ne 0 ]; then
                echo "$APPTAG ERROR: Could not rename subject '${SUBJECT_ID}' defaced file '${DEFACED_FILE}' to '${VOL_FILE}'. Exiting." >> "${LOGFILE}"
                exit 1
            else
                echo "$APPTAG INFO:  Successfully defaced subject '${SUBJECT_ID}' brain volume '${VOL_FILE}'." >> "${LOGFILE}"
            fi
        else
            echo "$APPTAG ERROR: Cannot read subject '${SUBJECT_ID}' defaced filed '${DEFACED_FILE}' after mri_deface command (even though it returned no error). Exiting." >> "${LOGFILE}"
            exit 1
        fi
    fi
done
