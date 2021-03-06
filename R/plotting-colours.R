################################################################################
#' Get colours for plotting Raster* objects.
#'
#' @param object     A \code{Raster*} object.
#'
#' @return Returns a named list of colors.
#'
#' @export
#' @docType methods
#' @aliases getColours
#' @rdname getColors
#'
#' @seealso \code{\link{setColors<-}}, \code{\link[RColorBrewer]{brewer.pal}}
#'
#' @author Alex Chubaty
#'
setGeneric("getColors", function(object) {
  standardGeneric("getColors")
})

#' @rdname getColors
setMethod("getColors",
          signature="Raster",
          definition=function(object) {
            cols <- lapply(names(object), function(x) {
              as.character(object[[x]]@legend@colortable)
            })
            names(cols) <- names(object)
            return(cols)
})

################################################################################
#' Set colours for plotting Raster* objects.
#'
#' @param object     A \code{Raster*} object.
#'
#' @param ...   Additional arguments to \code{colorRampPalette}.
#'
#' @param n     An optional vector of values specifiying the number
#'              of levels from which to interpolate the color palette.
#'
#' @param value  Named list of hex color codes (e.g., from
#'               \code{RColorBrewer::brewer.pal}), corresponding to the names
#'               of RasterLayers in \code{x}.
#'
#' @return Returns a Raster with the \code{colortable} slot set to \code{values}.
#'
#' @export
#' @importFrom grDevices colorRampPalette
#' @docType methods
#' @aliases setColours
#' @rdname setColors
#'
#' @seealso \code{\link[RColorBrewer]{brewer.pal}},
#'          \code{\link[grDevices]{colorRampPalette}}.
#'
#' @author Alex Chubaty
#'
setGeneric("setColors<-",
           function(object, ..., n, value) {
             standardGeneric("setColors<-")
})

#' @rdname setColors
setReplaceMethod("setColors",
                 signature("RasterLayer", "numeric", "character"),
                 function(object, ..., n, value) {
                   pal <- colorRampPalette(value, alpha=TRUE, ...)
                   object@legend@colortable <- pal(n)
                   validObject(object)
                   return(object)
})

#' @rdname setColors
setReplaceMethod("setColors",
                 signature("RasterLayer", "missing", "character"),
                 function(object, ..., value) {
                   n <- round((maxValue(object)-minValue(object)))+1
                   pal <- colorRampPalette(value, alpha=TRUE, ...)
                   object@legend@colortable <- pal(n)
                   validObject(object)
                   return(object)
})

#' @rdname setColors
setReplaceMethod("setColors",
                 signature("Raster", "numeric", "list"),
                 function(object, ..., n, value) {
                   i <- which(names(object) %in% names(value))
                   for(x in names(object)[i]) {
                     setColors(object[[x]], ..., n=n) <- value[[x]]
                   }
                   validObject(object)
                   return(object)
})

#' @rdname setColors
setReplaceMethod("setColors",
                 signature("Raster", "missing", "list"),
                 function(object, ..., value) {
                   i <- which(names(object) %in% names(value))
                   for(x in names(object)[i]) {
                     setColors(object[[x]], ...) <- value[[x]]
                   }
                   validObject(object)
                   return(object)
})

################################################################################
#' Convert Raster to color matrix useable by raster function for plotting
#'
#' Internal function.
#'
#' @param grobToPlot   A \code{SpatialObject}.
#'
#' @param zoomExtent   An \code{Extent} object for zooming to.
#'                     Defaults to whole extent of \code{grobToPlot}.
#'
#' @param maxpixels    Numeric. Number of cells to subsample the complete
#'                     \code{grobToPlot}.
#'
#' @param legendRange  Numeric vector giving values that, representing the lower
#'                     and upper bounds of a legend (i.e., \code{1:10} or
#'                     \code{c(1,10)} will give same result) that will override
#'                     the data bounds contained within the \code{grobToPlot}.
#'
#' @param cols         Colours specified in a way that can be understood directly
#'                     or by \code{\link{colorRampPalette}}.
#'
#' @param na.color     Character string indicating the color for \code{NA} values.
#'                     Default transparent.
#'
#' @param zero.color   Character string indicating the color for zero values,
#'                     when zero is the minimum value.
#'                     Otherwise, it is treated as any other color.
#'                     Default transparent.
#'                     Use \code{NULL} if zero should be the value given to it
#'                     by the colortable associated with the Raster.
#'
#' @param skipSample   Logical. If no downsampling is necessary, skip.
#'                     Default \code{TRUE}.
#'
#' @rdname makeColorMatrix
#' @aliases makeColourMatrix
#' @include plotting-classes.R
#' @importFrom grDevices colorRampPalette terrain.colors
#' @importFrom raster minValue getValues sampleRegular
#' @importFrom stats na.omit
#' @docType methods
#' @author Eliot McIntire
#'
setGeneric(".makeColorMatrix",
           function(grobToPlot, zoomExtent, maxpixels, legendRange,
                    cols=NULL, na.color="#FFFFFF00", zero.color=NULL,
                    skipSample = TRUE) {
  standardGeneric(".makeColorMatrix")
})


