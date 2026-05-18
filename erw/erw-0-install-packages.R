
# ------------------------------------------------------------------------------
# erw-0-install-packages.R
#
# Bootstrap R dependencies for the standalone ERW pipeline. Run once on a fresh
# machine before any other erw-*.R script.
# ------------------------------------------------------------------------------

install.packages('terra')
install.packages('geodata')
install.packages('here')     # project-relative paths anchored by the repo .here marker
remotes::install_github("gaiafrica/limer")
install.packages('Recocrop')

# extras used by the ERW economics + Bayesian arm
install.packages('brms')      # used by erw-yield-fit / erw-yield-predict
install.packages('readxl')    # used by erw-4-crop-parameters
install.packages('reshape2')  # used by erw-4-crop-parameters (figure)
install.packages('viridis')   # used by erw-4-crop-parameters (figure)

# optional, only needed if you let erw-basalt-access pull the MAP friction surface
# install.packages('malariaAtlas')
