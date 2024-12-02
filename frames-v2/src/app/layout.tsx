import type { Metadata } from "next";
import React from "react";

import "~/app/globals.css";
import { Providers } from "~/app/providers";

export const metadata: Metadata = {
  title: "Chandelier or Not?",
  description: "A Farcaster Frames v2 demo app",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>
        <React.StrictMode><Providers>{children}</Providers></React.StrictMode>
      </body>
    </html>
  );
}