#' @rdname makeColorMatrix
setMethod(
  ".makeColorMatrix",
  signature = c("Raster", "Extent", "numeric", "ANY"),
  definition = function(grobToPlot, zoomExtent, maxpixels, legendRange,
                        cols, na.color, zero.color, skipSample = TRUE) {
    zoom <- zoomExtent
    # It is 5x faster to access the min and max from the Raster than to
    # calculate it, but it is also often wrong... it is only metadata
    # on the raster, so it is possible that it is incorrect.
    if (!skipSample) {
      colorTable <- getColors(grobToPlot)[[1]]
      if (!is(try(minValue(grobToPlot)), "try-error")) {
        minz <- minValue(grobToPlot)
      }
      grobToPlot <- sampleRegular(
        x = grobToPlot, size = maxpixels,
        ext = zoom, asRaster = TRUE, useGDAL = TRUE
      )
      if (length(colorTable) > 0) {
        cols <- colorTable
      }
    }
    z <- getValues(grobToPlot)

    # If minValue is defined, then use it, otherwise, calculate them.
    #  This is different than maxz because of the sampleRegular.
    # If the low values in the raster are missed in the sampleRegular,
    #  then the legend will be off by as many as are missing at the bottom;
    #  so, use the metadata version of minValue, but use the max(z) to
    #  accomodate cases where there are too many legend values for the
    # number of raster values.
    if (!exists("minz")) {
      minz <- min(z, na.rm = TRUE)
    }
    if (is.na(minz)) {
      minz <- min(z, na.rm = TRUE)
    }
    #
    maxz <- max(z, na.rm = TRUE)
    real <- any(na.omit(z) %% 1 != 0) # Test for real values or not

    # Deal with colors - This gets all combinations, real vs. integers,
    #  with zero, with no zero, with NA, with no NA, not enough numbers,
    #  too many numbers
    maxNumCols <- 100

    nValues <- ifelse(real, maxNumCols + 1, maxz - minz + 1)
    colTable <- NULL

    if (is.null(cols)) {
      # i.e., contained within raster or nothing
      if (length(getColors(grobToPlot)[[1]]) > 0) {
        colTable <- getColors(grobToPlot)[[1]]
        lenColTable <- length(colTable)

        cols <- if (nValues > lenColTable) {
          # not enough colors, use colorRamp
          colorRampPalette(colTable)(nValues)
        } else if (nValues <= (lenColTable)) {
          # one more color than needed:
          #   assume bottom is NA
          colTable
        } else if (nValues <= (lenColTable - 1)) {
          # one more color than needed:
          #  assume bottom is NA
          na.color <- colTable[1]
          colTable[minz:maxz - minz + 2]
        } else if (nValues <= (lenColTable - 2)) {
          # two more colors than needed,
          #  assume bottom is NA, second is white
          na.color <- colTable[1]
          zero.color <- colTable[2]
          colTable[minz:maxz - minz + 3]
        } else {
          colTable
        }
      } else {
        # default color if nothing specified:
        cols <- rev(terrain.colors(nValues))
      }
    } else {
      cols <- if (nValues > length(cols)) {
        colorRampPalette(cols)(nValues)
      } else if (nValues < length(cols)) {
        cols[minz:maxz + max(0, 1 - minz)]
      } else {
        cols
      }
    }

    # Colors are indexed from 1, as with all objects in R, but there
    # are generally zero values on the rasters, so shift according to
    # the minValue value, if it is below 1.
    # Shift it by 2, 1 to make the zeros into two, the other for the
    # NAs to be ones.

    # If object is real numbers, the default above is to discretize.
    # This is particularly bad for numbers below 10.
    # Here, numbers below maxNumCols that are reals will be rescaled
    #  to max = 100.
    # These are, of course, only used for the color matrix, not the
    #  values on the Raster.
    if ((maxz <= maxNumCols) & real) {
      z <- maxNumCols / maxz * z
      # rescale so the minimum is 1, not <1:
      z <- z + (((maxNumCols / maxz * minz) < 1) *
                  (-(maxNumCols / maxz * minz) + 1))
    } else {
      # rescale so that the minimum is 1, not <1:
      z <- z + ((minz < 1) * (-minz + 1))
    }

    if (any(!is.na(legendRange))) {
      if ((max(legendRange) - min(legendRange) + 1) < length(cols)) {
        message(paste0(
          "legendRange is not wide enough, ",
          "scaling to min and max raster values"
        ))
      } else {
        minz <- min(legendRange)
        maxz <- max(legendRange)
        if (is.null(colTable)) {
          cols <- colorRampPalette(cols)(maxz - minz + 1)
        } else {
          if (length(getColors(grobToPlot)[[1]]) > 0) {
            cols <- colorRampPalette(colTable)(maxz - minz + 1)
          } else {
            # default color if nothing specified
            cols <- rev(terrain.colors(maxz - minz + 1))
          }
        }
      }
    }

    # here, the default color (transparent) for zero:
    # if it is the minimum value, can be overridden.
    if (!is.null(zero.color)) {
      if (minz == 0) {
        cols[1] <- zero.color
      }
    }
    z <- z + 1 # for the NAs
    z[is.na(z)] <- max(1, minz)

    cols <-
      c(na.color, cols) # make first index of colors be transparent

    if ((minz > 1) | (minz < 0)) {
      z <- matrix(
        cols[z - minz + 1], nrow = nrow(grobToPlot),
        ncol = ncol(grobToPlot), byrow = TRUE
      )
    } else {
      z <- matrix(
        cols[z], nrow = nrow(grobToPlot),
        ncol = ncol(grobToPlot), byrow = TRUE
      )
    }
    list(
      z = z, minz = minz, maxz = maxz, cols = cols, real = real
    )
  }
)
