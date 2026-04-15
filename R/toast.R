#' Make toast with any bread you want
#' 
#' @param bread The type of bread you want to use for your toast
#' @param buttered A boolean value indicating whether you want your toast buttered or not
#' @return A string describing the toast you made
#' @author Jared Andrews
#' @export
#' @examples
#' make_toast("sourdough", buttered = TRUE)
make_toast <- function(bread, buttered = FALSE) {
  my_toast <- NULL #output variable
  if (buttered) {
    my_toast <- paste("A buttered slice of", bread, "toast")
  } else {
    my_toast <- paste("A slice of", bread, "toast")
  }
  
  return(my_toast)
}
