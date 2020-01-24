# anonsurfer
Anonymization of freesurfer recon-all output based on metadata dropping and defacing -- in parallel.

**IMPORTANT: This pipeline will alter the data, e.g., overwrite voxels in brain volumes and change metadata in files. You should only run it on a backup copy of your data that you want to export. NEVER run this on your original data! If something goes wrong, you will have to restart from a fresh copy of the original data.**

## About

These are BASH shell scripts for the anonymization of neuroimaging data that has been created using the FreeSurfer `recon-all` pipeline. The goals are to:

* Deface all relevant volume files, so the face of the person cannot be reconstructed from the 3D images.
* Drop metadata in various recon-all output files that contains information on the original subject identifier.

The first goal is rather straight-forward and easy to accomplish using [mri_deface](https://surfer.nmr.mgh.harvard.edu/fswiki/mri_deface), the second one is very hard. Be sure to read and understand the warning on the metadata below if you need this. 

In case you do not care about the metadata and just want a parallel version of `mri_deface`: There are separate scripts for the two tasks, you do not need to run both.

# Defacing

**IMPORTANT: This pipeline will alter the data, e.g., overwrite voxels in brain volumes and change metadata in files. You should only run it on a backup copy of your data that you want to export. NEVER run this on your original data! If something goes wrong, you will have to restart from a fresh copy of the original data.**


Run the script `run_deface.bash` to use the deface pipeline.

The following files will be defaced for every subject by default:

* `mri/orig.mgz`
* `mri/orig_nu.mgz`
* `mri/T1.mgz`
* `mri/rawavg.mgz`
* `mri/orig/001.mgz`

# Metadata dropping

**IMPORTANT: This pipeline will alter the data, e.g., overwrite voxels in brain volumes and change metadata in files. You should only run it on a backup copy of your data that you want to export. NEVER run this on your original data! If something goes wrong, you will have to restart from a fresh copy of the original data.**


Run the script `run_dropmd.bash` to use the metadata dropping pipeline.

## A warning on the metadata

These scripts try to remove the ID from all standard output files in the follwoing sub directories: `mri`, `surf`, `stats`, `label`. The files in other sub directories are **not** handled, and some of them definitely contain the ID. The idea is to remove the ID from all data files that are shared with other scientists.

We checked the file formats  of various (ASCII and binary) FreeSurfer v6 output file formats for the IDs, but there is absolutely no guarantee that we did not miss anything, or that the scripts work with other FreeSurfer versions.

File types which are not listed below have not been treated in any way!

If you need to be sure, it may be better to rename the input DICOM/NIFTI files to random names and re-run recon-all from scratch, so the metadata can never make it into the files and does not have to be removed afterwards.

Also keep in mind that this pipeline does **not** try to remove personal data of the person who created the data (ran the `recon-all` commands). The FreeSurfer output files also contain information on the user account and machine name on which the pre-processing was run. The username often is a clear name or something from which the full name of the person can be derived. If you do not want this information in there, I would recommend to create a separate user account (e.g., named `fsuser`) and have everybody in your group use that when running `recon-all`. 


## How it works

Metadata and dropping method by file format, for the directories `mri`, `surf`, `stats`, `label`:

* mgh/mgz files (3 or 4-dimensional brain volumes): 
  - example file: `anonsubject/mri/brain.mgz`
  - contained metadata: 
    * original full absolute path to talairach file, including the ID in the source path
    * history of shell commands run on the file
  - removal method: convert to NIFTI and back (using `mris_convert`).
* label files (sections of a brain surface, defined by vertex list):
  - example file: `anonsubject/label/lh.cortex.label`
  - contained metadata:
    * in the ASCII format, the first line is a comment that contains the ID
  - removal method: replace the ID part in the files using regex and standard POSIX shell tools (e.g., `sed`)

*Please report by [opening an issue](https://github.com/dfsp-spirit/anonsurfer/issues/new) if you find the ID in file types in these directories which are not listed above.*

 
### In other sub directories (ignored, will not be handled):

* All log files in `scripts` definitely contain the ID, and are not handled.
* The sub directories `trash`, `touch` and `tmp` are not handled.

There is no need to share this data afaik.


## Performance

These scripts can be used with [GNU parallel](https://www.gnu.org/software/parallel/) to process several subjects in parallel. Keep in mind that some of the tasks are quite I/O heavy though, so if you have a machine with many cores but slow storage, you *may* be better off **not** using all cores.


## Requirements

* BASH shell
* FreeSurfer installed and configured for the BASH shell (e.g., environment variable FREESURFER_HOME set)
* GNU parallel
