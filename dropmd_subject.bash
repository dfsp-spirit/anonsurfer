#!/bin/bash
# dropmd_subject.bash -- drop metadata from a number of files of a subject
#
# This script is part of 'anonsurfer'
#
## Note that you can run this from run_dropmd.bash to apply it to several subjects in parallel.
## You can also call it manually for a single subject, of course.
#
# Under MacOS, you will have to install GNU sed for this to work: `brew install gnu-sed`. See 'SEC_COMMAND' setting below.

APPTAG="[DROPMD_SUBJECT]"

if [ "$OS" = "Darwin" ]; then
    SED_COMMAND='gsed'
else
    SED_COMMAND='sed'
fi


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


ORIGINAL_WORKING_DIR=$(pwd)
LOGFILE="${ORIGINAL_WORKING_DIR}/anonsurfer_subject_dropmd_${SUBJECT_ID}_${DATE_TAG}.log"


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


## --------------------------------- Handle metadata in files in mri/ and all other dirs ---------------------------------------



## ------------- Handle MGZ and MGH volume files  -----------

echo "$APPTAG INFO: Handling data in sub directory 'mri' for subject '${SUBJECT_ID}'." >> "${LOGFILE}"
if [ -d "$SD/mri/" ]; then

    # Delete leftover directories from 'mri_nu_correct.mni' run in case they exist. These directories contain files that are not needed, and the contained 'ones.mgz' file will lead to
    # an error when trying to convert it to NIFTI, which will show up in the logs as a (false positive) error and confuse people. So we delete the directory before handing MGZ files.
    # The full name of the directories we are deleting here is something like 'mri/tmp.mri_nu_correct.mni.60321', where the last number seems to consist of random digits.
    # Note: Under MacOS, the command will lead to one 'no such file or directory' message per matched folder, because 'find' first deletes the folder, but keeps its contents in the TODO list of
    # directories it wants to check for further matches. This is a find bug, and you should ignore these messages.
    find "$SD/mri/" -name "tmp.mri_nu_correct.mni*" -type d -exec rm -r "{}" \;

    VOLUME_FILES=$(find "$SD/" -name '*.mgz' -o -name '*.mgh');
    for VOL_FILE in $VOLUME_FILES; do
      cd "${ORIGINAL_WORKING_DIR}"
      if [ ! -f "${VOL_FILE}" ]; then
          echo "$APPTAG NOTICE: Subject '${SUBJECT_ID} has no volume file '${VOL_FILE}'. Strange. Continuing." >> "${LOGFILE}"
          continue
      fi
      VOL_FILE_DIR=$(dirname "${VOL_FILE}")
      VOL_FILE_BASENAME=$(basename "${VOL_FILE}")
      cd "$VOL_FILE_DIR"     # We needc to change the working directory, it seems to get encoded somewhere in the MGH file, even without tags.
      NOMD_FILE="${VOL_FILE_BASENAME}.nii"
      echo "$APPTAG INFO: * Handling subject '${SUBJECT_ID}' metadata in volume file '$VOL_FILE'." >> "${LOGFILE}"
      mri_convert "${VOL_FILE_BASENAME}" "${NOMD_FILE}"
      if [ $? -ne 0 ]; then
          echo "$APPTAG ERROR: mri_convert command failed for subject '${SUBJECT_ID}' volume file '${VOL_FILE}' (MGZ to NIFTI)." >> "${LOGFILE}"
      else
          if [ -f "${NOMD_FILE}" ]; then
              mri_convert "${NOMD_FILE}" "${VOL_FILE_BASENAME}"
              if [ $? -ne 0 ]; then
                  echo "$APPTAG ERROR: Could not convert subject '${SUBJECT_ID}' volume file '${NOMD_FILE}' back to '${VOL_FILE}' (NIFTI to MGZ)." >> "${LOGFILE}"
              else
                  echo "$APPTAG INFO: Successfully dropped metadata in subject '${SUBJECT_ID}' brain volume '${VOL_FILE}'." >> "${LOGFILE}"
              fi
              rm "${NOMD_FILE}"   # delete temporary NIFTI file
          else
              echo "$APPTAG ERROR: Cannot read subject '${SUBJECT_ID}' no metadata NIFTI volume file '${NOMD_FILE}' after mri_convert command (even though it returned no error). MD not dropped." >> "${LOGFILE}"
          fi
      fi
    done

    cd "${ORIGINAL_WORKING_DIR}"

    ## ------------- Handle lta files  -----------

    LTA_FILES=$(find "$SD/mri/" -name '*.lta');
    for LTA_FILE in $LTA_FILES; do
        echo "$APPTAG INFO: Handling subject '${SUBJECT_ID}' LTA file '$LTA_FILE'." >> "${LOGFILE}"
        $SED_COMMAND --in-place '/# created by/c\# created by anonymous' "${LTA_FILE}" >> "${LOGFILE}"
        if [ $? -ne 0 ]; then
            echo "$APPTAG ERROR: sed command changing creator failed for subject '${SUBJECT_ID}' LTA file '${LTA_FILE}'." >> "${LOGFILE}"
        fi
        $SED_COMMAND --in-place '/# transform file/c\# transform file REMOVED_BY_ANONSURFER' "${LTA_FILE}" >> "${LOGFILE}"
        if [ $? -ne 0 ]; then
            echo "$APPTAG ERROR: sed command changing first line with LTA file name failed for subject '${SUBJECT_ID}' LTA file '${LTA_FILE}'." >> "${LOGFILE}"
        fi
        $SED_COMMAND --in-place '/filename =/c\filename = REMOVED_BY_ANONSURFER' "${LTA_FILE}" >> "${LOGFILE}"
        if [ $? -ne 0 ]; then
            echo "$APPTAG ERROR: sed command changing filename transform file line failed for subject '${SUBJECT_ID}' LTA file '${LTA_FILE}'." >> "${LOGFILE}"
        fi
    done

    find "$SD/mri/" -name "*.log" -delete         # delete log files
    find "$SD/mri/" -name "*.bak" -delete         # delete backups of log files

