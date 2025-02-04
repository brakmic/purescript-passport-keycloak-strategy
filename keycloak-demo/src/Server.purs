module Keycloak.Demo.Server where

import Prelude (Unit, bind, discard, pure, show, unit, ($), (<>))
import Effect (Effect)
import Effect.Console (log)
import Data.Either (Either(..))
import Data.Nullable (null)
import Keycloak.Demo.Foreign.Express (Server, createServer, listen)
import Keycloak.Demo.Config (ServerConfig, makeKeycloakOptions)
import Foreign.KeycloakStrategy.ForeignKeycloakStrategy as Foreign
import Unsafe.Coerce (unsafeCoerce)
import Foreign (Foreign, unsafeToForeign)
import KeycloakStrategy.Types (fromPassportProfile, toNativeProfile, Profile)

-- | Helper function that calls the raw JS `done` callback.
-- This function will be used in verifyCallback.
foreign import callDone :: Foreign -> Foreign -> Foreign -> Effect Unit

-- | Setup Express.js Server
setupServer :: ServerConfig -> Effect Unit
setupServer config = do
  server <- createServer
  setupStrategy server config
  listen server config.port
  log $ "Server running on http://localhost:" <> show config.port
  log $ "Visit http://localhost:" <> show config.port <> "/auth/keycloak-init to start authentication"

-- | Setup KeycloakStrategy instance
setupStrategy :: Server -> ServerConfig -> Effect Unit
setupStrategy _ config = do
  let options = makeKeycloakOptions config
  strategyE <- Foreign.createKeycloakStrategy options (unsafeCoerce verifyCallback')
  case strategyE of 
    Left _ -> log "Failed to create strategy"
    Right strategy -> do
      _ <- Foreign.usePassportStrategy strategy
      pure unit

-- | Verify callback that prints out the tokens
verifyCallback'
  :: Foreign
  -> String
  -> String
  -> Profile
  -> Foreign
  -> Effect (Unit -> Effect Unit)
verifyCallback' _ accessToken refreshToken profile done = do
  log "=== Verify Callback ==="
  log ("Access Token: " <> accessToken)
  log ("Refresh Token: " <> refreshToken)
  -- Convert to JSON object that JS expects
  let rawProfile    = unsafeCoerce profile :: Foreign
  let nativeProfile = toNativeProfile (fromPassportProfile rawProfile)
  _ <- callDone done (unsafeToForeign null) nativeProfile
  pure (\_ -> pure unit)
