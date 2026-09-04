## Version: 01
## Date:    2026-09-04
## Author:  Pietro Coretto <pcoretto@unisa.it>
##          Luca Coraggio <luca.coraggio@unina.it>
##
## Description
##
##     Worked demonstration of the qcluster package: selection
##     among clustering solutions by held-out quadratic
##     scoring. Part I is a five-call recipe. Part II builds
##     candidate lists from sequences across several families,
##     wraps two methods the package does not implement,
##     screens the list, and goes through the three ranking
##     rules and the selection interface.
##
##     This file is GENERATED from demo.Rmd by make.R. Any
##     edit made here is lost at the next build; edit the
##     source instead.
##
##     Input:  none, the data ship with the package.
##     Output: printed summaries and plots, no file written.
##
##     Usage:
##
##         Rscript demo.R
##
##     or step through it in an interactive session.
##
## Requirements
##
##     R (>= 4.1), qcluster (>= 3.0.0) from CRAN, and mclust
##     for one section of Part II. Part II compares of the
##     order of a hundred and fifty candidates and takes
##     minutes rather than seconds: shorten the sequence KK to
##     speed it up.


## ----------------------------------------------------------------------------
## QCLUSTER: CLUSTERING SELECTION BY HELD-OUT QUADRATIC SCORING
## ----------------------------------------------------------------------------
##
## We demonstrate the use of the
## [`qcluster`](https://CRAN.R-project.org/package=qcluster) R package of
##
## - Luca Coraggio — [luca-coraggio.com](https://luca-coraggio.com) ·
##   [GitHub](https://github.com/LucaCoraggio)
##
## - Pietro Coretto —
##   [pietro-coretto.github.io](https://pietro-coretto.github.io) ·
##   [GitHub](https://github.com/pietro-coretto)
##
## The document has two parts:
##
## - **Part I**: basic use of the package.
##
## - **Part II**: for the reader who wants to control the details of the
##   methodology.
##
## Everything below runs on the `banknote` data that ship with the package, so
## the document is self-contained. The only external dependency is `mclust`,
## which one section of Part II uses to demonstrate how the user brings a
## method the package does not provide into a comparison.
##

##
library(qcluster)

## The number of parallel workers is deliberately small: we do not know
## what machine this runs on. Raise it on your own. The result does not
## depend on it, because every (method, split) task draws its own
## random-number substream, so a run is reproducible under set.seed()
## whatever the number of cores.
NCORES <- 2L

##
## ----------------------------------------------------------------------------
## The data
## ----------------------------------------------------------------------------
##
## Six measurements on two hundred old Swiss 1000-franc banknotes, one hundred
## genuine and one hundred counterfeit.
## We keep the class label aside: no procedure below ever sees it, and we read
## it only at the very end to look at what the selection found.
##
data("banknote")

dat <- banknote[-1]     ## the six features
cl0 <- banknote$Class   ## reference classes, held out of the analysis

table(cl0)

##
## ----------------------------------------------------------------------------
## PART I — THE SHORT RECIPE
## ----------------------------------------------------------------------------
##
## The entry point is `qcluster()`. It takes the data and a *method set*, an
## object listing the candidates to compare, and returns them scored and
## ranked.
##
## ----------------------------------------------------------------------------
## Set the list of candidates for the selection
## ----------------------------------------------------------------------------
##
## `mset_gmix()` builds a method set of Gaussian mixture models. Here we have
## five numbers of groups crossed with two settings of the eigenvalue ratio
## constraint, so ten candidates in all. The constraint, `erc`, is the largest
## ratio allowed between eigenvalues of the fitted cluster scatter matrices.
## This constraint is a model hyper-parameter that regularizes the MLE and
## affects the geometry of the final clusters.
## At `erc = 1` the constraint forces the clusters to be spherical and
## identical in size; at `erc = 100` they may differ considerably in volume
## and elongation. It is a complexity knob, and it is exactly the kind of
## tuning that a selection criterion should settle.
##
M0 <- mset_gmix(K = 1:5, erc = c(1, 100))

M0

##
## ----------------------------------------------------------------------------
## Validation
## ----------------------------------------------------------------------------
##
set.seed(20260903)

