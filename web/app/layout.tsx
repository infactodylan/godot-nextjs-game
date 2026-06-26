import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "New Game Project",
  description: "Play New Game Project in your browser.",
  icons: {
    icon: "/game/index.icon.png",
    apple: "/game/index.apple-touch-icon.png",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
