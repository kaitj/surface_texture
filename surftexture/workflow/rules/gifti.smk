# Rules
# NEED TO TRANSFORM SURFACES FROM TK TO MNI/SUBJECT SPACE
rule fs_to_gii:
    input: "work/fastsurfer/sub-{subject}/surf/{hemi}.{surf_suffix}"
    params:
        fastsurfer = config["singularity"]["fastsurfer"],
        workbench = config["singularity"]["workbench"],
        struct = lambda wildcards: "CORTEX_LEFT" if wildcards.hemi == "lh" else "CORTEX_RIGHT"
    output: "work/gifti/sub-{subject}/surf/{hemi,(lh|rh)}.{surf_suffix,(pial|white|inflated)}.surf.gii"
    shell:
        "echo {params.struct} && singularity exec {params.fastsurfer} mris_convert {input} {output} && "
        "singularity exec {params.workbench} wb_command -set-structure {output} {params.struct}"

rule gen_depth_surfaces:
    """ Generate surfaces for different depths """
    # Surfaces don't seem to line up with volume
    input:         
        lh_pial = "work/gifti/sub-{subject}/surf/lh.pial.surf.gii",
        lh_white = "work/gifti/sub-{subject}/surf/lh.white.surf.gii",
        rh_pial = "work/gifti/sub-{subject}/surf/rh.pial.surf.gii",
        rh_white = "work/gifti/sub-{subject}/surf/rh.white.surf.gii"
    params:
        workbench = config["singularity"]["workbench"]
    output:
        lh_depth = expand("work/gifti/sub-{{subject}}/surf/lh.depth-{depths}.surf.gii", depths=config["sample_depths"]),
        rh_depth = expand("work/gifti/sub-{{subject}}/surf/rh.depth-{depths}.surf.gii", depths=config["sample_depths"])
    run:
        for idx, depth in enumerate(config["sample_depths"]):
            os.system(f"singularity exec {params.workbench} wb_command -surface-cortex-layer {input.lh_white} {input.lh_pial} {depth} {output.lh_depth[idx]}")
            os.system(f"singularity exec {params.workbench} wb_command -surface-cortex-layer {input.rh_white} {input.rh_pial} {depth} {output.rh_depth[idx]}")

rule sample_depth_surfaces:
    """ Sample values at different depths 
        NOTE: CHECK EXTENSION NAME
    """
    input:
        t1 = bids(root="work/preproc_t1", datatype="anat", space=config["template"], **config["subj_wildcards"], suffix="T1w.nii.gz"),
        lh_depth = expand("work/gifti/sub-{{subject}}/surf/lh.depth-{depths}.surf.gii", depths=config["sample_depths"]),
        rh_depth = expand("work/gifti/sub-{{subject}}/surf/rh.depth-{depths}.surf.gii", depths=config["sample_depths"])
    params:
        workbench = config["singularity"]["workbench"],
        sample_method = "trilinear"
    output:
        out_dir = directory("work/gifti/sub-{subject}/metric"),
        lh_depth = expand("work/gifti/sub-{{subject}}/metric/lh.depth-{depths}.T1.shape.gii", depths=config["sample_depths"]),
        rh_depth = expand("work/gifti/sub-{{subject}}/metric/rh.depth-{depths}.T1.shape.gii", depths=config["sample_depths"])
    run:
        for idx, depth in enumerate(config["sample_depths"]):
            os.system(f"singularity exec {params.workbench} wb_command -volume-to-surface-mapping {input.t1} {input.lh_depth[idx]} {output.lh_depth[idx]} -{params.sample_method}")
            os.system(f"singularity exec {params.workbench} wb_command -volume-to-surface-mapping {input.t1} {input.rh_depth[idx]} {output.rh_depth[idx]} -{params.sample_method}")

