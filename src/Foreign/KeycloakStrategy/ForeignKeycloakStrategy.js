import passport from 'passport';
import KeycloakStrategy from 'passport-keycloak-oauth2-oidc-portable';

export const logOptions = (options) => () => {
  console.log('Raw options:', JSON.stringify(options, null, 2));
};

export const rawCreateKeycloakStrategy = (options) => (verify) => () => {
  const opts = options.value0;
  const strategy = new KeycloakStrategy({
    realm: opts.ksoRealm,
    authServerURL: opts.ksoAuthServerURL,
    clientID: opts.ksoClientID,
    callbackURL: opts.ksoCallbackURL,
    publicClient: opts.ksoPublicClient?.value0 ?? true,
    state: opts.ksoState?.value0 ?? true,
    pkce: opts.ksoPkce?.value0 ?? true,
    sslRequired: opts.ksoSslRequired?.value0 ?? 'none',
    scope: opts.ksoScope?.value0 ?? 'openid profile email',
    scopeSeparator: opts.ksoScopeSeparator?.value0 ?? ' ',
    clientSecret: opts.ksoClientSecret?.value0,
    authorizationURL: opts.ksoAuthorizationURL?.value0,
    tokenURL: opts.ksoTokenURL?.value0,
    sessionKey: opts.ksoSessionKey?.value0,
    skipUserProfile: opts.ksoSkipUserProfile?.value0 ?? false,
    proxy: opts.ksoProxy?.value0,
    customHeaders: opts.ksoCustomHeaders?.value0,
  }, (req, accessToken, refreshToken, rawProfile, done) => {
    try {
      verify(req)(accessToken)(refreshToken)(rawProfile)((err, user) => {
        if (err) {
          return done(err);
        }
        done(null, user);
      })();
      
    } catch (error) {
      console.error('Strategy Error:', error);
      done(error);
    }
  });
  return strategy;
};

export const usePassportStrategy = (strategy) => () => {
  passport.use(strategy);
};

