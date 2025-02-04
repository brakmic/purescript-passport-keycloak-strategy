## Overview

At a high level, the system implements an OIDC authentication flow where a client (written in PureScript) communicates with a Keycloak server through a Node.js/Express backend. The flow is designed for public clients (using PKCE) and follows these steps:

1. **Initialization:**  
   The client requests authentication by navigating to a URL (e.g. `/auth/keycloak-init`), which prepares a PKCE code challenge and redirects the user to Keycloak’s login page.

2. **Authentication:**  
   After logging in at Keycloak, the user is redirected back to the callback URL (e.g. `/auth/keycloak/callback`) on the Express server. Passport (integrated via our PureScript strategy) processes the returned tokens and user profile.

3. **Profile Conversion & Session Establishment:**  
   The PureScript verify callback converts the internal profile (a structured value with extra safety wrappers) into a native JavaScript object using conversion helpers. This object is then passed to Passport’s callback so that the session is established.

4. **Access and Logout:**  
   Once authenticated, the user can view their profile (rendered via an EJS view) and later log out, which terminates both the local session and the Keycloak SSO session.

---

## File Structure & Key Modules

Below is a brief overview of the most important parts of the project and what they do:

### 1. Main.purs

- **Role:**  
  The entry point of the application. It loads configuration (from environment variables or defaults) and starts the server.
- **Flow:**  
  It calls `loadConfig` to read necessary settings (e.g. port, realm, URLs) and then invokes `setupServer` to boot up the Express server.

### 2. Server.purs

- **Role:**  
  This module is responsible for configuring the Express server and setting up the Keycloak strategy.
- **Key Methods:**
  - **setupServer:**  
    Calls FFI functions to create and start the server. It also logs key startup messages.
  - **setupStrategy:**  
    Converts the loaded configuration into Keycloak strategy options (using `makeKeycloakOptions`), logs these options for debugging, creates the Keycloak strategy via an FFI call, and registers it with Passport.
  - **verifyCallback':**  
    The verify callback is invoked by the strategy when Keycloak responds with tokens and a user profile. It logs the access and refresh tokens and then calls helper functions (like `fromPassportProfile` and `toNativeProfile`) to convert the PureScript profile into a native JavaScript object. Finally, it calls the FFI helper `callDone` to pass this object back to Passport for session establishment.

### 3. Express FFI (Express.purs and Express.js)

- **Role:**  
  These files provide a bridge between PureScript and Express.js. They define types for the server, request, response, and session, and declare FFI imports (e.g. `createServerImpl`, `listenImpl`).
- **Express.js:**  
  Contains the JavaScript implementation for functions such as `callDone`, which is curried to match PureScript’s style. This function directly invokes Passport’s callback, passing along the error (if any) and the native user profile.

### 4. Configuration (Config.purs)

- **Role:**  
  Reads environment variables using the `lookupEnv` function from the Node.Process module. It provides a default configuration and exposes `loadConfig` and `makeKeycloakOptions` to standardize how configuration data is passed to the rest of the application.
- **Note:**  
  The callback URL, realm, client ID, and Keycloak server URL are critical to ensuring that the OAuth flow works correctly.

### 5. Conversion Helpers (in KeycloakStrategy.Types)

- **Role:**  
  This module defines the data types for profiles and strategy options. Importantly, it also exports several helper functions:
  - **pipeForwards (`|>`):**  
    A simple pipeline operator to make function application more readable.
  - **renameKey, unwrap, unwrapRecord, toNativeProfile, fromPassportProfile:**  
    These functions transform a PureScript-constructed profile into a native JavaScript object. The conversion is necessary because PureScript’s representation (with internal prefixes like `profileId`) is safer for internal logic, but the underlying Passport strategy expects plain JSON with keys such as `id` and `_id_token`.

### 6. ForeignKeycloakStrategy

- **Role:**  
  This module is the PureScript interface to the npm package [passport-keycloak-oauth2-oidc-portable](https://github.com/brakmic/passport-keycloak-oauth2-oidc-portable). It exposes FFI functions like `rawCreateKeycloakStrategy` and `usePassportStrategy`, and wraps them to provide a more ergonomic interface.
- **Key Methods:**
  - **logOptions:**  
    (For debugging) logs the options passed to Keycloak.
  - **createKeycloakStrategy:**  
    Creates a Keycloak strategy by invoking the raw JavaScript implementation.
  - **usePassportStrategy:**  
    Registers the strategy with Passport, so it is used during the authentication flow.

---

## Application Flow in Detail

```
 User                   Demo App (Keycloak Strategy)          Keycloak Server
   |                              |                                  |
   | 1. Init Login                |                                  |
   |----------------------------> |                                  |
   |                              | 2. Generate PKCE + Redirect      |
   |                              | 3. Send user to Keycloak         |
   |                              |--------------------------------> |
   |                              |                                  |
   |                              |                                  | 4. User logs in
   |                              |                                  | 5. Validate credentials
   |                              |                                  | 6. Redirect w/ Auth Code
   |                              | <------------------------------- |
   |                              |                                  |
   | 7. Callback                  |                                  |
   |----------------------------> |                                  |
   |                              | 8. Exchange code for tokens      |
   |                              | 9. Verify callback, set session  |
   |                              | 10. Redirect to /profile         |
   |                              |--------------------------------> |
   |                              |                                  |
   | 11. Access /profile          |                                  |
   |----------------------------> |                                  |
   |                              | 12. Check session, render page   |
   |                              | <------------------------------> |
   |                              |                                  |
   | 13. Logout                   |                                  |
   |----------------------------> |                                  |
   |                              | 14. Destroy session              |
   |                              | 15. Redirect to Keycloak logout  |
   |                              |--------------------------------> |
   |                              |                                  |
   |                              |                                  | 16. Keycloak terminates session
   |                              |                                  | 17. Redirect back to app
   |                              | <------------------------------- |
   | 18. Show logout confirmation |                                  |
   |----------------------------> |                                  |
```

1. **High-Level Flow:**  
   A user wishing to log in is redirected to Keycloak via a URL generated by the PureScript server. After successful authentication on Keycloak’s side, the user is redirected back to the Express server, which processes the returned tokens and user profile.

2. **Server Bootstrapping:**  
   - **Main.purs** loads configuration and calls `setupServer`.
   - **setupServer (Server.purs)** calls FFI functions from Express (via Express.purs) to create the server, registers routes, and listens on the configured port.

3. **Authentication Handling:**  
   - The `/auth/keycloak-init` route sets up a PKCE code challenge and redirects the user to the `/auth/keycloak` route.
   - **Passport Authentication:**  
     When the user is redirected back (via `/auth/keycloak/callback`), Passport (configured in Express.js) triggers the verify callback.
   - **Verify Callback:**  
     The verify callback (in Server.purs) logs the tokens and calls conversion helpers (e.g., `fromPassportProfile` and `toNativeProfile`) to convert the PureScript profile into the native object expected by Passport. Finally, it invokes the FFI function `callDone` to complete the process.

4. **Profile Rendering & Logout:**  
   - Once authentication is complete, the user is redirected to `/profile`, where the native profile is rendered using an EJS template.
   - The `/logout` route destroys the session and, if applicable, logs the user out of Keycloak using the `id_token`.

