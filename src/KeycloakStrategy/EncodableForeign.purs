module KeycloakStrategy.EncodableForeign where

import Data.Argonaut.Core (jsonNull)
import Data.Argonaut.Encode.Class (class EncodeJson)
import Data.Argonaut.Decode.Class (class DecodeJson)
import Foreign (Foreign)
import Unsafe.Coerce (unsafeCoerce)
import Data.Either (Either(..))

newtype EncodableForeign = EncodableForeign Foreign

instance encodeJsonEncodableForeign :: EncodeJson EncodableForeign where
  encodeJson _ = jsonNull

instance decodeJsonEncodableForeign :: DecodeJson EncodableForeign where
  decodeJson json = Right (EncodableForeign (unsafeCoerce json))
