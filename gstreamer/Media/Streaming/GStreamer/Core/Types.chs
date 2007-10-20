--  GIMP Toolkit (GTK) Binding for Haskell: binding to gstreamer -*-haskell-*-
--
--  Author : Peter Gavin
--  Created: 1-Apr-2007
--
--  Copyright (c) 2007 Peter Gavin
--
--  This library is free software: you can redistribute it and/or
--  modify it under the terms of the GNU Lesser General Public License
--  as published by the Free Software Foundation, either version 3 of
--  the License, or (at your option) any later version.
--  
--  This library is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
--  Lesser General Public License for more details.
--  
--  You should have received a copy of the GNU Lesser General Public
--  License along with this program.  If not, see
--  <http://www.gnu.org/licenses/>.
--  
--  GStreamer, the C library which this Haskell library depends on, is
--  available under LGPL Version 2. The documentation included with
--  this library is based on the original GStreamer documentation.

-- #hide

-- | Maintainer  : gtk2hs-devel\@lists.sourceforge.net
--   Stability   : alpha
--   Portability : portable (depends on GHC)
module Media.Streaming.GStreamer.Core.Types (
  
  module Media.Streaming.GStreamer.Core.Constants,
  module Media.Streaming.GStreamer.Core.Hierarchy,
  module Media.Streaming.GStreamer.Core.HierarchyBase,
  module Media.Streaming.GStreamer.Core.MiniHierarchy,
  module Media.Streaming.GStreamer.Core.MiniHierarchyBase,
  module Media.Streaming.GStreamer.Core.GObjectHierarchy,
  
  cToFlags,
  cFromFlags,
  cToEnum,
  cFromEnum,
  
  FourCC,
  Fraction,
  
  Format(..),
  FormatDefinition(..),
  
  mkObjectGetFlags,
  mkObjectSetFlags,
  mkObjectUnsetFlags,
  
  withObject,
  peekObject,
  takeObject,
  giveObject,
  
  PadDirection(..),
  PadPresence(..),
  PadLinkReturn(..),
  FlowReturn(..),
  ActivateMode(..),
  
  State(..),
  StateChangeReturn(..),
  SeekFlags(..),
  SeekType(..),
  
  PluginFilter,
  PluginFeatureFilter,
  
  BusFunc,
  BusSyncReply(..),
  
  ClockTimeDiff,
  ClockReturn(..),
  ClockID(..),
  withClockID,
  takeClockID,
  peekClockID,
  
  IndexCertainty(..),
  IndexEntry(..),
  takeIndexEntry,
  peekIndexEntry,
  IndexEntryType(..),
  
  IndexLookupMethod(..),
  IndexFilter,
  IndexAssociation(..),
  AssocFlags(..),
  
  mkMiniObjectGetFlags,
  mkMiniObjectGetFlagsM,
  mkMiniObjectSetFlagsM,
  mkMiniObjectUnsetFlagsM,
  
  withMiniObject,
  peekMiniObject,
  takeMiniObject,
  giveMiniObject,
  MiniObjectM(..),
  liftMiniObjectM,
  marshalMiniObjectModify,
  
  QueryType,
  QueryTypeDefinition(..),
  
  EventTypeFlags(..),
  
  PtrIterator(..),
  Iterator(..),
  IteratorItem(..),
  IteratorResult(..),
  Iterable(..),
  IteratorFilter,
  IteratorFoldFunction,
  withIterator,
  takeIterator,
  peekIterator,
  -- giveIterator - not defined - iterators don't have a refcount and
  -- are not copyable
  
  Caps(..),
  withCaps,
  takeCaps,
  peekCaps,
  giveCaps,
  
  Structure(..),
  StructureForeachFunc,
  withStructure,
  takeStructure,
  peekStructure,
  giveStructure,
  StructureM(..),
  StructureMRep,
  
  TagList,
  withTagList,
  takeTagList,
  peekTagList,
  giveTagList,
  Tag,
  TagFlag,
  TagMergeMode,
  
  Segment(..),
  
  ) where

import Control.Monad       ( liftM )
import Control.Monad.Trans
import Data.Bits           ( shiftL
                           , bit
                           , (.|.) )
