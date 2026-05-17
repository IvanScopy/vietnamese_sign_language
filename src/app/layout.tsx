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
    <html lang="vi">
      <body style={{ margin: 0, fontFamily: 'system-ui, sans-serif', background: '#FFFFFF', color: '#101010' }}>{children}</body>
    </html>
  );
}
