# Zype Roku Recipe

This document outlines step-by-step instructions for creating and publishing a Roku app powered by Zype's Endpoint API service and app production software and SDK template.

## Requirements and Prerequisites

#### Technical Contact

IT or developer support strongly recommended. Creating the final app package requires working with the Terminal to sideload and package the app.

#### Roku Device and Account

In order to package your Roku app, you will need a Roku device. If you use Zype's app production tools, you will get the code for the application; however Roku's process for packaging apps requires that you sideload and package the app on a Roku device before you download the package from the device itself. Because you need a Roku device to sideload the app on, you will also need a Roku account in order to set up the device.

#### Zype Roku Endpoint License

To create a Zype Roku app you need a paid and current Zype account that includes purchase of a valid license for the Zype Roku endpoint API. Learn more about [Zype's Endpoint API Service](http://www.zype.com/services/endpoint-api/).

#### Enrollment in Roku's Developer Program

The Roku Developer Program can be enrolled in via [Roku's developer website](https://developer.roku.com).

## Creating a New App with the SDK template

#### Generate your bundle

1. In order to generate your Roku app using the SDK, you will need to first create a Roku app on the Zype platform. If you have not done this yet, log in to your Zype account [here](https://admin.zype.com/users/sign_in), and click on the __Manage Apps__ link under the Publish menu in the left navigation. You will see a button to create a new app. Continue following the instructions provided within the app production software.

![Image to be provided](http://imagetobeprovided.com)

2. Once you have your Roku app created in the Zype platform and have included your assets, click on __Get New Bundle__ and the configured app bundle will be emailed to you.

![Image to be provided](http://imagetobeprovided.com)

#### Installing and testing your new app

3. Once you have received your new app, you will need to sideload the application in order to test it. You can view [Roku's documentation](https://sdkdocs.roku.com/display/sdkdoc/Loading+and+Running+Your+Application) for more details on how to sideload the application.

4. In order to submit to the Roku's app store you need to ensure that deep linking works as expected. There are more details on how to [test deep linking here](docs/testing/TestingDeepLinking.md).

5. __(Optional)__ If you are testing native subscriptions you will need to first create subscriptions on the Zype platform. You can create subscriptions on the Zype platform by [following the documentation here](https://zype.zendesk.com/hc/en-us/articles/215492488-Creating-a-Subscription).
  - __Note:__ Although it is recommended, you do not need a Braintree/Stripe account to create subscriptions on the Zype platform. You can head directly to [https://admin.zype.com/plans](https://admin.zype.com/plans) to create a plan without linking Braintree/Stripe.
  - After you have created your subscriptions in the platform your can test native subscriptions by [following the documentation here](docs/testing/TestingNativeSubscriptions.md).

#### Submitting to the Roku App Store

6. Once you have thoroughly tested and approve your app, you can start packaging your app. It should be noted that if you are submitting an update to an existing Roku app, you need to update the version numbers in the __manifest__ and the __Makefile__, then re-sideload your app. For more information on how to package your app, [see the documentation here](https://github.com/rokudev/docs/blob/062c73061e7ab6eb3e752a24c8dcae537dc59e53/develop/developer-tools/developer-settings.md#application-packager).
  - Screenshots are not required for Roku apps, but you can also take screenshots of your app by [following the documentation here](https://github.com/rokudev/docs/blob/062c73061e7ab6eb3e752a24c8dcae537dc59e53/develop/developer-tools/developer-settings.md#screenshot-utility).

7. After you have packaged your app you can start publishing your app by [following this documentation](https://github.com/rokudev/docs/blob/c74f97eee1101584b3113d71723a38e0a04cc35b/publish/channel-store/publishing.md). __There are a few things to note that are not explicitly stated in the documentation linked.__
  - If you are doing native subscriptions, it is not enough to create the in channel subscriptions. You also need to make sure that they are marked as __Cleared for Sale__, otherwise the Roku testers will not see the subscriptions when they test on their end.
  - All information related to testing your app needs to be stated in the __Test Accounts__ field under __Support Information__ when you are submitting. Everything from accounts needed to test device linking to deep linking parameters need to be included here. If you leave __Test Accounts__ empty, Roku will reject your app saying they do not have all the info needed to test your app.

8. Once submitted Roku will review your app (if it is public) against their submission guidelines. If your app is approved, they will update your app status and you should receive an email notification from Roku informing you that your app is live. You can then search for it on Roku's marketplace under the __Search__ tab.
