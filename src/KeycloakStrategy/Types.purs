module KeycloakStrategy.Types
  ( KeycloakStrategy(..)
  , KeycloakStrategyOptions(..)
  , Profile(..)
  , VerifyCallbackWithRequest
  , Request
  , Error  
  , User
  -- Export conversion helpers:
  , pipeForwards
  , (|>)
  , isUndefined
  , unsafeLookup
  , unwrap
  , unwrapRecord
  , renameKey
  , fromPassportProfile
  , toNativeProfile
  , object
  ) where

import Prelude
import Data.Maybe (Maybe(..))
import Data.Map (Map)
import Data.Nullable (null)
import Effect (Effect)
import Data.Argonaut.Encode.Class (class EncodeJson, encodeJson)
import Data.Argonaut.Decode.Class (class DecodeJson)
import Data.Argonaut.Decode.Combinators as ADC
import Data.Argonaut.Decode.Error (JsonDecodeError(..))
import Data.Tuple (Tuple(..))
import Data.Argonaut.Core (Json, fromObject, toObject)
import Foreign.Object as FO
import Foreign.Object (fromFoldable, keys, delete, insert)
import Foreign (Foreign, unsafeToForeign, typeOf)
import KeycloakStrategy.EncodableForeign (EncodableForeign)
import Data.Either (Either(..))
import Unsafe.Coerce (unsafeCoerce)

-- | Builds a JSON object from an Array of key/value pairs.
object :: Array (Tuple String Json) -> Json
object = fromObject <<< fromFoldable

-- | Represents the KeycloakStrategy instance (an opaque FFI type).
newtype KeycloakStrategy = KeycloakStrategy Foreign

-- | Options for configuring the KeycloakStrategy.
data KeycloakStrategyOptions = KeycloakStrategyOptions
  { ksoRealm            :: String
  , ksoAuthServerURL    :: String
  , ksoClientID         :: String
  , ksoCallbackURL      :: String
  , ksoPublicClient     :: Maybe Boolean
  , ksoClientSecret     :: Maybe String
  , ksoAuthorizationURL :: Maybe String
  , ksoTokenURL         :: Maybe String
  , ksoSslRequired      :: Maybe String
  , ksoScope            :: Maybe String
  , ksoCustomHeaders    :: Maybe (Map String String)
  , ksoScopeSeparator   :: Maybe String
  , ksoSessionKey       :: Maybe String
  , ksoStore            :: Maybe EncodableForeign
  , ksoState            :: Maybe Boolean
  , ksoSkipUserProfile  :: Maybe Boolean
  , ksoPkce             :: Maybe Boolean
  , ksoProxy            :: Maybe Boolean
  }

instance encodeJsonKeycloakStrategyOptions :: EncodeJson KeycloakStrategyOptions where
  encodeJson (KeycloakStrategyOptions { ksoRealm, ksoAuthServerURL, ksoClientID, ksoCallbackURL, ksoPublicClient, ksoClientSecret, ksoAuthorizationURL, ksoTokenURL, ksoSslRequired, ksoScope, ksoCustomHeaders, ksoScopeSeparator, ksoSessionKey, ksoStore, ksoState, ksoSkipUserProfile, ksoPkce, ksoProxy }) =
    object
      [ Tuple "realm"           (encodeJson ksoRealm)
      , Tuple "authServerURL"   (encodeJson ksoAuthServerURL)
      , Tuple "clientID"        (encodeJson ksoClientID)
      , Tuple "callbackURL"     (encodeJson ksoCallbackURL)
      , Tuple "publicClient"    (encodeJson ksoPublicClient)
      , Tuple "clientSecret"    (encodeJson ksoClientSecret)
      , Tuple "authorizationURL" (encodeJson ksoAuthorizationURL)
      , Tuple "tokenURL"        (encodeJson ksoTokenURL)
      , Tuple "sslRequired"     (encodeJson ksoSslRequired)
      , Tuple "scope"           (encodeJson ksoScope)
      , Tuple "customHeaders"   (encodeJson ksoCustomHeaders)
      , Tuple "scopeSeparator"  (encodeJson ksoScopeSeparator)
      , Tuple "sessionKey"      (encodeJson ksoSessionKey)
      , Tuple "store"           (encodeJson ksoStore)
      , Tuple "state"           (encodeJson ksoState)
      , Tuple "skipUserProfile" (encodeJson ksoSkipUserProfile)
      , Tuple "pkce"            (encodeJson ksoPkce)
      , Tuple "proxy"           (encodeJson ksoProxy)
      ]

