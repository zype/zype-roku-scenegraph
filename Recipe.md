# Zype Roku Recipe

This document outlines step-by-step instructions for creating and publishing a Roku app powered by Zype's Endpoint API service and app production software and SDK template.

## Requirements and Prerequisites

#### Technical Contact

IT or developer support strongly recommended. Creating the final app package requires working with the Terminal to sideload and package the app.

#### Roku Device and Account

In order to package your Roku app, you will need a Roku device. If you use Zype's app production tools, you will get the code for the application; however Roku's process for packaging apps requires that you sideload and package the app on a Roku device before you download the package from the device itself. Because you need a Roku device to sideload the app on, you will also need a Roku account in order to set up the device.

#### Zype Roku Endpoint License

To create a Zype Roku app you need a paid and current Zype account that includes purchase of a valid license for the Zype Roku endpoint API. Learn more about [Zype's Endpoint API Service](https://docs.zype.com/reference).

#### Enrollment in Roku's Developer Program

The Roku Developer Program can be enrolled at Roku's website. You can follow [these instructions](https://support.zype.com/hc/en-us/articles/216233438-Roku-Developer-Account-Setup) for setting up your Roku developer account.

## Creating a New App with the SDK template

#### Generate your bundle

1. You can generate your app bundle using Zype's Roku app builder. For more info see [here](https://support.zype.com/hc/en-us/articles/115010341848-Roku-App-Builder-Template)

#### Installing (sideloading) and testing your new app

2. After downloading your app bundle from Zype, you can [preview your app](https://support.zype.com/hc/en-us/articles/216101448-Previewing-Your-Channel-on-a-Roku-Device) by installing (sideloading) your app on your Roku device. 

- **Note:** You can also sideload the app from your Terminal by using the `Makefile`. Simply update the `ROKU_DEV_TARGET` and `DEVPASSWORD` in the **app.mk** file and enter `make install` from the base directory in your app bundle. (This is useful if you are making frequent changes)

3. You should test your app thoroughly before packaging your app for submission. You can use [this checklist](https://support.zype.com/hc/en-us/articles/360007396634-Roku-QA-Checklist) as a reference when testing your app.

#### Submitting to the Roku App Store

4. **(Optional)** If you are using native subscriptions, you can following [these instructions](https://support.zype.com/hc/en-us/articles/115009092407-Creating-Native-Subscription-in-Roku) for creating native subscriptions on your Roku account.

5. After you are satisfied with your app, you can package your app for submission. You can follow the [intructions here](https://support.zype.com/hc/en-us/articles/360007645113-Submitting-a-Roku-App) for packaging and submitting your app.

- **To update your app's version and build numbers, update the `manifest` file before sideloading your app.**
- **If you are updating an app**, you will need to [rekey your new app](https://support.zype.com/hc/en-us/articles/115010682547-Resubmitting-a-Roku-App) before [re-submitting](https://support.zype.com/hc/en-us/articles/115010682547-Resubmitting-a-Roku-App).