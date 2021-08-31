from nilearn.plotting import plot_anat
import matplotlib

matplotlib.use("Agg")

overlay = plot_anat(snakemake.input.t1, display_mode="ortho", dim=-1)
overlay.add_contours(snakemake.input.ref, colors="r")
overlay.savefig(snakemake.output.report)
overlay.close()