'use client'

import { useTransition } from 'react'
import { generateParentInvite } from './actions'

export default function GenerateInviteButton({ teamId }: { teamId: string }) {
  const [isPending, startTransition] = useTransition()

  function handleClick() {
    const formData = new FormData()
    formData.set('teamId', teamId)
    startTransition(async () => {
      await generateParentInvite(formData)
    })
  }

  return (
    <button
      onClick={handleClick}
      disabled={isPending}
      className="bg-green text-dark font-bold px-5 py-2.5 rounded-xl hover:opacity-90 transition-opacity text-sm disabled:opacity-60 disabled:cursor-not-allowed"
    >
      {isPending ? 'Generating…' : 'Generate Invite Link'}
    </button>
  )
}
