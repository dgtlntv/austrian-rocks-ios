# Austrian.rocks iOS

Austrian.rocks is an iOS climbing guide for discovering bouldering areas, problems, and access information across Austria.

Use the app to explore areas on a map, browse recommended areas, save projects, tick completed problems, and contribute improvements to the guidebook.

## Build the app

### Mapbox setup

#### Step 1

Create an account on https://www.mapbox.com and go to the [Tokens](https://account.mapbox.com/access-tokens/) page to create 2 tokens:
- 1 public token with all the public `scopes` (or use the default token)
- 1 secret token with all the public `scopes` + the `DOWNLOADS:READ` scope

#### Step 2: set up the public token

Store the public token in `~/.mapbox` like so:

```
YOUR_PUBLIC_MAPBOX_ACCESS_TOKEN
```

More info [here](https://docs.mapbox.com/help/troubleshooting/private-access-token-android-and-ios/#ios).

#### Step 3 (optional): set up the secret token

To be able to download the SDK via Swift Package Manager, you must first configure the secret token.

Edit your `~/.netrc` file to add the following lines:

```
machine api.mapbox.com
  login mapbox
  password YOUR_SECRET_MAPBOX_ACCESS_TOKEN
```

More info [here](https://docs.mapbox.com/ios/maps/guides/install/).

## Contribute

Want to help improve Austrian.rocks for climbers? Great!

Here are a few ways you can contribute:
- Open an issue if you find a bug
- Open an issue if you want to suggest an improvement
- Open a pull request for code, documentation, or data improvements

Please use the repository issues and pull requests to coordinate changes.
