import { syncMinigames } from "@/lib/data";
export const dynamic = "force-dynamic";
export async function GET() {
  const games = await syncMinigames();
  return Response.json({ ok: true, count: games.length, games });
}
