"use client";

import dynamic from "next/dynamic";

const ChandelierOrNot = dynamic(() => import("~/components/ChandelierOrNot"), {
  ssr: false,
});

export default function App() {
  return <ChandelierOrNot />;
}
