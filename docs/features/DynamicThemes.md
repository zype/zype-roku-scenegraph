## Dynamic Themes

Introduced in Version 1.1.0, the Roku app's theme and brand color can be configured quickly and easily. The __theme__ and __brand_color__ values can be set within the __source/config.json__ file. These values will determine the colors the different app components use.

The Roku app comes with preset themes and assets, but you can also use your own custom theme and assets.

#### Theme

The __theme__ accepts the following values: `"dark", "light", and "custom"`. By default the components use a dark theme, but this can be altered for your app's needs.

If you want to use a theme besides the light and dark theme, you can opt for a custom theme. To use a custom theme, simply set the __theme__ to `"custom"` and set the colors that you want within _CustomTheme()_ inside _source/themes.brs_.

- The _background_color_, _primary_text_color_ and _secondary_text_color_ accept any hex color value.
- The assets can be customized by editing the following images:
    - `components/screens/LoadingIndicator/customLoader.png`
        - the spinning wheel when app is loading info
    - `images/focus_grid_custom.9.png`
        - the box that surrounds the thumbnail you are hovered over
    - `images/customOverlay.png`
        - the overlay that covers the large video thumbnail in the background
    - `images/button-focus-custom.png`
        - the button for the current selected item

#### Brand Color

The __brand color__ accepts any hex color value inside string. The brand color is white (#ffffff) by default, but you can use any brand color you want.

Currently the brand color is used as the color for the options icon and the Search keyboard. If you want to use the brand colors in more components, you can find the corresponding BrightScript file for the component whose colors you want to alter and update the _Init()_ function. You can reassign any of the components' color values to `m.global.brand_color` to set it to your brand color.
