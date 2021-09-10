rule import_t1:
    """ 
    Grab first T1w image
    """
    input: config["input_path"]["T1w"]
    output: bids(root="work/preproc_t1", datatype="anat", **config["subj_wildcards"], suffix="T1w.nii.gz")
    group: "subj"
    shell: 
        "cp {input} {output}"

rule t1_to_mni152nlin2009casym:
    """
    Transform data to a standard template space
    """
    input: 
        t1 = bids(root="work/preproc_t1", datatype="anat", **config["subj_wildcards"], suffix="T1w.nii.gz"),
        ref = os.path.join(config['snakemake_dir'], config["template_files"][config["template"]]["T1w"])
    params: 
        prefix = bids(root="work/preproc_t1", datatype="anat", from_="T1w", to=config["template"], **config["subj_wildcards"], suffix="_")
    output:
        affine = bids(root="work/preproc_t1", datatype="anat", from_="T1w", to=config["template"], **config["subj_wildcards"], suffix="_0GenericAffine.mat"),
        warp = bids(root="work/preproc_t1", datatype="anat", from_="T1w", to=config["template"], **config["subj_wildcards"], suffix="_1Warp.nii.gz"),
        inv_warp = bids(root="work/preproc_t1", datatype="anat", from_="T1w", to=config["template"], **config["subj_wildcards"], suffix="_1InverseWarp.nii.gz")
    container: config["singularity"]["neuroglia-core"]
    threads: workflow.cores
    group: "subj"
    shell: 
        "antsRegistrationSyNQuick.sh -d 3 -f {input.ref} -m {input.t1} -o {params.prefix}"

rule apply_xfm:
    """
    Apply transformations
    """
    input:
        t1 = bids(root="work/preproc_t1", datatype="anat", **config["subj_wildcards"], suffix="T1w.nii.gz"),
        ref = os.path.join(config['snakemake_dir'], config["template_files"][config["template"]]["T1w"]),
        affine = bids(root="work/preproc_t1", datatype="anat", from_="T1w", to=config["template"], **config["subj_wildcards"], suffix="_0GenericAffine.mat"),
        warp = bids(root="work/preproc_t1", datatype="anat", from_="T1w", to=config["template"], **config["subj_wildcards"], suffix="_1Warp.nii.gz"),
    output: bids(root="work/preproc_t1", datatype="anat", space=config["template"], **config["subj_wildcards"], suffix="T1w.nii.gz")
    container: config["singularity"]["neuroglia-core"]
    group: "subj"
    threads: workflow.cores
    shell: 
        "antsApplyTransforms -d 3 -i {input.t1} -r {input.ref} -t {input.warp} -t [{input.affine},0] -o {output}"

# TO DO: CREATE A QC TO CHECK REGISTRATION