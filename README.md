# Zype Roku Scenegraph SDK

This SDK allows you to set up an eye-catching, easy to use Roku video streaming app integrated with the Zype platform with minimal coding and configuration. The app is built upon the Roku Scene Graph API and Zype API. With minimal setup you can have your Roku app up and running.

## Supported Features

- Populates your app with content from enhanced playlists
- Video Search
- Live Streaming videos
- Video Favorites (available with device linking)
- Resume watch functionality
- Deep linking to specific videos
- Dynamic theme colors
- Autoplay
- Subtitle Support (WebVTT, SRT)

## Unsupported Features

- Closed Caption Support

## Monetizations Supported

- Pre-roll and Midroll Ads (VAST)
- Native SVOD via In App Purchases
- Universal SVOD via device linking

## Creating New App with the SDK

In order to create an app using the Zype Roku Scenegraph, please follow the instructions inside this [Recipe](Recipe.md).

## Device Endpoint Notes

Older Roku devices will have less powerful hardware and therefore less processing power. One noticeable difference when running the apps on newer Roku devices (Roku 4 and newer) is that the loading indicator/spinner will have an animation. This feature was taken out for older Roku devices which did not have hardware to support animations and rendering of higher resolution images.

## Contributing to the repo

We welcome contributions to Zype Roku Scenegraph SDK. If you have any suggestions or notice any bugs you can raise an issue. If you have any changes to the code base that you want to see added, you can fork the repository, then submit a pull request with your changes explaining what you changed, why you believe it should be added, and how one would test these changes. Thank you to the community!

## Support

If you need more information on how Zype API works, you can read the [documentation here](http://dev.zype.com/api_docs/intro/). If you have any other questions, feel free to contact us at [support@zype.com](mailto:support@zype.com).

## Authors

- __Khurshid Fayzullaev__ ([@khfayzullaev](https://github.com/khfayzullaev)) - Initial work
- __Basit Nizami__ ([@basit-n](https://github.com/basit-n)) - Major SDK feature updates
- __Andy Zheng__ ([@azheng249](https://github.com/azheng249)) - Feature updates

See the full [list of contributors](https://github.com/zype/zype-roku-scenegraph/graphs/contributors) who particated in this project.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.
