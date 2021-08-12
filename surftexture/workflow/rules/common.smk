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
    """ Create zip archive of work directory """ 
    input: "work/fastsurfer/sub-{subject}"
    params:
        work_dir = lambda wildcards, input: os.path.dirname({input})[0]
    output: get_work_zip()
    group: "subj"
    shell: 
        "zip -Z store -ru {output} {params.work_dir} && rm -rf {params.work_dir}"