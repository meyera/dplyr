#' A grouped data frame.
#'
#' The easiest way to create a grouped data frame is to call the \code{group_by}
#' method on a data frame or data source: this will take care of capturing
#' the unevalated expressions for you.
#'
#' @param data a data source or data frame.
#' @param vars a list of quoted variables.
#' @param lazy if \code{TRUE}, index will be computed lazily every time it
#'   is needed. If \code{FALSE}, index will be computed up front on object
#'   creation.
#' @param drop if \code{TRUE} preserve all factor levels, even those without
#'   data.
grouped_df <- function(data, vars, lazy = TRUE, drop = TRUE) {
  attr(data, "vars") <- vars
  attr(data, "drop") <- drop
  if (!lazy) {
    data <- build_index(data)
  }

  class(data) <- c("grouped_df", "source_df", "source", class(data))
  data
}

#' @rdname grouped_df
#' @method is.lazy grouped_df
#' @export
is.lazy.grouped_df <- function(x) {
  is.null(attr(x, "index")) || is.null(attr(x, "labels"))
}

#' @rdname grouped_df
#' @export
is.grouped_df <- function(x) inherits(x, "grouped_df")

#' @S3method print grouped_df
print.grouped_df <- function(x, ...) {
  cat("Source: local data frame ", dim_desc(x), "\n", sep = "")
  cat("Groups: ", commas(deparse_all(attr(x, "vars"))), "\n", sep = "")
  cat("\n")
  trunc_mat(x)
}

#' @S3method group_size grouped_df
group_size.grouped_df <- function(x) {
  if (is.lazy(x)) x <- build_index(x)
  vapply(attr(x, "index"), length, integer(1))
}


#' @param x object (data frame or \code{\link{source_df}}) to group
#' @param ... unquoted variables to group by
#' @method group_by data.frame
#' @export
#' @rdname grouped_df
group_by.data.frame <- function(x, ..., drop = TRUE) {
  vars <- named_dots(...)
  grouped_df(x, c(x$group_by, vars), lazy = FALSE)
}


#' @S3method as.data.frame grouped_df
as.data.frame.grouped_df <- function(x, row.names = NULL,
                                            optional = FALSE, ...) {
#   if (!is.null(row.names)) warning("row.names argument ignored", call. = FALSE)
#   if (!identical(optional, FALSE)) warning("optional argument ignored", call. = FALSE)

  attr(x, "vars") <- NULL
  attr(x, "index") <- NULL
  attr(x, "labels") <- NULL
  attr(x, "drop") <- NULL

  class(x) <- setdiff(class(x), c("grouped_df", "source_df", "source"))
  x
}

#' @S3method ungroup grouped_df
ungroup.grouped_df <- function(x) {
  as.data.frame(x)
}

make_view <- function(x, env = parent.frame()) {
  if (is.lazy(x)) stop("No index present", call. = FALSE)
  view(x, attr(x, "index"), parent.frame())
}

build_index <- function(x) {
  splits <- lapply(attr(x, "vars"), eval, x, parent.frame())
  split_id <- id(splits, drop = attr(x, "drop"))
  assert_that(length(split_id) == nrow(x))

  attr(x, "labels") <- split_labels(splits, drop = attr(x, "drop"),
    id = split_id)
  attr(x, "index") <- split_indices(split_id, attr(split_id, "n"))

  x
}

split_labels <- function(splits, drop, id = plyr::id(splits, drop = TRUE)) {
  if (length(splits) == 0) return(data.frame())

  if (drop) {
    # Need levels which occur in data
    representative <- which(!duplicated(id))[order(unique(id))]
    as_df(lapply(splits, function(x) x[representative]))
  } else {
    unique_values <- llply(splits, ulevels)
    names(unique_values) <- names(splits)
    rev(expand.grid(rev(unique_values), stringsAsFactors = FALSE))
  }
}

ulevels <- function(x) {
  if (is.factor(x)) {
    levs <- levels(x)
    factor(levs, levels = levs)
  } else {
    sort(unique(x))
  }
}
