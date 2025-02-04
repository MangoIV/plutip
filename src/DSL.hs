{-# LANGUAGE ImplicitParams #-}

-- 
module DSL (
  BpiWallet,
  addSomeWallet,
  runContractTagged,
  runContract,
  runContract_,
  runUsingCluster,
  ada,
  waitSeconds,
  report,
  mkMainnetAddress,
  cardanoMainnetAddress,
  ledgerPaymentPkh,
  andThen,
) where

import BotInterface.Run (runContract, runContractTagged, runContract_)
import BotInterface.Wallet (
  BpiWallet,
  addSomeWallet,
  cardanoMainnetAddress,
  ledgerPaymentPkh,
  mkMainnetAddress,
 )
import Control.Concurrent (threadDelay)
import Control.Monad.IO.Class (MonadIO, liftIO)
import Control.Monad.Reader (ReaderT)
import Data.Text.IO qualified as TIO
import LocalCluster.Cluster (runUsingCluster)
import LocalCluster.Types (ClusterEnv, RunResult, isSuccess, prettyResult)
import Numeric.Natural (Natural)
import System.Console.ANSI (hSupportsANSIColor)
import System.IO (stdout)
import Test.Tasty.Ingredients.ConsoleReporter (withConsoleFormat)
import Test.Tasty.Providers.ConsoleFormat (failFormat, okFormat)
import Utils (ada)

-- | Print contract execution result to terminal
report :: (Show a, Show w, Show e, MonadIO m) => RunResult w e a -> m ()
report r = liftIO $ do
  canColors <- hSupportsANSIColor stdout
  let ?colors = canColors
  withConsoleFormat
    (pickFormat r)
    (TIO.putStrLn $ prettyResult r)
  where
    pickFormat res =
      if isSuccess res
        then okFormat
        else failFormat

-- | Awaiting via `threadDelay`
waitSeconds :: Natural -> ReaderT ClusterEnv IO ()
waitSeconds n = liftIO $ threadDelay (fromEnum n * 1_000_000)

-- | Alias for `>>=` for readability
andThen :: Monad m => m a -> (a -> m b) -> m b
andThen = (>>=)