val0 <- qcluster(dat, M0, B = 50, ncores = NCORES)

##
## `B` is the number of splits. Everything else stays at its default: the
## smooth score, a training fraction of one half, and the ranking that
## maximizes the held-out mean.
##
## ----------------------------------------------------------------------------
## Reading the table
## ----------------------------------------------------------------------------
##
val0

##
## One row per candidate, in rank order.
##
## - `mean` is the criterion, the average held-out score.
## - `sterr` describes how much that average moves when the training
##   observations change; it is not the standard error of a mean over `B` and
##   it is not a confidence half-width, so read it across candidates rather
##   than on its own.
## - `lower` and `upper` are the lower and the upper percentile bound of the
##   split distribution.
## - `complexity` is the gap between the score a candidate gives itself on its
##   own training block and the score it earns on the held-out block, that is
##   how much it flatters itself; `crank` orders the candidates by complexity,
##   `1` being the simplest.
## - `na_prop` is the fraction of splits on which the candidate failed to
##   produce a usable fit.
##
## ----------------------------------------------------------------------------
## The picture
## ----------------------------------------------------------------------------
##
plot(val0)

##
## ----------------------------------------------------------------------------
## Selecting and fitting
## ----------------------------------------------------------------------------
##
## The scored object holds no fitted models. `qcluster_select()` takes the
## rank-one candidate and re-estimates it on the whole data set.
##
fit0 <- qcluster_select(val0)

fit0

##
## ----------------------------------------------------------------------------
## Looking at the solution
## ----------------------------------------------------------------------------
##
## The returned object is the native fit of whatever method won, so the usual
## methods apply to it.
##
plot(fit0, data = dat, subset = c(4, 5, 6),
     what = c("clustering", "contour"))

##
## And now, only now, the labels that we kept aside:
##
table(cl0, fit0$cluster)

##
## ----------------------------------------------------------------------------
## What comes next
## ----------------------------------------------------------------------------
##
## That is the whole of the basic use. The point of the approach is that the
## comparison need not be homogeneous at all. Part II builds candidate lists
## from sequences of tuning values across several families at once, brings in
## two methods the package does not implement, reduces the resulting list
## before spending computing time on it, and then goes through the three
## ranking rules and the selection interface one at a time.
##
## ----------------------------------------------------------------------------
## PART II — CONTROLLING THE DETAILS
## ----------------------------------------------------------------------------
##
## A warning on running time before anything else. Part II compares of the
## order of a hundred and fifty candidates, twice: once cheaply, to discard
## the hopeless ones, and once properly on what survives. On a modest machine
## this is minutes rather than seconds.
## Shorten `KK` below if you only want to see the mechanics.
##
## ----------------------------------------------------------------------------
## What the score can and cannot rank
## ----------------------------------------------------------------------------
##
## The quadratic score is not a general-purpose cluster validation index, and
## treating it as one is the one way to misuse it. It scores a clustering
## through the quadratic discriminant function evaluated at the cluster
## description: proportions, centers, and covariance matrices. The groups it
## can recognize and rank are therefore groups that quadratic boundaries
## separate well (linear boundaries being the special case in which the
## scatters agree). This is a real class, and a broad one: it covers
## elliptical groups of different volume, shape and orientation that various
## methods can discover (model-based clustering based on elliptical models,
## k-means and other partitioning methods based on an appropriate
## dissimilarity notion). It does not cover groups defined by connectivity or
## by any notion under which a cluster is not a location-and-scatter object: a
## ring around a blob is two clusters to a density-based method and one badly
## fitted ellipse to this score.
##
## The practical consequence for the rest of this section is a rule about
## which methods it is legitimate to put into a comparison. The user can wrap
## any clustering method and pass it to `qcluster()`, and `qcluster()` scores
## it without complaint. Whether the resulting number means anything depends
## on whether the method pursues a notion of cluster compatible with the one
## the score encodes. Comparing a Gaussian mixture, a k-means partition and a
## Ward dendrogram cut is legitimate, because all three can discover similar
## kinds of objects. In what follows we give a couple of examples.
##
## ----------------------------------------------------------------------------
## Candidate families from sequences with package pre-built constructors
## ----------------------------------------------------------------------------
##
## The `mset_*` constructors expand every argument they are given into a grid:
## one candidate per combination of values. This is what makes it cheap to
## state a comparison as a set of sequences rather than as a list of models.
##
## number of clusters from 1 to 10
KK <- 1:10

