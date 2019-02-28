# Zype Roku Scenegraph SDK

This SDK allows you to set up an eye-catching, easy to use Roku video streaming app integrated with the Zype platform with minimal coding and configuration. The app is built upon the Roku Scene Graph API and Zype API. With minimal setup you can have your Roku app up and running.

## Supported Features

- Populates your app with content from enhanced playlists
- Video Search
- Live Streaming videos
- Video Favorites
- Resume watch functionality
- Deep linking to videos and playlists
- Dynamic theme colors
- Autoplay
- Subtitle Support (WebVTT, SRT)
- Subscribe to watch ad free (setting in config file)
- Lock icons for subscription videos
- Closed Caption Support

## Monetizations Supported

- Pre-roll and Midroll (via [ad timings](https://support.zype.com/hc/en-us/articles/223153427-Ad-Timings)) Ads (VAST)
- Native SVOD via In App Purchases
- Universal SVOD via device linking

## Creating New App with the SDK

In order to create an app using the Zype Roku Scenegraph, please follow the instructions inside this [Recipe](Recipe.md).

## Testing Native Subscriptions

In order to test native subscriptions, you need to setup the fake Roku store before sideloading. For more information on how to do this, [see here](docs/testing/TestingNativeSubscriptions.md)

## Contributing to the repo

We welcome contributions to Zype Roku Scenegraph SDK. If you have any suggestions or notice any bugs you can raise an issue. If you have any changes to the code base that you want to see added, you can fork the repository, then submit a pull request with your changes explaining what you changed, why you believe it should be added, and how one would test these changes. Thank you to the community!

## Support

If you need more information on how Zype API works, you can read the [documentation here](https://docs.zype.com/reference). If you have any other questions, feel free to contact us at [support@zype.com](mailto:support@zype.com).

## Authors

- __Khurshid Fayzullaev__ ([@khfayzullaev](https://github.com/khfayzullaev)) - Initial work
- __Basit Nizami__ ([@basit-n](https://github.com/basit-n)) - Major SDK feature updates
- __Andy Zheng__ ([@azheng249](https://github.com/azheng249)) - Feature updates

See the full [list of contributors](https://github.com/zype/zype-roku-scenegraph/graphs/contributors) who particated in this project.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.
