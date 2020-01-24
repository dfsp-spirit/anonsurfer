# anonsurfer
Anonymization of freesurfer recon-all output based on metadata dropping and defacing.

## About

These are BASH shell scripts for the anonymization of neuroimaging data that has been created using the FreeSurfer recon-all pipeline. The goals are to:

* deface all relevant volume files, so the face of the person cannot be reconstructed from the 3D images
* drop metadata in various recon-all output files that contains information on the original subject identifier

The first goal is rather straight-forward and easy to accomplish, the second one is very hard. Be sure to read and understand the warning below.

## A warning on the metadata

These scripts try to remove the ID from all standard output files in which they know the ID exists. We checked the file formats  of various (ASCII and binary) FreeSurfer v6 output file formats for the IDs, but there is absolutely no guarantee that we did not miss anything, or that the scripts work with other FreeSurfer versions.

If you need to be sure, it may be better to rename the input DICOM/NIFTI files to random names and re-run recon-all from scratch, so the metadata can never make it into the files and does not have to be removed afterwards.

## Metadata dropping by file format

* mgh/mgz files (3 or 4-dimensional brain volumes): 
  - contained metadata: 
    * original full absolute path to talairach file, including the ID in the source path
  - removal method: convert to NIFTI and back (using mris_convert).
