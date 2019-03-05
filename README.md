
<!-- README.md is generated from README.Rmd. Please edit that file -->
Differential Binding (dbr)
==========================

Shanahan Group at UZH and Levitt TFBM data
------------------------------------------

<!-- [![Travis build status](https://travis-ci.org/chumbleycode/dbr.svg?branch=master)](https://travis-ci.org/chumbleycode/dbr) -->
[![AppVeyor build status](https://ci.appveyor.com/api/projects/status/github/chumbleycode/dbr?branch=master&svg=true)](https://ci.appveyor.com/project/chumbleycode/dbr)

The goal of dbr is to implicate some gene regulator as the upstream cause of differential RNA expression between differerent treatment groups. Colloquially, whether there is "differential binding" (DB) of the regulator over treatments. In practice, dbr asks whether the pattern of differential RNA expression over genes reflects (the binding-site availability of) some upstream regulator. Binding-site availability or "enrichment" just refers to the total count of binding sites found in the DNA of each gene, which is in turn derived from external genomic DNA.

The package is in development and is likely to change. It currently reimplements the important TeLiS method of Cole, which used a gene-set approach to infer DB. Our reimplementation incorporates the most up-to-date motif binding data. Additionally, our package provides new functionality that eschews the need to heuristically define a gene set, i.e. a set that is categorically "differentially expressed", before proceeding to DB analysis. Instead we simply regress gene-specific DE estimates on gene-specific binding-site counts over the entire relevant genome (the set of genes with at least one binding motif for at least one regulator). For computational convenience our regression approach currently avoids full multilevel modeling.

Installation
------------

You can install dbr with:

``` r
install.packages("devtools")
devtools::install_github("chumbleycode/dbr")
```

There are currently three TFBM matrices: utr1, exonic1, exonic\_utr1. Get more info for each via ?utr1, ?exonic1, etc.

A simple example.
-----------------

Here we infer DB from the data published by Cole et al. (2016). The question is whether a regulatory transcription factor is implicated in differential RNA expression following early-life stress exposure (child soldier or not).

DB analysis has two steps. First, estimate differential RNA expression across exposure groups. Here we use a linear model: the exposure must be a *single* column of "design" matrix X (dbr cannot currently handle treatments defined across multiple collumns, e.g. factors with many levels). Second, we infer dependence of this estimate (over genes) on the binding-site count.

#### Estimate DE

``` r
# Load packages
library(tidyverse)
library(limma)
library(dbr)

# Download open source data then specify gene-by-gene regression model
dat = GEOquery::getGEO("GSE77164")[[1]]

# Specify whole-genome regression of rna on design
y <- dat %>% Biobase::exprs()
X <-
  dat %>%
  Biobase::pData() %>%
  select(age = `age:ch1`,
         soldier = `childsoldier:ch1`,
         edu = `educationlevel:ch1`)
X     <- model.matrix(~ soldier + edu + age, data = X) 

# Estimate DE using standard limmma/edger pipeline. 
of_in <- "soldier1"
ttT <-
  lmFit(y, X) %>%
  eBayes %>%
  tidy_topTable(of_in = of_in)
```

#### Infer DB

This step can be achieved either by regression of differential expression on motif site count and/or by providing a gene-set of interest (aka TeLiS).

##### Regression approach

``` r
# REGRESS DE ESTIMATE ON MOTIF SITE COUNT FOR THE TRANSCRIPTION FACTOR "AR"
ttT %>%
  infer_db(which_tfbms = "AR") %>%
  extract_db
# For all known tfbms: beware multiplicity
ttT %>%
  infer_db %>%
  extract_db
```

##### Gene-set approach (see Cole et al)

This approach requires some heuristic to select a set of subgenes to categorically label as DE. For example, we can filter on uncorrected p.value, or logfc (not an inference). This subset is identified by the argument ttT\_sub to infer\_db(). ttT\_sub is just a scrict subset of the rows of our universe of genes, given in ttT above (e.g. the subset whose logFC, or uncorrect p value exceeds some heuristic value). The additional options blow indicate that we have select our prefered tfbm matrix "which\_matrix", tfbm hypothesis set "which\_tfbms", and methods (p\_npar, p\_par, which require tt\_sub be specified).

``` r
ttT %>%
  infer_db(ttT_sub        = filter(ttT, P.Value <= 0.05),
           which_matrix   = exonic1_utr1 ,
           which_tfbms    =  c("ALX3", "ALX4_TBX21", "AR") ,
           n_sim          = 10000) %>%
  extract_db(methods =  c("p_npar", "p_par")) 
```

##### More interesting TF sets

Recent literature has examined "a pre-specified set of TFs involved in inflammation (NF-kB and AP-1), IFN response (interferon-stimulated response elements; ISRE), SNS activity (CREB, which mediates SNS-induced b-adrenergic signaling), and glucocorticoid signaling (glucocorticoid receptor; GR)." In our nomenclature, "NF-kB" is is identified with NFKB1 or NFKB2. AP-1 is called JUN. ISRE is identified with set of tfs including IRF2, IRF3, IRF4, 5, 7, 8, 9. CREB identified with CREB3 or CREB3L1. GR is called NR3C1. This leaves us with 13 regulators plus one complex CEBPG::CREB3L1.

``` r
(immune_tfbms = stringr::str_subset(colnames(utr1), c("NFKB1|NFKB2|JUN|IRF2|IRF3|IRF4|IRF5|IRF7|IRF8|IRF9|CREB3|CREB3L1|NR3C1")))

ttT %>%
  infer_db(ttT_sub         = filter(ttT, P.Value <= 0.05),
            which_tfbms    = immune_tfbms,
            explicit_zeros = T) %>%
  extract_db
```
