{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MagicHash #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UnboxedTuples #-}

{-# OPTIONS_GHC -Wall #-}

module Chronos
  ( -- * Functions
    -- ** Current
    now
  , today
  , tomorrow
  , yesterday
  , epoch
    -- ** Duration
  , stopwatch
  , stopwatch_
  , stopwatchWith
  , stopwatchWith_
    -- ** Construction
  , datetimeFromYmdhms
  , timeFromYmdhms
    -- ** Conversion
  , timeToDatetime
  , datetimeToTime
  , timeToOffsetDatetime
  , offsetDatetimeToTime
  , timeToDayTruncate
  , dayToTimeMidnight
  , dayToDate
  , dateToDay
  , dayToOrdinalDate
  , ordinalDateToDay
  , monthDateToDayOfYear
  , dayOfYearToMonthDay
    -- ** Build Timespan
  , second
  , minute
  , hour
  , day
  , week
    -- ** Matching
  , buildDayOfWeekMatch
  , buildMonthMatch
  , caseMonth
    -- ** Format
    -- $format
  , w3c
  , slash
  , hyphen
  , compact
    -- ** Months
  , january
  , february
  , march
  , april
  , may
  , june
  , july
  , august
  , september
  , october
  , november
  , december
    -- ** Days of Week
  , sunday
  , monday
  , tuesday
  , wednesday
  , thursday
  , friday
  , saturday
    -- ** Utility
  , daysInMonth
  , isLeapYear
  , observedOffsets
    -- * Textual Conversion
    -- ** Date
    -- *** Text
  , builder_Ymd
  , builder_Dmy
  , builder_HMS
  , parser_Ymd
  , parser_Mdy
  , parser_Dmy
    -- *** UTF-8 ByteString
  , builderUtf8_Ymd
  , parserUtf8_Ymd
    -- ** Time of Day
    -- *** Text
  , builder_IMS_p
  , builder_IMSp
  , parser_HMS
  , parser_HMS_opt_S
    -- *** UTF-8 ByteString
  , builderUtf8_HMS
  , builderUtf8_IMS_p
  , builderUtf8_IMSp
  , parserUtf8_HMS
  , parserUtf8_HMS_opt_S
    -- ** Datetime
    -- *** Text
  , builder_DmyHMS
  , builder_DmyIMSp
  , builder_DmyIMS_p
  , builder_YmdHMS
  , builder_YmdIMSp
  , builder_YmdIMS_p
  , builderW3C
  , encode_DmyHMS
  , encode_DmyIMS_p
  , encode_YmdHMS
  , encode_YmdIMS_p
  , parser_DmyHMS
  , parser_YmdHMS
  , parser_YmdHMS_opt_S
  , parser_DmyHMS_opt_S
  , decode_DmyHMS
  , decode_YmdHMS
  , decode_YmdHMS_opt_S
  , decode_DmyHMS_opt_S
    -- *** UTF-8 ByteString
  , encodeUtf8_YmdHMS
  , encodeUtf8_YmdIMS_p
  , builderUtf8_YmdHMS
  , builderUtf8_YmdIMSp
  , builderUtf8_YmdIMS_p
  , builderUtf8W3C
  , decodeUtf8_YmdHMS
  , decodeUtf8_YmdHMS_opt_S
  , parserUtf8_YmdHMS
  , parserUtf8_YmdHMS_opt_S
    -- ** Offset Datetime
    -- *** Text
  , encode_YmdHMSz
  , encode_DmyHMSz
  , builder_YmdHMSz
  , builder_DmyHMSz
  , parser_YmdHMSz
  , parser_DmyHMSz
  , builder_YmdIMS_p_z
  , builder_DmyIMS_p_z
  , builderW3Cz
    -- *** UTF-8 ByteString
  , builderUtf8_YmdHMSz
  , parserUtf8_YmdHMSz
  , builderUtf8_YmdIMS_p_z
  , builderUtf8W3Cz
    -- ** Offset
    -- *** Text
  , encodeOffset
  , builderOffset
  , decodeOffset
  , parserOffset
    -- *** UTF-8 ByteString
  , encodeOffsetUtf8
  , builderOffsetUtf8
  , decodeOffsetUtf8
  , parserOffsetUtf8
    -- ** Timespan
    -- *** Text
  , encodeTimespan 
  , builderTimespan 
    -- *** UTF-8 ByteString
  , encodeTimespanUtf8
  , builderTimespanUtf8
    -- * Types
  , Day(..)
  , DayOfWeek(..)
  , DayOfMonth(..)
  , DayOfYear(..)
  , Month(..)
  , Year(..)
  , Offset(..)
  , Time(..)
  , DayOfWeekMatch(..)
  , MonthMatch(..)
  , UnboxedMonthMatch(..)
  , Timespan(..)
  , SubsecondPrecision(..)
  , Date(..)
  , OrdinalDate(..)
  , MonthDate(..)
  , Datetime(..)
  , OffsetDatetime(..)
  , TimeOfDay(..)
  , DatetimeFormat(..)
  , OffsetFormat(..)
  , DatetimeLocale(..)
  , MeridiemLocale(..)
  ) where

import Data.Text (Text)
import Data.Vector (Vector)
import Data.Monoid
import Data.Attoparsec.Text (Parser)
import Control.Monad
import Data.Foldable
import Control.Applicative
import Data.Int (Int64)
import Data.Char (isDigit)
import Data.ByteString (ByteString)
import Torsor (add,difference,scale,plus)
import Chronos.Internal.CTimespec (getPosixNanoseconds)
import Data.Word (Word64)
import Torsor
import GHC.Generics (Generic)
import Data.Aeson (FromJSON,ToJSON,FromJSONKey,ToJSONKey)
import Data.Primitive
import Foreign.Storable
import Data.Hashable (Hashable)
import Control.Exception (evaluate)
import qualified System.Clock as CLK
import qualified Data.Aeson as AE
import qualified Data.Aeson.Encoding as AEE
import qualified Data.Aeson.Types as AET
import qualified Data.Text as Text
import qualified Data.Text.Read as Text
import qualified Data.Attoparsec.Text as AT
import qualified Data.Attoparsec.ByteString.Char8 as AB
import qualified Data.Vector as Vector
import qualified Data.Text.Lazy.Builder as TB
import qualified Data.Text.Lazy.Builder.Int as TB
import qualified Data.ByteString.Builder as BB
import qualified Data.ByteString.Char8 as BC
import qualified Data.Text.Lazy as LT
import qualified Data.ByteString.Lazy as LB
import qualified Data.Vector.Unboxed as UVector
import qualified Data.Vector.Generic as GVector
import qualified Data.Vector.Primitive as PVector
import qualified Data.Vector.Generic.Mutable as MGVector

second :: Timespan
second = Timespan 1000000000

minute :: Timespan
minute = Timespan 60000000000

hour :: Timespan
hour = Timespan 3600000000000

day :: Timespan
day = Timespan 86400000000000

week :: Timespan
week = Timespan 604800000000000

-- | Convert 'Time' to 'Datetime'.
timeToDatetime :: Time -> Datetime
timeToDatetime = utcTimeToDatetime . toUtc

-- | Convert 'Datetime' to 'Time'.
datetimeToTime :: Datetime -> Time
datetimeToTime = fromUtc . datetimeToUtcTime

-- | Convert 'Time' to 'OffsetDatetime' by providing an 'Offset'.
timeToOffsetDatetime :: Offset -> Time -> OffsetDatetime
timeToOffsetDatetime offset = utcTimeToOffsetDatetime offset . toUtc

-- | Convert 'OffsetDatetime' to 'Time'.
offsetDatetimeToTime :: OffsetDatetime -> Time
offsetDatetimeToTime = fromUtc . offsetDatetimeToUtcTime

-- | Convert 'Time' to 'Day'. This function is lossy; consequently, it 
--   does not roundtrip with 'dayToTimeMidnight'.
timeToDayTruncate :: Time -> Day
timeToDayTruncate (Time i) = Day (fromIntegral (div i 86400000000000) + 40587)

-- | Convert midnight of the given 'Day' to 'Time'.
dayToTimeMidnight :: Day -> Time
dayToTimeMidnight (Day d) = Time (fromIntegral (d - 40587) * 86400000000000)

-- | Construct a 'Datetime' from year, month, day, hour, minute, second:
--
--   >>> datetimeFromYmdhms 2014 2 26 17 58 52
--   foobar
datetimeFromYmdhms :: Int -> Int -> Int -> Int -> Int -> Int -> Datetime
datetimeFromYmdhms y m d h m' s = Datetime
  (Date
     (Year $ fromIntegral y)
     (Month mx)
     (DayOfMonth $ fromIntegral d)
  )
  (TimeOfDay
     (fromIntegral h)
     (fromIntegral m')
     (fromIntegral s * 1000000000)
  )
  where
  mx = if m >= 1 && m <= 12
    then fromIntegral (m - 1)
    else 1

timeFromYmdhms :: Int -> Int -> Int -> Int -> Int -> Int -> Time
timeFromYmdhms y m d h m' s = datetimeToTime (datetimeFromYmdhms y m d h m' s)

-- | Gets the current 'Day'. This does not take the user\'s
--   time zone into account.
today :: IO Day
today = fmap timeToDayTruncate now

-- | Gets the 'Day' of tomorrow.
tomorrow :: IO Day
tomorrow = fmap (add 1 . timeToDayTruncate) now

-- | Gets the 'Day' of yesterday.
yesterday :: IO Day
yesterday = fmap (add (-1) . timeToDayTruncate) now

-- | Get the current time from the system clock.
now :: IO Time
now = fmap Time getPosixNanoseconds

-- | The Unix epoch, that is 1970-01-01 00:00:00.
epoch :: Time
epoch = Time 0

-- | Measures the time it takes to run an action and evaluate
--   its result to WHNF. This measurement uses a monotonic clock
--   instead of the standard system clock.
stopwatch :: IO a -> IO (Timespan, a)
stopwatch = stopwatchWith CLK.Monotonic

-- | Measures the time it takes to run an action. The result
--   is discarded. This measurement uses a monotonic clock
--   instead of the standard system clock.
stopwatch_ :: IO a -> IO Timespan
stopwatch_ = stopwatchWith_ CLK.Monotonic

-- | Variant of 'stopwatch' that accepts a clock type. Users
--   need to import @System.Clock@ from the @clock@ package
--   in order to provide the clock type.
stopwatchWith :: CLK.Clock -> IO a -> IO (Timespan, a)
stopwatchWith c action = do
  start <- CLK.getTime c
  a <- action >>= evaluate
  end <- CLK.getTime c
  return (timeSpecToTimespan (CLK.diffTimeSpec end start),a)

-- | Variant of 'stopwatch_' that accepts a clock type.
stopwatchWith_ :: CLK.Clock -> IO a -> IO Timespan
stopwatchWith_ c action = do
  start <- CLK.getTime c
  _ <- action
  end <- CLK.getTime c
  return (timeSpecToTimespan (CLK.diffTimeSpec end start))

timeSpecToTimespan :: CLK.TimeSpec -> Timespan
timeSpecToTimespan (CLK.TimeSpec s ns) = Timespan (s * 1000000000 + ns)

data UtcTime = UtcTime
  {-# UNPACK #-} !Day -- day
  {-# UNPACK #-} !Int64 -- nanoseconds

toUtc :: Time -> UtcTime
toUtc (Time i) = let (d,t) = divMod i (getTimespan dayLength)
 in UtcTime (add (fromIntegral d) epochDay) (fromIntegral t)

fromUtc :: UtcTime -> Time
fromUtc (UtcTime d ns') = Time $ getTimespan $ plus
  (scale (intToInt64 (difference d epochDay)) dayLength)
  (if ns > dayLength then dayLength else ns)
  where ns = Timespan ns'

intToInt64 :: Int -> Int64
intToInt64 = fromIntegral

epochDay :: Day
epochDay = Day 40587

dayLength :: Timespan
dayLength = Timespan 86400000000000

dayLengthInt64 :: Int64
dayLengthInt64 = 86400000000000

nanosecondsInMinute :: Int64
nanosecondsInMinute = 60000000000

observedOffsets :: Vector Offset
observedOffsets = Vector.fromList $ map Offset
  [ -1200
  , -1100
  , -1000
  , -930
  , -900
  , -800
  , -700
  , -600
  , -500
  , -400
  , -330
  , -300
  , -230
  , -200
  , -100
  , 0
  , 100
  , 200
  , 300
  , 330
  , 400
  , 430
  , 500
  , 530
  , 545
  , 600
  , 630
  , 700
  , 800
  , 845
  , 900
  , 930
  , 1000
  , 1030
  , 1100
  , 1200
  , 1245
  , 1300
  , 1345
  , 1400
  ]

-- | The first argument in the resulting tuple in a day
--   adjustment. It should be either -1, 0, or 1, as no
--   offset should ever exceed 24 hours.
offsetTimeOfDay :: Offset -> TimeOfDay -> (Int, TimeOfDay)
offsetTimeOfDay (Offset offset) (TimeOfDay h m s) =
  (dayAdjustment,TimeOfDay h'' m'' s)
  where
  (!dayAdjustment, !h'') = divMod h' 24
  (!hourAdjustment, !m'') = divMod m' 60
  m' = m + offset
  h' = h + hourAdjustment

nanosecondsSinceMidnightToTimeOfDay :: Int64 -> TimeOfDay
nanosecondsSinceMidnightToTimeOfDay ns =
  if ns >= dayLengthInt64
    then TimeOfDay 23 59 (nanosecondsInMinute + (ns - dayLengthInt64))
    else TimeOfDay h' m' ns'
  where
  (!mInt64,!ns') = quotRem ns nanosecondsInMinute
  !m = fromIntegral mInt64
  (!h',!m')  = quotRem m 60

timeOfDayToNanosecondsSinceMidnight :: TimeOfDay -> Int64
timeOfDayToNanosecondsSinceMidnight (TimeOfDay h m ns) =
  fromIntegral h * 3600000000000 + fromIntegral m * 60000000000 + ns

-- | Convert 'Day' to a 'Date'.
dayToDate :: Day -> Date
dayToDate theDay = Date year month dayOfMonth
  where
  OrdinalDate year yd = dayToOrdinalDate theDay
  MonthDate month dayOfMonth = dayOfYearToMonthDay (isLeapYear year) yd

-- datetimeToOffsetDatetime :: Offset -> Datetime -> OffsetDatetime
-- datetimeToOffsetDatetime offset

utcTimeToOffsetDatetime :: Offset -> UtcTime -> OffsetDatetime
utcTimeToOffsetDatetime offset (UtcTime (Day d) nanoseconds) =
  let (!dayAdjustment,!tod) = offsetTimeOfDay offset (nanosecondsSinceMidnightToTimeOfDay nanoseconds)
      !date = dayToDate (Day (d + dayAdjustment))
   in OffsetDatetime (Datetime date tod) offset

utcTimeToDatetime :: UtcTime -> Datetime
utcTimeToDatetime (UtcTime d nanoseconds) =
  let !tod = nanosecondsSinceMidnightToTimeOfDay nanoseconds
      !date = dayToDate d
   in Datetime date tod

datetimeToUtcTime :: Datetime -> UtcTime
datetimeToUtcTime (Datetime date timeOfDay) =
  UtcTime (dateToDay date) (timeOfDayToNanosecondsSinceMidnight timeOfDay)

offsetDatetimeToUtcTime :: OffsetDatetime -> UtcTime
offsetDatetimeToUtcTime (OffsetDatetime (Datetime date timeOfDay) (Offset off)) =
  let (!dayAdjustment,!tod) = offsetTimeOfDay (Offset $ negate off) timeOfDay
      !(Day !theDay) = dateToDay date
   in UtcTime
        (Day (theDay + dayAdjustment))
        (timeOfDayToNanosecondsSinceMidnight tod)

-- | Convert 'Date' to a 'Day'.
dateToDay :: Date -> Day
dateToDay (Date y m d) = ordinalDateToDay $ OrdinalDate y
  (monthDateToDayOfYear (isLeapYear y) (MonthDate m d))

monthDateToDayOfYear :: Bool -> MonthDate -> DayOfYear
monthDateToDayOfYear isLeap (MonthDate month@(Month m) (DayOfMonth dayOfMonth)) =
  DayOfYear ((div (367 * (fromIntegral m + 1) - 362) 12) + k + day')
  where
  day' = fromIntegral $ clip 1 (daysInMonth isLeap month) dayOfMonth
  k = if month < Month 2 then 0 else if isLeap then -1 else -2

ordinalDateToDay :: OrdinalDate -> Day
ordinalDateToDay (OrdinalDate year@(Year y') theDay) = Day mjd where
  y = y' - 1
  mjd = (fromIntegral . getDayOfYear $
           (clip (DayOfYear 1) (if isLeapYear year then DayOfYear 366 else DayOfYear 365) theDay)
        )
      + (365 * y)
      + (div y 4) - (div y 100)
      + (div y 400) - 678576

isLeapYear :: Year -> Bool
isLeapYear (Year year) = (mod year 4 == 0) && ((mod year 400 == 0) || not (mod year 100 == 0))

dayOfYearToMonthDay :: Bool -> DayOfYear -> MonthDate
dayOfYearToMonthDay isLeap dayOfYear =
  let (!upperBound,!monthTable,!dayTable) =
        if isLeap
          then (DayOfYear 366, leapYearDayOfYearMonthTable, leapYearDayOfYearDayOfMonthTable)
          else (DayOfYear 365, normalYearDayOfYearMonthTable, normalYearDayOfYearDayOfMonthTable)
      DayOfYear clippedDay = clip (DayOfYear 1) upperBound dayOfYear
      clippedDayInt = fromIntegral clippedDay :: Int
      month = UVector.unsafeIndex monthTable clippedDayInt
      theDay = UVector.unsafeIndex dayTable clippedDayInt
   in MonthDate month theDay

dayToOrdinalDate :: Day -> OrdinalDate
dayToOrdinalDate (Day mjd) = OrdinalDate (Year $ fromIntegral year) (DayOfYear $ fromIntegral yd) where
  a = (fromIntegral mjd :: Int64) + 678575
  quadcent = div a 146097
  b = mod a 146097
  cent = min (div b 36524) 3
  c = b - (cent * 36524)
  quad = div c 1461
  d = mod c 1461
  y = min (div d 365) 3
  yd = (d - (y * 365) + 1)
  year = quadcent * 400 + cent * 100 + quad * 4 + y + 1

{- $format
 
The formats provided is this module are language-agnostic.
To find meridiem formats and month formats, look in a
language-specific module.

-}

w3c :: DatetimeFormat
w3c = DatetimeFormat (Just '-') (Just 'T') (Just ':')

slash :: DatetimeFormat
slash = DatetimeFormat (Just '/') (Just ' ') (Just ':')

hyphen :: DatetimeFormat
hyphen = DatetimeFormat (Just '-') (Just ' ') (Just ':')

compact :: DatetimeFormat
compact = DatetimeFormat Nothing (Just 'T') Nothing

buildDayOfWeekMatch :: a -> a -> a -> a -> a -> a -> a -> DayOfWeekMatch a
buildDayOfWeekMatch a b c d e f g =
  DayOfWeekMatch (Vector.fromList [a,b,c,d,e,f,g])

internalBuildMonthMatch :: a -> a -> a -> a -> a -> a -> a -> a -> a -> a -> a -> a -> MonthMatch a
internalBuildMonthMatch a b c d e f g h i j k l =
  MonthMatch (Vector.fromList [a,b,c,d,e,f,g,h,i,j,k,l])

internalMatchMonth :: MonthMatch a -> Month -> a
internalMatchMonth (MonthMatch v) (Month ix) = Vector.unsafeIndex v (fromIntegral ix)

daysInMonth ::
     Bool -- ^ Is this a leap year?
  -> Month -- ^ Month of year
  -> Int
daysInMonth isLeap m = if isLeap
  then internalMatchMonth leapYearMonthLength m
  else internalMatchMonth normalYearMonthLength m

leapYearMonthLength :: MonthMatch Int
leapYearMonthLength = internalBuildMonthMatch 31 29 31 30 31 30 31 31 30 31 30 31

normalYearMonthLength :: MonthMatch Int
normalYearMonthLength = internalBuildMonthMatch 31 30 31 30 31 30 31 31 30 31 30 31

leapYearDayOfYearDayOfMonthTable :: UVector.Vector DayOfMonth
leapYearDayOfYearDayOfMonthTable = UVector.fromList $ (DayOfMonth 1:) $ concat
  [ enumFromTo (DayOfMonth 1) (DayOfMonth 31)
  , enumFromTo (DayOfMonth 1) (DayOfMonth 29)
  , enumFromTo (DayOfMonth 1) (DayOfMonth 31)
  , enumFromTo (DayOfMonth 1) (DayOfMonth 30)
  , enumFromTo (DayOfMonth 1) (DayOfMonth 31)
  , enumFromTo (DayOfMonth 1) (DayOfMonth 30)
  , enumFromTo (DayOfMonth 1) (DayOfMonth 31)
  , enumFromTo (DayOfMonth 1) (DayOfMonth 31)
  , enumFromTo (DayOfMonth 1) (DayOfMonth 30)
  , enumFromTo (DayOfMonth 1) (DayOfMonth 31)
  , enumFromTo (DayOfMonth 1) (DayOfMonth 30)
  , enumFromTo (DayOfMonth 1) (DayOfMonth 31)
  ]
{-# NOINLINE leapYearDayOfYearDayOfMonthTable #-}

normalYearDayOfYearDayOfMonthTable :: UVector.Vector DayOfMonth
normalYearDayOfYearDayOfMonthTable = UVector.fromList $ (DayOfMonth 1:) $concat
  [ enumFromTo (DayOfMonth 1) (DayOfMonth 31)
  , enumFromTo (DayOfMonth 1) (DayOfMonth 28)
  , enumFromTo (DayOfMonth 1) (DayOfMonth 31)
  , enumFromTo (DayOfMonth 1) (DayOfMonth 30)
  , enumFromTo (DayOfMonth 1) (DayOfMonth 31)
  , enumFromTo (DayOfMonth 1) (DayOfMonth 30)
  , enumFromTo (DayOfMonth 1) (DayOfMonth 31)
  , enumFromTo (DayOfMonth 1) (DayOfMonth 31)
  , enumFromTo (DayOfMonth 1) (DayOfMonth 30)
  , enumFromTo (DayOfMonth 1) (DayOfMonth 31)
  , enumFromTo (DayOfMonth 1) (DayOfMonth 30)
  , enumFromTo (DayOfMonth 1) (DayOfMonth 31)
  ]
{-# NOINLINE normalYearDayOfYearDayOfMonthTable #-}

leapYearDayOfYearMonthTable :: UVector.Vector Month
leapYearDayOfYearMonthTable = UVector.fromList $ (Month 0:) $ concat
  [ replicate 31 (Month 0)
  , replicate 29 (Month 1)
  , replicate 31 (Month 2)
  , replicate 30 (Month 3)
  , replicate 31 (Month 4)
  , replicate 30 (Month 5)
  , replicate 31 (Month 6)
  , replicate 31 (Month 7)
  , replicate 30 (Month 8)
  , replicate 31 (Month 9)
  , replicate 30 (Month 10)
  , replicate 31 (Month 11)
  ]
{-# NOINLINE leapYearDayOfYearMonthTable #-}

normalYearDayOfYearMonthTable :: UVector.Vector Month
normalYearDayOfYearMonthTable = UVector.fromList $ (Month 0:) $ concat
  [ replicate 31 (Month 0)
  , replicate 28 (Month 1)
  , replicate 31 (Month 2)
  , replicate 30 (Month 3)
  , replicate 31 (Month 4)
  , replicate 30 (Month 5)
  , replicate 31 (Month 6)
  , replicate 31 (Month 7)
  , replicate 30 (Month 8)
  , replicate 31 (Month 9)
  , replicate 30 (Month 10)
  , replicate 31 (Month 11)
  ]
{-# NOINLINE normalYearDayOfYearMonthTable #-}

buildMonthMatch :: a -> a -> a -> a -> a -> a -> a -> a -> a -> a -> a -> a -> MonthMatch a
buildMonthMatch = internalBuildMonthMatch

caseMonth :: MonthMatch a -> Month -> a
caseMonth = internalMatchMonth

-- | This could be written much more efficiently since we know the
--   exact size the resulting 'Text' will be.
builder_Ymd :: Maybe Char -> Date -> TB.Builder
builder_Ymd msep (Date (Year y) m d) = case msep of
  Nothing ->
       TB.decimal y
    <> monthToZeroPaddedDigit m
    <> zeroPadDayOfMonth d
  Just sep -> let sepBuilder = TB.singleton sep in
       TB.decimal y
    <> sepBuilder
    <> monthToZeroPaddedDigit m
    <> sepBuilder
    <> zeroPadDayOfMonth d

builder_Dmy :: Maybe Char -> Date -> TB.Builder
builder_Dmy msep (Date (Year y) m d) = case msep of
  Nothing ->
       zeroPadDayOfMonth d
    <> monthToZeroPaddedDigit m
    <> TB.decimal y
  Just sep -> let sepBuilder = TB.singleton sep in
       zeroPadDayOfMonth d
    <> sepBuilder
    <> monthToZeroPaddedDigit m
    <> sepBuilder
    <> TB.decimal y

parser_Ymd :: Maybe Char -> Parser Date
parser_Ymd msep = do
  y <- parseFixedDigits 4
  traverse_ AT.char msep
  m <- parseFixedDigits 2
  when (m < 1 || m > 12) (fail "month must be between 1 and 12")
  traverse_ AT.char msep
  d <- parseFixedDigits 2
  when (d < 1 || d > 31) (fail "day must be between 1 and 31")
  return (Date (Year y) (Month $ m - 1) (DayOfMonth d))

parser_Mdy :: Maybe Char -> Parser Date
parser_Mdy msep = do
  m <- parseFixedDigits 2
  when (m < 1 || m > 12) (fail "month must be between 1 and 12")
  traverse_ AT.char msep
  d <- parseFixedDigits 2
  when (d < 1 || d > 31) (fail "day must be between 1 and 31")
  traverse_ AT.char msep
  y <- parseFixedDigits 4
  return (Date (Year y) (Month $ m - 1) (DayOfMonth d))

parser_Dmy :: Maybe Char -> Parser Date
parser_Dmy msep = do
  d <- parseFixedDigits 2
  when (d < 1 || d > 31) (fail "day must be between 1 and 31")
  traverse_ AT.char msep
  m <- parseFixedDigits 2
  when (m < 1 || m > 12) (fail "month must be between 1 and 12")
  traverse_ AT.char msep
  y <- parseFixedDigits 4
  return (Date (Year y) (Month $ m - 1) (DayOfMonth d))

builderUtf8_Ymd :: Maybe Char -> Date -> BB.Builder
builderUtf8_Ymd msep (Date (Year y) m d) = case msep of
  Nothing ->
       BB.intDec y
    <> monthToZeroPaddedDigitBS m
    <> zeroPadDayOfMonthBS d
  Just sep -> let sepBuilder = BB.char7 sep in
       BB.intDec y
    <> sepBuilder
    <> monthToZeroPaddedDigitBS m
    <> sepBuilder
    <> zeroPadDayOfMonthBS d

parserUtf8_Ymd :: Maybe Char -> AB.Parser Date
parserUtf8_Ymd msep = do
  y <- parseFixedDigitsIntBS 4
  traverse_ AB.char msep
  m <- parseFixedDigitsIntBS 2
  when (m < 1 || m > 12) (fail "month must be between 1 and 12")
  traverse_ AB.char msep
  d <- parseFixedDigitsIntBS 2
  when (d < 1 || d > 31) (fail "day must be between 1 and 31")
  return (Date (Year y) (Month $ m - 1) (DayOfMonth d))


builder_HMS :: SubsecondPrecision -> Maybe Char -> TimeOfDay -> TB.Builder
builder_HMS sp msep (TimeOfDay h m ns) =
     indexTwoDigitTextBuilder h
  <> internalBuilder_NS sp msep m ns

builder_IMS_p :: MeridiemLocale Text -> SubsecondPrecision -> Maybe Char -> TimeOfDay -> TB.Builder
builder_IMS_p meridiemLocale sp msep (TimeOfDay h m ns) =
     internalBuilder_I h
  <> internalBuilder_NS sp msep m ns
  <> " "
  <> internalBuilder_p meridiemLocale h

internalBuilder_I :: Int -> TB.Builder
internalBuilder_I h =
  indexTwoDigitTextBuilder $ if h > 12
    then h - 12
    else if h == 0
      then 12
      else h

internalBuilder_p :: MeridiemLocale Text -> Int -> TB.Builder
internalBuilder_p (MeridiemLocale am pm) h = if h > 11
  then TB.fromText pm
  else TB.fromText am

builder_IMSp :: MeridiemLocale Text -> SubsecondPrecision -> Maybe Char -> TimeOfDay -> TB.Builder
builder_IMSp meridiemLocale sp msep (TimeOfDay h m ns) =
     internalBuilder_I h
  <> internalBuilder_NS sp msep m ns
  <> internalBuilder_p meridiemLocale h

parser_HMS :: Maybe Char -> Parser TimeOfDay
parser_HMS msep = do
  h <- parseFixedDigits 2
  when (h > 23) (fail "hour must be between 0 and 23")
  traverse_ AT.char msep
  m <- parseFixedDigits 2
  when (m > 59) (fail "minute must be between 0 and 59")
  traverse_ AT.char msep
  ns <- parseSecondsAndNanoseconds
  return (TimeOfDay h m ns)

-- | Parses text that is formatted as either of the following:
--
-- * @%H:%M@
-- * @%H:%M:%S@
--
-- That is, the seconds and subseconds part is optional. If it is
-- not provided, it is assumed to be zero. This format shows up
-- in Google Chrome\'s @datetime-local@ inputs.
parser_HMS_opt_S :: Maybe Char -> Parser TimeOfDay
parser_HMS_opt_S msep = do
  h <- parseFixedDigits 2
  when (h > 23) (fail "hour must be between 0 and 23")
  traverse_ AT.char msep
  m <- parseFixedDigits 2
  when (m > 59) (fail "minute must be between 0 and 59")
  mc <- AT.peekChar
  case mc of
    Nothing -> return (TimeOfDay h m 0)
    Just c -> case msep of
      Just sep -> if c == sep
        then do
          _ <- AT.anyChar -- should be the separator
          ns <- parseSecondsAndNanoseconds
          return (TimeOfDay h m ns)
        else return (TimeOfDay h m 0)
      -- if there is no separator, we will try to parse the
      -- remaining part as seconds. We commit to trying to
      -- parse as seconds if we see any number as the next
      -- character.
      Nothing -> if isDigit c
        then do
          ns <- parseSecondsAndNanoseconds
          return (TimeOfDay h m ns)
        else return (TimeOfDay h m 0)

parseSecondsAndNanoseconds :: Parser Int64
parseSecondsAndNanoseconds = do
  s' <- parseFixedDigits 2
  let s = fromIntegral s' :: Int64
  when (s > 60) (fail "seconds must be between 0 and 60")
  nanoseconds <-
    ( do _ <- AT.char '.'
         numberOfZeroes <- countZeroes
         x <- AT.decimal
         let totalDigits = countDigits x + numberOfZeroes
             result = if totalDigits == 9
               then x
               else if totalDigits < 9
                 then x * raiseTenTo (9 - totalDigits)
                 else quot x (raiseTenTo (totalDigits - 9))
         return (fromIntegral result)
    ) <|> return 0
  return (s * 1000000000 + nanoseconds)

countZeroes :: AT.Parser Int
countZeroes = go 0 where
  go !i = do
    m <- AT.peekChar
    case m of
      Nothing -> return i
      Just c -> if c == '0'
        then AT.anyChar *> go (i + 1)
        else return i

nanosecondsBuilder :: Int64 -> TB.Builder
nanosecondsBuilder w
  | w == 0 = mempty
  | w > 99999999 = "." <> TB.decimal w
  | w > 9999999 = ".0" <> TB.decimal w
  | w > 999999 = ".00" <> TB.decimal w
  | w > 99999 = ".000" <> TB.decimal w
  | w > 9999 = ".0000" <> TB.decimal w
  | w > 999 = ".00000" <> TB.decimal w
  | w > 99 = ".000000" <> TB.decimal w
  | w > 9 = ".0000000" <> TB.decimal w
  | otherwise = ".00000000" <> TB.decimal w

microsecondsBuilder :: Int64 -> TB.Builder
microsecondsBuilder w
  | w == 0 = mempty
  | w > 99999 = "." <> TB.decimal w
  | w > 9999 = ".0" <> TB.decimal w
  | w > 999 = ".00" <> TB.decimal w
  | w > 99 = ".000" <> TB.decimal w
  | w > 9 = ".0000" <> TB.decimal w
  | otherwise = ".00000" <> TB.decimal w

millisecondsBuilder :: Int64 -> TB.Builder
millisecondsBuilder w
  | w == 0 = mempty
  | w > 99 = "." <> TB.decimal w
  | w > 9 = ".0" <> TB.decimal w
  | otherwise = ".00" <> TB.decimal w

prettyNanosecondsBuilder :: SubsecondPrecision -> Int64 -> TB.Builder
prettyNanosecondsBuilder sp nano = case sp of
  SubsecondPrecisionAuto
    | milliRem == 0 -> millisecondsBuilder milli
    | microRem == 0 -> microsecondsBuilder micro
    | otherwise -> nanosecondsBuilder nano
  SubsecondPrecisionFixed d -> if d == 0
    then mempty
    else
      let newSubsecondPart = quot nano (raiseTenTo (9 - d))
       in "."
          <> TB.fromText (Text.replicate (d - countDigits newSubsecondPart) "0")
          <> TB.decimal newSubsecondPart
  where
  (milli,milliRem) = quotRem nano 1000000
  (micro,microRem) = quotRem nano 1000


encodeTimespan :: SubsecondPrecision -> Timespan -> Text
encodeTimespan sp =
  LT.toStrict . TB.toLazyText . builderTimespan sp

builderTimespan :: SubsecondPrecision -> Timespan -> TB.Builder
builderTimespan sp (Timespan ns) = 
  TB.decimal sInt64 <> prettyNanosecondsBuilder sp nsRemainder
  where
  (!sInt64,!nsRemainder) = quotRem ns 1000000000

internalBuilder_NS :: SubsecondPrecision -> Maybe Char -> Int -> Int64 -> TB.Builder
internalBuilder_NS sp msep m ns = case msep of
  Nothing -> indexTwoDigitTextBuilder m
          <> indexTwoDigitTextBuilder s
          <> prettyNanosecondsBuilder sp nsRemainder
  Just sep -> let sepBuilder = TB.singleton sep in
             sepBuilder
          <> indexTwoDigitTextBuilder m
          <> sepBuilder
          <> indexTwoDigitTextBuilder s
          <> prettyNanosecondsBuilder sp nsRemainder
  where
  (!sInt64,!nsRemainder) = quotRem ns 1000000000
  !s = fromIntegral sInt64




builder_DmyHMS :: SubsecondPrecision -> DatetimeFormat -> Datetime -> TB.Builder
builder_DmyHMS sp (DatetimeFormat mdateSep msep mtimeSep) (Datetime date time) = 
  case msep of
    Nothing -> builder_Dmy mdateSep date
            <> builder_HMS sp mtimeSep time
    Just sep -> builder_Dmy mdateSep date
             <> TB.singleton sep
             <> builder_HMS sp mtimeSep time

builder_DmyIMS_p :: MeridiemLocale Text -> SubsecondPrecision -> DatetimeFormat -> Datetime -> TB.Builder
builder_DmyIMS_p locale sp (DatetimeFormat mdateSep msep mtimeSep) (Datetime date time) =
     builder_Dmy mdateSep date
  <> maybe mempty TB.singleton msep
  <> builder_IMS_p locale sp mtimeSep time

builder_DmyIMSp :: MeridiemLocale Text -> SubsecondPrecision -> DatetimeFormat -> Datetime -> TB.Builder
builder_DmyIMSp locale sp (DatetimeFormat mdateSep msep mtimeSep) (Datetime date time) =
     builder_Dmy mdateSep date
  <> maybe mempty TB.singleton msep
  <> builder_IMS_p locale sp mtimeSep time


encode_DmyHMS :: SubsecondPrecision -> DatetimeFormat -> Datetime -> Text
encode_DmyHMS sp format = 
  LT.toStrict . TB.toLazyText . builder_DmyHMS sp format

encode_DmyIMS_p :: MeridiemLocale Text -> SubsecondPrecision -> DatetimeFormat -> Datetime -> Text
encode_DmyIMS_p a sp b = LT.toStrict . TB.toLazyText . builder_DmyIMS_p a sp b

encode_YmdHMS :: SubsecondPrecision -> DatetimeFormat -> Datetime -> Text
encode_YmdHMS sp format =
  LT.toStrict . TB.toLazyText . builder_YmdHMS sp format

encode_YmdIMS_p :: MeridiemLocale Text -> SubsecondPrecision -> DatetimeFormat -> Datetime -> Text
encode_YmdIMS_p a sp b = LT.toStrict . TB.toLazyText . builder_YmdIMS_p a sp b

-- | This could be written much more efficiently since we know the
--   exact size the resulting 'Text' will be.
builder_YmdHMS :: SubsecondPrecision -> DatetimeFormat -> Datetime -> TB.Builder
builder_YmdHMS sp (DatetimeFormat mdateSep msep mtimeSep) (Datetime date time) =
  case msep of
    Nothing -> builder_Ymd mdateSep date
            <> builder_HMS sp mtimeSep time
    Just sep -> builder_Ymd mdateSep date
             <> TB.singleton sep
             <> builder_HMS sp mtimeSep time

builder_YmdIMS_p :: MeridiemLocale Text -> SubsecondPrecision -> DatetimeFormat -> Datetime -> TB.Builder
builder_YmdIMS_p locale sp (DatetimeFormat mdateSep msep mtimeSep) (Datetime date time) =
     builder_Ymd mdateSep date
  <> maybe mempty TB.singleton msep
  <> builder_IMS_p locale sp mtimeSep time

builder_YmdIMSp :: MeridiemLocale Text -> SubsecondPrecision -> DatetimeFormat -> Datetime -> TB.Builder
builder_YmdIMSp locale sp (DatetimeFormat mdateSep msep mtimeSep) (Datetime date time) =
     builder_Ymd mdateSep date
  <> maybe mempty TB.singleton msep
  <> builder_IMS_p locale sp mtimeSep time


builderW3C :: Datetime -> TB.Builder
builderW3C = builder_YmdHMS SubsecondPrecisionAuto (DatetimeFormat (Just '-') (Just 'T') (Just ':'))

decode_YmdHMS :: DatetimeFormat -> Text -> Maybe Datetime
decode_YmdHMS format =
  either (const Nothing) Just . AT.parseOnly (parser_YmdHMS format)

parser_DmyHMS :: DatetimeFormat -> Parser Datetime
parser_DmyHMS (DatetimeFormat mdateSep msep mtimeSep) = do
  date <- parser_Dmy mdateSep
  traverse_ AT.char msep
  time <- parser_HMS mtimeSep
  return (Datetime date time)

parser_DmyHMS_opt_S :: DatetimeFormat -> Parser Datetime
parser_DmyHMS_opt_S (DatetimeFormat mdateSep msep mtimeSep) = do
  date <- parser_Dmy mdateSep
  traverse_ AT.char msep
  time <- parser_HMS_opt_S mtimeSep
  return (Datetime date time)

decode_DmyHMS :: DatetimeFormat -> Text -> Maybe Datetime
decode_DmyHMS format =
  either (const Nothing) Just . AT.parseOnly (parser_DmyHMS format)

decode_DmyHMS_opt_S :: DatetimeFormat -> Text -> Maybe Datetime
decode_DmyHMS_opt_S format =
  either (const Nothing) Just . AT.parseOnly (parser_DmyHMS_opt_S format)

parser_YmdHMS :: DatetimeFormat -> Parser Datetime
parser_YmdHMS (DatetimeFormat mdateSep msep mtimeSep) = do
  date <- parser_Ymd mdateSep
  traverse_ AT.char msep
  time <- parser_HMS mtimeSep
  return (Datetime date time)

parser_YmdHMS_opt_S :: DatetimeFormat -> Parser Datetime
parser_YmdHMS_opt_S (DatetimeFormat mdateSep msep mtimeSep) = do
  date <- parser_Ymd mdateSep
  traverse_ AT.char msep
  time <- parser_HMS_opt_S mtimeSep
  return (Datetime date time)

decode_YmdHMS_opt_S :: DatetimeFormat -> Text -> Maybe Datetime
decode_YmdHMS_opt_S format =
  either (const Nothing) Just . AT.parseOnly (parser_YmdHMS_opt_S format)


---------------
-- ByteString stuff
---------------

builderUtf8_HMS :: SubsecondPrecision -> Maybe Char -> TimeOfDay -> BB.Builder
builderUtf8_HMS sp msep (TimeOfDay h m ns) =
     indexTwoDigitByteStringBuilder h
  <> internalBuilderUtf8_NS sp msep m ns

builderUtf8_IMS_p :: MeridiemLocale ByteString -> SubsecondPrecision -> Maybe Char -> TimeOfDay -> BB.Builder
builderUtf8_IMS_p meridiemLocale sp msep (TimeOfDay h m ns) =
     internalBuilderUtf8_I h
  <> internalBuilderUtf8_NS sp msep m ns
  <> " "
  <> internalBuilderUtf8_p meridiemLocale h

internalBuilderUtf8_I :: Int -> BB.Builder
internalBuilderUtf8_I h =
  indexTwoDigitByteStringBuilder $ if h > 12
    then h - 12
    else if h == 0
      then 12
      else h

internalBuilderUtf8_p :: MeridiemLocale ByteString -> Int -> BB.Builder
internalBuilderUtf8_p (MeridiemLocale am pm) h = if h > 11
  then BB.byteString pm
  else BB.byteString am

builderUtf8_IMSp :: MeridiemLocale ByteString -> SubsecondPrecision -> Maybe Char -> TimeOfDay -> BB.Builder
builderUtf8_IMSp meridiemLocale sp msep (TimeOfDay h m ns) =
     internalBuilderUtf8_I h
  <> internalBuilderUtf8_NS sp msep m ns
  <> internalBuilderUtf8_p meridiemLocale h

parserUtf8_HMS :: Maybe Char -> AB.Parser TimeOfDay
parserUtf8_HMS msep = do
  h <- parseFixedDigitsIntBS 2
  when (h > 23) (fail "hour must be between 0 and 23")
  traverse_ AB.char msep
  m <- parseFixedDigitsIntBS 2
  when (m > 59) (fail "minute must be between 0 and 59")
  traverse_ AB.char msep
  ns <- parseSecondsAndNanosecondsUtf8
  return (TimeOfDay h m ns)

-- | Parses text that is formatted as either of the following:
--
-- * @%H:%M@
-- * @%H:%M:%S@
--
-- That is, the seconds and subseconds part is optional. If it is
-- not provided, it is assumed to be zero. This format shows up
-- in Google Chrome\'s @datetime-local@ inputs.
parserUtf8_HMS_opt_S :: Maybe Char -> AB.Parser TimeOfDay
parserUtf8_HMS_opt_S msep = do
  h <- parseFixedDigitsIntBS 2
  when (h > 23) (fail "hour must be between 0 and 23")
  traverse_ AB.char msep
  m <- parseFixedDigitsIntBS 2
  when (m > 59) (fail "minute must be between 0 and 59")
  mc <- AB.peekChar
  case mc of
    Nothing -> return (TimeOfDay h m 0)
    Just c -> case msep of
      Just sep -> if c == sep
        then do
          _ <- AB.anyChar -- should be the separator
          ns <- parseSecondsAndNanosecondsUtf8
          return (TimeOfDay h m ns)
        else return (TimeOfDay h m 0)
      -- if there is no separator, we will try to parse the
      -- remaining part as seconds. We commit to trying to
      -- parse as seconds if we see any number as the next
      -- character.
      Nothing -> if isDigit c
        then do
          ns <- parseSecondsAndNanosecondsUtf8
          return (TimeOfDay h m ns)
        else return (TimeOfDay h m 0)

parseSecondsAndNanosecondsUtf8 :: AB.Parser Int64
parseSecondsAndNanosecondsUtf8 = do
  s' <- parseFixedDigitsIntBS 2
  let !s = fromIntegral s' :: Int64
  when (s > 60) (fail "seconds must be between 0 and 60")
  nanoseconds <-
    ( do _ <- AB.char '.'
         numberOfZeroes <- countZeroesUtf8
         x <- AB.decimal
         let totalDigits = countDigits x + numberOfZeroes
             result = if totalDigits == 9
               then x
               else if totalDigits < 9
                 then x * raiseTenTo (9 - totalDigits)
                 else quot x (raiseTenTo (totalDigits - 9))
         return (fromIntegral result)
    ) <|> return 0
  return (s * 1000000000 + nanoseconds)

countZeroesUtf8 :: AB.Parser Int
countZeroesUtf8 = go 0 where
  go !i = do
    m <- AB.peekChar
    case m of
      Nothing -> return i
      Just c -> if c == '0'
        then AB.anyChar *> go (i + 1)
        else return i

nanosecondsBuilderUtf8 :: Int64 -> BB.Builder
nanosecondsBuilderUtf8 w
  | w == 0 = mempty
  | w > 99999999 = "." <> int64Builder w
  | w > 9999999 = ".0" <> int64Builder w
  | w > 999999 = ".00" <> int64Builder w
  | w > 99999 = ".000" <> int64Builder w
  | w > 9999 = ".0000" <> int64Builder w
  | w > 999 = ".00000" <> int64Builder w
  | w > 99 = ".000000" <> int64Builder w
  | w > 9 = ".0000000" <> int64Builder w
  | otherwise = ".00000000" <> int64Builder w

microsecondsBuilderUtf8 :: Int64 -> BB.Builder
microsecondsBuilderUtf8 w
  | w == 0 = mempty
  | w > 99999 = "." <> int64Builder w
  | w > 9999 = ".0" <> int64Builder w
  | w > 999 = ".00" <> int64Builder w
  | w > 99 = ".000" <> int64Builder w
  | w > 9 = ".0000" <> int64Builder w
  | otherwise = ".00000" <> int64Builder w

millisecondsBuilderUtf8 :: Int64 -> BB.Builder
millisecondsBuilderUtf8 w
  | w == 0 = mempty
  | w > 99 = "." <> int64Builder w
  | w > 9 = ".0" <> int64Builder w
  | otherwise = ".00" <> int64Builder w

prettyNanosecondsBuilderUtf8 :: SubsecondPrecision -> Int64 -> BB.Builder
prettyNanosecondsBuilderUtf8 sp nano = case sp of
  SubsecondPrecisionAuto
    | milliRem == 0 -> millisecondsBuilderUtf8 milli
    | microRem == 0 -> microsecondsBuilderUtf8 micro
    | otherwise -> nanosecondsBuilderUtf8 nano
  SubsecondPrecisionFixed d -> if d == 0
    then mempty
    else
      let newSubsecondPart = quot nano (raiseTenTo (9 - d))
       in BB.char7 '.'
          <> BB.byteString (BC.replicate (d - countDigits newSubsecondPart) '0')
          <> int64Builder newSubsecondPart
  where
  (milli,milliRem) = quotRem nano 1000000
  (micro,microRem) = quotRem nano 1000

encodeTimespanUtf8 :: SubsecondPrecision -> Timespan -> ByteString
encodeTimespanUtf8 sp =
  LB.toStrict . BB.toLazyByteString . builderTimespanUtf8 sp

builderTimespanUtf8 :: SubsecondPrecision -> Timespan -> BB.Builder
builderTimespanUtf8 sp (Timespan ns) = 
  int64Builder sInt64 <> prettyNanosecondsBuilderUtf8 sp nsRemainder
  where
  (!sInt64,!nsRemainder) = quotRem ns 1000000000

int64Builder :: Int64 -> BB.Builder
int64Builder = BB.integerDec . fromIntegral

internalBuilderUtf8_NS :: SubsecondPrecision -> Maybe Char -> Int -> Int64 -> BB.Builder
internalBuilderUtf8_NS sp msep m ns = case msep of
  Nothing -> indexTwoDigitByteStringBuilder m
          <> indexTwoDigitByteStringBuilder s
          <> prettyNanosecondsBuilderUtf8 sp nsRemainder
  Just sep -> let sepBuilder = BB.char7 sep in
             sepBuilder
          <> indexTwoDigitByteStringBuilder m
          <> sepBuilder
          <> indexTwoDigitByteStringBuilder s
          <> prettyNanosecondsBuilderUtf8 sp nsRemainder
  where
  (!sInt64,!nsRemainder) = quotRem ns 1000000000
  !s = fromIntegral sInt64

encodeUtf8_YmdHMS :: SubsecondPrecision -> DatetimeFormat -> Datetime -> ByteString
encodeUtf8_YmdHMS sp format =
  LB.toStrict . BB.toLazyByteString . builderUtf8_YmdHMS sp format

encodeUtf8_YmdIMS_p :: MeridiemLocale ByteString -> SubsecondPrecision -> DatetimeFormat -> Datetime -> ByteString
encodeUtf8_YmdIMS_p a sp b = LB.toStrict . BB.toLazyByteString . builderUtf8_YmdIMS_p a sp b

builderUtf8_YmdHMS :: SubsecondPrecision -> DatetimeFormat -> Datetime -> BB.Builder
builderUtf8_YmdHMS sp (DatetimeFormat mdateSep msep mtimeSep) (Datetime date time) =
  case msep of
    Nothing -> builderUtf8_Ymd mdateSep date
            <> builderUtf8_HMS sp mtimeSep time
    Just sep -> builderUtf8_Ymd mdateSep date
             <> BB.char7 sep
             <> builderUtf8_HMS sp mtimeSep time

builderUtf8_YmdIMS_p :: MeridiemLocale ByteString -> SubsecondPrecision -> DatetimeFormat -> Datetime -> BB.Builder
builderUtf8_YmdIMS_p locale sp (DatetimeFormat mdateSep msep mtimeSep) (Datetime date time) =
     builderUtf8_Ymd mdateSep date
  <> maybe mempty BB.char7 msep
  <> builderUtf8_IMS_p locale sp mtimeSep time

builderUtf8_YmdIMSp :: MeridiemLocale ByteString -> SubsecondPrecision -> DatetimeFormat -> Datetime -> BB.Builder
builderUtf8_YmdIMSp locale sp (DatetimeFormat mdateSep msep mtimeSep) (Datetime date time) =
     builderUtf8_Ymd mdateSep date
  <> maybe mempty BB.char7 msep
  <> builderUtf8_IMS_p locale sp mtimeSep time


builderUtf8W3C :: Datetime -> BB.Builder
builderUtf8W3C = builderUtf8_YmdHMS SubsecondPrecisionAuto (DatetimeFormat (Just '-') (Just 'T') (Just ':'))

decodeUtf8_YmdHMS :: DatetimeFormat -> ByteString -> Maybe Datetime
decodeUtf8_YmdHMS format =
  either (const Nothing) Just . AB.parseOnly (parserUtf8_YmdHMS format)

parserUtf8_YmdHMS :: DatetimeFormat -> AB.Parser Datetime
parserUtf8_YmdHMS (DatetimeFormat mdateSep msep mtimeSep) = do
  date <- parserUtf8_Ymd mdateSep
  traverse_ AB.char msep
  time <- parserUtf8_HMS mtimeSep
  return (Datetime date time)

parserUtf8_YmdHMS_opt_S :: DatetimeFormat -> AB.Parser Datetime
parserUtf8_YmdHMS_opt_S (DatetimeFormat mdateSep msep mtimeSep) = do
  date <- parserUtf8_Ymd mdateSep
  traverse_ AB.char msep
  time <- parserUtf8_HMS_opt_S mtimeSep
  return (Datetime date time)

decodeUtf8_YmdHMS_opt_S :: DatetimeFormat -> ByteString -> Maybe Datetime
decodeUtf8_YmdHMS_opt_S format =
  either (const Nothing) Just . AB.parseOnly (parserUtf8_YmdHMS_opt_S format)


builder_YmdHMSz :: OffsetFormat -> SubsecondPrecision -> DatetimeFormat -> OffsetDatetime -> TB.Builder
builder_YmdHMSz offsetFormat sp datetimeFormat (OffsetDatetime datetime offset) =
     builder_YmdHMS sp datetimeFormat datetime
  <> builderOffset offsetFormat offset

parser_YmdHMSz :: OffsetFormat -> DatetimeFormat -> Parser OffsetDatetime
parser_YmdHMSz offsetFormat datetimeFormat = OffsetDatetime
  <$> parser_YmdHMS datetimeFormat
  <*> parserOffset offsetFormat

builder_YmdIMS_p_z :: OffsetFormat -> MeridiemLocale Text -> SubsecondPrecision -> DatetimeFormat -> OffsetDatetime -> TB.Builder
builder_YmdIMS_p_z offsetFormat meridiemLocale sp datetimeFormat (OffsetDatetime datetime offset) =
     builder_YmdIMS_p meridiemLocale sp datetimeFormat datetime
  <> " "
  <> builderOffset offsetFormat offset

encode_YmdHMSz :: OffsetFormat -> SubsecondPrecision -> DatetimeFormat -> OffsetDatetime -> Text
encode_YmdHMSz offsetFormat sp datetimeFormat =
    LT.toStrict . TB.toLazyText . builder_YmdHMSz offsetFormat sp datetimeFormat

builder_DmyHMSz :: OffsetFormat -> SubsecondPrecision -> DatetimeFormat -> OffsetDatetime -> TB.Builder
builder_DmyHMSz offsetFormat sp datetimeFormat (OffsetDatetime datetime offset) = 
     builder_DmyHMS sp datetimeFormat datetime
  <> builderOffset offsetFormat offset

parser_DmyHMSz :: OffsetFormat -> DatetimeFormat -> AT.Parser OffsetDatetime
parser_DmyHMSz offsetFormat datetimeFormat = OffsetDatetime
  <$> parser_DmyHMS datetimeFormat
  <*> parserOffset offsetFormat

builder_DmyIMS_p_z :: OffsetFormat -> MeridiemLocale Text -> SubsecondPrecision -> DatetimeFormat -> OffsetDatetime -> TB.Builder
builder_DmyIMS_p_z offsetFormat meridiemLocale sp datetimeFormat (OffsetDatetime datetime offset) = 
      builder_DmyIMS_p meridiemLocale sp datetimeFormat datetime
   <> " "
   <> builderOffset offsetFormat offset

encode_DmyHMSz :: OffsetFormat -> SubsecondPrecision -> DatetimeFormat -> OffsetDatetime -> Text
encode_DmyHMSz offsetFormat sp datetimeFormat =
    LT.toStrict . TB.toLazyText . builder_DmyHMSz offsetFormat sp datetimeFormat

builderW3Cz :: OffsetDatetime -> TB.Builder
builderW3Cz = builder_YmdHMSz
  OffsetFormatColonOn
  SubsecondPrecisionAuto
  (DatetimeFormat (Just '-') (Just 'T') (Just ':'))

encodeOffset :: OffsetFormat -> Offset -> Text
encodeOffset fmt = LT.toStrict . TB.toLazyText . builderOffset fmt

builderOffset :: OffsetFormat -> Offset -> TB.Builder
builderOffset x = case x of
  OffsetFormatColonOff -> builderOffset_z
  OffsetFormatColonOn -> builderOffset_z1
  OffsetFormatSecondsPrecision -> builderOffset_z2
  OffsetFormatColonAuto -> builderOffset_z3

decodeOffset :: OffsetFormat -> Text -> Maybe Offset
decodeOffset fmt =
  either (const Nothing) Just . AT.parseOnly (parserOffset fmt <* AT.endOfInput)

parserOffset :: OffsetFormat -> Parser Offset
parserOffset x = case x of
  OffsetFormatColonOff -> parserOffset_z
  OffsetFormatColonOn -> parserOffset_z1
  OffsetFormatSecondsPrecision -> parserOffset_z2
  OffsetFormatColonAuto -> parserOffset_z3

-- | True means positive, false means negative
parseSignedness :: Parser Bool
parseSignedness = do
  c <- AT.anyChar
  if c == '-'
    then return False
    else if c == '+'
      then return True
      else fail "while parsing offset, expected [+] or [-]"

parserOffset_z :: Parser Offset
parserOffset_z = do
  pos <- parseSignedness
  h <- parseFixedDigits 2
  m <- parseFixedDigits 2
  let !res = h * 60 + m
  return . Offset $ if pos
    then res
    else negate res

parserOffset_z1 :: Parser Offset
parserOffset_z1 = do
  pos <- parseSignedness
  h <- parseFixedDigits 2
  _ <- AT.char ':'
  m <- parseFixedDigits 2
  let !res = h * 60 + m
  return . Offset $ if pos
    then res
    else negate res

parserOffset_z2 :: AT.Parser Offset
parserOffset_z2 = do
  pos <- parseSignedness
  h <- parseFixedDigits 2
  _ <- AT.char ':'
  m <- parseFixedDigits 2
  _ <- AT.string ":00"
  let !res = h * 60 + m
  return . Offset $ if pos
    then res
    else negate res

-- | This is generous in what it accepts. If you give
--   something like +04:00 as the offset, it will be
--   allowed, even though it could be shorter.
parserOffset_z3 :: AT.Parser Offset
parserOffset_z3 = do
  pos <- parseSignedness
  h <- parseFixedDigits 2
  mc <- AT.peekChar
  case mc of
    Just ':' -> do
      _ <- AT.anyChar -- should be a colon
      m <- parseFixedDigits 2
      let !res = h * 60 + m
      return . Offset $ if pos
        then res
        else negate res
    _ -> return . Offset $ if pos
      then h * 60
      else h * (-60)

builderOffset_z :: Offset -> TB.Builder
builderOffset_z (Offset i) =
  let (!a,!b) = divMod (abs i) 60
      !prefix = if signum i == (-1) then "-" else "+"
   in prefix
      <> indexTwoDigitTextBuilder a
      <> indexTwoDigitTextBuilder b

builderOffset_z1 :: Offset -> TB.Builder
builderOffset_z1 (Offset i) =
  let (!a,!b) = divMod (abs i) 60
      !prefix = if signum i == (-1) then "-" else "+"
   in prefix
      <> indexTwoDigitTextBuilder a
      <> ":"
      <> indexTwoDigitTextBuilder b

builderOffset_z2 :: Offset -> TB.Builder
builderOffset_z2 (Offset i) =
  let (!a,!b) = divMod (abs i) 60
      !prefix = if signum i == (-1) then "-" else "+"
   in prefix
      <> indexTwoDigitTextBuilder a
      <> ":"
      <> indexTwoDigitTextBuilder b
      <> ":00"

builderOffset_z3 :: Offset -> TB.Builder
builderOffset_z3 (Offset i) =
  let (!a,!b) = divMod (abs i) 60
      !prefix = if signum i == (-1) then "-" else "+"
   in if b == 0
        then prefix
          <> indexTwoDigitTextBuilder a
        else prefix
          <> indexTwoDigitTextBuilder a
          <> ":"
          <> indexTwoDigitTextBuilder b

builderUtf8_YmdHMSz :: OffsetFormat -> SubsecondPrecision -> DatetimeFormat -> OffsetDatetime -> BB.Builder
builderUtf8_YmdHMSz offsetFormat sp datetimeFormat (OffsetDatetime datetime offset) =
     builderUtf8_YmdHMS sp datetimeFormat datetime
  <> builderOffsetUtf8 offsetFormat offset

parserUtf8_YmdHMSz :: OffsetFormat -> DatetimeFormat -> AB.Parser OffsetDatetime
parserUtf8_YmdHMSz offsetFormat datetimeFormat = OffsetDatetime
  <$> parserUtf8_YmdHMS datetimeFormat
  <*> parserOffsetUtf8 offsetFormat

builderUtf8_YmdIMS_p_z :: OffsetFormat -> MeridiemLocale ByteString -> SubsecondPrecision -> DatetimeFormat -> OffsetDatetime -> BB.Builder
builderUtf8_YmdIMS_p_z offsetFormat meridiemLocale sp datetimeFormat (OffsetDatetime datetime offset) =
     builderUtf8_YmdIMS_p meridiemLocale sp datetimeFormat datetime
  <> " "
  <> builderOffsetUtf8 offsetFormat offset

builderUtf8W3Cz :: OffsetDatetime -> BB.Builder
builderUtf8W3Cz = builderUtf8_YmdHMSz
  OffsetFormatColonOn
  SubsecondPrecisionAuto
  (DatetimeFormat (Just '-') (Just 'T') (Just ':'))

encodeOffsetUtf8 :: OffsetFormat -> Offset -> ByteString
encodeOffsetUtf8 fmt = LB.toStrict . BB.toLazyByteString . builderOffsetUtf8 fmt

decodeOffsetUtf8 :: OffsetFormat -> ByteString -> Maybe Offset
decodeOffsetUtf8 fmt =
  either (const Nothing) Just . AB.parseOnly (parserOffsetUtf8 fmt)

builderOffsetUtf8 :: OffsetFormat -> Offset -> BB.Builder
builderOffsetUtf8 x = case x of
  OffsetFormatColonOff -> builderOffsetUtf8_z
  OffsetFormatColonOn -> builderOffsetUtf8_z1
  OffsetFormatSecondsPrecision -> builderOffsetUtf8_z2
  OffsetFormatColonAuto -> builderOffsetUtf8_z3

parserOffsetUtf8 :: OffsetFormat -> AB.Parser Offset
parserOffsetUtf8 x = case x of
  OffsetFormatColonOff -> parserOffsetUtf8_z
  OffsetFormatColonOn -> parserOffsetUtf8_z1
  OffsetFormatSecondsPrecision -> parserOffsetUtf8_z2
  OffsetFormatColonAuto -> parserOffsetUtf8_z3

-- | True means positive, false means negative
parseSignednessUtf8 :: AB.Parser Bool
parseSignednessUtf8 = do
  c <- AB.anyChar
  if c == '-'
    then return False
    else if c == '+'
      then return True
      else fail "while parsing offset, expected [+] or [-]"

parserOffsetUtf8_z :: AB.Parser Offset
parserOffsetUtf8_z = do
  pos <- parseSignednessUtf8
  h <- parseFixedDigitsIntBS 2
  m <- parseFixedDigitsIntBS 2
  let !res = h * 60 + m
  return . Offset $ if pos
    then res
    else negate res

parserOffsetUtf8_z1 :: AB.Parser Offset
parserOffsetUtf8_z1 = do
  pos <- parseSignednessUtf8
  h <- parseFixedDigitsIntBS 2
  _ <- AB.char ':'
  m <- parseFixedDigitsIntBS 2
  let !res = h * 60 + m
  return . Offset $ if pos
    then res
    else negate res

parserOffsetUtf8_z2 :: AB.Parser Offset
parserOffsetUtf8_z2 = do
  pos <- parseSignednessUtf8
  h <- parseFixedDigitsIntBS 2
  _ <- AB.char ':'
  m <- parseFixedDigitsIntBS 2
  _ <- AB.string ":00"
  let !res = h * 60 + m
  return . Offset $ if pos
    then res
    else negate res

-- | This is generous in what it accepts. If you give
--   something like +04:00 as the offset, it will be
--   allowed, even though it could be shorter.
parserOffsetUtf8_z3 :: AB.Parser Offset
parserOffsetUtf8_z3 = do
  pos <- parseSignednessUtf8
  h <- parseFixedDigitsIntBS 2
  mc <- AB.peekChar
  case mc of
    Just ':' -> do
      _ <- AB.anyChar -- should be a colon
      m <- parseFixedDigitsIntBS 2
      let !res = h * 60 + m
      return . Offset $ if pos
        then res
        else negate res
    _ -> return . Offset $ if pos
      then h * 60
      else h * (-60)

builderOffsetUtf8_z :: Offset -> BB.Builder
builderOffsetUtf8_z (Offset i) =
  let (!a,!b) = divMod (abs i) 60
      !prefix = if signum i == (-1) then "-" else "+"
   in prefix
      <> indexTwoDigitByteStringBuilder a
      <> indexTwoDigitByteStringBuilder b

builderOffsetUtf8_z1 :: Offset -> BB.Builder
builderOffsetUtf8_z1 (Offset i) =
  let (!a,!b) = divMod (abs i) 60
      !prefix = if signum i == (-1) then "-" else "+"
   in prefix
      <> indexTwoDigitByteStringBuilder a
      <> ":"
      <> indexTwoDigitByteStringBuilder b

builderOffsetUtf8_z2 :: Offset -> BB.Builder
builderOffsetUtf8_z2 (Offset i) =
  let (!a,!b) = divMod (abs i) 60
      !prefix = if signum i == (-1) then "-" else "+"
   in prefix
      <> indexTwoDigitByteStringBuilder a
      <> ":"
      <> indexTwoDigitByteStringBuilder b
      <> ":00"

builderOffsetUtf8_z3 :: Offset -> BB.Builder
builderOffsetUtf8_z3 (Offset i) =
  let (!a,!b) = divMod (abs i) 60
      !prefix = if signum i == (-1) then "-" else "+"
   in if b == 0
        then prefix
          <> indexTwoDigitByteStringBuilder a
        else prefix
          <> indexTwoDigitByteStringBuilder a
          <> ":"
          <> indexTwoDigitByteStringBuilder b

january :: Month
january = Month 0

february :: Month
february = Month 1

march :: Month
march = Month 2

april :: Month
april = Month 3

may :: Month
may = Month 4

june :: Month
june = Month 5

july :: Month
july = Month 6

august :: Month
august = Month 7

september :: Month
september = Month 8

october :: Month
october = Month 9

november :: Month
november = Month 10

december :: Month
december = Month 11

sunday :: DayOfWeek
sunday = DayOfWeek 0

monday :: DayOfWeek
monday = DayOfWeek 1

tuesday :: DayOfWeek
tuesday = DayOfWeek 2

wednesday :: DayOfWeek
wednesday = DayOfWeek 3

thursday :: DayOfWeek
thursday = DayOfWeek 4

friday :: DayOfWeek
friday = DayOfWeek 5

saturday :: DayOfWeek
saturday = DayOfWeek 6


countDigits :: (Integral a) => a -> Int
countDigits v0
  | fromIntegral v64 == v0 = go 1 v64
  | otherwise              = goBig 1 (fromIntegral v0)
  where v64 = fromIntegral v0
        goBig !k (v :: Integer)
           | v > big   = goBig (k + 19) (v `quot` big)
           | otherwise = go k (fromIntegral v)
        big = 10000000000000000000
        go !k (v :: Word64)
           | v < 10    = k
           | v < 100   = k + 1
           | v < 1000  = k + 2
           | v < 1000000000000 =
               k + if v < 100000000
                   then if v < 1000000
                        then if v < 10000
                             then 3
                             else 4 + fin v 100000
                        else 6 + fin v 10000000
                   else if v < 10000000000
                        then 8 + fin v 1000000000
                        else 10 + fin v 100000000000
           | otherwise = go (k + 12) (v `quot` 1000000000000)
        fin v n = if v >= n then 1 else 0

clip :: (Ord t) => t -> t -> t -> t
clip a _ x | x < a = a
clip _ b x | x > b = b
clip _ _ x = x

parseFixedDigits :: Int -> AT.Parser Int
parseFixedDigits n = do
  t <- AT.take n
  case Text.decimal t of
    Left err -> fail err
    Right (i,r) -> if Text.null r
      then return i
      else fail "datetime decoding could not parse integral text"

parseFixedDigitsIntBS :: Int -> AB.Parser Int
parseFixedDigitsIntBS n = do
  t <- AB.take n
  case BC.readInt t of
    Nothing -> fail "datetime decoding could not parse integral bytestring (a)"
    Just (i,r) -> if BC.null r
      then return i
      else fail "datetime decoding could not parse integral bytestring (b)"

-- Only provide positive numbers to this function.
indexTwoDigitTextBuilder :: Int -> TB.Builder
indexTwoDigitTextBuilder i = if i < 100
  then Vector.unsafeIndex twoDigitTextBuilder (fromIntegral i)
  else TB.decimal i

-- | Only provide positive numbers to this function.
indexTwoDigitByteStringBuilder :: Int -> BB.Builder
indexTwoDigitByteStringBuilder i = if i < 100
  then Vector.unsafeIndex twoDigitByteStringBuilder (fromIntegral i)
  else BB.intDec i

twoDigitByteStringBuilder :: Vector BB.Builder
twoDigitByteStringBuilder = Vector.fromList
  $ map (BB.byteString . BC.pack) twoDigitStrings
{-# NOINLINE twoDigitByteStringBuilder #-}

twoDigitTextBuilder :: Vector TB.Builder
twoDigitTextBuilder = Vector.fromList
  $ map (TB.fromText . Text.pack) twoDigitStrings
{-# NOINLINE twoDigitTextBuilder #-}

twoDigitStrings :: [String]
twoDigitStrings =
  [ "00","01","02","03","04","05","06","07","08","09"
  , "10","11","12","13","14","15","16","17","18","19"
  , "20","21","22","23","24","25","26","27","28","29"
  , "30","31","32","33","34","35","36","37","38","39"
  , "40","41","42","43","44","45","46","47","48","49"
  , "50","51","52","53","54","55","56","57","58","59"
  , "60","61","62","63","64","65","66","67","68","69"
  , "70","71","72","73","74","75","76","77","78","79"
  , "80","81","82","83","84","85","86","87","88","89"
  , "90","91","92","93","94","95","96","97","98","99"
  ]

raiseTenTo :: Int -> Int64
raiseTenTo i = if i > 15
  then 10 ^ i
  else UVector.unsafeIndex tenRaisedToSmallPowers i

tenRaisedToSmallPowers :: UVector.Vector Int64
tenRaisedToSmallPowers = UVector.fromList $ map (10 ^) [0 :: Int ..15]

monthToZeroPaddedDigit :: Month -> TB.Builder
monthToZeroPaddedDigit (Month x) =
  indexTwoDigitTextBuilder (x + 1)

zeroPadDayOfMonth :: DayOfMonth -> TB.Builder
zeroPadDayOfMonth (DayOfMonth d) = indexTwoDigitTextBuilder d

monthToZeroPaddedDigitBS :: Month -> BB.Builder
monthToZeroPaddedDigitBS (Month x) =
  indexTwoDigitByteStringBuilder (x + 1)

zeroPadDayOfMonthBS :: DayOfMonth -> BB.Builder
zeroPadDayOfMonthBS (DayOfMonth d) = indexTwoDigitByteStringBuilder d

-- | A day represented as the modified Julian date, the number of days
--   since midnight on November 17, 1858.
newtype Day = Day { getDay :: Int }
  deriving (Show,Read,Eq,Ord,Hashable,Enum,ToJSON,FromJSON,Storable,Prim)

instance Torsor Day Int where
  add i (Day d) = Day (d + i)
  difference (Day a) (Day b) = a - b

-- | The day of the week.
newtype DayOfWeek = DayOfWeek { getDayOfWeek :: Int }
  deriving (Show,Read,Eq,Ord,Hashable)

-- | The day of the month.
newtype DayOfMonth = DayOfMonth { getDayOfMonth :: Int }
  deriving (Show,Read,Eq,Ord,Prim,Enum)

-- | The day of the year.
newtype DayOfYear = DayOfYear { getDayOfYear :: Int }
  deriving (Show,Read,Eq,Ord,Prim)

-- | The month of the year.
newtype Month = Month { getMonth :: Int }
  deriving (Show,Read,Eq,Ord,Prim)

instance Bounded Month where
  minBound = Month 0
  maxBound = Month 11

-- | The number of years elapsed since the beginning
--   of the Common Era.
newtype Year = Year { getYear :: Int }
  deriving (Show,Read,Eq,Ord)

newtype Offset = Offset { getOffset :: Int }
  deriving (Show,Read,Eq,Ord,Enum)

-- | POSIX time with nanosecond resolution.
newtype Time = Time { getTime :: Int64 }
  deriving (FromJSON,ToJSON,Hashable,Eq,Ord,Show,Read,Storable,Prim)

newtype DayOfWeekMatch a = DayOfWeekMatch { getDayOfWeekMatch :: Vector a }

newtype MonthMatch a = MonthMatch { getMonthMatch :: Vector a }

newtype UnboxedMonthMatch a = UnboxedMonthMatch { getUnboxedMonthMatch :: UVector.Vector a }

-- | A timespan. This is represented internally as a number
--   of nanoseconds.
newtype Timespan = Timespan { getTimespan :: Int64 }
  deriving (Show,Read,Eq,Ord,ToJSON,FromJSON,Additive)

instance Monoid Timespan where
  mempty = Timespan 0
  mappend (Timespan a) (Timespan b) = Timespan (a + b)

instance Torsor Time Timespan where
  add (Timespan ts) (Time t) = Time (t + ts)
  difference (Time t) (Time s) = Timespan (t - s)

instance Scaling Timespan Int64 where
  scale i (Timespan ts) = Timespan (i * ts)

instance Torsor Offset Int where
  add i (Offset x) = Offset (x + i)
  difference (Offset x) (Offset y) = x - y

-- | The precision used when encoding seconds to a human-readable format.
data SubsecondPrecision
  = SubsecondPrecisionAuto -- ^ Rounds to second, millisecond, microsecond, or nanosecond
  | SubsecondPrecisionFixed {-# UNPACK #-} !Int -- ^ Specify number of places after decimal

-- | A date as represented by the Gregorian calendar.
data Date = Date
  { dateYear  :: {-# UNPACK #-} !Year
  , dateMonth :: {-# UNPACK #-} !Month
  , dateDay   :: {-# UNPACK #-} !DayOfMonth
  } deriving (Show,Read,Eq,Ord)

-- | The year and number of days elapsed since the beginning it began.
data OrdinalDate = OrdinalDate
  { ordinalDateYear :: {-# UNPACK #-} !Year
  , ordinalDateDayOfYear :: {-# UNPACK #-} !DayOfYear
  } deriving (Show,Read,Eq,Ord)

-- | A month and the day of the month. This does not actually represent
--   a specific date, since this recurs every year.
data MonthDate = MonthDate
  { monthDateMonth :: {-# UNPACK #-} !Month
  , monthDateDay :: {-# UNPACK #-} !DayOfMonth
  } deriving (Show,Read,Eq,Ord)

-- | A date as represented by the Gregorian calendar
--   and a time of day.
data Datetime = Datetime
  { datetimeDate :: {-# UNPACK #-} !Date
  , datetimeTime :: {-# UNPACK #-} !TimeOfDay
  } deriving (Show,Read,Eq,Ord)

data OffsetDatetime = OffsetDatetime
  { offsetDatetimeDatetime :: {-# UNPACK #-} !Datetime
  , offsetDatetimeOffset :: {-# UNPACK #-} !Offset
  } deriving (Show,Read,Eq,Ord)

-- | A time of day with nanosecond resolution.
data TimeOfDay = TimeOfDay
  { timeOfDayHour :: {-# UNPACK #-} !Int
  , timeOfDayMinute :: {-# UNPACK #-} !Int
  , timeOfDayNanoseconds :: {-# UNPACK #-} !Int64
  } deriving (Show,Read,Eq,Ord)

data DatetimeFormat = DatetimeFormat
  { datetimeFormatDateSeparator :: !(Maybe Char)
    -- ^ Separator in the date
  , datetimeFormatSeparator :: !(Maybe Char)
    -- ^ Separator between date and time
  , datetimeFormatTimeSeparator :: !(Maybe Char)
    -- ^ Separator in the time
  } deriving (Show,Read,Eq,Ord)

-- | Formatting settings for a timezone offset.
data OffsetFormat
  = OffsetFormatColonOff -- ^ @%z@ (e.g., -0400)
  | OffsetFormatColonOn -- ^ @%:z@ (e.g., -04:00)
  | OffsetFormatSecondsPrecision -- ^ @%::z@ (e.g., -04:00:00)
  | OffsetFormatColonAuto -- ^ @%:::z@ (e.g., -04, +05:30)
  deriving (Show,Read,Eq,Ord,Enum,Bounded,Generic)

-- | Locale-specific formatting for weekdays and months. The
--   type variable will likely be instantiated to @Text@
--   or @ByteString@.
data DatetimeLocale a = DatetimeLocale
  { datetimeLocaleDaysOfWeekFull :: !(DayOfWeekMatch a)
    -- ^ full weekdays starting with Sunday, 7 elements
  , datetimeLocaleDaysOfWeekAbbreviated :: !(DayOfWeekMatch a)
    -- ^ abbreviated weekdays starting with Sunday, 7 elements
  , datetimeLocaleMonthsFull :: !(MonthMatch a)
    -- ^ full months starting with January, 12 elements
  , datetimeLocaleMonthsAbbreviated :: !(MonthMatch a)
    -- ^ abbreviated months starting with January, 12 elements
  }

-- | Locale-specific formatting for AM and PM.
data MeridiemLocale a = MeridiemLocale
  { meridiemLocaleAm :: !a
  , meridiemLocalePm :: !a
  } deriving (Read,Show,Eq,Ord)

newtype instance UVector.MVector s Month = MV_Month (PVector.MVector s Month)
newtype instance UVector.Vector Month = V_Month (PVector.Vector Month)

instance UVector.Unbox Month

instance MGVector.MVector UVector.MVector Month where
  {-# INLINE basicLength #-}
  {-# INLINE basicUnsafeSlice #-}
  {-# INLINE basicOverlaps #-}
  {-# INLINE basicUnsafeNew #-}
  {-# INLINE basicInitialize #-}
  {-# INLINE basicUnsafeReplicate #-}
  {-# INLINE basicUnsafeRead #-}
  {-# INLINE basicUnsafeWrite #-}
  {-# INLINE basicClear #-}
  {-# INLINE basicSet #-}
  {-# INLINE basicUnsafeCopy #-}
  {-# INLINE basicUnsafeGrow #-}
  basicLength (MV_Month v) = MGVector.basicLength v
  basicUnsafeSlice i n (MV_Month v) = MV_Month $ MGVector.basicUnsafeSlice i n v
  basicOverlaps (MV_Month v1) (MV_Month v2) = MGVector.basicOverlaps v1 v2
  basicUnsafeNew n = MV_Month `liftM` MGVector.basicUnsafeNew n
  basicInitialize (MV_Month v) = MGVector.basicInitialize v
  basicUnsafeReplicate n x = MV_Month `liftM` MGVector.basicUnsafeReplicate n x
  basicUnsafeRead (MV_Month v) i = MGVector.basicUnsafeRead v i
  basicUnsafeWrite (MV_Month v) i x = MGVector.basicUnsafeWrite v i x
  basicClear (MV_Month v) = MGVector.basicClear v
  basicSet (MV_Month v) x = MGVector.basicSet v x
  basicUnsafeCopy (MV_Month v1) (MV_Month v2) = MGVector.basicUnsafeCopy v1 v2
  basicUnsafeMove (MV_Month v1) (MV_Month v2) = MGVector.basicUnsafeMove v1 v2
  basicUnsafeGrow (MV_Month v) n = MV_Month `liftM` MGVector.basicUnsafeGrow v n

instance GVector.Vector UVector.Vector Month where
  {-# INLINE basicUnsafeFreeze #-}
  {-# INLINE basicUnsafeThaw #-}
  {-# INLINE basicLength #-}
  {-# INLINE basicUnsafeSlice #-}
  {-# INLINE basicUnsafeIndexM #-}
  {-# INLINE elemseq #-}
  basicUnsafeFreeze (MV_Month v) = V_Month `liftM` GVector.basicUnsafeFreeze v
  basicUnsafeThaw (V_Month v) = MV_Month `liftM` GVector.basicUnsafeThaw v
  basicLength (V_Month v) = GVector.basicLength v
  basicUnsafeSlice i n (V_Month v) = V_Month $ GVector.basicUnsafeSlice i n v
  basicUnsafeIndexM (V_Month v) i = GVector.basicUnsafeIndexM v i
  basicUnsafeCopy (MV_Month mv) (V_Month v) = GVector.basicUnsafeCopy mv v
  elemseq _ = seq

newtype instance UVector.MVector s DayOfMonth = MV_DayOfMonth (PVector.MVector s DayOfMonth)
newtype instance UVector.Vector DayOfMonth = V_DayOfMonth (PVector.Vector DayOfMonth)

instance UVector.Unbox DayOfMonth

instance MGVector.MVector UVector.MVector DayOfMonth where
  {-# INLINE basicLength #-}
  {-# INLINE basicUnsafeSlice #-}
  {-# INLINE basicOverlaps #-}
  {-# INLINE basicUnsafeNew #-}
  {-# INLINE basicInitialize #-}
  {-# INLINE basicUnsafeReplicate #-}
  {-# INLINE basicUnsafeRead #-}
  {-# INLINE basicUnsafeWrite #-}
  {-# INLINE basicClear #-}
  {-# INLINE basicSet #-}
  {-# INLINE basicUnsafeCopy #-}
  {-# INLINE basicUnsafeGrow #-}
  basicLength (MV_DayOfMonth v) = MGVector.basicLength v
  basicUnsafeSlice i n (MV_DayOfMonth v) = MV_DayOfMonth $ MGVector.basicUnsafeSlice i n v
  basicOverlaps (MV_DayOfMonth v1) (MV_DayOfMonth v2) = MGVector.basicOverlaps v1 v2
  basicUnsafeNew n = MV_DayOfMonth `liftM` MGVector.basicUnsafeNew n
  basicInitialize (MV_DayOfMonth v) = MGVector.basicInitialize v
  basicUnsafeReplicate n x = MV_DayOfMonth `liftM` MGVector.basicUnsafeReplicate n x
  basicUnsafeRead (MV_DayOfMonth v) i = MGVector.basicUnsafeRead v i
  basicUnsafeWrite (MV_DayOfMonth v) i x = MGVector.basicUnsafeWrite v i x
  basicClear (MV_DayOfMonth v) = MGVector.basicClear v
  basicSet (MV_DayOfMonth v) x = MGVector.basicSet v x
  basicUnsafeCopy (MV_DayOfMonth v1) (MV_DayOfMonth v2) = MGVector.basicUnsafeCopy v1 v2
  basicUnsafeMove (MV_DayOfMonth v1) (MV_DayOfMonth v2) = MGVector.basicUnsafeMove v1 v2
  basicUnsafeGrow (MV_DayOfMonth v) n = MV_DayOfMonth `liftM` MGVector.basicUnsafeGrow v n

instance GVector.Vector UVector.Vector DayOfMonth where
  {-# INLINE basicUnsafeFreeze #-}
  {-# INLINE basicUnsafeThaw #-}
  {-# INLINE basicLength #-}
  {-# INLINE basicUnsafeSlice #-}
  {-# INLINE basicUnsafeIndexM #-}
  {-# INLINE elemseq #-}
  basicUnsafeFreeze (MV_DayOfMonth v) = V_DayOfMonth `liftM` GVector.basicUnsafeFreeze v
  basicUnsafeThaw (V_DayOfMonth v) = MV_DayOfMonth `liftM` GVector.basicUnsafeThaw v
  basicLength (V_DayOfMonth v) = GVector.basicLength v
  basicUnsafeSlice i n (V_DayOfMonth v) = V_DayOfMonth $ GVector.basicUnsafeSlice i n v
  basicUnsafeIndexM (V_DayOfMonth v) i = GVector.basicUnsafeIndexM v i
  basicUnsafeCopy (MV_DayOfMonth mv) (V_DayOfMonth v) = GVector.basicUnsafeCopy mv v
  elemseq _ = seq

------------------------
-- The Torsor and Enum instances for Date and OrdinalDate
-- are both bad. This only causes problems for dates
-- at least a million years in the future. Some of this
-- badness is caused by pragmatism, and some of it is caused by
-- my own laziness.
--
-- The badness that comes from pragmatism:
--   - Int technically is not a good delta for Date. Date
--     has too many inhabitants. If we subtract the lowest
--     Date from the highest Date, we get something too
--     big to fit in a machine integer.
--   - There is no good way to write fromEnum or toEnum for
--     Date. Again, Date has more inhabitants than Int, so
--     it simply cannot be done.
-- The badness that comes from laziness:
--   - Technically, we should still be able to add deltas to
--     Dates that do not fit in machine integers. We should
--     also be able to correctly subtract Dates to cannot
--     fit in machine integers.
--   - For similar reasons, the Enum functions succ, pred,
--     enumFromThen, enumFromThenTo, etc. could all have
--     better definitions than the default ones currently
--     used.
-- If, for some reason, anyone ever wants to fix the badness
-- that comes from laziness, all
-- you really have to do is define a version of dateToDay,
-- dayToDate, ordinalDateToDay, and dayToOrdinalDate
-- that uses something bigger instead of Day. Maybe something like
-- (Int,Word) or (Int,Word,Word). I'm not exactly sure how
-- big it would need to be to work correctly. Then you could
-- handle deltas of two very far off days correctly, provided
-- that the two days weren't also super far from each other.
--
------------------------
instance Torsor Date Int where
  add i d = dayToDate (add i (dateToDay d))
  difference a b = difference (dateToDay a) (dateToDay b)

instance Torsor OrdinalDate Int where
  add i d = dayToOrdinalDate (add i (ordinalDateToDay d))
  difference a b = difference (ordinalDateToDay a) (ordinalDateToDay b)

instance Enum Date where
  fromEnum d = fromEnum (dateToDay d)
  toEnum i = dayToDate (toEnum i)

instance Enum OrdinalDate where
  fromEnum d = fromEnum (ordinalDateToDay d)
  toEnum i = dayToOrdinalDate (toEnum i)

instance ToJSON Datetime where
  toJSON = AE.String . encode_YmdHMS SubsecondPrecisionAuto hyphen
  toEncoding x = AEE.unsafeToEncoding (BB.char7 '"' <> builderUtf8_YmdHMS SubsecondPrecisionAuto hyphen x <> BB.char7 '"')

instance ToJSON Offset where
  toJSON = AE.String . encodeOffset OffsetFormatColonOn
  toEncoding x = AEE.unsafeToEncoding (BB.char7 '"' <> builderOffsetUtf8 OffsetFormatColonOn x <> BB.char7 '"')

instance FromJSON Offset where
  parseJSON = AE.withText "Offset" aesonParserOffset

instance ToJSONKey Offset where
  toJSONKey = AE.ToJSONKeyText
    (encodeOffset OffsetFormatColonOn)
    (\x -> AEE.unsafeToEncoding (BB.char7 '"' <> builderOffsetUtf8 OffsetFormatColonOn x <> BB.char7 '"'))

instance FromJSONKey Offset where
  fromJSONKey = AE.FromJSONKeyTextParser aesonParserOffset

aesonParserOffset :: Text -> AET.Parser Offset
aesonParserOffset t = case decodeOffset OffsetFormatColonOn t of
  Nothing -> fail "could not parse Offset"
  Just x -> return x

