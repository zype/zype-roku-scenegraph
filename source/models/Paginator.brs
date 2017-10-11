function Paginator(next_page as integer) as object
    return {
        hdposterurl: "pkg:/images/paginate.png",
        hdbackgroundimageurl: "pkg:/images/paginate.png",
        isPaginator: true,
        nextPage: next_page
    }
end function
