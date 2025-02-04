module Keycloak.Demo.Config where

import Prelude
import Effect (Effect)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Int (fromString)
import Node.Process (lookupEnv)
import KeycloakStrategy.Types (KeycloakStrategyOptions(..))

type ServerConfig = 
  { port :: Int
  , realm :: String
  , authServerURL :: String
  , clientId :: String
  , callbackURL :: String
  }

defaultConfig :: ServerConfig
defaultConfig = 
  { port: 3002
  , realm: "TestRealm"
  , authServerURL: "http://keycloak:8080"
  , clientId: "test-client"
  , callbackURL: "http://localhost:3002/auth/keycloak/callback"
  }

loadConfig :: Effect ServerConfig
loadConfig = do
  mPort <- lookupEnv "PORT"
  mRealm <- lookupEnv "KEYCLOAK_REALM"
  mAuthServerURL <- lookupEnv "KEYCLOAK_AUTH_SERVER_URL"
  mClientId <- lookupEnv "KEYCLOAK_CLIENT_ID"
  mCallbackURL <- lookupEnv "KEYCLOAK_CALLBACK_URL"
  pure $ defaultConfig
    { port = fromMaybe defaultConfig.port (map (\s -> fromMaybe defaultConfig.port (fromString s)) mPort)
    , realm = fromMaybe defaultConfig.realm mRealm
    , authServerURL = fromMaybe defaultConfig.authServerURL mAuthServerURL
    , clientId = fromMaybe defaultConfig.clientId mClientId
    , callbackURL = fromMaybe defaultConfig.callbackURL mCallbackURL
    }

makeKeycloakOptions :: ServerConfig -> KeycloakStrategyOptions
makeKeycloakOptions config = KeycloakStrategyOptions
  { ksoRealm: config.realm
  , ksoAuthServerURL: config.authServerURL
  , ksoClientID: config.clientId
  , ksoCallbackURL: config.callbackURL
  , ksoPublicClient: Just true
  , ksoClientSecret: Nothing
  , ksoAuthorizationURL: Nothing
  , ksoTokenURL: Nothing
  , ksoSslRequired: Just "none"
  , ksoScope: Just "openid profile email"
  , ksoCustomHeaders: Nothing
  , ksoScopeSeparator: Just " "
  , ksoSessionKey: Nothing
  , ksoStore: Nothing
  , ksoState: Just true
  , ksoSkipUserProfile: Just false
  , ksoPkce: Just true
  , ksoProxy: Nothing
  }
