# Variables
surf_suffix = ["pial", "white", "inflated"]

# Rules
if config["use_gpu"]: 
    rule fastsurfer_gpu:
        """"
        Run fastsurfer on GPU
        Will automatically default to CPU if GPU not found via fastsurfer
        NOTE: Fastsurfer requires real paths
        """
        input:
            t1 = bids(root="work/preproc_t1", datatype="anat", space=config["template"], **config["subj_wildcards"], suffix="T1w.nii.gz")
        params:
            fastsurfer = config["singularity"]["fastsurfer"],
            fs_license = config["fs_license"],
            work_dir = os.path.realpath("work/fastsurfer"),
            realpath_t1 = lambda wildcards, input: os.path.realpath(input.t1)
        output:
            out_dir = directory("work/fastsurfer/sub-{subject}"),
            lh_surf = expand("work/fastsurfer/sub-{{subject}}/surf/lh.{surf_suffix}", surf_suffix=surf_suffix),
            rh_surf = expand("work/fastsurfer/sub-{{subject}}/surf/rh.{surf_suffix}", surf_suffix=surf_suffix)
        resources:
            gpu = 1
        threads: workflow.cores
        shell:
            "singularity exec --nv {params.fastsurfer} /fastsurfer/run_fastsurfer.sh --fs_license {params.fs_license} --t1 {params.realpath_t1} --sd {params.work_dir} --sid sub-{wildcards.subject}"
else:
    rule fastsurfer_cpu:
        """ 
        Run fastsurfer on CPU
        NOTE: Fastsurfer requires real paths
        """ 
        input:
            t1 = bids(root="work/preproc_t1", datatype="anat", space=config["template"], **config["subj_wildcards"], suffix="T1w.nii.gz")
        params:
            fs_license = config["fs_license"],
            work_dir = os.path.realpath("work/fastsurfer"),
            realpath_t1 = lambda wildcards, input: os.path.realpath(input.t1)
        output:
            out_dir = directory("work/fastsurfer/sub-{subject}"),
            lh_surf = expand("work/fastsurfer/sub-{{subject}}/surf/lh.{surf_suffix}", surf_suffix=surf_suffix),
            rh_surf = expand("work/fastsurfer/sub-{{subject}}/surf/rh.{surf_suffix}", surf_suffix=surf_suffix),
        container:
            config["singularity"]["fastsurfer"],
        threads: workflow.cores
        group: "subj"
        shell:
            "/fastsurfer/run_fastsurfer.sh --fs_license {params.fs_license} --t1 {params.realpath_t1} --sd {params.work_dir} --sid sub-{wildcards.subject} --no_cuda"