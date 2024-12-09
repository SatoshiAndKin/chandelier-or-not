"use client";

import { ConnectKitButton } from "connectkit";
import { useEffect, useCallback, useState, useMemo } from "react";
import sdk, {
  FrameNotificationDetails,
  type FrameContext,
} from "@farcaster/frame-sdk";
import useKonami from 'react-use-konami';
import {
  
  useAccount,
  useSendTransaction,
  useWaitForTransactionReceipt,
  useDisconnect,
  useConnect,
  useSwitchChain,
  useChainId,
} from "wagmi";
import { Address } from "viem";

import { Ipfs } from "~/components/Ipfs";
import { IpfsImage } from "~/components/ui/IpfsImage";
import { Button } from "~/components/ui/Button";
import { truncateAddress } from "~/lib/truncateAddress";
import { base, optimism } from "wagmi/chains";
import { BaseError, UserRejectedRequestError } from "viem";

export default function ChandelierOrNot() {
  const title = "Chandelier or Not?";

  const [isSDKLoaded, setIsSDKLoaded] = useState(false);
  const [frameContext, setFrameContext] = useState<FrameContext>();
  const [isContextOpen, setIsContextOpen] = useState(false);
  const [txHash, setTxHash] = useState<string | null>(null);
  const [addFrameResult, setAddFrameResult] = useState("");
  const [notificationDetails, setNotificationDetails] =
    useState<FrameNotificationDetails | null>(null);
  const [sendNotificationResult, setSendNotificationResult] = useState("");

  const [hasVoted, setHasVoted] = useState<null | boolean>(null);

  // TODO: get the initial post id from the URL
  const [currentPostId, setCurrentPostId] = useState(0);

  // TODO: is a ton of state the right thing here? these all get loaded from a single query
  // TODO: this needs to refresh every few minutes as new blocks arrive. probably better to poll every minute/have a refresh button than to subscribe
  const [yesBalance, setYesBalance] = useState<number>(0);
  const [noBalance, setNoBalance] = useState<number>(0);
  const [totalYes, setTotalYes] = useState<number>(0);
  const [totalNo, setTotalNo] = useState<number>(0);
  const [totalPosts, setTotalPosts] = useState<number>(10);

  const { isConnected } = useAccount();

  // TODO: this should be a "debugMode" component
  const [debugMode, setDebugMode] = useState<boolean>(() => {
    const storageDebugMode = localStorage.getItem('debugMode');
    return storageDebugMode ? JSON.parse(storageDebugMode) : false;
  });
  useKonami(() => {
    setDebugMode((prev: boolean) => !prev);
  }, {
      code: ['ArrowUp', 'ArrowDown', 'Enter'], 
  });
  useEffect(() => {
      localStorage.setItem('debugMode', JSON.stringify(debugMode));
  }, [debugMode]);

  useEffect(() => {
    const load = async () => {
      setFrameContext(await sdk.context);
      sdk.actions.ready();
    };
    if (sdk && !isSDKLoaded) {
      setIsSDKLoaded(true);
      load();
    }
  }, [isSDKLoaded]);

  const goToPreviousPost = () => {
    if (currentPostId > 0) {
      setCurrentPostId((prevIndex) => prevIndex - 1);
    }
  };

  const goToNextPost = () => {
    if (currentPostId < totalPosts - 1) {
      setCurrentPostId((prevIndex) => prevIndex + 1);
    }
  };

  const goToRandomPost = () => {
    while (true) {
      const randomIndex = Math.floor(Math.random() * totalPosts);
      if (randomIndex !== currentPostId) {
        setCurrentPostId(randomIndex);
        break;
      }
    }
  };

  // TODO: button to close the frame!
  const closeFrame = useCallback(() => {
    sdk.actions.close();
  }, []);

  const addFrame = useCallback(async () => {
    try {
      setNotificationDetails(null);

      const result = await sdk.actions.addFrame();

      if (result.added) {
        if (result.notificationDetails) {
          setNotificationDetails(result.notificationDetails);
        }
        setAddFrameResult(
          result.notificationDetails
            ? `Added, got notificaton token ${result.notificationDetails.token} and url ${result.notificationDetails.url}`
            : "Added, got no notification details"
        );
      } else {
        setAddFrameResult(`Not added: ${result.reason}`);
      }
    } catch (error) {
      setAddFrameResult(`Error: ${error}`);
    }
  }, []);

  const sendNotification = useCallback(async () => {
    setSendNotificationResult("");
    if (!notificationDetails) {
      return;
    }

    try {
      const response = await fetch("/api/send-notification", {
        method: "POST",
        mode: "same-origin",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          token: notificationDetails.token,
          url: notificationDetails.url,
          targetUrl: window.location.href,
        }),
      });

      if (response.status === 200) {
        setSendNotificationResult("Success");
        return;
      }

      const data = await response.text();
      setSendNotificationResult(`Error: ${data}`);
    } catch (error) {
      setSendNotificationResult(`Error: ${error}`);
    }
  }, [notificationDetails]);

  const toggleContext = useCallback(() => {
    setIsContextOpen((prev) => !prev);
  }, []);

  const {
    sendTransaction,
    error: sendTxError,
    isError: isSendTxError,
    isPending: isSendTxPending,
  } = useSendTransaction();

  // TODO: this is wrong. this needs to send a transaction and then wait for the result before setting has voted to true
  const voteYes = useCallback(() => {
    setHasVoted(true);
  }, [sendTransaction]);

  const voteNo = useCallback(() => {
    setHasVoted(true);
  }, [sendTransaction]);
  
  if (!isSDKLoaded) {
    return <div>Loading...</div>;
  }

  const chandelierOrNotAddress: Address = "0x001";

  // TODO: handle large and small screens
  return (
    <div className="w-[300px] md:w-[500px] mx-auto py-4 px-2">
      <h1 className="text-2xl font-bold mb-4 text-center">{title}</h1>

      <div className="flex items-center justify-between mb-4">
        <h2 className="font-bold text-lg text-left">Post #{currentPostId}</h2>
        <ConnectKitButton />
      </div>

      <div className="mb-4">
        <IpfsImage chandelierOrNotAddress={chandelierOrNotAddress} postId={currentPostId} />
      </div>

      {(isConnected && !hasVoted) && (
        <div className="mb-4 grid grid-cols-2 gap-2 mx-auto items-center justify-center">
          <Button className="flex w-full justify-center" onClick={voteYes}>Vote Yes</Button>
          <Button className="flex w-full justify-center bg-red-500 hover:bg-red-600" onClick={voteNo}>Vote No</Button>
        </div>
      )}

      {(yesBalance + noBalance > 0) && (
        <div className="mb-4 grid grid-cols-2 gap-2 mx-auto items-center justify-center">
          <div className="p-4 mt-2 flex w-full justify-center bg-gray-100 dark:bg-gray-800">
            Your Yes Balance: {yesBalance} (of {totalYes} total)
          </div>
          <div className="p-4 mt-2 flex w-full justify-center bg-gray-100 dark:bg-gray-800">
            Your No Balance: {noBalance} (of {totalNo} total)
          </div>
          {/* TODO: button to swap your votes */}
        </div>
      )}

      <div className="mb-4 grid grid-cols-3 gap-2 mx-auto items-center justify-center">
        {/* TODO: disable previous button if we are post 0 */}
        <Button
          className="flex w-full justify-center"
          disabled={currentPostId === 0}
          onClick={goToPreviousPost}
        >
          Previous Post
        </Button>
        {/* TODO: disable next button if we are at the last post */}
        <Button
          className="flex w-full justify-center"
          disabled={currentPostId === totalPosts - 1}
          onClick={goToNextPost}
        >
          Next Post
        </Button>
        <Button
          className="flex w-full justify-center"
          disabled={totalPosts <= 1}
          onClick={goToRandomPost}
        >
          Random Post
        </Button>
      </div>

      {/* TODO: only display this if we have a frame conext */}
      {frameContext && (
        <div className="mb-4">
          {addFrameResult && (
            <div className="mb-2">Add frame result: {addFrameResult}</div>
          )}
          <Button onClick={addFrame}>Add frame to client</Button>
          <Button onClick={closeFrame}>Close</Button>
        </div>
      )}

      {notificationDetails && (
        <div>
          <h2 className="font-2xl font-bold">Notify</h2>

          {sendNotificationResult && (
            <div className="mb-2">
              Send notification result: {sendNotificationResult}
            </div>
          )}
          <div className="mb-4">
            <Button onClick={sendNotification}>Send notification</Button>
          </div>
        </div>
      )}

      {debugMode && (
        <div className="mb-4">
          <h2 className="font-2xl font-bold">Context</h2>
          <button
            onClick={toggleContext}
            className="flex items-center gap-2 transition-colors"
          >
            <span
              className={`transform transition-transform ${
                isContextOpen ? "rotate-90" : ""
              }`}
            >
              ➤
            </span>
            Tap to expand
          </button>

          {isContextOpen && (
            <div className="p-4 mt-2 bg-gray-100 dark:bg-gray-800 rounded-lg">
              <pre className="font-mono text-xs whitespace-pre-wrap break-words max-w-[260px] overflow-x-">
                {JSON.stringify(frameContext, null, 2)}
              </pre>
              <Ipfs />
            </div>
          )}
        </div>
      )}
    </div>
  );
}

