# Rules
if config["use_gpu"]: 
    rule fastsurfer_gpu:
        """"
        Run fastsurfer on GPU
        Will default to CPU if GPU not found via fastsurfer
        """
        input:
            t1 = bids(root="work", datatype="anat", **config["subj_wildcards"], suffix="T1w.nii.gz")
        params:
            fastsurfer = config["singularity"]["fastsurfer"],
            fs_license = config["fs_license"]
        output:
            out_dir = directory("work")
        resources:
            gpu = 1
        shell:
            "singularity exec --nv {params.fastsurfer} /fastsurfer/run_fastsurfer.sh --fs-license {params.fs_license} --t1 {input.t1} --sd {output.out_dir} --sid {wildcards.subject}"
else:
    # Run FastSurfer on cpu
    rule fastsurfer_cpu:
        """ 
        Run fastsurfer on CPU
        """ 
        input:
            t1 = bids(root="work", datatype="anat", **config["subj_wildcards"], suffix="T1w.nii.gz")
        params:
            fastsurfer = config["singularity"]["fastsurfer"],
            fs_license = config["fs_license"]
        output:
            out_dir = directory("work"),
            aparc_aseg = "work/sub-{wildcards.subject}/mri/aparc.DKTatlas+aseg.deep.mgz"
        group: "subj"
        shell:
            "/fastsurfer/run_fastsurfer.sh --fs-license {params.fs_license} --t1 {input.t1} --sd {output.out_dir} --sid {wildcards.subject}"