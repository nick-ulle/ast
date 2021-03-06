% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/counter.R
\name{next_name}
\alias{next_name}
\title{Next Name from Counter}
\usage{
next_name(counter, name, ...)
}
\arguments{
\item{counter}{(Counter) The counter for lookup.}

\item{name}{(character) The name to look up in the counter.}

\item{...}{Additional arguments, currently ignored.}
}
\value{
(character) A string containing the name and the new count.
}
\description{
This function looks up the given name in the given counter, increments the
counter for that name, and returns a string with the name and new count.
}
\details{
Side effects: The counter is modified in-place.
}
