'use client'

import { useState } from 'react'

export default function CopyLink({ url }: { url: string }) {
  const [copied, setCopied] = useState(false)

  async function handleCopy() {
    await navigator.clipboard.writeText(url)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  return (
    <div className="flex items-center gap-3 bg-dark rounded-xl px-4 py-3 border border-white/5">
      <span className="text-gray text-sm truncate flex-1 font-mono">{url}</span>
      <button
        onClick={handleCopy}
        className="shrink-0 text-xs font-bold text-green hover:opacity-80 transition-opacity"
      >
        {copied ? 'Copied!' : 'Copy'}
      </button>
    </div>
  )
}
