#!/bin/bash
#
# When defacing subjects in parallel with the run_deface.bash pipeline, failed files get logged
# to one log file per subject. This script collects all failed files, by simply concatenating the
# subject log files.
#
# Written by TS, 2022-02-08.

subjects_file="$1"
subjects_dir="$2"
all_failed_files_log_file="deface_all_failed_files.log"
all_failed_subjects_log_file="deface_all_failed_subjects.log"

APPTAG="[COLLECT_DEF_FAILED]"

if [ -z "$subjects_dir" ]; then
    echo "$APPTAG Collect all files that failed defacing in file '${all_failed_files_log_file}'."
    echo "$APPTAG Usage: $0 <subjects_file> <subjects_dir>"
    echo "$APPTAG    <subjects_file> : path to a textfile containing one subject per line"
    echo "$APPTAG    <subjects_dir>  : path to the FreeSurfer recon-all output directory (known as FreeSurfer SUBJECTS_DIR)."
fi

if [ -f "${all_failed_files_log_file}" ]; then
    rm "${all_failed_files_log_file}"
    if [ -f "${all_failed_files_log_file}" ]; then
        echo "$APPTAG ERROR: Output log file for all failed files '${all_failed_files_log_file}' exists and deleting it failed."
        exit 1
    fi
fi
if [ -f "${all_failed_subjects_log_file}" ]; then
    rm "${all_failed_subjects_log_file}"
    if [ -f "${all_failed_subjects_log_file}" ]; then
        echo "$APPTAG ERROR: Output log file for all failed subjects '${all_failed_subjects_log_file}' exists and deleting it failed."
        exit 1
    fi
fi

touch "${all_failed_files_log_file}"
touch "${all_failed_subjects_log_file}"

subjects_list=$(cat "${subjects_file}" | tr -d '\r' | tr '\n' ' ')    # fix potential windows line endings (delete '\r') and replace newlines by spaces as we want a list

num_subjects_okay=0
num_subjects_failed=0
for subject in $subjects_list; do
    subject_failed_files_log="failed_files_anonsurfer_subject_deface_${subject}.log"
    if [ -f "${subject_failed_files_log}" ]; then
        num_subjects_failed=$((num_subjects_failed+1))
        cat "${subject_failed_files_log}" >> ${all_failed_files_log_file}       # Fill failed files logfile.
        echo "${subject}" >> ${all_failed_subjects_log_file}                    # Fill failed subjects logfile.
    else
        num_subjects_okay=$((num_subjects_okay+1))
    fi
done

echo "$APPTAG Collected failed files for $num_subjects_failed subjects in '${all_failed_files_log_file}' and the failed subjects in '${all_failed_subjects_log_file}'. $num_subjects_okay subjects did not have any failed files."
