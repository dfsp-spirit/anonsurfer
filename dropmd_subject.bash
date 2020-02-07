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
LOGFILE="anonsurfer_subject_dropmd_${SUBJECT_ID}_${DATE_TAG}.log"


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
echo "$APPTAG INFO: --- Dropping metadata for subject '${SUBJECT_ID}' in directory '${SD}'. ---" >> "${LOGFILE}"


## Skip tags during MGZ writing. This ONLY affects MGH/MGZ files.
## Explanation: The environment variable is checked in the FreeSurfer source code when MGH/MGZ files are written.
## This happens in this script when the `mri_convert` command is run. Exporting this ensures that the last command
## line (conversion back from NIFTI to MGZ) is not stored in the final MGZ file.
FS_SKIP_TAGS=1
export FS_SKIP_TAGS


## --------------------------------- Handle metadata in files in mri/ dir ---------------------------------------

## ------------- Handle MGZ volume files  -----------

echo "$APPTAG INFO: Handling data in sub directory 'mri' for subject '${SUBJECT_ID}'." >> "${LOGFILE}"
if [ -d "$SD/mri/" ]; then
    VOLUME_FILES=$(find "$SD/mri/" -name '*.mgz');
    for VOL_FILE in $VOLUME_FILES; do
      if [ ! -f "${VOL_FILE}" ]; then
          echo "$APPTAG NOTICE: Subject '${SUBJECT_ID} has no volume file '${VOL_FILE}'. Continuing." >> "${LOGFILE}"
          continue
      fi
      NOMD_FILE="${VOL_FILE}.nii"
      echo "$APPTAG INFO: * Handling subject '${SUBJECT_ID}' metadata in volume file '$VOL_FILE'." >> "${LOGFILE}"
      mri_convert "${VOL_FILE}" "${NOMD_FILE}"
      if [ $? -ne 0 ]; then
          echo "$APPTAG ERROR: mri_convert command failed for subject '${SUBJECT_ID}' volume file '${VOL_FILE}' (MGZ to NIFTI)." >> "${LOGFILE}"
      else
          if [ -f "${NOMD_FILE}" ]; then
              mri_convert "${NOMD_FILE}" "${VOL_FILE}"
              if [ $? -ne 0 ]; then
                  echo "$APPTAG ERROR: Could not convert subject '${SUBJECT_ID}' volume file '${NOMD_FILE}' back to '${VOL_FILE}' (NIFTI to MGZ)." >> "${LOGFILE}"
              else
                  rm "${NOMD_FILE}"   # delete temporary NIFTI file
                  echo "$APPTAG INFO: Successfully dropped metadata in subject '${SUBJECT_ID}' brain volume '${VOL_FILE}'." >> "${LOGFILE}"
              fi
          else
              echo "$APPTAG ERROR: Cannot read subject '${SUBJECT_ID}' no metadata NIFTI volume file '${NOMD_FILE}' after mri_convert command (even though it returned no error). MD not dropped." >> "${LOGFILE}"
          fi
      fi
    done
else
    echo "$APPTAG WARNING: Subject '${SUBJECT_ID} has no 'mri' sub directory. Continuing." >> "${LOGFILE}"
fi


## --------------------------------- Handle metadata in files in label/ dir ---------------------------------------

if [ "$OS" = "Darwin" ]; then
    # gotta love MacOS and its BSD sed.
    SED_INLINE_COMMAND='sed -i "" '
else
    SED_INLINE_COMMAND='sed --inline'
fi


## ------------- Handle ASCII label files  -----------
echo "$APPTAG INFO: Handling data in sub directory 'label' for subject '${SUBJECT_ID}'." >> "${LOGFILE}"
if [ -d "$SD/label/" ]; then
    LABEL_FILES=$(find "$SD/label/" -name '*.label');
    for LABEL_FILE in $LABEL_FILES; do
        echo "$APPTAG INFO: Handling subject '${SUBJECT_ID}' ASCII label file '$LABEL_FILE'." >> "${LOGFILE}"
        $SED_INLINE_COMMAND "1s/.*/#! ascii label for anon subject/" "${LABEL_FILE}" >> "${LOGFILE}"
        if [ $? -ne 0 ]; then
            echo "$APPTAG ERROR: sed command failed for subject '${SUBJECT_ID}' label file '${LABEL_FILE}'." >> "${LOGFILE}"
        fi
    done
