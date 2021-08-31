# Rules
rule fs_surf_to_gii:
    """ Convert surfaces (pial, white, etc.) to gifti (surf.gii) """
    input: "work/fastsurfer/sub-{subject}/surf/{hemi}.{surf_suffix}"
    params:
        fastsurfer = config["singularity"]["fastsurfer"],
        workbench = config["singularity"]["workbench"],
        struct = lambda wildcards: "CORTEX_LEFT" if wildcards.hemi == "lh" else "CORTEX_RIGHT"
    output: "work/gifti/sub-{subject}/surf/{hemi,(lh|rh)}.{surf_suffix,(pial|white|inflated|sphere.reg)}.surf.gii"
    shell:
        "singularity exec {params.fastsurfer} mris_convert {input} {output} && "
        "singularity exec {params.workbench} wb_command -set-structure {output} {params.struct}"

rule resample_to_fs32K:
    """ Resample surface to fsLR 32K (in fsaverage space) """
    input:
        pial = "work/gifti/sub-{subject}/surf/{hemi}.pial.surf.gii",
        white = "work/gifti/sub-{subject}/surf/{hemi}.white.surf.gii",
        inflated = "work/gifti/sub-{subject}/surf/{hemi}.inflated.surf.gii",
        subj_sphere = "work/gifti/sub-{subject}/surf/{hemi}.sphere.reg.surf.gii",
        fs32k = lambda wildcards: os.path.join(config["snakemake_dir"], config["fs_sphere"][config["fs_den"]]["lh"]) if wildcards.hemi == "lh" else os.path.join(config["snakemake_dir"], config["fs_sphere"][config["fs_den"]]["rh"])
    params:
        method = "BARYCENTRIC"
    output:
        pial = "work/gifti/sub-{subject}/surf/{hemi,(lh|rh)}.pial.fs32k.surf.gii",
        white = "work/gifti/sub-{subject}/surf/{hemi,(lh|rh)}.white.fs32k.surf.gii",
        inflated = "work/gifti/sub-{subject}/surf/{hemi,(lh|rh)}.inflated.fs32k.surf.gii"
    group: "subj"
    threads: workflow.cores
    container: config["singularity"]["workbench"]
    shell: 
        "wb_command -surface-resample {input.pial} {input.subj_sphere} {input.fs32k} {params.method} {output.pial} && "
        "wb_command -surface-resample {input.white} {input.subj_sphere} {input.fs32k} {params.method} {output.white} && "
        "wb_command -surface-resample {input.inflated} {input.subj_sphere} {input.fs32k} {params.method} {output.inflated}"
    
rule apply_tkr2scanner_surf:
    """ Apply tk transform to bring surface back to subject/scanner space """
    input: 
        surf = "work/gifti/sub-{subject}/surf/{hemi}.{surf_suffix}.fs32k.surf.gii",
        tkr2scanner = "work/fastsurfer/sub-{subject}/mri/transforms/tkr2scanner.xfm"
    output:
        surf = "work/gifti/sub-{subject}/surf/{hemi,(lh|rh)}.{surf_suffix,(pial|white|inflated)}" + f".{config['template']}32k.surf.gii"
    container: config["singularity"]["workbench"]
    group: "subj"
    shell:
        "wb_command -surface-apply-affine {input.surf} {input.tkr2scanner} {output.surf}"

rule compute_cortical_thickness:
    """ Compute thickness from resampled surface """
    input: 
        pial = "work/gifti/sub-{subject}/surf/{hemi}.pial" + f".{config['template']}32k.surf.gii",
        white = "work/gifti/sub-{subject}/surf/{hemi}.white" + f".{config['template']}32k.surf.gii"
    output:
        gii = "work/gifti/sub-{subject}/metric/{hemi}.thickness" + f".{config['template']}32k.shape.gii"
    container: config['singularity']['workbench']
    group: 'subj' 
    shell:
        "wb_command -surface-to-surface-3d-distance {input.pial} {input.white} {output}"    

rule gen_depth_surfaces:
    """ Generate surfaces for different depths """
    input:         
        pial = "work/gifti/sub-{subject}/surf/{hemi}.pial" + f".{config['template']}32k.surf.gii",
        white = "work/gifti/sub-{subject}/surf/{hemi}.white" + f".{config['template']}32k.surf.gii",
    output:
        depth = "work/gifti/sub-{subject}/surf/{hemi,(lh|rh)}.depth-{depth}" + f".{config['template']}32k.surf.gii"
    group: "subj"
    container: config["singularity"]["workbench"]
    shell:
        "wb_command -surface-cortex-layer {input.white} {input.pial} {wildcards.depth} {output.depth}"

rule sample_depth_surfaces:
    """ Sample values at different depths """
    input:
        t1 = bids(root="work/preproc_t1", datatype="anat", space=config["template"], **config["subj_wildcards"], suffix="T1w.nii.gz"),
        depth = "work/gifti/sub-{subject}/surf/{hemi}.depth-{depth}" + f".{config['template']}32k.surf.gii",
    params:
        sample_method = "trilinear"
    output:
        depth = "work/gifti/sub-{subject}/metric/{hemi}.depth-{depth}.T1" + f".{config['template']}32k.shape.gii",
    container: config["singularity"]["workbench"]
    group: "subj"
    shell:
        "wb_command -volume-to-surface-mapping {input.t1} {input.depth} {output.depth} -{params.sample_method}"

# TO DO: QC TO CHECK FIT OF SURFACES