{-# OPTIONS_HADDOCK not-home #-}

{-# LANGUAGE AllowAmbiguousTypes    #-}
{-# LANGUAGE DataKinds              #-}
{-# LANGUAGE FlexibleInstances      #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE PolyKinds              #-}
{-# LANGUAGE ScopedTypeVariables    #-}
{-# LANGUAGE TypeApplications       #-}
{-# LANGUAGE TypeFamilies           #-}
{-# LANGUAGE TypeOperators          #-}
{-# LANGUAGE UndecidableInstances   #-}

{-|
Module      : Data.Generic.HKD.Field
Description : Manipulate HKD structures using field names.
Copyright   : (c) Tom Harding, 2019
License     : MIT
Maintainer  : tom.harding@habito.com
Stability   : experimental
-}
module Data.Generic.HKD.Field
  ( HasField' (..)
  ) where

import Control.Lens (Lens', dimap)
import Data.Generic.HKD.Types (HKD (..), HKD_)
import Data.Kind (Type)
import GHC.TypeLits (Symbol)
import qualified Data.GenericLens.Internal as G
import qualified Data.Generics.Internal.VL.Lens as G

-- | When we work with records, all the fields are named, and we can refer to
-- them using these names. This class provides a lens from our HKD structure to
-- any @f@-wrapped field.
--
-- >>> :set -XDataKinds -XDeriveGeneric
-- >>> import Control.Lens ((&), (.~))
-- >>> import Data.Monoid (Last)
-- >>> import GHC.Generics
--
-- >>> data User = User { name :: String, age :: Int } deriving (Generic, Show)
-- >>> type Partial = HKD Last
--
-- We can create an empty partial @User@ and set its name to "Tom" (which, in
-- this case, is @pure "Tom" :: Last String@):
--
-- >>> mempty @(Partial User) & field @"name" .~ pure "Tom"
-- User {name = Last {getLast = Just "Tom"}, age = Last {getLast = Nothing}}
--
-- Thanks to some @generic-lens@ magic, we also get some pretty magical type
-- errors! If we create a (complete) partial user:
--
-- >>> import Data.Generic.HKD.Construction (deconstruct)
-- >>> total = deconstruct @Last (User "Tom" 25)
--
-- ... and then try to access a field that isn't there, we get a friendly
-- message to point us in the right direction:
--
-- >>> total & field @"oops" .~ pure ()
class HasField'
    (field     ::       Symbol)
    (f         :: Type -> Type)
    (structure ::         Type)
    (focus     ::         Type)
    | field f structure -> focus where
  field :: Lens' (HKD f structure) (f focus)

data FieldPredicate :: Symbol -> G.TyFun (Type -> Type) (Maybe Type)
type instance G.Eval (FieldPredicate sym) tt = G.HasTotalFieldP sym tt

instance G.GLens' (FieldPredicate field) (HKD_ f structure) (f focus)
    => HasField' field f structure focus where
  field = G.ravel (dimap runHKD HKD . G.glens @(FieldPredicate field))
