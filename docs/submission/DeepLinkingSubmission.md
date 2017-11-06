# Submitting Deep Linking Parameters

When submitting your app remember to include parameters for deep linking. If you forget to include them, Roku will reject your app and ask you for them later. You can include these parameters in the __Test Accounts__ text box under the __Support Information__.

### Expected Behavior

With deep linking, the app is supposed to open a video or playlist depending on the parameters provided. If the user is deep linked and entitled to the movie/episode (video), the video should automatically play after the app loads. If the user is deep linked to a series/season (playlist), the app should display all the videos for that series/season.

### Provide the following info

![Deep linking](images/deep-linking1.png)

__mediaType__ can be one of the following: movie, series, season, or episode.
- use _movie_ or _episode_ when providing video id
- use _series_ or _season_ when providing playlist id

__contentID__ is the id for an active video or playlist.
- When you provide a video id, Roku expects the video to be playable when it deep links so it is recommended to use a free video's id.
