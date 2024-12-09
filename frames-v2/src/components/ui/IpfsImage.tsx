import { Address } from "viem";
import { useReadContract } from "wagmi";
import ChandelierOrNot from "~/contracts/ChandelierOrNot.json";

// TODO: take props for class name and alt text
export function IpfsImage({chandelierOrNotAddress, postId}: {chandelierOrNotAddress: Address, postId: number}) {
    const { data, isError, isLoading } = useReadContract({
        address: chandelierOrNotAddress,
        abi: ChandelierOrNot.abi,
        functionName: 'getTokenURI',
        args: [postId],
      })

    // TODO: get helia from context

    // TODO: use helia to load the image over ipfs. fallback to https://ipfs.io/ipfs/${cid}

    return (
        <img className="mb-4 h-auto max-w-full rounded-lg hover:scale-105 transition-transform duration-300" src="https://ipfs.io/ipfs/QmaARLig5XkChLpj7RnBZ1Sdad7YbhLqZ17Y349f9rGH54"></img>
    );
}