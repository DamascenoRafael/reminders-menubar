BOB Auth Deep Link (Custom Token)

Overview
- The app accepts a Firebase custom token via the URL scheme `bobreminders://`.
- This allows completing auth in the system browser or web app, then passing the token back to the macOS app for Firebase sign-in.

URL format
- `bobreminders://auth?token=<FIREBASE_CUSTOM_TOKEN>`

App behavior
- The app handles the deep link and calls `Auth.auth().signIn(withCustomToken:)`.
- On success, the app updates the signed-in state (menu shows the user identity).

Web app flow (example)
1) Sign the user in with Google (or another provider) in your web app.
2) Mint a Firebase custom token for the user on your backend.
3) Redirect the browser to `bobreminders://auth?token=<CUSTOM_TOKEN>`.

Helper to start auth from the app
- The app can open your web app with a `return` param so the web app knows where to redirect after minting a custom token:
- Example opened by the app: `https://<your-app>/?return=bobreminders://auth&intent=customToken&uid=<current-or-known-uid>`
- Implement your web app to read `return`, mint a custom token, then `window.location = return + '?token=' + token`.

Manual fallback
- In the app’s Web Sign-in window, click “Paste Custom Token,” paste the token, and click “Sign In.”

Notes
- Ensure Google provider is enabled in Firebase and the macOS app is configured with the correct `GoogleService-Info.plist`.
- The existing Google native flow remains available and is preferred when possible.
