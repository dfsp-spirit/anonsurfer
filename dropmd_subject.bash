#!/bin/bash
# dropmd_subject.bash -- drop metadata from a number of files of a subject
#
# This script is part of 'anonsurfer'
#
## Note that you can run this from run_dropmd.bash to apply it to several subjects in parallel.
## You can also call it manually for a single subject, of course.

APPTAG="[DROPMD_SUBJECT]"

# Parse command line arguments
if [ -z "$2" ]; then
  echo "$APPTAG ERROR: Arguments missing."
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
LOGFILE="anonsurfer_dropmd_{$SUBJECT_ID}_${DATE_TAG}.log"


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

SD = "${SUBJECTS_DIR}/${SUBJECT_ID}";
echo "$APPTAG INFO: --- Dropping metadata for subject '${SUBJECT_ID}' in directory '${SD}'. ---" >> "${LOGFILE}"


## --------------------------------- Handle metadata in files in mri/ dir ---------------------------------------
echo "$APPTAG INFO: Handling data in sub directory 'mri' for subject '${SUBJECT_ID}'." >> "${LOGFILE}"
VOLUME_FILES=$(find "$SD/mri/" -name '*.mgz');
for VOL_FILE in $VOLUME_FILES; do
  if [ ! -f "${VOL_FILE}" ]; then
      echo "$APPTAG NOTICE: Subject '${SUBJECT_ID} has no file '${VOL_FILE}'. Continuing." >> "${LOGFILE}"
      continue
  fi
  NOMD_FILE="${VOL_FILE}.nii"
  echo "$APPTAG INFO: * Handling subject '${SUBJECT_ID}' metadata in volume file '$VOL_FILE'." >> "${LOGFILE}"
  mri_convert "${VOL_FILE}" "${NOMD_FILE}"
  if [ $? -ne 0 ]; then
      echo "$APPTAG ERROR: mri_convert command failed for subject '${SUBJECT_ID}' file '${VOL_FILE}'. Exiting." >> "${LOGFILE}"
      exit 1
  else
      if [ -f "${NOMD_FILE}" ]; then
          mv "${NOMD_FILE}" "${VOL_FILE}"
          if [ $? -ne 0 ]; then
              echo "$APPTAG ERROR: Could not rename subject '${SUBJECT_ID}' volume file '${NOMD_FILE}' to '${VOL_FILE}'. Exiting." >> "${LOGFILE}"
              exit 1
          else
              echo "$APPTAG INFO: Successfully defaced subject '${SUBJECT_ID}' brain volume '${VOL_FILE}'." >> "${LOGFILE}"
          fi
      else
          echo "$APPTAG ERROR: Cannot read subject '${SUBJECT_ID}' defaced filed '${NOMD_FILE}' after mri_convert command (even though it returned no error). Exiting." >> "${LOGFILE}"
          exit 1
      fi
  fi
done


## --------------------------------- Handle metadata in files in label/ dir ---------------------------------------
echo "$APPTAG INFO: Handling data in sub directory 'label' for subject '${SUBJECT_ID}'." >> "${LOGFILE}"
LABEL_FILES=$(find "$SD/label/" -name '*.label');
for LABEL_FILE in $LABEL_FILES; do
    echo "$APPTAG INFO: Handling subject '${SUBJECT_ID}' ASCII label file '$LABEL_FILE'." >> "${LOGFILE}"
    sed --in-place "1s/.*/#! ascii label for anon subject/" "${LABEL_FILE}" >> "${LOGFILE}"
    if [ $? -ne 0 ]; then
        echo "$APPTAG ERROR: sed command failed for subject '${SUBJECT_ID}' label file '${LABEL_FILE}'. Exiting." >> "${LOGFILE}"
        exit 1
    fi
done

echo "$APPTAG INFO: Finished metadata dropping for subject '${SUBJECT_ID}'." >> "${LOGFILE}"
