# Text Customization

While some of the text in the Zype Roku SDK is hardcoded, many of the text labels can be changed inside `source/text_labels_config.json`. The text is stored with the app's global node and can be accessed anywhere in the app through `m.global.labels`.

For example, if I wanted to update the text for my sign in button, I can update `sign_in_button` in the config file from "Sign In" to "Have an account?".

```
{
  ...
  "sign_in_button": "Have an account?",
  ...
}
```
