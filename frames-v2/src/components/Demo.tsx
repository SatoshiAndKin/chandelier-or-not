import { useEffect, useCallback, useState } from "react";
import sdk, { type FrameContext } from "@farcaster/frame-sdk";
import {
  useAccount,
  useSendTransaction,
  useWaitForTransactionReceipt,
  useDisconnect,
  useConnect,
} from "wagmi";

import { config } from "~/components/providers/WagmiProvider";
import { Button } from "~/components/ui/Button";
import { IpfsComponent } from "~/components/Ipfs";
import { IpfsImage } from "~/components/ui/IpfsImage";
import { truncateAddress } from "~/lib/truncateAddress";

export default function Demo(
  { title }: { title?: string } = { title: "Frames v2 Demo" }
) {
  const [hasVoted, setHasVoted] = useState<null | boolean>(null);
  const [isSDKLoaded, setIsSDKLoaded] = useState(false);
  const [context, setContext] = useState<FrameContext>();
  const [isContextOpen, setIsContextOpen] = useState(false);
  const [txHash, setTxHash] = useState<string | null>(null);
  const [postId, setPostId] = useState(0);

  const { address, isConnected } = useAccount();
  const {
    sendTransaction,
    error: sendTxError,
    isError: isSendTxError,
    isPending: isSendTxPending,
  } = useSendTransaction();

  const { isLoading: isConfirming, isSuccess: isConfirmed } =
    useWaitForTransactionReceipt({
      hash: txHash as `0x${string}`,
    });

  const { disconnect: disconnectWallet } = useDisconnect();
  const { connect: connectWallet } = useConnect();

  useEffect(() => {
    const load = async () => {
      const ctx = await sdk.context;

      if (ctx === undefined) {
        // TODO: how best to display an error?
        console.error("not in a frame");
        return;
      }

      setContext(ctx);
      sdk.actions.ready();
    };
    if (sdk && !isSDKLoaded) {
      setIsSDKLoaded(true);
      load();
    }
  }, [isSDKLoaded]);

  const closeFrame = useCallback(() => {
    sdk.actions.close();
  }, []);

  // TODO: this is wrong. this needs to send a transaction and then wait for the result before setting has voted to true
  const voteYes = useCallback(() => {
    setHasVoted(true);
  }, [sendTransaction]);

  const voteNo = useCallback(() => {
    setHasVoted(true);
  }, [sendTransaction]);

  // TODO: rewrite this to vote on a post
  const sendTx = useCallback(() => {
    sendTransaction(
      {
        to: "0x4bBFD120d9f352A0BEd7a014bd67913a2007a878",
        data: "0x9846cd9efc000023c0",
      },
      {
        onSuccess: (hash) => {
          setTxHash(hash);
        },
      }
    );
  }, [sendTransaction]);

  const toggleContext = useCallback(() => {
    setIsContextOpen((prev) => !prev);
  }, []);

  const renderError = (error: Error | null) => {
    if (!error) return null;
    return <div className="text-red-500 text-xs mt-1">{error.message}</div>;
  };

  if (!isSDKLoaded) {
    return <div>Loading...</div>;
  }

  return (
    <div className="w-[300px] mx-auto py-4 px-2">
      <h1 className="text-2xl font-bold text-center mb-4">{title || "Chandelier or Not?"}</h1>

      <div className="mb-4">
        <h2 className="font-bold mb-4 text-center">Post #{postId}</h2>

        <div className="mb-4">
          <IpfsImage />
        </div>

        {!hasVoted && (
          <div className="mb-4 flex justify-between space-x-2">
            <Button className="px-4 py-2" onClick={voteYes}>Vote Yes</Button>
            <Button className="px-4 py-2 bg-red-500 hover:bg-red-600" onClick={voteNo}>Vote No</Button>
          </div>
        )}

        <div className="mb-4">
          <div className="p-4 mt-2 bg-gray-100 dark:bg-gray-800 rounded-lg">
            Your Yes Balance: ? (of ? total)
          </div>
          <div className="p-4 mt-2 bg-gray-100 dark:bg-gray-800 rounded-lg">
            Your No Balance: ? (of ? total)
          </div>
        </div>

        <div className="mb-4 flex justify-between space-x-2">
          {/* TODO: disable previous button if we are post 0 */}
          <Button className="px-4 py-2">
            Previous Post
          </Button>
          {/* TODO: disable next button if we are at the last post */}
          <Button className="px-4 py-2">
            Next Post
          </Button>
          <Button className="px-4 py-2">
            Random Post
          </Button>
        </div>
      </div>

      <div>
        <h2 className="font-2xl font-bold">Wallet</h2>

        {address && (
          <div className="my-2 text-xs">
            Address: <pre className="inline">{truncateAddress(address)}</pre>
          </div>
        )}

        <div className="mb-4">
          <Button
            onClick={() =>
              isConnected
                ? disconnectWallet()
                : connectWallet({ connector: config.connectors[0] })
            }
          >
            {isConnected ? "Disconnect" : "Connect"}
          </Button>
        </div>

        {isConnected && (
          <>
            <div className="mb-4">
              <Button
                onClick={sendTx}
                disabled={!isConnected || isSendTxPending}
                isLoading={isSendTxPending}
              >
                Send Transaction
              </Button>
              {isSendTxError && renderError(sendTxError)}
              {txHash && (
                <div className="mt-2 text-xs">
                  <div>Hash: {truncateAddress(txHash)}</div>
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
            </div>
          </>
        )}
      </div>

      <div className="mb-4">
        <h2 className="font-2xl font-bold">Debugging</h2>
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
              {JSON.stringify(context, null, 2)}
            </pre>
            
            <IpfsComponent />

            {/* TODO: contract addresses */}
          </div>
        )}
      </div>

      {/* TODO: this should be an "X" at the top of the page */}
      <div className="mb-4">
        <Button onClick={closeFrame}>Close Frame</Button>
      </div>
    </div>
  );
}
