rule import_t1:
    """ 
    Grab first T1w image
    """
    input: config["input_path"]["T1w"]
    output: bids(root="work/preproc_t1", datatype="anat", **config["subj_wildcards"], suffix="T1w.nii.gz")
    group: "subj"
    shell: 
        "cp {input} {output}"