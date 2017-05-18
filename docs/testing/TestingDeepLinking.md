# Testing Deep Linking for Roku

For Roku apps, one of their requirements is that they support deep linking. Deep linking is essentially the process of linking dirctly to a video in the app. When you deep link to a particular app, you provide the app with a _mediaType_ and a _contentID_ parameter which the app then uses to open the video directly. For more information on deep linking in Roku you can see [Roku's documentation here](https://sdkdocs.roku.com/display/sdkdoc/Deep+Linking).

In order to test deep linking you can use the __Terminal__ or the __Deep Linking Tester Tool__ from Roku. To use to Deep Linking Tester Tool you can add it to your account by logging into your Roku account and adding the channel with this code: __KX3UPK__.

To test deep linking you will need to provide the _mediaType_ and _contentID_ when you make your request. The mediaType can be any of the valid media types provided by Roku: __movie, episode, short-form, or season__. The contentID is the id of an active video that you are trying to play.

#### Testing Deep Linking with the Terminal

To test deep linking with the Terminal, you should side load your app ([more information here](https://sdkdocs.roku.com/display/sdkdoc/Loading+and+Running+Your+Application)). Then in your __Terminal__ you want to enter this command:

`curl -d '' 'http://< IP address of your Roku device >:8060/launch/dev?mediaType=< Any media type >&contentID=< ID of your video >'`

#### Testing Deep Linking with the Deep Linking Tester Tool

Once you have the Deep Linking Tester Tool you can test deep linking by side loading your app ([more information here](https://sdkdocs.roku.com/display/sdkdoc/Loading+and+Running+Your+Application)).

Then you should open up the Deep Linking Tester Tool and select your side loaded app. The sideloaded app is always the last app on your Home Menu. In the Deep Linking Tester Tool the id for your side loaded is always __dev__. After you select the app you can enter your mediaType (__movie, episode, short-form, or season__) and contentID (__id of the video you want to deep link__).

#### How Do I Know If Deep Linking Worked

You will know if deep linking worked if you are taken directly to the video. If you deep linked correctly, the loading screen shown is different then if you opened the app normally. It will also take longer than normal to load the content, as it initializes the app in the background before handling the device linking logic.

If the video has no subscription on it, the video should automatically start playing. If the video does have a subscription, it should stop loading and display a video page with subscribe buttons. If the id for the video that you linked is invalid or the video is inactive, the app should take you directly to the app's home page.
