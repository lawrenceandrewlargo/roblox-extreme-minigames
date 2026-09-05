import { readDoc } from "@/lib/data";
export const dynamic = "force-dynamic";
export async function GET(_req: Request, ctx: { params: Promise<{ slug: string }> }) {
  const { slug } = await ctx.params;
  const md = readDoc(slug);
  if (!md) return Response.json({ ok: false, error: "not_found" }, { status: 404 });
  return new Response(md, { headers: { "content-type": "text/markdown; charset=utf-8" } });
}
