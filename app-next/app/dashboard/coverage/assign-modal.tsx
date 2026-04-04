'use client'

import { useState, useTransition } from 'react'
import { assignCoverage } from './actions'

interface Coach {
  id: string
  display_name: string | null
}

interface AssignModalProps {
  requestId: string
  coaches: Coach[]
  onClose: () => void
}

export default function AssignModal({ requestId, coaches, onClose }: AssignModalProps) {
  const [selectedCoach, setSelectedCoach] = useState(coaches[0]?.id ?? '')
  const [error, setError] = useState<string | null>(null)
  const [isPending, startTransition] = useTransition()

  function handleAssign() {
    if (!selectedCoach) {
      setError('Select a coach')
      return
    }
    setError(null)
    startTransition(async () => {
      try {
        await assignCoverage(requestId, selectedCoach)
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
        <h2 className="text-xl font-bold mb-6">Assign Coverage</h2>

        <label className="block text-sm font-medium text-gray mb-2">Select a coach</label>
        <select
          value={selectedCoach}
          onChange={e => setSelectedCoach(e.target.value)}
          className="w-full bg-dark border border-white/10 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-green transition-colors appearance-none mb-2"
        >
          {coaches.map(c => (
            <option key={c.id} value={c.id}>{c.display_name ?? 'Unknown'}</option>
          ))}
        </select>

        {error && <p className="text-red text-sm mt-2 mb-2">{error}</p>}

        <div className="flex gap-3 mt-6">
          <button
            onClick={onClose}
            className="flex-1 bg-dark border border-white/10 text-gray font-medium py-3 rounded-xl hover:text-white transition-colors"
          >
            Cancel
          </button>
          <button
            onClick={handleAssign}
            disabled={isPending}
            className="flex-1 bg-green text-dark font-bold py-3 rounded-xl hover:opacity-90 transition-opacity disabled:opacity-60 disabled:cursor-not-allowed"
          >
            {isPending ? 'Assigning\u2026' : 'Assign'}
          </button>
        </div>
      </div>
    </div>
  )
}
