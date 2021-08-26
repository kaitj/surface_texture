# Rules
rule fs_to_gii:
    input: "work/fastsurfer/sub-{subject}/surf/{hemi}.{surf_suffix}"
    params:
        fastsurfer = config["singularity"]["fastsurfer"],
        workbench = config["singularity"]["workbench"],
        struct = "CORTEX_LEFT" if "{hemi}" == "lh" else "CORTEX_RIGHT"
    output: "work/gifti/sub-{subject}/surf/{hemi,(lh|rh)}.{surf_suffix,(pial|white|inflated)}.surf.gii"
    shell:
        "singularity exec {params.fastsurfer} mris_convert {input} {output} && "
        "singularity exec {params.workbench} wb_command -set-structure {output} {params.struct}"

rule depth_sampling:
    """ Sample different depths """
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