import Data.Ratio          ( Ratio )
import System.Glib.FFI
import System.Glib.Flags
{#import System.Glib.GType#}
{#import System.Glib.GObject#}
{#import System.Glib.GValue#}
import System.Glib.UTFString
import Media.Streaming.GStreamer.Core.Constants
import Media.Streaming.GStreamer.Core.HierarchyBase
{#import Media.Streaming.GStreamer.Core.MiniHierarchyBase#}
{#import Media.Streaming.GStreamer.Core.Hierarchy#}
{#import Media.Streaming.GStreamer.Core.MiniHierarchy#}
{#import Media.Streaming.GStreamer.Core.GObjectHierarchy#}

{# context lib = "gstreamer" prefix = "gst" #}

type FourCC = Word32
type Fraction = Ratio Int

{# enum GstParseError as ParseError {underscoreToCase} with prefix = "GST" deriving (Eq, Show) #}

cToFlags :: (Integral int, Flags flags)
         => int
         -> [flags]
cToFlags = toFlags . fromIntegral
cFromFlags :: (Integral int, Flags flags)
           => [flags]
           -> int
cFromFlags = fromIntegral . fromFlags

cToEnum :: (Integral int, Enum enum)
        => int
        -> enum
cToEnum = toEnum . fromIntegral
cFromEnum :: (Integral int, Enum enum)
           => enum
           -> int
cFromEnum = fromIntegral . fromEnum

--------------------------------------------------------------------

{# enum GstFormat as Format {underscoreToCase} with prefix = "GST" deriving (Eq, Show) #}

data FormatDefinition = FormatDefinition { formatValue       :: Format
                                         , formatNick        :: String
                                         , formatDescription :: String
                                         , formatQuark       :: Quark }
                        deriving (Eq, Show)
instance Storable FormatDefinition where
    sizeOf = undefined
    alignment = undefined
    peek ptr =
        do value       <- liftM cToEnum $ {# get GstFormatDefinition->value #} ptr
           nick        <- {# get GstFormatDefinition->nick #} ptr >>= peekUTFString
           description <- {# get GstFormatDefinition->description #} ptr >>= peekUTFString
           quark       <- {# get GstFormatDefinition->quark #} ptr
           return $ FormatDefinition value nick description quark
    poke _ _ = undefined
instance Iterable FormatDefinition where
    peekIterable = peek . castPtr
    withIterable = with

--------------------------------------------------------------------

withObject :: ObjectClass objectT
           => objectT
           -> (Ptr objectT -> IO a)
           -> IO a
withObject object action =
    let objectFPtr = unObject $ toObject object
    in withForeignPtr (castForeignPtr objectFPtr) action

peekObject, takeObject :: ObjectClass obj
                       => Ptr obj
                       -> IO obj
peekObject cObject = do
    liftM (unsafeCastGObject . GObject . castForeignPtr) $
        do cObjectRef $ castPtr cObject
           newForeignPtr (castPtr cObject) objectFinalizer
foreign import ccall unsafe "&gst_object_unref"
  objectFinalizer :: FunPtr (Ptr () -> IO ())
foreign import ccall unsafe "gst_object_ref"
  cObjectRef :: Ptr ()
             -> IO (Ptr ())

takeObject cObject =
    liftM (unsafeCastGObject . GObject . castForeignPtr) $
        do cObjectUnfloat $ castPtr cObject
           newForeignPtr (castPtr cObject) objectFinalizer
foreign import ccall unsafe "_hs_gst_object_unfloat"
  cObjectUnfloat :: Ptr ()
                 -> IO ()

mkObjectGetFlags :: (ObjectClass objectT, Flags flagsT)
                 => objectT
                 -> IO [flagsT]
mkObjectGetFlags object =
    liftM (toFlags . fromIntegral) $
        withObject (toObject object) cObjectGetFlags
foreign import ccall unsafe "_hs_gst_object_flags"
    cObjectGetFlags :: Ptr Object
                    -> IO CUInt

mkObjectSetFlags :: (ObjectClass objectT, Flags flagsT)
                 => objectT
                 -> [flagsT]
                 -> IO ()
mkObjectSetFlags object flags =
    withObject (toObject object) $ \cObject ->
        cObjectSetFlags cObject (fromIntegral $ fromFlags flags)
foreign import ccall unsafe "_hs_gst_object_flag_set"
    cObjectSetFlags :: Ptr Object
                    -> CUInt
                    -> IO ()

mkObjectUnsetFlags :: (ObjectClass objectT, Flags flagsT)
                   => objectT
                   -> [flagsT]
                   -> IO ()
mkObjectUnsetFlags object flags =
    withObject (toObject object) $ \cObject ->
        cObjectUnsetFlags cObject (fromIntegral $ fromFlags flags)
foreign import ccall unsafe "_hs_gst_object_flag_unset"
    cObjectUnsetFlags :: Ptr Object
                    -> CUInt
                    -> IO ()

-- | Use 'giveObject' to pass an object to a function that takes
--   ownership of it.
giveObject :: (ObjectClass obj, MonadIO m)
           => obj
           -> (obj -> m a)
           -> m a
giveObject obj action =
    do liftIO $ withObject (toObject obj) $ {# call gst_object_ref #} . castPtr
       action obj

--------------------------------------------------------------------

{# enum GstPadDirection  as PadDirection  {underscoreToCase} with prefix = "GST" deriving (Eq, Show) #}
{# enum GstPadPresence   as PadPresence   {underscoreToCase} with prefix = "GST" deriving (Eq, Show) #}
{# enum GstPadLinkReturn as PadLinkReturn {underscoreToCase} with prefix = "GST" deriving (Eq, Show) #}
{# enum GstFlowReturn    as FlowReturn    {underscoreToCase} with prefix = "GST" deriving (Eq, Show) #}
{# enum GstActivateMode  as ActivateMode  {underscoreToCase} with prefix = "GST" deriving (Eq, Show) #}

instance Iterable Pad where
    peekIterable = peekObject . castPtr
    withIterable = withObject

--------------------------------------------------------------------

{# enum GstPluginError as PluginError {underscoreToCase} with prefix = "GST" deriving (Eq, Show) #}

--------------------------------------------------------------------

{# enum GstSeekFlags as SeekFlags {underscoreToCase} with prefix = "GST" deriving (Eq, Bounded, Show) #}
instance Flags SeekFlags
{# enum GstSeekType  as SeekType  {underscoreToCase} with prefix = "GST" deriving (Eq, Show) #}
{# enum GstState     as State     {underscoreToCase} with prefix = "GST" deriving (Eq, Show) #}

{# enum GstStateChangeReturn as StateChangeReturn {underscoreToCase} with prefix = "GST" deriving (Eq, Show) #}

instance Iterable Element where
    peekIterable = peekObject . castPtr
    withIterable = withObject

--------------------------------------------------------------------

type PluginFilter = Plugin -> IO Bool
type PluginFeatureFilter = PluginFeature -> IO Bool

--------------------------------------------------------------------

{# enum GstBusSyncReply as BusSyncReply {underscoreToCase} with prefix = "GST" deriving (Eq, Show) #}

type BusFunc =  Bus
             -> Message
             -> IO Bool

--------------------------------------------------------------------

type ClockTimeDiff = Int64

{# enum GstClockReturn as ClockReturn {underscoreToCase} with prefix = "GST" deriving (Eq, Show) #}

{# pointer *GstClockID as ClockID foreign newtype #}
withClockID :: ClockID
            -> (Ptr ClockID -> IO a)
            -> IO a
withClockID (ClockID clockID) = withForeignPtr clockID
takeClockID, peekClockID :: Ptr ClockID
                        -> IO ClockID
takeClockID clockIDPtr =
    liftM ClockID $ newForeignPtr clockIDPtr clockIDFinalizer
peekClockID clockIDPtr =
    do {# call clock_id_ref #} $ castPtr clockIDPtr
       takeClockID clockIDPtr

foreign import ccall unsafe "&gst_clock_id_unref"
    clockIDFinalizer :: FunPtr (Ptr ClockID -> IO ())

--------------------------------------------------------------------

{# enum GstIndexCertainty    as IndexCertainty    {underscoreToCase} with prefix = "GST" deriving (Eq, Show) #}
{# enum GstIndexEntryType    as IndexEntryType    {underscoreToCase} with prefix = "GST" deriving (Eq, Show) #}
{# enum GstIndexLookupMethod as IndexLookupMethod {underscoreToCase} with prefix = "GST" deriving (Eq, Show) #}

{# pointer *GstIndexEntry as IndexEntry foreign newtype #}

takeIndexEntry :: Ptr IndexEntry
              -> IO IndexEntry
takeIndexEntry ptr =
    liftM IndexEntry $ newForeignPtr ptr indexEntryFinalizer
foreign import ccall unsafe "&gst_index_entry_free"
    indexEntryFinalizer :: FunPtr (Ptr IndexEntry -> IO ())
peekIndexEntry :: Ptr IndexEntry
               -> IO IndexEntry
peekIndexEntry ptr =
    (liftM IndexEntry $ newForeignPtr_ ptr) >>=
        {# call index_entry_copy #} >>=
            takeIndexEntry

type IndexFilter  = Index
                 -> IndexEntry
                 -> IO Bool

data IndexAssociation = IndexAssociation Format Int64
                        deriving (Eq, Show)
instance Storable IndexAssociation where
    sizeOf _ = {# sizeof GstIndexAssociation #}
    alignment _ = alignment (undefined :: CString)
    peek ptr =
        do format <- {# get GstIndexAssociation->format #} ptr
           value <- {# get GstIndexAssociation->value #} ptr
           return $ IndexAssociation (cToEnum format) (fromIntegral value)
    poke ptr (IndexAssociation format value) =
        do {# set GstIndexAssociation->format #} ptr $ cFromEnum format
           {# set GstIndexAssociation->value #} ptr $ fromIntegral value

{# enum GstAssocFlags as AssocFlags {underscoreToCase} with prefix = "GST" deriving (Eq, Bounded, Show) #}
instance Flags AssocFlags

--------------------------------------------------------------------

withMiniObject :: MiniObjectClass miniObjectT
               => miniObjectT
               -> (Ptr miniObjectT -> IO a)
               -> IO a
withMiniObject miniObject action =
    let miniObjectFPtr = unMiniObject $ toMiniObject miniObject
    in withForeignPtr (castForeignPtr miniObjectFPtr) action

takeMiniObject, peekMiniObject :: (MiniObjectClass obj)
                               => Ptr obj
                               -> IO obj
peekMiniObject cMiniObject =
    do cMiniObjectRef $ castPtr cMiniObject
       takeMiniObject cMiniObject
foreign import ccall unsafe "gst_mini_object_ref"
  cMiniObjectRef :: Ptr ()
                 -> IO (Ptr ())

takeMiniObject cMiniObject =
    do cMiniObjectMakeReadOnly $ castPtr cMiniObject
       object <- newForeignPtr (castPtr cMiniObject) miniObjectFinalizer
       return $ unsafeCastMiniObject $ MiniObject $ castForeignPtr object
foreign import ccall unsafe "&gst_mini_object_unref"
  miniObjectFinalizer :: FunPtr (Ptr () -> IO ())
foreign import ccall unsafe "_hs_gst_mini_object_make_read_only"
  cMiniObjectMakeReadOnly :: Ptr MiniObject
                          -> IO ()

-- | Use 'giveMiniObject' to pass an miniObject to a function that takes
--   ownership of it.
giveMiniObject :: (MiniObjectClass obj, MonadIO m)
               => obj
               -> (obj -> m a)
               -> m a
giveMiniObject obj action =
    do liftIO $ {# call gst_mini_object_ref #} (toMiniObject obj)
       action obj

newtype MiniObjectClass miniObjectT =>
    MiniObjectM miniObjectT a =
        MiniObjectM (MiniObjectMRep miniObjectT a)
type MiniObjectMRep miniObjectT a = miniObjectT -> IO a

instance MiniObjectClass miniObjectT =>
    Monad (MiniObjectM miniObjectT) where
        (MiniObjectM aM) >>= fbM =
            MiniObjectM $ \miniObject ->
                do a <- aM miniObject
                   let MiniObjectM bM = fbM a
                   bM miniObject
        return a = MiniObjectM $ const $ return a
instance MiniObjectClass miniObjectT =>
    MonadIO (MiniObjectM miniObjectT) where
        liftIO aM = MiniObjectM $ const aM

liftMiniObjectM :: MiniObjectClass miniObjectT
                => (miniObjectT -> a)
                -> MiniObjectM miniObjectT a
liftMiniObjectM f =
    MiniObjectM $ \miniObject ->
        return $! f miniObject

runMiniObjectM :: MiniObjectClass miniObjectT
               => Ptr miniObjectT
               -> (ForeignPtr miniObjectT -> miniObjectT)
               -> MiniObjectM miniObjectT a
               -> IO a
runMiniObjectM ptr cons (MiniObjectM action) =
    do object <- liftM cons $ newForeignPtr_ ptr
       action object

marshalMiniObjectModify :: MiniObjectClass miniObjectT
                        => IO (Ptr miniObjectT)
                        -> MiniObjectM miniObjectT a
                        -> IO (miniObjectT, a)
marshalMiniObjectModify mkMiniObject (MiniObjectM action) =
    do ptr <- mkMiniObject >>= cMiniObjectMakeWritable . castPtr
       object <- liftM MiniObject $ newForeignPtr_ $ castPtr ptr
       result <- action $ unsafeCastMiniObject object
       object' <- takeMiniObject $ castPtr ptr
       return (unsafeCastMiniObject object', result)
foreign import ccall unsafe "gst_mini_object_make_writable"
    cMiniObjectMakeWritable :: Ptr MiniObject
                            -> IO (Ptr MiniObject)

mkMiniObjectGetFlags :: (MiniObjectClass miniObjectT, Flags flagsT)
                     => miniObjectT
                     -> [flagsT]
mkMiniObjectGetFlags miniObject =
    toFlags $ fromIntegral $ unsafePerformIO $
        withMiniObject (toMiniObject miniObject) cMiniObjectGetFlags
foreign import ccall unsafe "_hs_gst_mini_object_flags"
    cMiniObjectGetFlags :: Ptr MiniObject
                        -> IO CUInt

mkMiniObjectGetFlagsM :: (MiniObjectClass miniObjectT, Flags flagsT)
                      => MiniObjectM miniObjectT [flagsT]
mkMiniObjectGetFlagsM =
    MiniObjectM $ \miniObject ->
        withMiniObject (toMiniObject miniObject) $ \cMiniObject ->
            liftM cToFlags $ cMiniObjectGetFlags cMiniObject

mkMiniObjectSetFlagsM :: (MiniObjectClass miniObjectT, Flags flagsT)
                      => [flagsT]
                      -> MiniObjectM miniObjectT ()
mkMiniObjectSetFlagsM flags =
    MiniObjectM $ \miniObject ->
        withMiniObject (toMiniObject miniObject) $ \cMiniObject ->
            cMiniObjectSetFlags cMiniObject (fromIntegral $ fromFlags flags)
foreign import ccall unsafe "_hs_gst_mini_object_flag_set"
    cMiniObjectSetFlags :: Ptr MiniObject
                        -> CUInt
                        -> IO ()

mkMiniObjectUnsetFlagsM :: (MiniObjectClass miniObjectT, Flags flagsT)
                        => [flagsT]
                        -> MiniObjectM miniObjectT ()
mkMiniObjectUnsetFlagsM flags =
    MiniObjectM $ \miniObject ->
        withMiniObject (toMiniObject miniObject) $ \cMiniObject ->
            cMiniObjectUnsetFlags cMiniObject (fromIntegral $ fromFlags flags)
foreign import ccall unsafe "_hs_gst_mini_object_flag_unset"
    cMiniObjectUnsetFlags :: Ptr MiniObject
                          -> CUInt
                          -> IO ()

--------------------------------------------------------------------

type QueryType = {# type GstQueryType #}
data QueryTypeDefinition = QueryTypeDefinition {
    queryTypeDefinitionValue       :: QueryType,
    queryTypeDefinitionNick        :: String,
    queryTypeDefinitionDescription :: String,
    queryTypeDefinitionQuark       :: Quark
    } deriving (Eq, Show)
instance Storable QueryTypeDefinition where
    sizeOf _ = {# sizeof GstQuery #}
    alignment _ = alignment (undefined :: CString)
    peek ptr =
        do value <- {# get GstQueryTypeDefinition->value #} ptr
           nick <- {# get GstQueryTypeDefinition->nick #} ptr >>= peekUTFString
           description <- {# get GstQueryTypeDefinition->description #} ptr >>= peekUTFString
           quark <- {# get GstQueryTypeDefinition->quark #} ptr
           return $ QueryTypeDefinition value
                                        nick
                                        description
                                        quark
    poke _ _ = undefined
instance Iterable QueryTypeDefinition where
    peekIterable = peek . castPtr
    withIterable = with

--------------------------------------------------------------------

{# enum GstEventTypeFlags as EventTypeFlags {underscoreToCase} with prefix = "GST" deriving (Eq, Bounded, Show) #}
instance Flags EventTypeFlags

--------------------------------------------------------------------

{# pointer *GstIterator as PtrIterator foreign newtype #}

withPtrIterator :: PtrIterator
                -> (Ptr PtrIterator -> IO a)
                -> IO a
withPtrIterator (PtrIterator cPtrIterator) = withForeignPtr cPtrIterator

takePtrIterator, peekPtrIterator :: Ptr PtrIterator
                                 -> IO PtrIterator
takePtrIterator ptrIteratorPtr =
    liftM PtrIterator $ newForeignPtr ptrIteratorPtr ptrIteratorFinalizer
peekPtrIterator ptrIteratorPtr =
    liftM PtrIterator $ newForeignPtr_ ptrIteratorPtr

foreign import ccall unsafe "&gst_iterator_free"
    ptrIteratorFinalizer :: FunPtr (Ptr PtrIterator -> IO ())

{# enum GstIteratorItem   as IteratorItem   {underscoreToCase} with prefix = "GST" deriving (Eq, Show) #}
{# enum GstIteratorResult as IteratorResult {underscoreToCase} with prefix = "GST" deriving (Eq, Show) #}

mkIterator newPtrIterator cPtrIterator =
    do ptrIterator <- newPtrIterator cPtrIterator
       return $ Iterator ptrIterator

newtype Iterable a => Iterator a = Iterator PtrIterator

withIterator :: Iterator a
             -> (Ptr PtrIterator -> IO a)
             -> IO a
withIterator (Iterator ptrIterator) = withPtrIterator ptrIterator

takeIterator, peekIterator :: Ptr PtrIterator
                          -> IO (Iterator a)
takeIterator  cPtrIterator = mkIterator takePtrIterator  cPtrIterator
peekIterator cPtrIterator = mkIterator peekPtrIterator cPtrIterator

class Iterable a where
    peekIterable :: Ptr ()
                 -> IO a
    withIterable :: a
                 -> (Ptr a -> IO b)
                 -> IO b

type IteratorFilter itemT = itemT
                         -> IO Bool
type IteratorFoldFunction itemT accumT = itemT
                                      -> accumT
                                      -> IO (Bool, accumT)

--------------------------------------------------------------------

{# pointer *GstCaps as Caps foreign newtype #}
mkCaps :: ForeignPtr Caps -> Caps
mkCaps = Caps
unCaps :: Caps -> ForeignPtr Caps
unCaps (Caps caps) = caps

withCaps :: Caps -> (Ptr Caps -> IO a) -> IO a
withCaps = withForeignPtr . unCaps

takeCaps, peekCaps :: Ptr Caps
                  -> IO Caps
takeCaps capsPtr =
    liftM Caps $ newForeignPtr capsPtr capsFinalizer
peekCaps capsPtr =
    cCapsRef capsPtr >>= takeCaps
foreign import ccall unsafe "gst_caps_ref"
    cCapsRef :: Ptr Caps
             -> IO (Ptr Caps)

giveCaps :: MonadIO m
         => Caps
         -> (Caps -> m a)
         -> m a
giveCaps caps action =
    do liftIO $ {# call caps_ref #} caps
       action caps

foreign import ccall unsafe "&gst_caps_unref"
    capsFinalizer :: FunPtr (Ptr Caps -> IO ())

--------------------------------------------------------------------

{# pointer *GstStructure as Structure foreign newtype #}
mkStructure :: ForeignPtr Structure -> Structure
mkStructure = Structure
unStructure :: Structure -> ForeignPtr Structure
unStructure (Structure structure) = structure

withStructure :: Structure -> (Ptr Structure -> IO a) -> IO a
withStructure = withForeignPtr . unStructure

mkNewStructure :: (Ptr Structure -> IO (ForeignPtr Structure))
               -> Ptr Structure
               -> IO Structure
mkNewStructure mkFP structurePtr =
    do cStructureMakeImmutable structurePtr
       liftM Structure $ mkFP structurePtr
foreign import ccall unsafe "_hs_gst_structure_make_immutable"
    cStructureMakeImmutable :: Ptr Structure
                            -> IO ()

takeStructure, peekStructure :: Ptr Structure
                            -> IO Structure
takeStructure =
    mkNewStructure $ flip newForeignPtr structureFinalizer
peekStructure =
    mkNewStructure $ newForeignPtr_

giveStructure :: MonadIO m
              => Structure
              -> (Structure -> m a)
              -> m a
giveStructure structure action =
    do structure <- liftIO $
                        {# call structure_copy #} structure >>=
                            peekStructure
       action structure

foreign import ccall unsafe "&gst_structure_free"
    structureFinalizer :: FunPtr (Ptr Structure -> IO ())

type StructureForeachFunc =  Quark
                          -> GValue
                          -> IO Bool

newtype StructureM a = StructureM (StructureMRep a)
type StructureMRep a = (Structure -> IO a)

instance Monad StructureM where
    (StructureM aM) >>= fbM =
        StructureM $ \structure ->
            do a <- aM structure
               let StructureM bM = fbM a
               bM structure
    return a = StructureM $ const $ return a

--------------------------------------------------------------------

type TagList = Structure
mkTagList = mkStructure
unTagList = unStructure
withTagList = withStructure
takeTagList = takeStructure
peekTagList = takeStructure
giveTagList :: MonadIO m
            => TagList
            -> (TagList -> m a)
            -> m a
giveTagList = giveStructure

type Tag = String

{# enum GstTagFlag      as TagFlag      {underscoreToCase} with prefix = "GST" deriving (Eq, Show) #}
{# enum GstTagMergeMode as TagMergeMode {underscoreToCase} with prefix = "GST" deriving (Eq, Show) #}

--------------------------------------------------------------------

data Segment = Segment { segmentRate        :: Double
                       , segmentAbsRate     :: Double
                       , segmentFormat      :: Format
                       , segmentFlags       :: [SeekFlags]
                       , segmentStart       :: Int64
                       , segmentStop        :: Int64
                       , segmentTime        :: Int64
                       , segmentAccum       :: Int64
                       , segmentLastStop    :: Int64
                       , segmentDuration    :: Int64 }
               deriving (Eq, Show)
instance Storable Segment where
    sizeOf _ = fromIntegral cSegmentSizeof
    alignment _ = alignment (undefined :: CString)
    peek ptr =
        do rate        <- {# get GstSegment->rate #} ptr
           absRate     <- {# get GstSegment->abs_rate #} ptr
           format      <- {# get GstSegment->format #} ptr
           flags       <- {# get GstSegment->flags #} ptr
           start       <- {# get GstSegment->start #} ptr
           stop        <- {# get GstSegment->stop #} ptr
           time        <- {# get GstSegment->time #} ptr
           accum       <- {# get GstSegment->accum #} ptr
           lastStop    <- {# get GstSegment->last_stop #} ptr
           duration    <- {# get GstSegment->duration #} ptr
           return $ Segment (realToFrac rate)
                            (realToFrac absRate)
                            (cToEnum format)
                            (toFlags $ fromIntegral flags)
                            (fromIntegral start)
                            (fromIntegral stop)
                            (fromIntegral time)
                            (fromIntegral accum)
                            (fromIntegral lastStop)
                            (fromIntegral duration)
    poke ptr (Segment rate
                      absRate
                      format
                      flags
                      start
                      stop
                      time
                      accum
                      lastStop
                      duration) =
        do {# call segment_init #} (castPtr ptr)
                                   (cFromEnum format)
           {# set GstSegment->rate #} ptr $ realToFrac rate
           {# set GstSegment->abs_rate #} ptr $ realToFrac absRate
           {# set GstSegment->format #} ptr $ cFromEnum format
           {# set GstSegment->flags #} ptr $ fromIntegral $ fromFlags flags
           {# set GstSegment->start #} ptr $ fromIntegral start
           {# set GstSegment->stop #} ptr $ fromIntegral stop
           {# set GstSegment->time #} ptr $ fromIntegral time
           {# set GstSegment->accum #} ptr $ fromIntegral accum
           {# set GstSegment->last_stop #} ptr $ fromIntegral lastStop
           {# set GstSegment->duration #} ptr $ fromIntegral duration
foreign import ccall unsafe "_hs_gst_segment_sizeof"
    cSegmentSizeof :: {# type gsize #}

--------------------------------------------------------------------