else
    echo "$APPTAG WARNING: Subject '${SUBJECT_ID} has no 'label' sub directory. Continuing." >> "${LOGFILE}"
fi
## --------------------------------- Handle metadata in files in surf/ dir ---------------------------------------

## ------------- Handle surface files  -----------
echo "$APPTAG INFO: Handling data in sub directory 'surf' for subject '${SUBJECT_ID}'." >> "${LOGFILE}"
# This is ugly: the surface files cannot be identified by their file extension (they have none), so we need to know them. If
# you manually created additional surfaces, you will have to add them here.
SURFACES="white pial inflated orig smoothwm orig.nofix inflated.nofix pial-outer-smoothed qsphere.nofix sphere"
HEMIS="lh rh"
if [ -d "$SD/surf/" ]; then
    for SURFACE in $SURFACES; do
        for HEMI in $HEMIS; do
            SURFACE_FILE="$SD/surf/${HEMI}.${SURFACE}"
            if [ -f "${SURFACE_FILE}" ]; then
                echo "$APPTAG INFO: * Handling subject '${SUBJECT_ID}' metadata in surface file '$SURFACE_FILE'." >> "${LOGFILE}"
                NOMD_FILE="${SURFACE_FILE}.gii"
                mris_convert "${SURFACE_FILE}" "${NOMD_FILE}"
                if [ $? -ne 0 ]; then
                    echo "$APPTAG ERROR: mris_convert command failed for subject '${SUBJECT_ID}' surface file '${SURFACE_FILE}' (fssurf to GIFTI)." >> "${LOGFILE}"
                else
                    if [ -f "${NOMD_FILE}" ]; then
                        mris_convert "${NOMD_FILE}" "${SURFACE_FILE}"
                        if [ $? -ne 0 ]; then
                            echo "$APPTAG ERROR: Could not convert subject '${SUBJECT_ID}' GIFTI surface file '${NOMD_FILE}' back to '${SURFACE_FILE}' (GIFTI to fssurf)." >> "${LOGFILE}"
                        else
                            rm "${NOMD_FILE}" # delete temporary GIFTI file
                            echo "$APPTAG INFO: Successfully dropped metadata in subject '${SUBJECT_ID}' brain surface '${SURFACE_FILE}'." >> "${LOGFILE}"
                        fi
                    else
                        echo "$APPTAG ERROR: Cannot read subject '${SUBJECT_ID}' no metadata GIFTI surface file '${NOMD_FILE}' after mris_convert command (even though it returned no error). MD not dropped." >> "${LOGFILE}"
                    fi
                fi
            else
                echo "$APPTAG NOTICE: subject '${SUBJECT_ID}' has no surface file for surface '$SURFACE' hemi '$HEMI' at '${SURFACE_FILE}'." >> "${LOGFILE}"
            fi
        done
    done
else
    echo "$APPTAG WARNING: Subject '${SUBJECT_ID} has no 'surf' sub directory. Continuing." >> "${LOGFILE}"
fi


## --------------------------------- Handle statistics files in stats/ dir ---------------------------------------
if [ -d "$SD/stats/" ]; then
    echo "$APPTAG WARNING: Sub directory 'stats' not handled yet." >> "${LOGFILE}"
else
    echo "$APPTAG WARNING: Subject '${SUBJECT_ID} has no 'stats' sub directory. Continuing." >> "${LOGFILE}"
fi


echo "$APPTAG INFO: Finished metadata dropping for subject '${SUBJECT_ID}'." >> "${LOGFILE}"
