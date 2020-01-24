#!/bin/bash
# deface_subject.bash -- run mris_deface for all volume files of a subject
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


#### ok, lets go

SD = "${SUBJECTS_DIR}/${SUBJECT_ID}";
echo "$APPTAG --- Defacing subject '${SUBJECT_ID}' in directory '${SD}'. ---"
echo "$APPTAG --- Defacing not implemented yet ---"


VOLUME_FILES=$(find "$SD/mri/" -name '*.mgz');
for VOL_FILE in $VOLUME_FILES; do
    echo "Would handle volume file '$VOL_FILE'."
done

LABEL_FILES=$(find "$SD/label/" -name '*.label');
for LABEL_FILE in $LABEL_FILES; do
    echo "Would handle label file '$LABEL_FILE'."
done
