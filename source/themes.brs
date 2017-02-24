Function DarkTheme() as Object
    theme = {
        background_color:           "#151515",
        primary_text_color:         "#f5f5f5",
        secondary_text_color:       "#a8a8a8",
        loader_uri:                 "pkg:/components/screens/LoadingIndicator/lightLoader.png",
        focus_grid_uri:             "pkg:/images/focus_grid_light.9.png",
        overlay_uri:                "pkg:/images/blackOverlay.png",
        button_focus_uri:           "pkg:/images/button-focus-light.png"
    }
    return theme
End Function

Function LightTheme() as Object
    theme = {
        background_color:           "#f7f7f7",
        primary_text_color:         "#1f1f1f",
        secondary_text_color:       "#595959",
        loader_uri:                 "pkg:/components/screens/LoadingIndicator/darkLoader.png",
        focus_grid_uri:             "pkg:/images/focus_grid_dark.9.png",
        overlay_uri:                "pkg:/images/whiteOverlay.png",
        button_focus_uri:           "pkg:/images/button-focus-dark.png"
    }
    return theme
End Function
