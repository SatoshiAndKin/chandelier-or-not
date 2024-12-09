import { WagmiProvider, createConfig, http, injected } from "wagmi";
import { base } from "wagmi/chains";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { ConnectKitProvider, getDefaultConfig } from "connectkit";
import { coinbaseWallet, metaMask, safe } from "wagmi/connectors";
import { frameConnector } from "~/lib/connector";

// TODO: option to save the default connector in local storage
const config = createConfig(
  getDefaultConfig({
    chains: [base],
    // TODO: frameConnector(), 
    connectors: [injected(), coinbaseWallet(), metaMask(), safe()],
    transports: {
      [base.id]: http(),
    },

    // Required API Keys
    // TODO: what if i don't care about wallet connect?
    walletConnectProjectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || "",

    // Required App Info
    appName: "Chandelier or Not?",

    // Optional App Info
    appDescription: "Train an AI to recognize chandeliers and learn about linguistics.",
    appUrl: "https://chandelierornot.com", // your app's url
    appIcon: "https://chandelierornot.com/icon.png", // your app's icon, no bigger than 1024x1024px (max. 1MB)
  }),
);

const queryClient = new QueryClient();

export default function Provider({ children }: { children: React.ReactNode }) {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <ConnectKitProvider>{children}</ConnectKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
};