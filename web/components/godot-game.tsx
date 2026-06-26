"use client";

import { useEffect, useRef, useState } from "react";

const GODOT_BASE = "/game";

type GodotConfig = {
  args: string[];
  canvasResizePolicy: number;
  emscriptenPoolSize: number;
  ensureCrossOriginIsolationHeaders: boolean;
  executable: string;
  experimentalVK: boolean;
  fileSizes: Record<string, number>;
  focusCanvas: boolean;
  gdextensionLibs: string[];
  godotPoolSize: number;
  serviceWorker?: boolean;
};

type GodotEngine = {
  getMissingFeatures: (options: { threads: boolean }) => string[];
  installServiceWorker: () => Promise<void>;
  startGame: (override: {
    onProgress: (current: number, total: number) => void;
  }) => Promise<void>;
};

declare global {
  interface Window {
    Engine: {
      new (config: GodotConfig): GodotEngine;
      getMissingFeatures: GodotEngine["getMissingFeatures"];
    };
  }
}

async function loadGodotEngine(): Promise<void> {
  if (window.Engine) {
    return;
  }

  await new Promise<void>((resolve, reject) => {
    const script = document.createElement("script");
    script.src = `${GODOT_BASE}/index.js`;
    script.async = true;
    script.onload = () => resolve();
    script.onerror = () => reject(new Error("Failed to load the Godot engine."));
    document.body.appendChild(script);
  });
}

async function fetchGodotConfig(): Promise<GodotConfig> {
  const response = await fetch(`${GODOT_BASE}/index.html`);
  if (!response.ok) {
    throw new Error("Game files are missing. Run scripts/export_web.sh first.");
  }

  const html = await response.text();
  const match = html.match(/const GODOT_CONFIG = (\{[\s\S]*?\});/);
  if (!match) {
    throw new Error("Could not read Godot configuration from the exported build.");
  }

  const config = JSON.parse(match[1]) as GodotConfig;
  return prefixGodotPaths(config);
}

function prefixGodotPaths(config: GodotConfig): GodotConfig {
  const prefix = (path: string) =>
    path.startsWith("/") ? path : `${GODOT_BASE}/${path}`;

  return {
    ...config,
    executable: prefix(config.executable),
    fileSizes: Object.fromEntries(
      Object.entries(config.fileSizes).map(([file, size]) => [
        prefix(file),
        size,
      ]),
    ),
  };
}

export function GodotGame() {
  const [mounted, setMounted] = useState(false);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const statusRef = useRef<HTMLDivElement>(null);
  const progressRef = useRef<HTMLProgressElement>(null);
  const noticeRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    setMounted(true);
  }, []);

  useEffect(() => {
    if (!mounted) {
      return;
    }

    let cancelled = false;
    let initializing = true;
    let statusMode = "";

    const statusOverlay = statusRef.current;
    const statusProgress = progressRef.current;
    const statusNotice = noticeRef.current;
    const canvas = canvasRef.current;

    if (!statusOverlay || !statusProgress || !statusNotice || !canvas) {
      return;
    }

    const setStatusMode = (mode: "hidden" | "progress" | "notice") => {
      if (statusMode === mode || !initializing) {
        return;
      }

      if (mode === "hidden") {
        statusOverlay.remove();
        initializing = false;
        return;
      }

      statusOverlay.style.visibility = "visible";
      statusProgress.style.display = mode === "progress" ? "block" : "none";
      statusNotice.style.display = mode === "notice" ? "block" : "none";
      statusMode = mode;
    };

    const setStatusNotice = (text: string) => {
      statusNotice.replaceChildren();
      text.split("\n").forEach((line, index, lines) => {
        statusNotice.appendChild(document.createTextNode(line));
        if (index < lines.length - 1) {
          statusNotice.appendChild(document.createElement("br"));
        }
      });
    };

    const displayFailureNotice = (err: unknown) => {
      console.error(err);
      if (err instanceof Error) {
        setStatusNotice(err.message);
      } else if (typeof err === "string") {
        setStatusNotice(err);
      } else {
        setStatusNotice("An unknown error occurred.");
      }
      setStatusMode("notice");
      initializing = false;
    };

    const start = async () => {
      try {
        await loadGodotEngine();
        if (cancelled) {
          return;
        }

        const godotConfig = await fetchGodotConfig();
        if (cancelled) {
          return;
        }

        const threadsEnabled = false;
        const engine = new window.Engine(godotConfig);
        const missing = window.Engine.getMissingFeatures({ threads: threadsEnabled });

        if (missing.length !== 0) {
          const missingMsg =
            "Error\nThe following features required to run Godot projects on the Web are missing:\n";
          displayFailureNotice(missingMsg + missing.join("\n"));
          return;
        }

        setStatusMode("progress");
        await engine.startGame({
          onProgress(current, total) {
            if (current > 0 && total > 0) {
              statusProgress.value = current;
              statusProgress.max = total;
            } else {
              statusProgress.removeAttribute("value");
              statusProgress.removeAttribute("max");
            }
          },
        });

        if (!cancelled) {
          setStatusMode("hidden");
        }
      } catch (err) {
        if (!cancelled) {
          displayFailureNotice(err);
        }
      }
    };

    void start();

    return () => {
      cancelled = true;
    };
  }, [mounted]);

  if (!mounted) {
    return <div className="godot-shell bg-black" />;
  }

  return (
    <div className="godot-shell">
      <canvas id="canvas" ref={canvasRef} tabIndex={0}>
        Your browser does not support the canvas tag.
      </canvas>

      <div id="status" ref={statusRef}>
        <img
          id="status-splash"
          className="show-image--true fullsize--true use-filter--true"
          src={`${GODOT_BASE}/index.png`}
          alt=""
        />
        <progress id="status-progress" ref={progressRef} />
        <div id="status-notice" ref={noticeRef} />
      </div>
    </div>
  );
}
