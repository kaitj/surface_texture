import glob

# Functions
def get_result_outputs(wildcards):
    """
    Gather all results; is trigger to run all other rules 
    """
    result_output = []
    result_output.extend(list(glob.iglob(f"result/{wildcards.subject}/**/*")))

    return result_output


def get_work_zip(): 
    """
    Zip work files 
    """
    return bids(root="work", suffix="work.zip", 
                include_subject_dir=False, include_session_dir=False, 
                **config['subj_wildcards'])


# Rules
rule archive_work:
    """ 
    Create zip archive of work directory (point to last step) 
    """ 
    input: get_result_outputs
    output: get_work_zip()
    group: "subj"
    shell:
        "echo Hello world"
        # "zip -Z store -ru {output} work/*/sub-{wildcards.subject}" # && rm -rf work/*/sub-{wildcards.subject}"