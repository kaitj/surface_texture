# Functions
def get_result_outputs():
    """ Gather all results; is trigger to run all other rules """
    subj_output = get_work_zip()

    result_output = []
    result_output.extend(
        expand(
            subj_output,
            subject=config["subjects"],
            session=config["sessions"]
        )
    )

    return result_output


def get_work_zip(): 
    """ Zip work files """
    return bids(root="work", suffix="work.zip", 
                include_subject_dir=False, include_session_dir=False, 
                **config['subj_wildcards'])


# Rules
rule archive_work:
    """ Create zip archive of work directory (point to last step) """ 
    input: 
        # depths = expand("work/gifti/sub-{{subject}}/metric/rh.depth-{depths}.T1.shape.gii", depths=config["sample_depths"]),
        inflated = expand("work/gifti/sub-{{subject}}/surf/{hemi}.{surf_suffix}.scanner.surf.gii", hemi=["lh", "rh"], surf_suffix=["pial", "white", "inflated"]),
    output: get_work_zip()
    group: "subj"
    shell:
        "echo Hello world"
        # "zip -Z store -ru {output} work/*/sub-{wildcards.subject} && rm -rf work/*/sub-{wildcards.subject}"