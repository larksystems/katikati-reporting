# katikati-reporting

### To develop

- Make sure the project is listed under `deploy/project_config.json`.
- Run `dart dev.dart <project-name> && webdev serve`.

### To build

- Update the projects you want to build under `deploy/project_config.json`.
- Run `dart build.dart`.
- This produces the build for all the projects listed. `build/proj1` `build/proj2`

### To deploy

- Make sure `firebase login` is connected and has access to the projects under `.firebaserc`
- Run the build steps from above.
- Run `firebase deploy` to update all the db & firestore rules, and to deploy all the build folders to firebase.
- Optional: Run `firebase deploy --only hosting` to deploy only the build folders.
- The projects are accessible in the browser at `[hostname-from-firebase-deploy-log]/[project-name]/web`

---

### Base config

Located under `config/base_config.json`
Currently used keys

**Firebase**

```
  "apiKey": "KEY",
  "authDomain": "XXXXXXXXX.firebaseapp.com",
  "databaseURL": "https://XXXXXXXXX.firebaseio.com",
  "projectId": "XXXXXXXXX",
  "storageBucket": "XXXXXXXXX.appspot.com",
  "messagingSenderId": "1111111111",
  "appId": "1:1111111111:web:2222222222",
  "measurementId": "G-YYYYYYYYYY",
```

[Firebase console](https://console.firebase.google.com/) > project > project settings > `Firebase SDK snippet`

**Mapbox**

```
  "mapboxKey": "pk.KEY",
  "mapboxStyleURL": "mapbox://styles/user/map_id"
```

After signup with mapbox, [visit here](https://account.mapbox.com/access-tokens/) to get the `mapboxKey` (public key).
`mapboxStyleURL` can be generated after customising the map at [mapbox studio](https://www.mapbox.com/mapbox-studio/)

### Project specific config

Located under `config/project_config.json`

```
{
    "project_1_name": {
        "metadataPath": "datasets/path/to/metadata/settings",
        "allowedEmailDomains": ["domain.com", "email.com"]
    }
}
```

`metadataPath` is the path in firestore to retrieve the settings authored in the "Settings" tab of the dashboard
`allowedEmailDomains` does a softcheck to remove the email IDs that are used to sign up, but do not have access to the dataset.
