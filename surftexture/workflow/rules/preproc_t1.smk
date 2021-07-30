rule import_t1:
    """ 
    Grab first T1w image
    """
    input: lambda wildcards: expand(config["input_path"]["T1w"], zip, **snakebids.filter_list(config["input_zip_lists"]["T1w"], wildcards))[0]
    output: bids(root="work", datatype="anat", **config["subj_wildcards"], suffix="T1w.nii.gz")
    group: "subj"
    shell: 
        "cp {input} {output}"

rule n4_t1:
    input: 
        t1 = bids(root="work", datatype="anat", **config["subj_wildcards"], suffix="T1w.nii.gz")
    output: 
        t1 = bids(root="work", datatype="anat", **config["subj_wildcards"], desc="preproc", suffix="T1w.nii.gz")
    threads: 8        
    container: config["singularity"]["neuroglia-core"]
    shell:
        "ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads} "
        "N4BiasFieldCorrection -d 3 -i {input.t1} -o {output}"