## GAUSSIAN MIXTURES: 10 values of K, 3 ERC constraint levels
GMIX <- mset_gmix(K = KK, erc = c(1, 100, 1000))

## STUDENT-T MIXTURES, 10 values of K, 3 ERC constraint levels, 2 fixed
## degrees of freedom
TMIX <- mset_tmix(K = KK, erc = c(1, 100, 1000), df = c(4, 15))

## KMEANS: a partitioning method, it estimates no scatter, and yet it is scorable
## The closures generated by the constructor generates cluster description from the
## returned partition, through clust2params()
KMNS <- mset_kmeans(K = KK)

##
## ----------------------------------------------------------------------------
## Set methods that the package does not provide
## ----------------------------------------------------------------------------
##
## The user can work with any method of choice using the constructor
## `mset_user()`. This is the general constructor of which all the others are
## specializations. It takes the *name* of a prototype function and expands
## the arguments passed through `...` into one candidate per combination,
## exactly as above. The prototype must take `data` as its first argument and
## must return a list carrying a `params` component with `proportion` (length
## K), `mean` (P by K), and `cov` (P by P by K).
##
## The construction requires two things:
##
## - a function wrapper so that, for a fixed candidate, the method is able to
##   output a cluster description with a list containing: `proportion` ,
##   `mean`, `cov`, and cluster labels. The function wrapper can take any
##   input and output, the only requirement is the previous cluster
##   description;
##
## - the construction of the list of candidates via `mset_user()`.
##
## We explore two cases:
##
## - a case where the method/algorithm does not _naturally_ provide the
##   cluster parametric description;
## - a case where the method/algorithm already provides the description.
##
## ----------------------------------------------------------------------------
## CASE 1: the method that returns labels only
## ----------------------------------------------------------------------------
##
## Hierarchical clustering returns a tree; cutting it returns labels and
## nothing else. `clust2params()` supplies the rest. One can question whether
## this method can produce adequate "quadratic partitions", however here we
## wanto to only show the flexibility of the following constructor.
##
## The following function wrapper provides the cluster description via its
## output object `res`. The parametric description is filled using
## `clust2params()`. The follosing call to `mset_user()` constructs the list
## of candidates. In this case we want to validate over number of clusters and
## linkage, for which we consider `method = c("ward.D2", "complete")`.  An
## important argument here is `method_name`, it creates a meaninful codename
## by which a candidate is addressed and printed in the outputs. In absence of
## specified `method_name`, `mset_user()` will guess one.  `.export` names the
## objects needed by the parallel workers in parallel executions.
##
## method's wrapper
hc_wrapper <- function(data, K, ...) {
    ## Description
    ##     Prototype wrapper exposing stats::hclust() to mset_user(), by
    ##     cutting the tree at K groups and attaching the cluster
    ##     description the score consumes.
    ##
    ## Syntax
    ##     hc_wrapper(data, K, ...)
    ##
    ## Arguments
    ##     data  numeric matrix or data frame of observations
    ##     K     number of groups at which the tree is cut
    ##     ...   further arguments passed to hclust(), typically the
    ##           agglomeration 'method'
    ##
    ## Example
    ##     hc_wrapper(banknote[-1], K = 2, method = "ward.D2")
    ##
    dm <- dist(data, method = "euclidean")
    hc <- hclust(dm, ...)
    cl <- cutree(hc, k = K)

    res         <- list()
    res$cluster <- cl
    res$params  <- clust2params(data, cluster = cl)
    return(res)
}

## construnction of the candidates' list
HCL <- mset_user(fname = "hc_wrapper",
                 K = KK,
                 method = c("ward.D2", "complete"),
                 method_name = function(K, method) {
                     paste0("hc_", method, "_K", K)
                 },
                 .export = "hc_wrapper")

length(HCL)

