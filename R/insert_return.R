#' Insert Optional Return Expressions
#'
#' This function transforms a function so that every expression that can be
#' returned is explicitly marked by a \code{return()} expression.
#'
#' This is an in-place transformation! This function may not behave as expected
#' if called on a non-function.
#' 
#' @param node (Function) The function to transform.
#' @param ... Optional arguments to and from methods.
#' @param recursive (logical) Should functions defined in \code{node} also be
#' transformed?
#'
#' @export
insert_return =
function(node, ..., recursive = TRUE)
{
  UseMethod("insert_return")
}

#' @export
insert_return.Function =
function(node, ..., recursive = TRUE, .first = TRUE)
{
  if (recursive || .first) {
    node$body = insert_return(node$body, ..., recursive = recursive,
      .first = FALSE)
  }

  node
}

#' @export
insert_return.Brace =
function(node, ..., recursive = TRUE)
{
  len = length(node$contents)

  # Empty brace.
  if (len == 0L) {
    node$contents[[1L]] = Return$new(Null$new(), parent = node)
    return (node)
  }

  # Check for function definitions.
  if (recursive) {
    indices = find_node_indices(node$contents[-len], is, "Function"
      , recursive = FALSE)

    for (i in indices) {
      def = child(node, i)
      child(node, i) = insert_return.Function(def, ...)
    }
  }

  last = insert_return(node$contents[[len]], ..., recursive = recursive)

  node$contents = c(node$contents[-len], last)

  node
}

#' @export
insert_return.If =
function(node, ...)
{
  node$true = insert_return(node$true, ...)
  node$false = insert_return(node$false, ...)

  node
}

#' @export
insert_return.Loop =
function(node, ...)
{
  # Insert `return(NULL)` after the loop.
  list(
    node,
    Return$new(Null$new())
  )
}


#' @export
insert_return.Assignment =
function(node, ...)
{
  list(
    node,
    Return$new(copy(node$write))
  )
}


#' @export
insert_return.Literal =
function(node, ...)
{
  Return$new(node)
}

#' @export
insert_return.Symbol = insert_return.Literal

#' @export
insert_return.Invocation = insert_return.Literal


#' @export
insert_return.Branch =
function(node, ...)
{
  node
}
