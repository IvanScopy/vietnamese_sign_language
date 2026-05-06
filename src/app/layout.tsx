import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "VSL Bridge",
  description: "Vietnamese Sign Language Bridge - Communication and Learning",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
