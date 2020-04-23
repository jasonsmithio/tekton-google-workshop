<!-- https://cloud.google.com/run/docs/quickstarts/build-and-deploy#python -->
<!-- https://cloud.google.com/python/getting-started/ -->

# Google Python Bookshelf App

Let's build the bookshelf app. First we need to setup a Firestore.

## Firestore

1. Go [here](https://pantheon.corp.google.com/firestore) to navigate to Firestore. Depending on how you setup your project previously, it may tell you that Datastore. If it does, just click the *Go To Datastore Page* button.
2. From the Select a Firestore mode screen, click Select Native Mode.
3. Select a location for your Firestore database. This location setting is the default Google Cloud resource location for your Cloud project . This location is used for Google Cloud services in your Cloud project that require a location setting, specifically, your default Cloud Storage bucket and your Cloud Run app.
4. Click Create Database