instance decodeJsonKeycloakStrategyOptions :: DecodeJson KeycloakStrategyOptions where
  decodeJson json =
    case toObject json of
      Nothing -> Left (TypeMismatch "Expected an object for KeycloakStrategyOptions")
      Just obj -> do
        ksoRealm            <- ADC.getField obj "realm"
        ksoAuthServerURL    <- ADC.getField obj "authServerURL"
        ksoClientID         <- ADC.getField obj "clientID"
        ksoCallbackURL      <- ADC.getField obj "callbackURL"
        ksoPublicClient     <- ADC.getFieldOptional obj "publicClient"
        ksoClientSecret     <- ADC.getFieldOptional obj "clientSecret"
        ksoAuthorizationURL <- ADC.getFieldOptional obj "authorizationURL"
        ksoTokenURL         <- ADC.getFieldOptional obj "tokenURL"
        ksoSslRequired      <- ADC.getFieldOptional obj "sslRequired"
        ksoScope            <- ADC.getFieldOptional obj "scope"
        ksoCustomHeaders    <- ADC.getFieldOptional obj "customHeaders"
        ksoScopeSeparator   <- ADC.getFieldOptional obj "scopeSeparator"
        ksoSessionKey       <- ADC.getFieldOptional obj "sessionKey"
        ksoStore            <- ADC.getFieldOptional obj "store"
        ksoState            <- ADC.getFieldOptional obj "state"
        ksoSkipUserProfile  <- ADC.getFieldOptional obj "skipUserProfile"
        ksoPkce             <- ADC.getFieldOptional obj "pkce"
        ksoProxy            <- ADC.getFieldOptional obj "proxy"
        pure $ KeycloakStrategyOptions
          { ksoRealm
          , ksoAuthServerURL
          , ksoClientID
          , ksoCallbackURL
          , ksoPublicClient
          , ksoClientSecret
          , ksoAuthorizationURL
          , ksoTokenURL
          , ksoSslRequired
          , ksoScope
          , ksoCustomHeaders
          , ksoScopeSeparator
          , ksoSessionKey
          , ksoStore
          , ksoState
          , ksoSkipUserProfile
          , ksoPkce
          , ksoProxy
          }

-- | User profile obtained from Keycloak.
-- Internal field names are prefixed with "profile" to avoid clashes.
data Profile = Profile
  { profileProvider    :: String
  , profileId          :: String
  , profileDisplayName :: Maybe String
  , profileUsername    :: Maybe String
  , profileEmails      :: Maybe (Array { value :: String })
  , profileRaw         :: Maybe String
  , profileJson        :: Maybe EncodableForeign
  , profileIdToken     :: Maybe String
  }

instance Show Profile where
  show (Profile p) = 
    "Profile { profileProvider: " <> p.profileProvider <>
    ", profileId: "               <> p.profileId  <>
    ", profileDisplayName: "      <> show p.profileDisplayName <>
    ", profileUsername: "         <> show p.profileUsername <>
    " }"

instance encodeJsonProfile :: EncodeJson Profile where
  encodeJson (Profile { profileProvider, profileId, profileDisplayName, profileUsername, profileEmails, profileRaw, profileJson, profileIdToken }) =
    object
      [ Tuple "provider"    (encodeJson profileProvider)
      , Tuple "id"          (encodeJson profileId)
      , Tuple "displayName" (encodeJson profileDisplayName)
      , Tuple "username"    (encodeJson profileUsername)
      , Tuple "emails"      (encodeJson profileEmails)
      , Tuple "_raw"        (encodeJson profileRaw)
      , Tuple "_json"       (encodeJson profileJson)
      , Tuple "_id_token"   (encodeJson profileIdToken)
      ]

