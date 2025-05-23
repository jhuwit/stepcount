% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/use_stepcount_condaenv.R
\name{use_stepcount_condaenv}
\alias{use_stepcount_condaenv}
\alias{conda_create_stepcount}
\alias{unset_reticulate_python}
\alias{have_stepcount_condaenv}
\title{Use Conda Environment for \code{stepcount}}
\usage{
use_stepcount_condaenv(envname = "stepcount", ...)

conda_create_stepcount(envname = "stepcount", ..., python_version = "3.9")

unset_reticulate_python()

have_stepcount_condaenv()
}
\arguments{
\item{envname}{environment name for the conda environment}

\item{...}{additional arguments to pass to \code{\link[reticulate:use_python]{reticulate::use_condaenv()}}
other than \code{condaenv}.}

\item{python_version}{version of Python to use for environment}
}
\value{
Nothing
}
\description{
Use Conda Environment for \code{stepcount}
}
