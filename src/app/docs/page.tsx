import Link from "next/link";
import { listDocs } from "@/lib/data";
import { Card } from "@/components/ui";
export const dynamic = "force-dynamic";
export default function DocsPage() {
  const docs = listDocs();
  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-black">Documentation</h1>
      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {docs.map((d) => (
          <Link key={d.slug} href={`/docs/${d.slug}`}><Card className="h-full hover:border-fuchsia-400/50"><div className="font-semibold">{d.title}</div><div className="text-xs text-slate-500">docs/{d.slug}.md</div></Card></Link>
        ))}
      </div>
    </div>
  );
}
