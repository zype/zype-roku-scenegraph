function Paginator(next_page as integer) as object
    return {
        id: "paginator-" + Str(next_page - 1),
        title: m.global.labels.paginate_button_text,
        hdposterurl: m.global.theme.paginate_button,
        hdbackgroundimageurl: m.global.theme.paginate_button,
        isPaginator: true,
        nextPage: next_page
    }
end function
