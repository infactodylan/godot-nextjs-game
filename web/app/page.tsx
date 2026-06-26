import Link from "next/link";

export default function Home() {
  return (
    <main className="flex min-h-full flex-col items-center justify-center gap-4">
      <h1 className="text-2xl font-semibold">New Game Project</h1>
      <Link
        href="/game"
        className="rounded-lg bg-white px-6 py-3 text-sm font-medium text-black transition hover:bg-neutral-200"
      >
        Play Game
      </Link>
    </main>
  );
}
