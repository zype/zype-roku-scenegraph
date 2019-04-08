' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********
 ' inits grid Screen
 ' creates all children
 ' sets all observers
Function Init()
    ? "[GridScreen] Init"

    m.rowList       =   m.top.findNode("RowList")
    m.description   =   m.top.findNode("Description")
    m.background    =   m.top.findNode("Background")

    m.top.observeField("visible", "onVisibleChange")
    m.top.observeField("focusedChild", "OnFocusedChildChange")
    m.carouselShow=m.top.findNode("carouselShow")
    ' Set theme
    m.rowList.focusBitmapUri = m.global.theme.focus_grid_uri
    m.rowList.rowLabelColor = m.global.theme.primary_text_color

    m.optionsLabel = m.top.findNode("OptionsLabel")
    m.optionsLabel.text = m.global.labels.menu_label
    m.optionsLabel.color = m.global.theme.primary_text_color

    m.optionsIcon = m.top.findNode("OptionsIcon")
    m.optionsIcon.blendColor = m.global.brand_color
End Function

' handler of focused item in RowList
Sub OnItemFocused()
    itemFocused = m.top.itemFocused
    ' item focused should be an intarray with row and col of focused element in RowList
    If itemFocused.Count() = 2 then
        focusedContent          = m.top.content.getChild(itemFocused[0]).getChild(itemFocused[1])
        if focusedContent <> invalid then
            m.top.focusedContent    = focusedContent
            m.description.content   = focusedContent
            m.background.uri        = focusedContent.hdBackgroundImageUrl
        end if
    end if
End Sub

' set proper focus to RowList in case if return from Details Screen
Sub onVisibleChange()
    if m.top.visible = true then
        if m.top.heroCarouselData.count()>0
            m.carouselShow.visible=false
            m.sliderGroup.visible=true
            m.sliderButton.setFocus(true)
        else
            m.carouselShow.visible=true
            m.sliderGroup.visible=false
            m.rowList.setFocus(true)
        end if
    end if
End Sub

' set proper focus to RowList in case if return from Details Screen
Sub OnFocusedChildChange()
    if m.top.isInFocusChain() and not m.rowList.hasFocus()  then
        if m.top.heroCarouselData.count()>0
            m.sliderButton.setFocus(true)
            m.sliderGroup.visible=true
            m.carouselShow.visible=false
        else
            m.carouselShow.visible=true
            m.sliderGroup.visible=false
            m.rowList.setFocus(true)
        end if
    end if
End Sub

Sub showHeroCarousel()
    'for each item in m.top.heroCarouselData

           '' ?item.pictures[0]
    'end for
    m.sliderData=[]
    m.index=0
    m.sliderValuesHome={}
    m.sliderValuesHome.height=300
    m.sliderValuesHome.width=950
    m.sliderValuesHome.translation1=[-800,5]
    m.sliderValuesHome.translation2=[165,5]
    m.sliderValuesHome.translation3=[1130,5]

    m.sliderFocusValuesHome={}
    m.sliderFocusValuesHome.height=310
    m.sliderFocusValuesHome.width=960
    m.sliderFocusValuesHome.translation=[160,0]

    m.sliderButton=m.top.findNode("sliderButton")
    m.sliderGroup=m.top.findNode("sliderGroup")
    m.sliderGroup.translation=[0,60]

    m.slider1=m.top.findNode("slider1")
    m.slider1.loadHeight=m.sliderValuesHome.height
    m.slider1.loadWidth=m.sliderValuesHome.width
    m.slider1.loadDisplayMode="scaleToFill"
    m.slider1.translation=m.sliderValuesHome.translation1
    m.slider1.uri=m.top.heroCarouselData[m.index].pictures[0].url

    m.index+=1
    m.value=m.index
    if m.top.heroCarouselData[m.index]=invalid
        m.index=0
    end if
    m.slider2=m.top.findNode("slider2")
    m.slider2.loadHeight=m.sliderValuesHome.height
    m.slider2.loadWidth=m.sliderValuesHome.width
    m.slider2.loadDisplayMode="scaleToFill"
    m.slider2.translation=m.sliderValuesHome.translation2
    m.slider2.uri=m.top.heroCarouselData[m.index].pictures[0].url

    m.index+=1
    if m.top.heroCarouselData[m.index]=invalid
        m.index=0
    end if
    m.slider3=m.top.findNode("slider3")
    m.slider3.loadHeight=m.sliderValuesHome.height
    m.slider3.loadWidth=m.sliderValuesHome.width
    m.slider3.loadDisplayMode="scaleToFill"
    m.slider3.translation=m.sliderValuesHome.translation3
    m.slider3.uri=m.top.heroCarouselData[m.index].pictures[0].url

    m.sliderFocus=m.top.findNode("sliderFocus")
    m.sliderFocus.color="#ffffff"
    m.sliderFocus.height=m.sliderFocusValuesHome.height
    m.sliderFocus.width=m.sliderFocusValuesHome.width
    m.sliderFocus.translation=m.sliderFocusValuesHome.translation

    m.sliderButton=m.top.findNode("sliderButton")
    m.sliderButton.observeField("buttonSelected","selectSlider")
    m.sliderTimer=m.top.findNode("sliderTimer")
    m.sliderTimer.control="start"
    m.sliderTimer.ObserveField("fire","changeSliderImage")
