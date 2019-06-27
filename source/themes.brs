Function DarkTheme() as Object
    theme = {
        background_color:           "#000000",
        primary_text_color:         "#f5f5f5",
        secondary_text_color:       "#a8a8a8",
        plan_button_color:          "#464646",
        loader_uri:                 "pkg:/components/screens/LoadingIndicator/lightLoader.png",
        focus_grid_uri:             "pkg:/images/focus_grid_light.9.png",
        overlay_uri:                "pkg:/images/blackOverlay.png",
        button_focus_uri:           "pkg:/images/button-focus-light.png",
        button_filledin_uri:        "pkg:/images/button-filledin-light.png"
        paginate_button:            "pkg:/images/paginate_light.png"
        slider_focus:               "pkg://images/roku_white_highlight_thicker.png"
    }
    return theme
End Function

Function LightTheme() as Object
    theme = {
        background_color:           "#f0f0f0",
        primary_text_color:         "#1f1f1f",
        secondary_text_color:       "#595959",
        plan_button_color:          "#d6d6d6",
        loader_uri:                 "pkg:/components/screens/LoadingIndicator/darkLoader.png",
        focus_grid_uri:             "pkg:/images/focus_grid_dark.9.png",
        overlay_uri:                "pkg:/images/whiteOverlay.png",
        button_focus_uri:           "pkg:/images/button-focus-dark.png",
        button_filledin_uri:        "pkg:/images/button-filledin-dark.png"
        paginate_button:            "pkg:/images/paginate_dark.png"
        slider_focus:               "pkg://images/roku_black_highlight_thicker.png"
    }
    return theme
End Function

' Set the custom theme that you want
'
' If you want to customize the assets, you will have to edit and save the images to have the colors you want
' If you need further explanation what these images are for:
'     loader          = the spinning wheel that is shown when the app is loading something
'     focus grid      = the box that surrounds the thumbnails as you scroll through the items
'     overlay         = the image that covers up the borders of the background image
'     button focus    = the button shown for the currently selected item
Function CustomTheme() as Object
    theme = {
        background_color:           "#008080",
        primary_text_color:         "#121212",
        secondary_text_color:       "#ffa500",
        loader_uri:                 "pkg:/components/screens/LoadingIndicator/customLoader.png",
        focus_grid_uri:             "pkg:/images/focus_grid_custom.9.png",
        overlay_uri:                "pkg:/images/whiteOverlay.png",
        button_focus_uri:           "pkg:/images/button-focus-custom.png"
        button_filledin_uri:        "pkg:/images/button-filledin-light.png"
        paginate_button:            "pkg:/images/paginate_light.png"        
    }
    return theme
End Function
