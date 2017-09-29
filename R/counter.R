#' Counter for Strings
#'
#' This data structure keeps a running total of the number of times it has seen
#' each unique string. This is an R6 class, so the object can be modified in
#' place and assignment has reference semantics.
#'
#' @export
Counter = R6::R6Class("Counter",
  "private" = list(
    counter = integer(0)
  ),

  "public" = list(
    increment = function(basename) {
      if (basename %in% names(private$counter)) {
        counter = private$counter[[basename]] + 1L
      } else {
        counter = 1L
      }
      
      private$counter[[basename]] = counter

      return (counter)
    }
  )
)
