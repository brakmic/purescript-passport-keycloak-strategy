module Foreign.KeycloakStrategy.ForeignKeycloakStrategy where

import Prelude
import Effect (Effect)
import Foreign (Foreign)
import Data.Either (Either(..))
import KeycloakStrategy.Types (KeycloakStrategy(..), KeycloakStrategyOptions, VerifyCallbackWithRequest)

foreign import logOptions :: KeycloakStrategyOptions -> Effect Unit

foreign import rawCreateKeycloakStrategy ::
  KeycloakStrategyOptions -> VerifyCallbackWithRequest -> Effect Foreign

createKeycloakStrategy ::
  KeycloakStrategyOptions -> VerifyCallbackWithRequest -> Effect (Either Foreign KeycloakStrategy)
createKeycloakStrategy options verify = do
  strategy <- rawCreateKeycloakStrategy options verify
  pure $ Right $ KeycloakStrategy strategy

foreign import usePassportStrategy ::
  KeycloakStrategy -> Effect Unit
