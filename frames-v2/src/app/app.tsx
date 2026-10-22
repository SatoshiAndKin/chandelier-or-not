"use client";

import dynamic from "next/dynamic";

const ChandelierOrNot = dynamic(() => import("~/components/ChandelierOrNot"), {
  ssr: false,
});

export default function App({ title }: { title?: string }) {
  return <ChandelierOrNot title={title} />;
}
