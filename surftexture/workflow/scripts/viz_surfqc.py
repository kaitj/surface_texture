from nilearn.plotting import plot_anat
import matplotlib

matplotlib.use("Agg")

overlay = plot_anat(snakemake.input.t1, display_mode="mosaic", cut_coords=5, dim=-1)
overlay.add_contours(snakemake.input.lh_white, colors="b", linewidths=1)
overlay.add_contours(snakemake.input.rh_white, colors="b", linewidths=1)
overlay.add_contours(snakemake.input.lh_pial, colors="r", linewidths=1)
overlay.add_contours(snakemake.input.rh_pial, colors="r", linewidths=1)
overlay.savefig(snakemake.output.report)
overlay.close()