context("constant propagation")


test_that("constants are propagated in linear code", {
  cfg = quote_cfg({
    x <- 1
    y <- x
  })

  const = propagate_constants(cfg)

  # -----
  expect_identical(const[["x_1"]], 1)
  expect_identical(const[["y_1"]], 1)
})


test_that("constants are propagated through phi functions", {
  cfg = quote_cfg({
    if (TRUE) {
      x <- 1
    } else {
      x <- 2
    }
    y <- x
  })

  const = propagate_constants(cfg)

  # -----
  expect_identical(const[["x_1"]], 1)
  expect_identical(const[["y_1"]], 1)
})


test_that("unknowns are not propagated", {
  cfg = quote_cfg({
    x = rnorm(1)
    if (x > 0) {
      x <- 1
    } else {
      x <- 2
    }
    y <- x
  })

  const = propagate_constants(cfg)

  # -----
  expect_identical(const[["x_1"]], NONCONST)
  expect_identical(const[["x_2"]], 1)
  expect_identical(const[["x_3"]], 2)
  expect_identical(const[["x_4"]], NONCONST)
  expect_identical(const[["y_1"]], NONCONST)
})


test_that("loop variables are nonconstant", {
  cfg = quote_cfg({
    x = 42L
    for (i in 1:10) {
      x = i
    }
  })

  const = propagate_constants(cfg)

  # -----
  expect_identical(const[["._counter_i_2"]], NONCONST)

  expect_equal(const[["x_1"]], 42L)
  expect_identical(const[["x_2"]], NONCONST)
})


test_that("constants propagate through arithmetic", {
  cfg = quote_cfg({
    x = 1
    y = x + 3
    z = (y * 7) / 4
  })

  const = propagate_constants(cfg)

  ## -----
  expect_equal(const[["x_1"]], 1L)
  expect_equal(const[["y_1"]], 4L)
  expect_equal(const[["z_1"]], 7L)
})
