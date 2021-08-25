# Look-up tables
hemi_struct_lut = {"lh": "CORTEX_LEFT", "rh": "CORTEX_RIGHT"}

# Expand lists
surf_suffix = ["pial", "white", "inflated"]

# Rules
rule fs_to_gii:
    """ Convert FS surfaces to gifti """
    input: 
        lh_surf = expand("work/fastsurfer/sub-{{subject}}/surf/lh.{surf_suffix}", surf_suffix=surf_suffix),
        rh_surf = expand("work/fastsurfer/sub-{{subject}}/surf/rh.{surf_suffix}", surf_suffix=surf_suffix)
    params:
        fastsurfer = config["singularity"]["fastsurfer"]
    output: 
        out_dir = directory("work/gifti/sub-{subject}"),
        lh_surf = expand("work/gifti/sub-{{subject}}/surf/lh.{surf_suffix}", surf_suffix=surf_suffix),
        rh_surf = expand("work/gifti/sub-{{subject}}/surf/rh.{surf_suffix}", surf_suffix=surf_suffix)
    group: "subj"
    run: 
        for idx in range(len(input.lh_surf)):
            os.system(f"singularity exec {params.fastsurfer} mris_convert {input.lh_surf[idx]} {output.lh_surf[idx]}")
            os.system(f"singularity exec {params.fastsurfer} mris_convert {input.rh_surf[idx]} {output.rh_surf[idx]}")