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
        depths = expand("work/gifti/sub-{{subject}}/metric/{hemi}.depth-{depth}.T1.scanner.shape.gii", hemi=["lh", "rh"], depth=config["sample_depths"]),
        inflated = expand("work/gifti/sub-{{subject}}/surf/{hemi}.inflated.scanner.surf.gii", hemi=["lh", "rh"]),
        thickness = expand("work/gifti/sub-{{subject}}/surf/{hemi}.thickness.scanner.shape.gii", hemi=["lh", "rh"])
    output: get_work_zip()
    group: "subj"
    shell:
        "echo Hello world"
        # "zip -Z store -ru {output} work/*/sub-{wildcards.subject} && rm -rf work/*/sub-{wildcards.subject}"