##
## ----------------------------------------------------------------------------
## CASE 2: a method that already carries the description (size, mean, cov)
## ----------------------------------------------------------------------------
##
## `mclust` fits Gaussian mixtures, so the parameters are in the fitted object
## already and only need to be renamed into the layout the score expects. In
## this case we want to validate mclust models with varying `K` and covariance
## models "EEI", "VVI", and "VVV". The wrapping function only needs to
## translate the mclust's output into the desired description object returned
## by the wrapper. The following constructor in this case needs an additional
## input: `.packages`.  The argument '.packages' is the mechanism for a
## prototype whose dependencies are not visible on a parallel worker, whose
## environment does not inherit the current one. Here it also has to *attach*
## mclust rather than merely load its namespace, because Mclust resolves some
## of its own internals by bare name.
##
library(mclust)
## function wrapper
mc_wrapper <- function(data, K, ...) {
    ## Description
    ##     Prototype wrapper exposing mclust::Mclust() to mset_user(), by
    ##     relabelling the fitted parameters into the layout qcluster
    ##     expects.
    ##
    ## Syntax
    ##     mc_wrapper(data, K, ...)
    ##
    ## Arguments
    ##     data  numeric matrix or data frame of observations
    ##     K     number of mixture components
    ##     ...   further arguments passed to mclust::Mclust(), typically
    ##           'modelNames'
    ##
    ## Example
    ##     mc_wrapper(banknote[-1], K = 2, modelNames = "VVV")
    y <- mclust::Mclust(data, G = K, ...)

    y[["cluster"]] <- y[["classification"]]
    y[["params"]]  <- list(proportion = y$parameters$pro,
                           mean       = y$parameters$mean,
                           cov        = y$parameters$variance$sigma)
    return(y)
}

## construnction of the candidates' list
MCL <- mset_user(fname = "mc_wrapper",
                 K = KK,
                 modelNames = c("EEI", "VVI", "VVV"),
                 method_name = function(K, modelNames) {
                     paste0("mcl_", modelNames, "_K", K)
                 },
                 .packages = "mclust",
                 .export = "mc_wrapper")

length(MCL)

##
## ----------------------------------------------------------------------------
## Using the method list
## ----------------------------------------------------------------------------
##
## A method set is a list of ready-to-run clustering setups, and it can be
## inspected and executed as such.
##
## the compact table: index, codename, base routine, and only the
## arguments that actually vary within each routine group
print(HCL)

## the codenames are what every other function matches against
head(names(GMIX))

## everything about one candidate, addressed by position or by codename
summary(GMIX, id = 1)
summary(GMIX, method_name = names(GMIX)[4])

## Each element carries the closure that runs it, so a candidate can be fitted
## directly, and asked for the cluster description alone.
##
mm <- MCL[["mcl_VVV_K3"]]
mm

fit_mc <- mm$fn(dat)
class(fit_mc)

## only the cluster description, which is the form the scoring engine uses
str(mm$fn(dat, only_params = TRUE))

##
## However, `apply_method()` does the same through the set rather than through
## the element, and returns the fit with a rendered description of the method
## attached, so that it can say later what it is. Here we easily put together
## 150 candidates.
##
fit_hc <- apply_method(dat, HCL, method_name = "hc_ward.D2_K2")
fit_hc

##
## ----------------------------------------------------------------------------
## Combining the candidates' list
## ----------------------------------------------------------------------------
##
## `mbind()` concatenates method sets without touching them.
##
MLIST <- mbind(GMIX, TMIX, KMNS, HCL, MCL)

length(MLIST)

