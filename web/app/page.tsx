import Link from "next/link";

export default function Home() {
  return (
    <main className="welcome-page">
      <section className="hero-section">
        <div className="hero-copy">
          <p className="eyebrow">A story-driven survival adventure</p>
          <h1>The Village</h1>
          <p className="hero-description">
            The night has changed everything. Explore a hand-built village,
            uncover what happened, and survive the creatures that now roam the
            streets.
          </p>
          <div className="hero-actions">
            <Link href="/game/index.html" className="play-button">
              Play the game <span aria-hidden="true">→</span>
            </Link>
            <a href="#story" className="text-link">Discover the story</a>
          </div>
        </div>
        <div className="hero-art" aria-label="Gameplay screenshot">
          <div className="art-frame">
            <img src="/gameplay-screenshot.png" alt="The Village gameplay in a dark city street" />
          </div>
          <span className="art-caption">Captured in game · 01</span>
        </div>
      </section>

      <section id="story" className="story-section">
        <div>
          <p className="eyebrow">Enter the quiet</p>
          <h2>Every street has a secret.</h2>
        </div>
        <p className="story-copy">
          Move through shadowed courtyards and abandoned rooms, manage every
          round, and choose when to fight. The village remembers what you do.
        </p>
      </section>

      <section className="feature-grid" aria-label="Game features">
        <article><span>01</span><h3>Explore</h3><p>Find your way through a living world built for discovery.</p></article>
        <article><span>02</span><h3>Survive</h3><p>Keep your health and ammo close when the night closes in.</p></article>
        <article><span>03</span><h3>Uncover</h3><p>Piece together a story hidden in the village’s quiet places.</p></article>
      </section>

      <footer className="welcome-footer"><span>THE VILLAGE</span><span>Built for the brave</span></footer>
    </main>
  );
}
