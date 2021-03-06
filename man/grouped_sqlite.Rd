\name{grouped_sqlite}
\alias{group_by.grouped_sqlite}
\alias{group_by.source_sqlite}
\alias{grouped_sqlite}
\title{A grouped sqlite database.}
\usage{
  grouped_sqlite(source, vars, group_by)

  \method{group_by}{source_sqlite} (x, ...)

  \method{group_by}{grouped_sqlite} (x, ...)
}
\arguments{
  \item{source}{a data source or data frame.}

  \item{vars}{a list of quoted variables.}

  \item{group_by}{\code{vars} partially evaluated in the
  correct environment}

  \item{x}{an existing sqlite data source}

  \item{...}{expressions describing how to group data}
}
\description{
  Typically you will create a grouped data table is to call
  the \code{group_by} method on a sqlite data source: this
  will take care of capturing the unevalated expressions
  for you.
}
\section{Performance}{
  For best performance, the database should have an index
  on the variables that you are grouping by. A good
  introduction to how indices affect database performance
  can be found at
  \url{http://www.sqlite.org/queryplanner.html}.
}
\examples{
db_path <- system.file("db", "baseball.sqlite3", package = "dplyr")
baseball_s <- source_sqlite(db_path, "baseball")

by_year_lg <- group_by(baseball_s, year, lg)
group_size(by_year_lg)
summarise(by_year_lg, players = count(), avg_g = mean(g))

by_team <- group_by(baseball_s, team)
summarise(by_team, players = count())

# do by
mods <- do(by_team, failwith(NULL, lm), formula = r ~ poly(year, 2), .chunk_size = 1000)

sizes <- summarise(by_team, freq = count())
not_small <- as.data.frame(filter(sizes, freq > 10))
teams <- not_small$team
ok <- filter(by_team, team \%in\% teams)
mods <- do(ok, failwith(NULL, lm), formula = r ~ poly(year, 2),
  .chunk_size = 1000)

# Since we it's not easy to figure out what variables you are using
# in general, it will often be faster to let dplyr know what you need
mods <- do(filter(ok, year, r), failwith(NULL, lm), formula = r ~ poly(year, 2),
  .chunk_size = 1000)
}

