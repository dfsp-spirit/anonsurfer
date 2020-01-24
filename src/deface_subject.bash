#!/bin/bash
# deface_subject.bash -- run mri_deface for all volume files of a subject
#
# This script is part of 'anonsurfer'
#
## Note that you can run this from run_deface.bash to apply it to several subjects in parallel.
## You can also call it manually for a single subject, of course.

APPTAG="[DEFACE_SUBJECT]"

if [ -z "$2" ]; then
  echo "$APPTAG ERROR: Arguments missing."
  echo "$APPTAG Usage: $0 <subject_id> <subjects_dir>"
  exit 1
else
  SUBJECT_ID="$1"
  SUBJECTS_DIR="$2"
fi

#### check some basic stuff first

if [ ! -d "${SUBJECTS_DIR}" ]; then
  echo "$APPTAG ERROR: Parameter 'subjects_dir' points to '${SUBJECTS_DIR}' but that directory does NOT exist. Exiting."
  exit 1
fi


if [ ! -d "${SUBJECTS_DIR}/${SUBJECT_ID}" ]; then
  echo "$APPTAG ERROR: Directory for subject '${SUBJECT_ID}' not found in SUBJECTS_DIR '${SUBJECTS_DIR}'. Exiting."
  exit 1
fi


#### Check deface tools
SKULL_TEMPLATE="${FREESURFER_HOME}/average/talairach_mixed_with_skull.gca"
if [ ! -f "${SKULL_TEMPLATE}" ]; then
    echo "$APPTAG ERROR: skull template for defacing not found at '${SKULL_TEMPLATE}'. Exiting."
    exit 1
fi

FACE_TEMPLATE="${FREESURFER_HOME}/average/face.gca"
if [ ! -f "${FACE_TEMPLATE}" ]; then
    echo "$APPTAG ERROR: face template for defacing not found at '${FACE_TEMPLATE}'. Exiting."
    exit 1
fi

#### ok, lets go

SD = "${SUBJECTS_DIR}/${SUBJECT_ID}";
echo "$APPTAG --- Defacing subject '${SUBJECT_ID}' in directory '${SD}'. ---"
echo "$APPTAG --- Defacing not implemented yet ---"


VOLUME_FILES=$(find "$SD/mri/" -name '*.mgz');
for VOL_FILE in $VOLUME_FILES; do
    DEFACED_FILE = "${VOL_FILE}.defaced"
    echo "$APPTAG * Handling volume file '$VOL_FILE'."
    mri_deface "${VOL_FILE}" "${SKULL_TEMPLATE}" "${FACE_TEMPLATE}" "${DEFACED_FILE}"
    if [ $? -ne 0 ]; then
        echo "$APPTAG ERROR: mri_deface command failed. Exiting."
        exit 1
    else
        if [ -f "${DEFACED_FILE}" ]; then
            mv "${DEFACED_FILE}" "${VOL_FILE}"
            if [ $? -ne 0 ]; then
                echo "$APPTAG ERROR: Could not renamed defaced file '${DEFACED_FILE}' to '${VOL_FILE}'. Exiting."
                exit 1
            else
                echo "$APPTAG   Successfully defaced brain volume '${DEFACED_FILE}'."
            fi
        else
            echo "$APPTAG ERROR: Cannot read defaced filed '${DEFACED_FILE}' after mri_deface command (even though it returned no error). Exiting."
            exit 1
        fi
    fi
done
