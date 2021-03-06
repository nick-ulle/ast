% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/find_nodes.R
\name{where_is}
\alias{where_is}
\title{Where is RStatic Object in Tree?}
\usage{
where_is(node, index = integer(0))
}
\arguments{
\item{node}{(ASTNode) The RStatic object to traverse.}

\item{index}{(integer) Initial index. The value of this parameter is
appended to the end of the computed index.}
}
\value{
An integer vector which can be used as an index in the \code{\link[=child]{child()}}
function.
}
\description{
This function finds the index of the given RStatic object relative to its
ancestor nodes.
}
\examples{
ast = quote_ast(x <- y + z)
node = child(ast, c(2, 2, 1))

where_is(node)
}