else
    echo "$APPTAG ERROR: Subject '${SUBJECT_ID} has no 'mri' sub directory. Continuing." >> "${LOGFILE}"
fi

cd "${ORIGINAL_WORKING_DIR}"


## --------------------------------- Handle metadata in files in label/ dir ---------------------------------------




## ------------- Handle ASCII label files  -----------
echo "$APPTAG INFO: Handling data in sub directory 'label' for subject '${SUBJECT_ID}'." >> "${LOGFILE}"
if [ -d "$SD/label/" ]; then
    LABEL_FILES=$(find "$SD/label/" -name '*.label');
    for LABEL_FILE in $LABEL_FILES; do
        echo "$APPTAG INFO: Handling subject '${SUBJECT_ID}' ASCII label file '$LABEL_FILE'." >> "${LOGFILE}"
        $SED_COMMAND --in-place "1s/.*/#! ascii label for anon subject/" "${LABEL_FILE}" >> "${LOGFILE}"
        if [ $? -ne 0 ]; then
            echo "$APPTAG ERROR: sed command failed for subject '${SUBJECT_ID}' label file '${LABEL_FILE}'." >> "${LOGFILE}"
        fi
    done
    find "$SD/label/" -name "*.bak" -delete         # delete backups of log files
else
    echo "$APPTAG ERROR: Subject '${SUBJECT_ID} has no 'label' sub directory. Continuing." >> "${LOGFILE}"
fi
## --------------------------------- Handle metadata in files in surf/ dir ---------------------------------------

## ------------- Handle surface files  -----------
echo "$APPTAG INFO: Handling data in sub directory 'surf' for subject '${SUBJECT_ID}'." >> "${LOGFILE}"
# This is ugly: the surface files cannot be identified by their file extension (they have none), so we need to know them. If
# you manually created additional surfaces, you will have to add them here.
SURFACES="white pial inflated orig smoothwm smoothwm.nofix orig.nofix inflated.nofix pial-outer-smoothed qsphere.nofix sphere sphere.reg white.preaparc"
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
    find "$SD/surf/" -name "*.log" -delete         # delete surface log files
    find "$SD/surf/" -name "*.bak" -delete         # delete backups of log files
else
    echo "$APPTAG ERROR: Subject '${SUBJECT_ID} has no 'surf' sub directory. Continuing." >> "${LOGFILE}"
fi


