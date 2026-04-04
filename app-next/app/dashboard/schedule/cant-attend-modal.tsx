'use client'

import { useState, useTransition } from 'react'
import { createCoverageRequest } from '../coverage/actions'

interface CantAttendModalProps {
  eventId: string
  userProfileId: string
  userRole: string
  onClose: () => void
}

export default function CantAttendModal({ eventId, userProfileId, userRole, onClose }: CantAttendModalProps) {
  const isCoach = userRole === 'coach'
  const [error, setError] = useState<string | null>(null)
  const [isPending, startTransition] = useTransition()

  function handleSubmit() {
    setError(null)
    startTransition(async () => {
      try {
        await createCoverageRequest(eventId, userProfileId)
        onClose()
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Something went wrong')
      }
    })
  }

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 px-4"
      onClick={e => { if (e.target === e.currentTarget) onClose() }}
    >
      <div className="bg-dark-secondary rounded-2xl p-8 w-full max-w-md border border-white/10 shadow-2xl">
        <h2 className="text-xl font-bold mb-4">Can&apos;t Attend</h2>
        <p className="text-gray text-sm mb-6">
          A coverage request will be sent to all other coaches in your club. If no one accepts, the DOC will be notified.
        </p>

        {error && <p className="text-red text-sm mb-4">{error}</p>}

        <div className="flex gap-3">
          <button
            onClick={onClose}
            className="flex-1 bg-dark border border-white/10 text-gray font-medium py-3 rounded-xl hover:text-white transition-colors"
          >
            Cancel
          </button>
          <button
            onClick={handleSubmit}
            disabled={isPending}
            className="flex-1 bg-green text-dark font-bold py-3 rounded-xl hover:opacity-90 transition-opacity disabled:opacity-60 disabled:cursor-not-allowed"
          >
            {isPending ? 'Sending…' : 'Send Request'}
          </button>
        </div>
      </div>
    </div>
  )
}
