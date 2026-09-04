<!-- Created: 03-09-2026 | Authors: Pietro Coretto and Luca Coraggio -->

THE QCLUSTER PACKAGE DEMO
=========================

CLUSTERING SELECTION BY HELD-OUT QUADRATIC SCORING
--------------------------------------------------

This repository demonstrates the use of the  [`qcluster`](https://CRAN.R-project.org/package=qcluster) R package of 

- Luca Coraggio — [luca-coraggio.com](https://luca-coraggio.com) · [GitHub](https://github.com/LucaCoraggio)

- Pietro Coretto — [pietro-coretto.github.io](https://pietro-coretto.github.io) · [GitHub](https://github.com/pietro-coretto)


## OVERVIEW 

[`qcluster`](https://CRAN.R-project.org/package=qcluster) is an R package that selects and validates clusterings whose groups can be separated by quadratic boundaries and described by three descriptors: size, center, and scatter. It is the right tool when the structure being looked for is  adequately described by mean and covariance parameters.  
The methodology  makes no promise to recover the "true" clusters, but  it searches for the configuration that is best represented by quadratic regions. Coraggio and Coretto (2023) show that this notion of cluster is coherent with generative models of the finite mixtures of elliptically-symmetric type, and that it satisfies certain  optimality criteria under sampling from Gaussian mixtures. Normality is nowhere assumed of the groups being scored: the criterion reads a fitted parametric description and asks how well it represents quadratic regions, not whether the data came from a Gaussian mixture. On the connection between the cluster concept behind `qcluster` and generative models see also Coretto and Hennig (2025).

Once the target notion of cluster is fixed, everything else becomes comparable. Partitions obtained from different methods and algorithms can be put side by side, and so can one method run under different hyperparameters: the number of groups, the scale constraints, the tolerances, the initialization, whatever the algorithm exposes. Each solution is reduced to its parametric description and evaluated by held-out validation.




## CONTENTS



- **[`demo.md`](demo.md)** — the walkthrough, with all code, output and figures.
  Read it here in the browser; nothing needs to be installed.

- **[`demo.R`](demo.R)** — the same session as a plain R script, ready to download and run. This R scipt requires the following installation
```r
install.packages("qcluster")
install.packages("mclust")   ## used by one section of Part II only
```


## CITING

The method:

```bibtex
@Article{Coraggio-Coretto-2023,
  author  = {Coraggio, Luca and Coretto, Pietro},
  title   = {Selecting the number of clusters, clustering models, and algorithms. {A} unifying approach based on the quadratic discriminant score},
  journal = {Journal of Multivariate Analysis},
  year    = {2023},
  volume  = {196},
  pages   = {105181},
  doi     = {10.1016/j.jmva.2023.105181}
}
```

The software:

```bibtex
@Manual{qcluster-v3,
  title  = {qcluster: Clustering via Quadratic Scoring},
  author = {Coraggio, Luca and Coretto, Pietro},
  year   = {2026},
  note   = {R package version 3.0.0},
  url    = {https://CRAN.R-project.org/package=qcluster},
  doi    = {10.32614/CRAN.package.qcluster}
}
```

The published entry is also returned by `citation("qcluster")`.

## LICENSE

GPL (>= 2), the license of the package this material demonstrates.
