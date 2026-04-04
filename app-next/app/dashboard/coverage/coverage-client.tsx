'use client'

import { useState } from 'react'
import RequestCard from './request-card'
import AssignModal from './assign-modal'

interface CoverageClientProps {
  requests: any[]
  responses: any[]
  coaches: Array<{ id: string; display_name: string | null }>
}

export default function CoverageClient({ requests, responses, coaches }: CoverageClientProps) {
  const [assignRequestId, setAssignRequestId] = useState<string | null>(null)

  const escalated = requests.filter(r => r.status === 'escalated')
  const pending = requests.filter(r => r.status === 'pending')
  const resolved = requests.filter(r => r.status === 'accepted' || r.status === 'resolved').slice(0, 10)

  return (
    <>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-3xl font-black tracking-tight">Coverage</h1>
          <p className="text-gray text-sm mt-1">
            {escalated.length + pending.length} active request{escalated.length + pending.length !== 1 ? 's' : ''}
          </p>
        </div>
      </div>

      {escalated.length > 0 && (
        <div className="mb-8">
          <h2 className="text-sm font-bold text-red uppercase tracking-wider mb-3">Escalated — Needs Your Attention</h2>
          <div className="space-y-3">
            {escalated.map(req => (
              <RequestCard key={req.id} request={req} responses={responses} onAssign={setAssignRequestId} />
            ))}
          </div>
        </div>
      )}

      {pending.length > 0 && (
        <div className="mb-8">
          <h2 className="text-sm font-bold text-yellow-500 uppercase tracking-wider mb-3">Active Requests</h2>
          <div className="space-y-3">
            {pending.map(req => (
              <RequestCard key={req.id} request={req} responses={responses} onAssign={setAssignRequestId} />
            ))}
          </div>
        </div>
      )}

      {escalated.length === 0 && pending.length === 0 && (
        <div className="bg-dark-secondary rounded-2xl p-12 text-center border border-white/5 mb-8">
          <p className="text-gray text-lg">No active coverage requests.</p>
          <p className="text-gray text-sm mt-1">When a coach can&apos;t attend an event, it&apos;ll show up here.</p>
        </div>
      )}

      {resolved.length > 0 && (
        <div>
          <h2 className="text-sm font-bold text-gray uppercase tracking-wider mb-3">Recently Resolved</h2>
          <div className="space-y-3">
            {resolved.map(req => (
              <RequestCard key={req.id} request={req} responses={responses} onAssign={setAssignRequestId} />
            ))}
          </div>
        </div>
      )}

      {assignRequestId && (
        <AssignModal requestId={assignRequestId} coaches={coaches} onClose={() => setAssignRequestId(null)} />
      )}
    </>
  )
}
