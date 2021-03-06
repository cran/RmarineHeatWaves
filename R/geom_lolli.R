#' Visualise a Timeline of Several Event Metrics as 'Lollipops'.
#'
#' The function will return a graph of the intensity of the selected
#' metric along the *y*-axis versus a time variable along the *x*-axis.
#' The number of top events (\code{n}) from the chosen metric may be highlighted
#' in a brighter colour with the aesthetic value \code{colour.n}.
#' This function differs in use from \code{\link{lolli_plot}}
#' in that it must be created as a ggplot2 'geom' object. The benefit of this being
#' that one may add additional information layer by layer to the figure as
#' geoms as necessary.
#'
#' @seealso \code{\link{lolli_plot}} for a non-geom based lolliplot function.
#'
#' @section Aesthetics:
#' \code{geom_lolli} understands the following aesthetics (required aesthetics
#' are in bold):
#' \itemize{
#'   \item \strong{\code{x}}
#'   \item \strong{\code{y}}
#'   \item \code{alpha}
#'   \item \code{color}
#'   \item \code{linetype}
#'   \item \code{size}
#'   \item \code{shape}
#'   \item \code{stroke}
#'   \item \code{fill}
#'   \item \code{colour.n}: While this value may be used as an aesthetic, it also
#' works as a parameter for this function. If one chooses not to highlight
#' any events, use \code{colour.n = NA} outside of \code{aes()}. One may
#' also provide a non-static value to \code{colour.na} but remember that
#' one may not provide multiple continuous or discrete scales to a single
#' ggplot2 object. Therefore, if one provides a continuous value to
#' \code{aes(colour)}, the values supplied to \code{colour.n} must be
#' discrete. ggplot2 will attempt to do this automatically.
#' }
#'
#' @param mapping Set of aesthetic mappings created by \code{aes()} or \code{aes_()}. If
#' specified and inherit.aes = TRUE (the default), it is combined with the
#' default mapping at the top level of the plot. You must supply mapping if
#' there is no plot mapping.
#' @param data The data to be displayed in this layer. There are three options:
#'
#' If NULL, the default, the data is inherited from the plot data as specified
#' in the call to \code{ggplot()}.
#'
#' A data.frame, or other object, will override the plot data. All objects will
#' be fortified to produce a data frame. See \code{fortify()} for which variables will
#' be created.
#'
#' A function will be called with a single argument, the plot data. The return
#' value must be a \code{data.frame}, and will be used as the layer data.
#' @param show.legend Logical. Should this layer be included in the legends? \code{NA},
#' the default, includes if any aesthetics are mapped. \code{FALSE} never includes, and
#' \code{TRUE} always includes. It can also be a named logical vector to finely select
#' the aesthetics to display.
#' @param inherit.aes If \code{FALSE}, overrides the default aesthetics, rather
#' than combining with them. This is most useful for helper functions that define
#' both data and aesthetics and shouldn't inherit behaviour from the default plot
#' specification, e.g. \code{borders()}.
#' @param na.rm If \code{FALSE} (the default), removes missing values with
#'    a warning. If \code{TRUE} silently removes missing values.
#' @param ... other arguments passed on to \code{\link{layer}}. These are
#'   often aesthetics, used to set an aesthetic to a fixed value, like
#'   \code{color = "red"} or \code{size = 3}. They may also be parameters
#'   to the paired geom/stat.
#' @param n The number of top events to highlight. Default is 1. This parameter
#' has no effect if \code{colour.n} is set to \code{NA} outside of \code{aes()}.
#'
#' @author Robert W. Schlegel
#'
#' @export
#'
#' @examples
#' ts_dat <- make_whole(sst_NW_Atl)
#' # with defaults:
#' res <- detect(ts_dat, climatology_start = "1983-01-01",
#'               climatology_end = "2012-12-31")
#' mhw <- res$event
#'
#' \dontrun{
#' require(lubridate)
#' # Height of lollis represent event durations and their colours
#' # are mapped to the events' cumulative intensity:
#' ggplot(mhw, aes(x = mhw$date_peak, y = mhw$duration)) +
#'   geom_lolli(n = 0, shape = 20, aes(colour = mhw$int_cum), colour.n = NA) +
#'   scale_color_distiller(palette = "Spectral", name = "Cumulative \nintensity") +
#'   xlab("Date") + ylab("Event duration [days]")
#'
#' # Height of lollis represent event durations and the top three (longest)
#' # lollis are highlighted in red:
#' ggplot(mhw, aes(x = mhw$date_peak, y = mhw$duration)) +
#'   geom_lolli(n = 3, shape = 20, colour.n = "red") +
#'   scale_color_distiller(palette = "Spectral", name = "Cumulative \nintensity") +
#'   xlab("Date") + ylab("Event duration [days]")
#' }

geom_lolli <- function(mapping = NULL, data = NULL,
                       ...,
                       n = 1,
                       na.rm = FALSE, show.legend = NA, inherit.aes = TRUE) {

  ggplot2::layer(
    geom = GeomLolli,
    data = data,
    mapping = mapping,
    stat = "identity",
    position = "identity",
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      na.rm = na.rm,
      n = n,
      ...
    )
  )
}

GeomLolli <- ggplot2::ggproto("GeomLolli", ggplot2::Geom,
                              required_aes = c("x", "y"),
                              default_aes = ggplot2::aes(shape = 19, colour = "grey35", size = 1, fill = NA,
                                                alpha = NA, stroke = 1, colour.n = "black"),

                              draw_key = ggplot2::draw_key_point,

                              draw_group = function(data, panel_scales, coord, n) {
                                data$xend = data$x
                                data$yend = 0
                                data = data[order(abs(data$y), decreasing = T),]

                                # Define the big points
                                big_points = data
                                big_points$size = data$size*2

                                # Define the look of the small white fillings
                                small_points = data
                                small_points$size = data$size/2
                                small_points$colour = "white"

                                # Define the top n events
                                data_n = data[1:n,]
                                data_n$colour = data$colour.n[1:n]
                                big_points_n = big_points[1:n,]
                                big_points_n$colour = data$colour.n[1:n]

                                grid::gList(
                                  ggplot2::GeomSegment$draw_panel(data, panel_scales, coord),
                                  ggplot2::GeomPoint$draw_panel(big_points, panel_scales, coord),
                                  ggplot2::GeomSegment$draw_panel(data_n, panel_scales, coord),
                                  ggplot2::GeomPoint$draw_panel(big_points_n, panel_scales, coord),
                                  ggplot2::GeomPoint$draw_panel(small_points, panel_scales, coord)
                                )

                              }
)
