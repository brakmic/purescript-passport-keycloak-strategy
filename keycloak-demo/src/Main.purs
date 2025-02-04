module Main where

import Prelude
import Effect (Effect)
import Keycloak.Demo.Config (loadConfig)
import Keycloak.Demo.Server (setupServer)

main :: Effect Unit
main = do
  config <- loadConfig
  setupServer config
