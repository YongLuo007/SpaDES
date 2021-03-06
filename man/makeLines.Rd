% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in R/plotting-helpers.R
\docType{methods}
\name{makeLines}
\alias{makeLines}
\alias{makeLines,SpatialPoints,SpatialPoints-method}
\title{Make \code{SpatialLines} object from two \code{SpatialPoints} objects}
\usage{
makeLines(from, to)

\S4method{makeLines}{SpatialPoints,SpatialPoints}(from, to)
}
\arguments{
\item{from}{Starting spatial coordinates (\code{SpatialPointsDataFrame}).}

\item{to}{Ending spatial coordinates (\code{SpatialPointsDataFrame}).}
}
\value{
A \code{SpatialLines} object. When this object is used within a
        \code{Plot} call and the \code{length} argument is specified, then
        arrow heads will be drawn. See examples.
}
\description{
The primary conceived usage of this is to draw arrows following the
trajectories of agents.
}
\examples{
library(sp)
# Make 2 objects
caribou1 <- SpatialPoints(cbind(x=stats::runif(10, -50, 50), y=stats::runif(10, -50, 50)))
caribou2 <- SpatialPoints(cbind(x=stats::runif(10, -50, 50), y=stats::runif(10, -50, 50)))

caribouTraj <- makeLines(caribou1, caribou2)
Plot(caribouTraj, new=TRUE, length=0.1)

# or  to a previous Plot
\dontrun{
filelist <- data.frame(files =
     dir(file.path(find.package("SpaDES",
                                lib.loc=getOption("devtools.path"),
                                quiet=FALSE),
                  "maps"),
        full.names=TRUE, pattern= "tif"),
     functions="rasterToMemory",
     packages="SpaDES")

# Load files to memory (using rasterToMemory)
sim1 <- loadFiles(filelist=filelist)

Plot(sim1$DEM, new=TRUE)
caribouTraj <- makeLines(caribou1, caribou2)
Plot(caribouTraj, addTo="sim1$DEM", length=0.1)
}
}
\author{
Eliot McIntire
}

