# Rules
rule fs_to_gii:
    input: "work/fastsurfer/sub-{subject}/surf/{hemi}.{surf_suffix}"
    params:
        fastsurfer = config["singularity"]["fastsurfer"],
        workbench = config["singularity"]["workbench"],
        struct = lambda wildcards: "CORTEX_LEFT" if wildcards.hemi == "lh" else "CORTEX_RIGHT"
    output: "work/gifti/sub-{subject}/surf/{hemi,(lh|rh)}.{surf_suffix,(pial|white|inflated)}.surf.gii"
    shell:
        "singularity exec {params.fastsurfer} mris_convert {input} {output} && "
        "singularity exec {params.workbench} wb_command -set-structure {output} {params.struct}"

rule apply_tkr2scanner_xfm:
    input: 
        surf = "work/gifti/sub-{subject}/surf/{hemi}.{surf_suffix}.surf.gii",
        tkr2scanner = "work/fastsurfer/sub-{subject}/mri/transforms/tkr2scanner.xfm"
    output:
        surf = "work/gifti/sub-{subject}/surf/{hemi,(lh|rh)}.{surf_suffix,(pial|white|inflated)}.scanner.surf.gii"
    container: config["singularity"]["workbench"]
    group: "subj"
    shell:
        "wb_command -surface-apply-affine {input.surf} {input.tkr2scanner} {output.surf}"

rule gen_depth_surfaces:
    """ Generate surfaces for different depths """
    input:         
        pial = "work/gifti/sub-{subject}/surf/{hemi}.pial.scanner.surf.gii",
        white = "work/gifti/sub-{subject}/surf/{hemi}.white.scanner.surf.gii",
    output:
        depth = "work/gifti/sub-{subject}/surf/{hemi,(lh|rh)}.depth-{depth}.scanner.surf.gii"
    group: "subj"
    container: config["singularity"]["workbench"]
    shell:
        "wb_command -surface-cortex-layer {input.white} {input.pial} {wildcards.depth} {output.depth}"

rule sample_depth_surfaces:
    """ Sample values at different depths """
    input:
        t1 = bids(root="work/preproc_t1", datatype="anat", space=config["template"], **config["subj_wildcards"], suffix="T1w.nii.gz"),
        depth = "work/gifti/sub-{subject}/surf/{hemi}.depth-{depth}.scanner.surf.gii",
    params:
        sample_method = "trilinear"
    output:
        depth = "work/gifti/sub-{subject}/metric/{hemi}.depth-{depth}.T1.scanner.shape.gii",
    container: config["singularity"]["workbench"]
    group: "subj"
    shell:
        "wb_command -volume-to-surface-mapping {input.t1} {input.depth} {output.depth} -{params.sample_method}"

# TO DO: QC TO CHECK FIT OF SURFACES
# Convert thickness files