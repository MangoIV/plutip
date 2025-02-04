module LocalCluster.Types (
  ClusterEnv (..),
  RunResult (..),
  Outcome (..),
  FailReason (..),
  nodeSocket,
  isSuccess,
  prettyResult,
) where

import BotPlutusInterface.Types (ContractState)
import Cardano.Api (NetworkId)
import Cardano.BM.Tracing (Trace)
import Cardano.Launcher.Node (CardanoNodeConn)
import Cardano.Wallet.Shelley.Launch.Cluster (RunningNode (RunningNode))
import Control.Exception (SomeException)
import Data.Text (Text, intercalate, pack)
import Servant.Client (BaseUrl)

-- | Environment for actions that use local cluster
data ClusterEnv = ClusterEnv
  { runningNode :: RunningNode
  , chainIndexUrl :: !BaseUrl
  , networkId :: !NetworkId
  , -- | this directory atm used to store all node related files,
    -- files created by `cardano-cli`, `chain-index` and `bot-plutus-interface`
    supportDir :: FilePath
  , tracer :: Trace IO Text -- not really used anywhere now
  }

-- | Helper function to get socket path from
nodeSocket :: ClusterEnv -> CardanoNodeConn
nodeSocket (ClusterEnv (RunningNode sp _ _) _ _ _ _) = sp

-- | Result of `Contract` execution
data RunResult w e a = RunResult
  { contractTag :: Maybe Text -- ^ optional text tag
  , outcome :: Outcome w e a -- ^ outcome of running contract (success or failure)
  }
  deriving stock (Show)

-- | Outcome of running contract
data Outcome w e a
  = Success
      { contractResult :: a -- ^ return value of `Contract`
      , contractState :: ContractState w -- ^ `Contract` state after execution
      }
  | Fail {reason :: FailReason e -- ^ reason of `Contract` execution failure
         }
  deriving stock (Show)

-- | Reason of `Contract` execution failure
data FailReason e
  = ContractExecutionError e -- ^ error thrown by `Contract` (via `throwError`)
  | CaughtException SomeException -- ^ exception caught during contract run
  | OtherErr Text
  deriving stock (Show)

-- | Check if outcome of contract execution result is `Success`
isSuccess :: RunResult w e a -> Bool
isSuccess = \case
  RunResult _ (Success _ _) -> True
  RunResult _ (Fail _) -> False

-- | Pretty print (temporary impl)
prettyResult :: (Show a, Show w, Show e) => RunResult w e a -> Text
prettyResult res@(RunResult tag outc) =
  intercalate "\n" [header, prettyOut outc, ""]
  where
    header =
      mconcat
        [ maybe "Contract" (\t -> "\'" <> t <> "\'") tag
        , " execution "
        , if isSuccess res then "succeeded" else "failed"
        ]

prettyOut :: (Show a, Show w, Show e) => Outcome w e a -> Text
prettyOut = \case
  (Success cRes cState) ->
    intercalate
      "\n"
      [ " Contract returned: " <> toText cRes
      , " Contract state: " <> toText cState
      ]
  (Fail e) -> " The error is: " <> toText e

toText :: Show a => a -> Text
toText = pack . show