## --------------------------------- Handle statistics files in stats/ dir ---------------------------------------
if [ -d "$SD/stats/" ]; then

    STATS_FILES=$(find "$SD/stats/" -name '*.stats');
    for STAT_FILE in $STATS_FILES; do
        echo "$APPTAG INFO: Handling subject '${SUBJECT_ID}' stats file '$STAT_FILE'." >> "${LOGFILE}"

        $SED_COMMAND --in-place '/# cmdline/c\# cmdline mris_anatomical_stats REMOVED_BY_ANONSURFER' "${STAT_FILE}" >> "${LOGFILE}"
        if [ $? -ne 0 ]; then
            echo "$APPTAG ERROR: sed command handling 'cmdline' failed for subject '${SUBJECT_ID}' stat file '${STAT_FILE}'." >> "${LOGFILE}"
        fi

        $SED_COMMAND --in-place '/# user/c\# user anonymous' "${STAT_FILE}" >> "${LOGFILE}"
        if [ $? -ne 0 ]; then
            echo "$APPTAG ERROR: sed command handling 'user' failed for subject '${SUBJECT_ID}' stat file '${STAT_FILE}'." >> "${LOGFILE}"
        fi

        $SED_COMMAND --in-place '/# hostname/c\# hostname box' "${STAT_FILE}" >> "${LOGFILE}"
        if [ $? -ne 0 ]; then
            echo "$APPTAG ERROR: sed command handling 'hostname' failed for subject '${SUBJECT_ID}' stat file '${STAT_FILE}'." >> "${LOGFILE}"
        fi

        $SED_COMMAND --in-place '/# SUBJECTS_DIR/c\# SUBJECTS_DIR REMOVED_BY_ANONSURFER' "${STAT_FILE}" >> "${LOGFILE}"
        if [ $? -ne 0 ]; then
            echo "$APPTAG ERROR: sed command handling 'SUBJECTS_DIR' failed for subject '${SUBJECT_ID}' stat file '${STAT_FILE}'." >> "${LOGFILE}"
        fi

        $SED_COMMAND --in-place '/# subjectname/c\# subjectname REMOVED_BY_ANONSURFER' "${STAT_FILE}" >> "${LOGFILE}"
        if [ $? -ne 0 ]; then
            echo "$APPTAG ERROR: sed command handling 'subjectname' failed for subject '${SUBJECT_ID}' stat file '${STAT_FILE}'." >> "${LOGFILE}"
        fi

        $SED_COMMAND --in-place '/# ColorTable /c\# ColorTable REMOVED_BY_ANONSURFER' "${STAT_FILE}" >> "${LOGFILE}"
        if [ $? -ne 0 ]; then
            echo "$APPTAG ERROR: sed command handling 'ColorTable' failed for subject '${SUBJECT_ID}' stat file '${STAT_FILE}'." >> "${LOGFILE}"
        fi

        $SED_COMMAND --in-place '/# InVolFile /c\# InVolFile REMOVED_BY_ANONSURFER' "${STAT_FILE}" >> "${LOGFILE}"
        if [ $? -ne 0 ]; then
            echo "$APPTAG ERROR: sed command handling 'InVolFile' failed for subject '${SUBJECT_ID}' stat file '${STAT_FILE}'." >> "${LOGFILE}"
        fi

        $SED_COMMAND --in-place '/# Annot /c\# Annot REMOVED_BY_ANONSURFER' "${STAT_FILE}" >> "${LOGFILE}"
        if [ $? -ne 0 ]; then
            echo "$APPTAG ERROR: sed command handling 'InVolFile' failed for subject '${SUBJECT_ID}' stat file '${STAT_FILE}'." >> "${LOGFILE}"
        fi
    done

    find "$SD/stats/" -name "*.bak" -delete         # delete backups of log files
else
    echo "$APPTAG ERROR: Subject '${SUBJECT_ID} has no 'stats' sub directory. Continuing." >> "${LOGFILE}"
fi

# Delete temporary junk files that may or may not exist. They can contain the user ID of the person who started recon-all.
find "${SD}" -name "sum.junk" -delete


echo "$APPTAG INFO: Finished metadata dropping for subject '${SUBJECT_ID}'." >> "${LOGFILE}"