function SendEth() {
  const { isConnected, chainId } = useAccount();
  const {
    sendTransaction,
    data,
    error: sendTxError,
    isError: isSendTxError,
    isPending: isSendTxPending,
  } = useSendTransaction();

  const { isLoading: isConfirming, isSuccess: isConfirmed } =
    useWaitForTransactionReceipt({
      hash: data,
    });

  const toAddr = useMemo(() => {
    // Protocol guild address
    return chainId === base.id
      ? "0x32e3C7fD24e175701A35c224f2238d18439C7dBC"
      : "0xB3d8d7887693a9852734b4D25e9C0Bb35Ba8a830";
  }, [chainId]);

  const handleSend = useCallback(() => {
    sendTransaction({
      to: toAddr,
      value: 1n,
    });
  }, [toAddr, sendTransaction]);

  return (
    <>
      <Button
        onClick={handleSend}
        disabled={!isConnected || isSendTxPending}
        isLoading={isSendTxPending}
      >
        Send Transaction (eth)
      </Button>
      {isSendTxError && renderError(sendTxError)}
      {data && (
        <div className="mt-2 text-xs">
          <div>Hash: {truncateAddress(data)}</div>
          <div>
            Status:{" "}
            {isConfirming
              ? "Confirming..."
              : isConfirmed
              ? "Confirmed!"
              : "Pending"}
          </div>
        </div>
      )}
    </>
  );
}

const renderError = (error: Error | null) => {
  if (!error) return null;
  if (error instanceof BaseError) {
  const isUserRejection = error.walk((e) => e instanceof UserRejectedRequestError)
  
    if (isUserRejection) {
      return <div className="text-red-500 text-xs mt-1">Rejected by user.</div>;
    }
  }

  return <div className="text-red-500 text-xs mt-1">{error.message}</div>;
};

