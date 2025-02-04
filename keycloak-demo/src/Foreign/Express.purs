module Keycloak.Demo.Foreign.Express where

import Prelude
import Effect (Effect)
import Foreign (Foreign)
-- import Data.Maybe (Maybe)

foreign import data Server :: Type
foreign import data Request :: Type
foreign import data Response :: Type
foreign import data Session :: Type

type Next = Effect Unit

foreign import fromForeign :: Foreign -> Request

-- FFI imports from Express.js
foreign import createServerImpl :: Effect Server
foreign import listenImpl :: Server -> Int -> Effect Unit

-- foreign import getImpl :: Server -> String -> (Request -> Response -> Effect Unit) -> Effect Unit
-- foreign import setSessionImpl :: Request -> String -> Foreign -> Effect Unit
-- foreign import getSessionImpl :: Request -> String -> Effect (Maybe Foreign)
-- foreign import destroySessionImpl :: Request -> Effect Unit
-- foreign import isAuthenticatedImpl :: Request -> Effect Boolean
-- foreign import redirectImpl :: Response -> String -> Effect Unit
-- foreign import sendImpl :: Response -> String -> Effect Unit
-- foreign import statusImpl :: Response -> Int -> Effect Response
-- foreign import loginImpl :: Request -> Foreign -> Effect Unit

-- Server operations
createServer :: Effect Server
createServer = createServerImpl

listen :: Server -> Int -> Effect Unit
listen = listenImpl

-- Route handling
-- get :: Server -> String -> (Request -> Response -> Effect Unit) -> Effect Unit
-- get = getImpl

-- -- Session operations
-- setSession :: forall a. Request -> String -> a -> Effect Unit
-- setSession req key value = setSessionImpl req key (unsafeToForeign value)

-- getSession :: forall a. Request -> String -> Effect (Maybe a)
-- getSession req key = do
--   mValue <- getSessionImpl req key
--   pure $ map unsafeFromForeign mValue

-- destroySession :: Request -> Effect Unit
-- destroySession = destroySessionImpl

-- isAuthenticated :: Request -> Effect Boolean
-- isAuthenticated = isAuthenticatedImpl

-- -- Response helpers
-- redirect :: Response -> String -> Effect Unit
-- redirect = redirectImpl

-- send :: Response -> String -> Effect Unit
-- send = sendImpl

-- status :: Response -> Int -> Effect Response
-- status = statusImpl

-- login :: Request -> Foreign -> Effect Unit
-- login = loginImpl
