rule import_t1:
    """ 
    Grab first T1w image
    """
    input: bids(root=config["bids_dir"], datatype="anat", **config["subj_wildcards"], suffix="T1w.nii.gz") if config["acq"] == "" else bids(root=config["bids_dir"], datatype="anat", acq=config["acq"], **config["subj_wildcards"], suffix="T1w.nii.gz")
    output: bids(root="work/preproc_t1", datatype="anat", **config["subj_wildcards"], suffix="T1w.nii.gz")
    group: "subj"
    shell: 
        "echo {input} && cp {input} {output}"

rule t1_to_mni152nlin2009casym:
    """
    Transform data to a standard template space
    """
    input: 
        t1 = bids(root="work/preproc_t1", datatype="anat", **config["subj_wildcards"], suffix="T1w.nii.gz"),
        ref = os.path.join(config['snakemake_dir'], config["template_files"][config["template"]]["T1w"])
    params: 
        prefix = bids(root="work/preproc_t1", datatype="anat", from_="T1w", to=config["template"], **config["subj_wildcards"], suffix="")
    output:
        affine = bids(root="work/preproc_t1", datatype="anat", from_="T1w", to=config["template"], **config["subj_wildcards"], suffix="0GenericAffine.mat"),
        warp = bids(root="work/preproc_t1", datatype="anat", from_="T1w", to=config["template"], **config["subj_wildcards"], suffix="1Warp.nii.gz"),
        inv_warp = bids(root="work/preproc_t1", datatype="anat", from_="T1w", to=config["template"], **config["subj_wildcards"], suffix="1InverseWarp.nii.gz")
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
        affine = bids(root="work/preproc_t1", datatype="anat", from_="T1w", to=config["template"], **config["subj_wildcards"], suffix="0GenericAffine.mat"),
        warp = bids(root="work/preproc_t1", datatype="anat", from_="T1w", to=config["template"], **config["subj_wildcards"], suffix="1Warp.nii.gz"),
    output: bids(root="work/preproc_t1", datatype="anat", space=config["template"], **config["subj_wildcards"], suffix="T1w.nii.gz")
    container: config["singularity"]["neuroglia-core"]
    group: "subj"
    threads: workflow.cores
    shell: 
        "antsApplyTransforms -d 3 -i {input.t1} -r {input.ref} -t {input.warp} -t [{input.affine},0] -o {output}"

rule t1_datasink:
    """
    Datasink anat workflow(s)
    """
    input: 
        affine = bids(root="work/preproc_t1", datatype="anat", from_="T1w", 
        to=config["template"], **config["subj_wildcards"], 
        suffix="0GenericAffine.mat"),
        warp = bids(root="work/preproc_t1", datatype="anat", from_="T1w", 
        to=config["template"], **config["subj_wildcards"], 
        suffix="1Warp.nii.gz"),
        t1 = bids(root="work/preproc_t1", datatype="anat", 
        space=config["template"], **config["subj_wildcards"], 
        suffix="T1w.nii.gz")
    output: 
        affine = bids(root="result", datatype="anat", from_="T1w", 
        to=config["template"], **config["subj_wildcards"], 
        suffix="0GenericAffine.mat"),
        warp = bids(root="result", datatype="anat", from_="T1w", 
        to=config["template"], **config["subj_wildcards"], 
        suffix="1Warp.nii.gz"),
        t1 = bids(root="result", datatype="anat", space=config["template"], 
        **config["subj_wildcards"], suffix="T1w.nii.gz"),
        anat_dir = directory("result/sub-{subject}/anat")
    shell: 
        "cp {input.affine} {output.affine} && "
        "cp {input.warp} {output.warp} && "
        "cp {input.t1} {output.t1}"
        
# TO DO: CREATE A QC TO CHECK REGISTRATION
rule qc_reg_to_template:
    """ 
    Create visualization to QC registration with template
    """
    input:
        t1 = bids(root="work/preproc_t1", datatype="anat", space=config["template"], **config["subj_wildcards"], suffix="T1w.nii.gz"),
        ref = os.path.join(config['snakemake_dir'], config["template_files"][config["template"]]["T1w"]),
    output: 
        report = report(bids(root="result", datatype="qc", **config['subj_wildcards'], suffix='regqc.svg', from_='subject', 
        to=config['template']), caption='../report/t1w_template_regqc.rst', category='T1w to Template Registration')
    group: 'subj'
    script: '../scripts/viz_regqc.py'
