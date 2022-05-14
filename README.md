# Surface Textures

Pipeline to extend and perform surface-based texture analysis

_**Archived underdevelopment workflow as no plans to use this workflow**_

## Development

The following describes how to set up the repository for development. We recommend setting up a 
virtual environment for development.

1. Clone this repository: `git clone git@github.com:kaitj/surface_textures.git <clone_directory>`
1. Setup virtual environment: `python -m <venv_name> <venv_directory>`
1. Activate the virtual environment: `source <venv_directory>/bin/activate`
1. Install the required pacakges: `pip install -r requirements.txt`

_Note: You will have to activate the virtual environment every time you wish to run the application_

To run the app locally, run the following: `<clone_directory>/surftexture/run.py <bids_dir> <out_dir> participant --use-singularity`

To perform a dry-run: `<clone_directory>/surftexture/run.py <bids_dir> <out_dir> participant -np --use-singularity`