instance decodeJsonProfile :: DecodeJson Profile where
  decodeJson json =
    case toObject json of
      Nothing -> Left (TypeMismatch "Expected an object for Profile")
      Just obj -> do
        pProv   <- ADC.getField obj ("provider" :: String)     :: Either JsonDecodeError String
        pId     <- ADC.getField obj ("id" :: String)           :: Either JsonDecodeError String
        pDisp   <- ADC.getField obj ("displayName" :: String)  :: Either JsonDecodeError (Maybe String)
        pUser   <- ADC.getField obj ("username" :: String)     :: Either JsonDecodeError (Maybe String)
        pEmails <- ADC.getField obj ("emails" :: String)       :: Either JsonDecodeError (Maybe (Array { value :: String }))
        pRaw    <- ADC.getField obj ("_raw" :: String)         :: Either JsonDecodeError (Maybe String)
        pJson   <- ADC.getField obj ("_json" :: String)        :: Either JsonDecodeError (Maybe EncodableForeign)
        pIdToken<- ADC.getField obj ("_id_token" :: String)    :: Either JsonDecodeError (Maybe String)
        pure (Profile { profileProvider: pProv
                      , profileId: pId
                      , profileDisplayName: pDisp
                      , profileUsername: pUser
                      , profileEmails: pEmails
                      , profileRaw: pRaw
                      , profileJson: pJson
                      , profileIdToken: pIdToken
                      })

type Request = Foreign
type Error   = EncodableForeign
type User    = Foreign

type VerifyCallbackWithRequest =
  Request -> String -> String -> Profile -> (Error -> Maybe User -> Effect Unit) -> Effect Unit

-- Conversion and helper functions

-- | Pipeline operator
pipeForwards :: forall a b. a -> (a -> b) -> b
pipeForwards x f = f x

infixl 1 pipeForwards as |>

-- | Check if a Foreign value is undefined.
isUndefined :: Foreign -> Boolean
isUndefined x = typeOf x == "undefined"

-- | Lookup helper.
unsafeLookup :: String -> Foreign -> Foreign
unsafeLookup key obj = unsafeCoerce (FO.lookup key (unsafeCoerce obj))

-- | Recursively unwrap a value if it’s an object with a "value0" property.
unwrap :: Foreign -> Foreign
unwrap x =
  if typeOf x == "object" then
    case FO.lookup "value0" (unsafeCoerce x) of
      Just v -> unwrap v
      Nothing -> x
  else
    x

-- | Unwrap every field of a record.
unwrapRecord :: Foreign -> Foreign
unwrapRecord obj =
  let ks = keys (unsafeCoerce obj)
      pairs = map (\k ->
                      case FO.lookup k (unsafeCoerce obj) of
                        Nothing -> Tuple k (unsafeToForeign null)
                        Just val -> Tuple k (unwrap val)
                  ) ks
  in unsafeToForeign (fromFoldable pairs)

-- Rename a key in a record.
renameKey :: String -> String -> Foreign -> Foreign
renameKey oldKey newKey obj =
  let val = unsafeLookup oldKey obj in
  if isUndefined val then obj
  else
    let withoutOld = delete oldKey (unsafeCoerce obj)
        updated = insert newKey val withoutOld
    in unsafeToForeign updated

-- | Convert a PureScript-constructed profile (with "profile" prefixes)
-- to a native Keycloak profile.
toNativeProfile :: Foreign -> Foreign
toNativeProfile obj =
  let renamed =
        obj
          |> renameKey "profileId" "id"
          |> renameKey "profileProvider" "provider"
          |> renameKey "profileDisplayName" "displayName"
          |> renameKey "profileUsername" "username"
          |> renameKey "profileEmails" "emails"
          |> renameKey "profileRaw" "_raw"
          |> renameKey "profileJson" "_json"
          |> renameKey "profileIdToken" "_id_token"
  in unwrapRecord renamed

-- | Convert a raw Passport profile (with keys "id", "provider", etc.) 
-- into the intermediate form expected by toNativeProfile.
fromPassportProfile :: Foreign -> Foreign
fromPassportProfile raw =
  raw
    |> renameKey "id"         "profileId"
    |> renameKey "provider"   "profileProvider"
    |> renameKey "displayName" "profileDisplayName"
    |> renameKey "username"   "profileUsername"
    |> renameKey "emails"     "profileEmails"
    |> renameKey "_raw"       "profileRaw"
    |> renameKey "_json"      "profileJson"
    |> renameKey "_id_token"  "profileIdToken"
