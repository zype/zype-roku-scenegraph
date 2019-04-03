' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********
 'setting top interfaces
Sub Init()
    m.top.Title             = m.top.findNode("Title")
    m.top.Description       = m.top.findNode("Description")
    m.top.ReleaseDate       = m.top.findNode("ReleaseDate")

    m.top.Title.color = m.global.theme.primary_text_color
    m.top.ReleaseDate.color = m.global.theme.secondary_text_color
    m.top.Description.color = m.global.theme.secondary_text_color
End Sub

' Content change handler
' All fields population
Sub OnContentChanged()
    item = m.top.content

    title = item.title.toStr()
    if title <> invalid then
        m.top.Title.text = title.toStr()
    end if

    value = item.description
    if value <> invalid then
        m.top.Description.text = value.toStr()
    end if

    value = item.ReleaseDate
    if value <> invalid then
        if value <> ""
            m.top.ReleaseDate.text = value.toStr()
        else
            m.top.ReleaseDate.text = "No release date"
        end if
    end if
End Sub
