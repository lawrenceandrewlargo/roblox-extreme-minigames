import { syncMinigames } from "@/lib/data";
import { Card, Badge, CATEGORY_COLORS } from "@/components/ui";

export const dynamic = "force-dynamic";

export default async function MinigamesPage({ searchParams }: { searchParams: Promise<{ category?: string }> }) {
  const { category } = await searchParams;
  const all = await syncMinigames();
  const games = category ? all.filter((g) => g.category === category || g.secondaryCategory === category) : all;
  const cats = [...new Set(all.flatMap((g) => [g.category, g.secondaryCategory].filter(Boolean) as string[]))].sort();
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-black">Minigame library</h1>
        <p className="text-slate-400">{all.length} minigames parsed from <code>roblox/src/shared/MinigameCatalog.luau</code>. Each has its own server module in <code>roblox/src/server/Minigames/</code>.</p>
      </div>
      <div className="flex flex-wrap gap-2 text-xs">
        <a href="/minigames" className={`rounded-full px-3 py-1 ${!category ? "bg-white text-black" : "bg-white/10"}`}>All</a>
        {cats.map((c) => <a key={c} href={`/minigames?category=${c}`} className={`rounded-full px-3 py-1 ${category === c ? "bg-white text-black" : "bg-white/10"}`}>{c}</a>)}
      </div>
      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        {games.map((g) => (
          <Card key={g.id}>
            <div className="flex items-start justify-between gap-2">
              <div>
                <div className="flex items-center gap-2"><span className={`h-2.5 w-2.5 rounded-full ${CATEGORY_COLORS[g.category] ?? "bg-slate-400"}`} /><h2 className="font-bold">{g.displayName}</h2></div>
                <div className="text-xs text-slate-500">{g.id}</div>
              </div>
              <div className="flex flex-col items-end gap-1"><Badge>{g.category}</Badge>{g.secondaryCategory && <Badge tone="info">{g.secondaryCategory}</Badge>}</div>
            </div>
            <p className="mt-2 text-sm text-slate-300">{g.description}</p>
            <dl className="mt-3 grid grid-cols-3 gap-2 text-xs text-slate-400">
              <div><dt className="uppercase tracking-wider">Players</dt><dd className="text-slate-200">{g.minPlayers}–{g.maxPlayers}</dd></div>
              <div><dt className="uppercase tracking-wider">Duration</dt><dd className="text-slate-200">{g.duration}s</dd></div>
              <div><dt className="uppercase tracking-wider">Cooldown</dt><dd className="text-slate-200">{g.cooldownRounds} rounds</dd></div>
            </dl>
            <div className="mt-3 flex flex-wrap gap-1 text-[11px]">
              {g.maps.map((m) => <span key={m} className="rounded bg-white/5 px-1.5 py-0.5 text-slate-300">🗺 {m}</span>)}
              {g.supportsTeams && <span className="rounded bg-emerald-500/10 px-1.5 py-0.5 text-emerald-300">teams</span>}
              {g.hidesInformation && <span className="rounded bg-violet-500/10 px-1.5 py-0.5 text-violet-300">spectator-restricted</span>}
              {Object.entries(g.movement).filter(([, v]) => v === true).map(([k]) => <span key={k} className="rounded bg-sky-500/10 px-1.5 py-0.5 text-sky-300">{k.toLowerCase()}</span>)}
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
}