End Sub

Sub selectSlider()
    ?m.top.heroCarouselData[m.value]
End SUb

Sub changeSliderImage()
    m.index+=1
    if m.top.heroCarouselData[m.index]=invalid
        m.index=0
    end if
    m.slider1.uri=m.top.heroCarouselData[m.index].pictures[0].url

    m.index+=1
    if m.top.heroCarouselData[m.index]=invalid
        m.index=0
    end if
    m.value=m.index
    m.slider2.uri=m.top.heroCarouselData[m.index].pictures[0].url

    m.index+=1
    if m.top.heroCarouselData[m.index]=invalid
        m.index=0
    end if
    m.slider3.uri=m.top.heroCarouselData[m.index].pictures[0].url
ENd SUb

function onKeyEvent(key as String, press as Boolean) as Boolean
    result = false
    if press then
        if key="down"
           if m.sliderButton.hasFocus()
                m.carouselShow.visible=true
                m.sliderGroup.visible=false
                m.rowList.setFocus(true)
                result=true
            end if
        else if key="up"
            if m.rowList.hasFocus() AND m.top.heroCarouselData.Count()>0
                m.carouselShow.visible=false
                m.sliderGroup.visible=true
                m.sliderButton.setFocus(true)
                result=true
            end if
        else if key="right"
            if m.sliderGroup.visible=true
                m.value=m.value+1
                

                m.index=m.value
                if m.top.heroCarouselData[m.index]=invalid
                    m.index=0
                end if
                m.slider2.uri=m.top.heroCarouselData[m.index].pictures[0].url   

                m.index+=1
                if m.top.heroCarouselData[m.index]=invalid
                    m.index=0
                end if
                m.slider3.uri=m.top.heroCarouselData[m.index].pictures[0].url

                m.index+=1
                if m.top.heroCarouselData[m.index]=invalid
                    m.index=0
                end if
                m.slider1.uri=m.top.heroCarouselData[m.index].pictures[0].url
                result=true
          
            end if
        else if key="left"
            if m.sliderGroup.visible=true
                m.value=m.value-1
            
                m.index=m.value
                if m.top.heroCarouselData[m.index]=invalid
                    m.index=m.top.heroCarouselData.Count()-1
                end if
                m.slider2.uri=m.top.heroCarouselData[m.index].pictures[0].url

                m.index-=1
                if m.top.heroCarouselData[m.index]=invalid
                    m.index=m.top.heroCarouselData.Count()-1
                end if
                m.slider1.uri=m.top.heroCarouselData[m.index].pictures[0].url

                m.index-=1
                if m.top.heroCarouselData[m.index]=invalid
                    m.index=m.top.heroCarouselData.Count()-1
                end if
                m.slider3.uri=m.top.heroCarouselData[m.index].pictures[0].url
                result=true
            
            end if
        end if
    end if
    return result
end function