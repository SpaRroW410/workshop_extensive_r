#!/bin/bash
# cloud_setup.sh — install R, the workshop's R packages and Quarto in a Claude Code cloud session (Ubuntu 24.04).
# Use as the environment's Setup script:   bash scripts/cloud_setup.sh
# (GitHub release downloads are blocked there, so Quarto comes from PyPI; R packages are Posit binaries.)
set -e
export DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 LC_ALL=C.UTF-8
apt-get update -qq
apt-get install -y -qq r-base-core r-base-dev pandoc libcurl4-openssl-dev libssl-dev libxml2-dev \
  libfontconfig1-dev libharfbuzz-dev libfribidi-dev libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev \
  libudunits2-dev libgdal-dev libgeos-dev libproj-dev libsqlite3-dev >/dev/null
cat > /etc/R/Rprofile.site <<'RP'
options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/noble/latest"), Ncpus = 4,
        HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(), paste(getRversion(), R.version["platform"], R.version["arch"], R.version["os"])))
RP
Rscript -e 'pk <- c("tidyverse","gtsummary","broom","performance","see","car","lmtest","pROC","jsonlite","yaml","sandwich","knitr","rmarkdown","janitor","readxl","haven","flextable","gt","patchwork","plotly","DT","kableExtra","survival","broom.helpers","cardx","parameters","effectsize","here","glue","scales","naniar","skimr","sf","spdep","spatialreg","tmap","leaflet","classInt","units","terra","smerc","ggsurvfit","survminer","cmprsk","tidycmprsk","ggspatial","leafsync","stars","lwgeom"); install.packages(setdiff(pk, rownames(installed.packages())))'
pip install -q quarto-cli
grep -q "LANG=C.UTF-8" /etc/environment || echo "LANG=C.UTF-8" >> /etc/environment
echo "R $(Rscript -e 'cat(as.character(getRversion()))') · Quarto $(quarto --version)"