##
## ----------------------------------------------------------------------------
## The three settings that matter for the held-out validation
## ----------------------------------------------------------------------------
##
## **The training fraction, `sprop`.** It fixes the size of the training
## block, the validation block getting the rest. The default is `0.5`, chosen
## on theoretical and experimental grounds. The two things it trades off are
## that a larger training fraction fits every candidate closer to what it
## would be on the full data, and a smaller one leaves more observations to
## score on and so a less noisy evaluation.
## Pushed to either extreme it degrades: near one the validation block is too
## small for the held-out score to mean much, and near zero every candidate is
## fitted on so little data that the comparison is about small-sample behavior
## rather than about the models.
## There is a band of values over which the selection is stable, and one half
## sits in the middle of it.
##
## **The number of splits, `B`.** More is better and the only cost is time.
## For a screening pass, `50` is an acceptable floor. For a final comparison
## on a list that has already been shortened, `B=1000` is a good benchmark; in
## our experience `B=250` has always been enough. The rules differ in how much
## they need: the percentile bounds, and the ranking that reads them, are the
## part a short resample cannot pin down, whereas the dispersion-band rule is
## comparatively stable at small `B`. The numbers used below are smaller than
## any of this, for a demonstration that has to finish.
##
## **The seed.** Set it wherever the function argument exists, and set
## `set.seed()` where it does not. `mset_screen()` takes a `seed`;
## `qcluster()` does not, and reads the ambient generator. The reproducibility
## is not conditional on the number of cores in either case.
##
## ----------------------------------------------------------------------------
## Screening a large set
## ----------------------------------------------------------------------------
##
## Running a validation on 150 candidates at a serious `B` is wasteful,
## because most of them are not competitive and it does not take much evidence
## to establish it. `mset_screen()` removes them in two steps.
##
## Step one is deterministic and does not resample: every candidate is fitted
## once on the full data and dropped if it fails, if it returns fewer groups
## than it declared, if a group is smaller than the data dimension allows, if
## a scatter matrix is singular, or if the score comes back non-finite. Step
## two is a short paired held-out run on the survivors, all scored on the same
## splits, keeping every candidate whose held-out mean sits within `delta`
## reported dispersions of the best.
##
## That second step is the parsimonious rule of the selection stage, used as a
## filter instead of as a decision. The rule that will make the final choice
## admits a band around the held-out maximizer; screening with a *wider* band
## than the selection will use guarantees that the screen throws away nothing
## the selection would have admitted.
## Hence the default `delta = 2` here against `delta = 1` in `qcluster()`: two
## is wide enough for the containment to hold under all three ranking rules
## and not only under the band rule itself. The guarantee holds for a screen
## and a selection that agree on data, seed, `B` and `sprop`; run cheaper, as
## below, and the screen becomes what it was designed to be, a filter that
## keeps the competitive candidates with high probability. One thing it does
## not do is correct for the multiplicity of comparing every candidate against
## the best, so `delta` should be raised on long lists.
##
SCR <- mset_screen(MLIST, data = dat, B = 25, delta = 2,
                   seed = 1234, ncores = NCORES)

SCR

length(SCR)

##
## The report has one row per candidate that went in, with what happened to
## it.
##
rep <- attr(SCR, "screen_report")

table(rep$status)
table(rep$retained)

head(rep[, c("method", "status", "mean", "distance", "band", "retained")], 10)

##
## What comes out is an ordinary method set, and it goes downstream unchanged.
##
## ----------------------------------------------------------------------------
## The validation run
## ----------------------------------------------------------------------------
##
set.seed(1234)
VAL <- qcluster(dat, SCR, B = 100, type = "both", ncores = NCORES)

VAL

##
## `type = "both"` computes the hard and the smooth score. They are two
## readings of the same cluster description: the hard score assigns each point
## to its highest-scoring component and adds up what that component gives it,
## the smooth score weights every component by its posterior share. Neither
## dominates the other, and where they disagree the disagreement is
## informative.
##
plot(VAL, nmax = 25)

##
## ----------------------------------------------------------------------------
## Re-ranking
## ----------------------------------------------------------------------------
##
## The ranking is a view over the summaries, and `qcluster_rank()` changes it
## without recomputing anything. There are three rules.
##
## - `"mean"` maximizes the held-out criterion.
##
## - `"lpb"` maximizes the lower percentile bound, preferring a candidate that
##   is stable across splits to one that is higher on average and erratic;
##   `prob` is the one-sided tail probability that locates the bound, and the
##   bounds are centred percentiles of the split distribution, not Wald
##   limits, so no normal-theory reading applies to them.
##
## - `"se"` is the parsimonious rule: it admits every candidate within `delta`
##   dispersions of the held-out maximizer and takes the least complex of
##   them, complexity is the apparent-minus-held-out gap.
##
## the lower percentile bound
val_lpb <- qcluster_rank(VAL, rankby = "lpb", prob = 0.10)

