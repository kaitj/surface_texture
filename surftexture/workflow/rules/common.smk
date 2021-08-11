import glob 

# Functions 
def get_anat():
    anat = []
    anat.extend(
        expand( 
            bids(root="results", datatype="anat",
            suffix="T1w.nii.gz", **config["subj_wildcards"]),
            allow_missing=True
        )
    )
    return anat

def get_fastsurfer():
    # Fastsurfer is not stored in BIDs by default
    # surf = []
    surf = ["work/sub-{subject}/mri/aparc.DKTatlas+aseg.deep.mgz"]
    
    # surf = list(glob.iglob("work/{wildcards.subject}/**/*", recursive=True))
    
    return surf


def get_subj_output():
    subj_output = []
    subj_output.extend(get_anat())
    subj_output.extend(get_fastsurfer())

    return subj_output


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
    dir_with_files = expand(bids(root="work", **config["subj_wildcards"]), **wildcards)
    return os.path.dirname(dir_with_files[0])


# Rules
rule output_results:
    """ Copy data from work to results """
    input: "work/{file}"
    output: "results/{file}"
    group: "subj"
    shell: "cp -v {input} {output}"


rule archive_work:
    """ Create zip archive of work directory """ 
    input: get_subj_output()
    params:
        work_dir = get_work_dir
    output: get_work_zip() 
    group: "subj"
    shell: 
        "zip -Z store -ru {output} {params.work_dir} && rm -rf {params.work_dir}"