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

rule resample_to_fs:
    """ Resample surface to fsLR 32K (in fsaverage space) """
    input:
        pial = "work/gifti/sub-{subject}/surf/{hemi}.pial.surf.gii",
        white = "work/gifti/sub-{subject}/surf/{hemi}.white.surf.gii",
        inflated = "work/gifti/sub-{subject}/surf/{hemi}.inflated.surf.gii",
        subj_sphere = "work/gifti/sub-{subject}/surf/{hemi}.sphere.reg.surf.gii",
        fs_sphere = lambda wildcards: os.path.join(config["snakemake_dir"], config["fs_sphere"][config['fs_den']]["lh"]) if wildcards.hemi == "lh" else os.path.join(config["snakemake_dir"], config["fs_sphere"][config['fs_den']]["rh"])
    params:
        method = "BARYCENTRIC"
    output:
        pial = f"work/gifti/sub-{{subject}}/surf/{{hemi,(lh|rh)}}.pial.{config['fs_den']}.surf.gii",
        white = f"work/gifti/sub-{{subject}}/surf/{{hemi,(lh|rh)}}.white.{config['fs_den']}.surf.gii",
        inflated = f"work/gifti/sub-{{subject}}/surf/{{hemi,(lh|rh)}}.inflated.{config['fs_den']}.surf.gii"
    group: "subj"
    threads: workflow.cores
    container: config["singularity"]["workbench"]
    shell: 
        "wb_command -surface-resample {input.pial} {input.subj_sphere} {input.fs_sphere} {params.method} {output.pial} && "
        "wb_command -surface-resample {input.white} {input.subj_sphere} {input.fs_sphere} {params.method} {output.white} && "
        "wb_command -surface-resample {input.inflated} {input.subj_sphere} {input.fs_sphere} {params.method} {output.inflated}"
    
rule apply_tkr2scanner_surf:
    """ Apply tk transform to bring surface back to subject/scanner space """
    input: 
        surf = f"work/gifti/sub-{{subject}}/surf/{{hemi}}.{{surf_suffix}}.{config['fs_den']}.surf.gii",
        tkr2scanner = "work/fastsurfer/sub-{subject}/mri/transforms/tkr2scanner.xfm"
    output:
        surf = f"work/gifti/sub-{{subject}}/surf/{{hemi,(lh|rh)}}.{{surf_suffix,(pial|white|inflated)}}.{config['template']}{config['fs_den'][2:]}.surf.gii"
    container: config["singularity"]["workbench"]
    group: "subj"
    shell:
        "wb_command -surface-apply-affine {input.surf} {input.tkr2scanner} {output.surf}"

rule compute_cortical_thickness:
    """ Compute thickness from resampled surface """
    input: 
        pial = f"work/gifti/sub-{{subject}}/surf/{{hemi}}.pial.{config['template']}{config['fs_den'][2:]}.surf.gii",
        white = f"work/gifti/sub-{{subject}}/surf/{{hemi}}.white.{config['template']}{config['fs_den'][2:]}.surf.gii"
    output:
        gii = f"work/gifti/sub-{{subject}}/metric/{{hemi}}.thickness.{config['template']}{config['fs_den'][2:]}.shape.gii"
    container: config['singularity']['workbench']
    group: 'subj' 
    shell:
        "wb_command -surface-to-surface-3d-distance {input.pial} {input.white} {output}"    

rule gen_depth_surfaces:
    """ Generate surfaces for different depths """
    input:         
        pial = f"work/gifti/sub-{{subject}}/surf/{{hemi}}.pial.{config['template']}{config['fs_den'][2:]}.surf.gii",
        white = f"work/gifti/sub-{{subject}}/surf/{{hemi}}.white.{config['template']}{config['fs_den'][2:]}.surf.gii",
    output:
        depth = f"work/gifti/sub-{{subject}}/surf/{{hemi,(lh|rh)}}.depth-{{depth}}.{config['template']}{config['fs_den'][2:]}.surf.gii"
    group: "subj"
    container: config["singularity"]["workbench"]
    shell:
        "wb_command -surface-cortex-layer {input.white} {input.pial} {wildcards.depth} {output.depth}"

