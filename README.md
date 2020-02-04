# anonsurfer
Anonymization of [FreeSurfer](http://freesurfer.net/) recon-all output based on metadata dropping and defacing -- in parallel.

**IMPORTANT: This pipeline will alter the FreeSurfer output data, e.g., overwrite voxels in brain volumes and change metadata in files like brain labels. You should only run it on a backup copy of your data that you want to anonomize. NEVER run this on your original data!**

### About

These are BASH shell scripts for the anonymization of neuroimaging data that has been created using the FreeSurfer `recon-all` pipeline. The goals are to:

* Deface all relevant volume files, so the face of the person cannot be reconstructed from the 3D images.
* Drop metadata in various recon-all output files that contain information on the original subject identifier.

The first goal is rather straight-forward and easy to accomplish using [mri_deface](https://surfer.nmr.mgh.harvard.edu/fswiki/mri_deface), the second one is very hard. Be sure to read and understand the warnings on the metadata below if you need this. 

In case you do not care about the metadata and just want a parallel version of `mri_deface`: There are separate scripts for the two tasks, you do not need to run both.

## Defacing

**IMPORTANT: This pipeline will alter the FreeSurfer output data, e.g., overwrite voxels in brain volumes and change metadata in files like brain labels. You should only run it on a backup copy of your data that you want to anonomize. NEVER run this on your original data!**


Run the script `run_deface.bash` to use the deface pipeline. Usage:

```
./run_deface.bash <subjects_file> <subjects_dir> <num_proc>
```

The *subjects_file* is a text file containing one subject per line. The *subject_dir* is your FreeSurfer SUBJECTS_DIR, the directory containing the data. The *num_proc* parameter defines the number of subjects to run in parallel, and should not exceed the number of cores of the machine. Run `nproc` under Linux to find it.


The following files will be defaced for every subject by default:

* `mri/orig.mgz`
* `mri/orig_nu.mgz`
* `mri/T1.mgz`
* `mri/rawavg.mgz`
* `mri/orig/001.mgz`

### Verification of the mri_deface results

I use my [fsbrain R library](https://github.com/dfsp-spirit/fsbrain), a script that renders all relavant volumes of a subject is [available as an example client for the library here](https://github.com/dfsp-spirit/fsbrain/blob/master/web/examples/facecheck.R). I render pre- and post-deface images and manually inspect them to verify that `mri_deface` worked as expected. Here are two examples:

Original volumes for one subject:

![original](https://github.com/dfsp-spirit/fsbrain/raw/master/web/examples/facecheck_subject1_original.png?raw=true "Original volumes")


After `mri_deface` pipeline run:
![Defaced](https://github.com/dfsp-spirit/fsbrain/raw/master/web/examples/facecheck_subject1_defaced.png?raw=true "Defaced volumes")

The 5 volumes in each image are the ones listed above, in the same order. Note that `rawavg.mgz` and `001.mgz` are not conformed, so their orientation differs. You can adapt the script to rotate them if you prefer, but I feel it's not needed.


## Metadata dropping

**IMPORTANT: This pipeline will alter the FreeSurfer output data, e.g., overwrite voxels in brain volumes and change metadata in files like brain labels. You should only run it on a backup copy of your data that you want to anonomize. NEVER run this on your original data!**


Run the script `run_dropmd.bash` to use the metadata dropping pipeline.


```
./run_dropmd.bash <subjects_file> <subjects_dir> <num_proc>
```

See the usage section of the run_deface pipeline above for details.


### A warning on the metadata

These scripts try to remove the ID from all standard output files in the follwoing sub directories: `mri`, `surf`, `stats`, `label`. The files in other sub directories are **not** handled, and some of them definitely contain the ID. The idea is to remove the ID from all data files that are shared with other scientists.

We checked the file formats  of various (ASCII and binary) FreeSurfer v6 output file formats for the IDs, but there is absolutely no guarantee that we did not miss anything, or that the scripts work with other FreeSurfer versions.

File types which are not listed below have not been treated in any way!

If you need to be sure, it may be better to rename the input DICOM/NIFTI files to random names and re-run recon-all from scratch, so the metadata can never make it into the files and does not have to be removed afterwards.

Also keep in mind that this pipeline does **not** try to remove personal data of the person who created the data (ran the `recon-all` commands). The FreeSurfer output files also contain information on the user account and machine name on which the pre-processing was run. The username often is a clear name or something from which the full name of the person can be derived. If you do not want this information in there, I would recommend to create a separate user account (e.g., named `fsuser`) and have everybody in your group use that when running `recon-all`. 


### How metadata dropping works

Metadata and dropping method by file format, for the directories `mri`, `surf`, `stats`, `label`:

* mgh/mgz files (contains 3 or 4-dimensional brain volumes or 1D morph data): 
  - example file: `anonsubject/mri/brain.mgz`
  - contained metadata: 
    * original full absolute path to talairach file, including the ID in the source path
    * history of shell commands run on the file
  - how to check whether metadata is contained:
    * for talairach info: `mri_info <file> | grep talairach`
    * for command line history: `mri_info --cmds <file>`
  - removal method: export `FS_SKIP_TAGS 1`, convert to NIFTI and back (using `mri_convert`).
* label files (contains sections of a brain surface, defined by a vertex list):
  - example file: `anonsubject/label/lh.cortex.label`
  - contained metadata:
    * in the ASCII format, the first line is a comment that contains the ID
  - how to check whether metadata is contained:
    * it's a text file, just use `head -n 1 <file>`
  - removal method: replace the ID part in the files using regex and standard POSIX shell tools (e.g., `sed`)
* lta files (transformation info):
  - example file: `anonsubject/mri/transforms/cc_up.lta`
  - **NOT handled yet**
* stats files (text files containing volume and surface-based statistics)
  - example files: `stats/aseg.stats`
  - **NOT handled yet**
* binary surface files (containing brain surface meshes)
  - example file: `surf/lh.white`
  - **NOT handled yet**

*Please report by [opening an issue](https://github.com/dfsp-spirit/anonsurfer/issues/new) if you find the ID in file types in these directories which are not listed above.*

 
### Ignored metadata

Metadata in other sub directories (outside of `mri`, `surf`, `stats`, `label`) are ignored and will not be handled:

* All log files in `scripts` definitely contain the ID, and are not handled.
* The sub directories `trash`, `touch` and `tmp` are not handled.

There is no need to share the data in afaik, so this pipeline does not alter them.

## Logging and error handling

The exit status of all relevant shell commands are monitored and logged, so that you can tell whether anything went wrong, which subjects are affected, and which files were and were not handled successfully. When you run any pipeline, the following log files will be created in the current working directory:

* `anonsurfer_pipeline_<TASK>_<RUN_ID>.log`: contains the GNU parallel log for the run
* `anonsurfer_deface_<SUBJECT_ID>_<RUN_ID>.log`: contains the deface log for the subject (if run)
* `anonsurfer_dropmd_<SUBJECT_ID>_<RUN_ID>.log`: contains the drop metadata log for the subject (if run)

The `<RUN_ID>` is a string constructed from the date and time when the pipeline was started. It is shared by all log files that belong to a run (i.e., it will be identical for the pipeline log and all subject log files).

If any errors occurred, the log lines contain the string `ERROR:`.


## Runtime and Performance

These scripts can be used with [GNU parallel](https://www.gnu.org/software/parallel/) to process several subjects in parallel. Keep in mind that some of the tasks are quite I/O heavy though, so if you have a machine with many cores but slow storage, you *may* be better off **not** using all cores.

A very rough guide to estimate the runtime of the pipelines:

* **deface pipeline**: On a modern CPU, defacing takes roughly 2 minutes per volume file. A typical subject has 5 volume files that need to be defaced.
* **drop metadata pipeline**: Converting an MGH/MGZ volume to NIFTI and back takes < 3 seconds (and may depend more on IO than your CPU). A typical subject has about 30 volume files that need to be converted.

Parallelization happens on subject level, **not** on file level. 


## System Requirements

* Linux or MacOS system (with BASH shell installed)
* [FreeSurfer](http://freesurfer.net/) installed and configured for the BASH shell (e.g., environment variable FREESURFER_HOME set)
* [GNU parallel](https://www.gnu.org/software/parallel/)
