context('List squishing')

test_that('Proper output from squishList', {
    vecList <- list(a=1:4,
                    b=data.frame(x=1:2),
                    a=5:10,
                    b=data.frame(x=3:6))
    vecSquish <- squishList(vecList)
    expect_identical(vecSquish$a, 1:10)
    expect_identical(vecSquish$b, data.frame(x=1:6))

    listList <- list(a=list(x=1:3, y=1:5),
                     a=list(x=4:5),
                     x=1:3)
    listSquish <- squishList(listList)
    expect_identical(listSquish$a$x, 1:5)
    expect_identical(listSquish$x, 1:3)

    nullList <- list(a=1:2,
                     a=NULL,
                     a=3:4)
    nullSquish <- squishList(nullList)
    expect_identical(nullSquish$a, 1:4)

    expect_identical(squishList(list()), list())
})