val_lpb

##
## the parsimonious rule
val_se <- qcluster_rank(VAL, rankby = "se", delta = 1)

print(val_se, max_raw = "selected")

##
## the same rule read on the other score component only
val_hard <- qcluster_rank(VAL, rankby = "mean", type = "hard")

val_hard

##
## ----------------------------------------------------------------------------
## What re-ranking cannot do
## ----------------------------------------------------------------------------
##
## Two remarks. A `prob` override recomputes the bounds from the raw per-split
## scores, so it needs them; a `delta` override reads only the stored summary
## and works on anything.
##
noraw <- qcluster(dat, mset_gmix(K = 2:4), B = 20,
                  ncores = NCORES, save_scores = FALSE)

## fine: the band rule needs mean, sterr and the complexity rank, all
## stored in the summary
qcluster_rank(noraw, rankby = "se", delta = 1)

## not fine: there are no raw scores to recompute the bounds from
try(qcluster_rank(noraw, rankby = "lpb", prob = 0.10))

##
## And a component that was never computed cannot be ranked.
##
hardonly <- qcluster(dat, mset_gmix(K = 2:4), B = 20,
                     type = "hard", ncores = NCORES)

try(qcluster_rank(hardonly, type = "smooth", rankby = "mean"))

##
## ----------------------------------------------------------------------------
## Selection
## ----------------------------------------------------------------------------
##
## `qcluster_select()` refits a candidate referenced by the scored object,
## always on the full data. When both score components are present the choice
## between them is the analyst's, and the function refuses to guess.
##
try(qcluster_select(VAL))

##
## naming the component is enough: the ranking already stored in VAL is
## used as it stands
best_s <- qcluster_select(VAL, type = "smooth")
best_s

best_h <- qcluster_select(VAL, type = "hard")
best_h

##
## The analyst can also change the ranking on the fly, for the purpose of one
## selection and without touching the scored object.
##
alt <- qcluster_select(VAL, type = "smooth", rankby = "se", delta = 1)
alt

##
## One can ask for any rank, not only the first, which is how one looks at
## what came close.
##
third <- qcluster_select(VAL, type = "smooth", rank = 3)
third

##
## Giving an index or a codename addresses a candidate directly and ignores
## the ranking altogether.
##
byname <- qcluster_select(VAL, method_name = names(VAL$method_set)[1])
byname

##
## Selection runs on the direct output of `qcluster()` and on nothing else. A
## re-ranked object is a display: it carries the summaries and the ordering,
## and deliberately not the raw scores nor the data, so it cannot refit and
## says so.
##
try(qcluster_select(val_se))

##
## ----------------------------------------------------------------------------
## The selected solution
## ----------------------------------------------------------------------------
##
## The object returned is the native fit of whichever method won.
## `plot_clustering()` takes the assignment and the cluster description rather
## than a fit of a particular class.
##
plot_clustering(dat, subset = c(4, 5, 6),
                cluster = best_s$cluster,
                params  = best_s$params,
                what    = c("clustering", "contour", "boundary"))

##
## The shaded regions are the decision regions of the quadratic rule under the
## selected description: this is the partition of the feature space the score
## is reading, drawn on the two coordinates of each panel.
##
table(cl0, best_s$cluster)
table(cl0, best_h$cluster)

##
## ----------------------------------------------------------------------------
## REFERENCES
## ----------------------------------------------------------------------------
##
## Coraggio, L. and Coretto, P. (2023).
## Selecting the number of clusters, clustering models, and algorithms.
## A unifying approach based on the quadratic discriminant score.
## *Journal of Multivariate Analysis*, 196, 105181.
## [doi:10.1016/j.jmva.2023.105181](https://doi.org/10.1016/j.jmva.2023.105181)
##
## See the [README](README.md) for how to cite the package and this material.
##
## ----------------------------------------------------------------------------
## REPRODUCIBILITY
## ----------------------------------------------------------------------------
##
sessionInfo()

