# Functions 
def get_anat():
    "Grab transforms and registered nii.gz"
    anat_files = [] 
    anat_files.extend(
        expand(
            bids(
                    root='work/preproc_t1',
                    datatype='anat',
                    space=config['template'],
                    suffix='T1w.nii.gz',
                    **config['subj_wildcards']),
                allow_missing=True))
    anat_files.extend(
        expand(
            bids(
                    root='work/preproc_t1',
                    datatype='anat',
                    suffix='{suffix}',
                    from_="T1w",
                    to=config["template"],
                    **config['subj_wildcards']),
                suffix=["_0GenericAffine.mat", "_1Warp.nii.gz"],
                allow_missing=True))

    return anat_files

def get_subj_outputs():
    subj_outputs = []
    subj_outputs.extend(get_anat())

    return subj_outputs


def get_result_outputs():
    """ Gather all results; is trigger to run all other rules """
    subj_output = get_work_zip()

    result_output = []
    result_output.extend(
        expand(
            subj_output,
            subject=config["subjects"],
            session=config["sessions"]
        )
    )

    return result_output


def get_work_zip(): 
    """ Zip work files """
    return bids(root="work", suffix="work.zip", 
                include_subject_dir=False, include_session_dir=False, 
                **config['subj_wildcards'])

def get_work_dir(wildcards):
    dir_with_files = expand(bids(root='work',**config['subj_wildcards']),**wildcards)
    return os.path.dirname(dir_with_files[0])

# Rules
rule archive_work:
    """ Create zip archive of work directory """ 
    input: get_subj_outputs()
    params:
        work_dir = get_work_dir
    output: get_work_zip()
    group: "subj"
    shell: 
        "zip -Z store -ru {output} {params.work_dir} && rm -rf {params.work_dir}"
