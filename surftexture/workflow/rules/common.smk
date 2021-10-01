import glob 

# Functions
def get_gii_outputs(wildcards):
    """
    Gather gifti outputs
    """
    gii = []

    for hemi in ["lh", "rh"]:
        # Grab surfaces
        gii.extend([f"result/sub-{wildcards.subject}/gifti/surf/sub-{wildcards.subject}_hemi-{hemi}_den-{config['fs_den'][2:]}_{surf}.surf.gii" for surf in ["pial", "white", "inflated"]])
        # Grab depth sampled T1w
        gii.extend([f"result/sub-{wildcards.subject}/gifti/metric/sub-{wildcards.subject}_hemi-{hemi}_den-{config['fs_den'][2:]}_depth-{depth}_T1w.shape.gii" for depth in config["sample_depths"]])
        # Grab thickness
        gii.append(f"result/sub-{wildcards.subject}/gifti/metric/sub-{wildcards.subject}_hemi-{hemi}_den-{config['fs_den'][2:]}_thickness.shape.gii")

    return gii

def get_qc_outputs(wildcards):
    """
    Gather qc files 
    """
    qc = []
    qc.extend(
        expand(
            bids(root="result", datatype="qc", **config["subj_wildcards"], suffix="surfqc.svg"),
            allow_missing=True
        )
    )

    return qc

def get_final_outputs(wildcards):
    """ 
    Gather all final subject outputs 
    """
    final_output = []
    final_output.append(f"result/sub-{wildcards.subject}/anat")
    final_output.append(f"result/sub-{wildcards.subject}/fastsurfer/sub-{wildcards.subject}_fastsurfer.zip")
    final_output.extend(get_gii_outputs(wildcards))
    final_output.extend(get_qc_outputs(wildcards))

    return final_output

def get_work_zip(): 
    """
    Zip work files 
    """
    return bids(root="sourcedata", suffix="sourcedata.zip", 
                include_subject_dir=False, include_session_dir=False, 
                **config['subj_wildcards'])

def complete_wf():
    """ 
    Grab final zip file and trigger all other rules 
    """
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


# Rules
rule archive_work:
    """ 
    Create zip archive of work directory (triggered after files are datasinked)
    """ 
    input: get_final_outputs
    output: get_work_zip() 
    group: "subj"
    shell:
        "zip -Z store -ru {output} work/*/sub-{wildcards.subject}" # && rm -rf work/*/sub-{wildcards.subject}"