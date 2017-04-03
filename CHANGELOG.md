# Dynamic Themes (April 3, 2017)

- Merged _dynamic-themes_ into _master_. The update allows the developer to easily set the theme and brand color of the app inside _source/config.json_. To change the theme and brand color, simply update and save the values inside the config file and side load the app.
- The theme can be set to: "dark", "light", and "custom". The app by default uses the _"dark"_ theme, but this can be changed as you see fit. The custom theme can be set inside _source/themes.brs_ inside the _CustomTheme()_ function.
- The brand color is a hex color value. The app by default has a brand color of _#ffffff_. The brand color is used in the options icon and the Search keyboard. If you want to use the brand color elsewhere, you can find the corresponding BrightScript file for the component you want use the brand color in and set the component's colors inside the _Init()_ function.

# Zype Roku Scenegraph SDK (March 15, 2017)

- Merged _nsvod-resume-deep-linking_ into _master_. This is the stable version of the SDK. Features to date include: device linking, device unlinking, native subscriptions, resume watching, deep linking, video search, favoriting.
