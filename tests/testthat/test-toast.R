test_that("that buttered works", {
  expect_equal(make_toast("rye", buttered = FALSE), 
               "A buttered slice of rye toast")
  
  expect_equal(make_toast("rye", buttered = FALSE), 
               "A slice of rye toast")
})
