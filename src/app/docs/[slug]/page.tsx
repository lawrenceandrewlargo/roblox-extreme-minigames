import { notFound } from "next/navigation";
import { marked } from "marked";
import { readDoc, listDocs } from "@/lib/data";
import Link from "next/link";
export const dynamic = "force-dynamic";

export default async function DocPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const md = readDoc(slug);
  if (!md) notFound();
  const html = await marked.parse(md);
  const docs = listDocs();
  return (
    <div className="grid gap-8 lg:grid-cols-[220px_1fr]">
      <aside className="hidden lg:block">
        <div className="sticky top-20 space-y-1 text-xs">
          {docs.map((d) => <Link key={d.slug} href={`/docs/${d.slug}`} className={`block rounded px-2 py-1 ${d.slug === slug ? "bg-white/10 text-white" : "text-slate-400 hover:text-white"}`}>{d.title}</Link>)}
        </div>
      </aside>
      <article className="prose-doc max-w-none" dangerouslySetInnerHTML={{ __html: html }} />
    </div>
  );
}
