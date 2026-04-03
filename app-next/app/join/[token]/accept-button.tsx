'use client'

import { useTransition } from 'react'
import { acceptInvite } from './actions'

export default function AcceptButton({ token }: { token: string }) {
  const [isPending, startTransition] = useTransition()

  function handleAccept() {
    const formData = new FormData()
    formData.set('token', token)
    startTransition(async () => {
      await acceptInvite(formData)
    })
  }

  return (
    <button
      onClick={handleAccept}
      disabled={isPending}
      className="w-full bg-green text-dark font-bold py-3 px-4 rounded-xl uppercase tracking-wider hover:opacity-90 transition-opacity disabled:opacity-60 disabled:cursor-not-allowed"
    >
      {isPending ? 'Joining…' : 'Accept & Join'}
    </button>
  )
}
