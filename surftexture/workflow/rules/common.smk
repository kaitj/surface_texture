import glob

# Functions
def get_anat_result():
"""
Gather final anat outputs
"""
    anat = [] 

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
    """ 
    Create zip archive of work directory (point to last step) 
    """ 
    input: 
        depths = expand("work/gifti/sub-{{subject}}/metric/{hemi}.depth-{depth}.T1." + f"{config['template']}32k.shape.gii", hemi=["lh", "rh"], depth=config["sample_depths"]),
        thickness = expand("work/gifti/sub-{{subject}}/metric/{hemi}.thickness." + f"{config['template']}32k.shape.gii", hemi=["lh", "rh"]),
        # Files below this line do not get used elsewhere
        inflated = expand("work/gifti/sub-{{subject}}/surf/{hemi}.inflated." + f"{config['template']}32k.surf.gii", hemi=["lh", "rh"]),
        # t1_qc = report(bids(root='work/qc', **config['subj_wildcards'], suffix='regqc.svg', from_='subject', to=config['template']), caption='../report/t1w_template_regqc.rst', category='T1w to Template Registration QC')
    output: get_work_zip()
    group: "subj"
    shell:
        "echo Hello world"
        # "zip -Z store -ru {output} work/*/sub-{wildcards.subject}" # && rm -rf work/*/sub-{wildcards.subject}"