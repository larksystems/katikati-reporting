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
