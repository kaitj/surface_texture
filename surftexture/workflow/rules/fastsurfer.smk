# Variables
hemi = ["lh", "rh"]
surf_suffix = ["pial", "white", "inflated", "thickness"]

ruleorder: fastsurfer > get_tkr2scanner

# Rules
if config["use_gpu"]: 
    rule fastsurfer:
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
            realpath_t1 = lambda wildcards, input: os.path.realpath(input.t1),
            threads = workflow.cores
        output:
            fs_t1 = "work/fastsurfer/sub-{subject}/mri/T1.mgz",
            fs_surf = expand("work/fastsurfer/sub-{{subject}}/surf/{hemi}.{surf_suffix}", hemi=hemi, surf_suffix=surf_suffix),
            fs_sphere = expand("work/fastsurfer/sub-{{subject}}/surf/{hemi}.sphere.reg", hemi=hemi)
        resources:
            gpu = 1
        threads: workflow.cores
        shell:
            "singularity exec --nv {params.fastsurfer} /fastsurfer/run_fastsurfer.sh --fs_license {params.fs_license} --t1 {params.realpath_t1} --sd {params.work_dir} --sid sub-{wildcards.subject} --surfreg --threads {param.threads}"
else:
    rule fastsurfer:
        """ 
        Run fastsurfer on CPU
        NOTE: Fastsurfer requires real paths
        """ 
        input:
            t1 = bids(root="work/preproc_t1", datatype="anat", space=config["template"], **config["subj_wildcards"], suffix="T1w.nii.gz")
        params:
            fs_license = config["fs_license"],
            work_dir = os.path.realpath("work/fastsurfer"),
            realpath_t1 = lambda wildcards, input: os.path.realpath(input.t1),
            threads = workflow.cores
        output:
            fs_t1 = "work/fastsurfer/sub-{subject}/mri/T1.mgz",
            fs_surf = expand("work/fastsurfer/sub-{{subject}}/surf/{hemi}.{surf_suffix}", hemi=hemi, surf_suffix=surf_suffix),
            fs_sphere = expand("work/fastsurfer/sub-{{subject}}/surf/{hemi}.sphere.reg", hemi=hemi)
        container:
            config["singularity"]["fastsurfer"],
        threads: workflow.cores
        group: "subj"
        shell:
            "/fastsurfer/run_fastsurfer.sh --fs_license {params.fs_license} --t1 {params.realpath_t1} --sd {params.work_dir} --sid sub-{wildcards.subject} --no_cuda --surfreg --threads {params.threads}"

rule get_tkr2scanner:
    """
    Get tk transformation to bring data back to original scanner/subject space from fs input
    """
    input: "work/fastsurfer/sub-{subject}/mri/T1.mgz"
    container: config["singularity"]["fastsurfer"]
    output: 
        xfm = "work/fastsurfer/sub-{subject}/mri/transforms/tkr2scanner.xfm"
        fastsurfer_dir = directory("work/fastsurfer/sub-{subject}")
    group: "subj"
    shell:
        "mri_info {input} --tkr2scanner > {output.xfm}"

rule fs_datasink:
    """
    Datasink Fastsurfer (zips fastsurfer output)
    """
    input: "work/fastsurfer/sub-{subject}"
    output: "result/sub-{subject}/fastsurfer/sub-{subject}_fastsurfer.zip"
    shell: 
        "zip -Z store -ru {output} {input}"        

# TO DO: QC TO CHECK SURFACE FIT