rule sample_depth_surfaces:
    """ Sample values at different depths """
    input:
        t1 = bids(root="work/preproc_t1", datatype="anat", space=config['template'], **config["subj_wildcards"], suffix="T1w.nii.gz"),
        depth = f"work/gifti/sub-{{subject}}/surf/{{hemi}}.depth-{{depth}}.{config['template']}{config['fs_den'][2:]}.surf.gii",
    params:
        sample_method = "trilinear"
    output:
        depth = f"work/gifti/sub-{{subject}}/metric/{{hemi}}.depth-{{depth}}.T1.{config['template']}{config['fs_den'][2:]}.shape.gii",
    container: config["singularity"]["workbench"]
    group: "subj"
    shell:
        "wb_command -volume-to-surface-mapping {input.t1} {input.depth} {output.depth} -{params.sample_method}"

rule gii_surf_datasink:
    """
    Datasink gifti surfaces
    """
    input: f"work/gifti/sub-{{subject}}/surf/{{hemi}}.{{surf_suffix}}.{config['template']}{config['fs_den'][2:]}.surf.gii"
    output: f"result/sub-{{subject}}/gifti/surf/sub-{{subject}}_space-{config['template']}_hemi-{{hemi,(lh|rh)}}_den-{config['fs_den'][2:]}_{{surf_suffix,(pial|white|inflated)}}.surf.gii"
    shell: 
        "cp {input} {output}"

rule gii_thickness_datasink:
    """
    Datasink gifti thickness
    """
    input: f"work/gifti/sub-{{subject}}/metric/{{hemi}}.thickness.{config['template']}{config['fs_den'][2:]}.shape.gii"
    output: f"result/sub-{{subject}}/gifti/metric/sub-{{subject}}_space-{config['template']}_hemi-{{hemi,(lh|rh)}}_den-{config['fs_den'][2:]}_thickness.shape.gii"
    shell:
        "cp {input} {output}"

rule gii_depth_sample_datasink:
    """
    Datasink sampled depth
    """
    input: f"work/gifti/sub-{{subject}}/metric/{{hemi}}.depth-{{depth}}.T1.{config['template']}{config['fs_den'][2:]}.shape.gii"
    output: f"result/sub-{{subject}}/gifti/metric/sub-{{subject}}_space-{config['template']}_hemi-{{hemi,(lh|rh)}}_den-{config['fs_den'][2:]}_depth-{{depth}}_T1w.shape.gii"
    shell:
        "cp {input} {output}"

rule qc_surf:
    """
    Create visualization to QC generated white and pial surfaces
    """
    input:
        scene_template = os.path.join(config["snakemake_dir"], config["wb_scenes"]["surf_qc"]),
        lh_pial = f"work/gifti/sub-{{subject}}/surf/lh.pial.{config['template']}{config['fs_den'][2:]}.surf.gii",
        lh_white = f"work/gifti/sub-{{subject}}/surf/lh.white.{config['template']}{config['fs_den'][2:]}.surf.gii",
        rh_pial = f"work/gifti/sub-{{subject}}/surf/rh.pial.{config['template']}{config['fs_den'][2:]}.surf.gii",
        rh_white = f"work/gifti/sub-{{subject}}/surf/rh.white.{config['template']}{config['fs_den'][2:]}.surf.gii",
        t1 = bids(root="work/preproc_t1", datatype="anat", space=config['template'], **config["subj_wildcards"], suffix="T1w.nii.gz")
    params:
        workbench = config["singularity"]["workbench"]
    output: 
        report = report(bids(root="result", datatype="qc", space=config['template'], **config['subj_wildcards'], suffix='surfqc.svg'), caption='../report/surf_template_qc.rst', category='Surface ribbons')
    group: "subj"
    threads: workflow.cores
    script: "../scripts/viz_surfqc.py"