'use server'

import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { revalidatePath } from 'next/cache'

export async function generateParentInvite(formData: FormData) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/login')

  const teamId = formData.get('teamId') as string

  if (!teamId) throw new Error('Team ID is required')

  const { data: profile, error: profileError } = await supabase
    .from('profiles')
    .select('club_id')
    .eq('user_id', user.id)
    .single()

  if (profileError || !profile?.club_id) {
    throw new Error('Could not find your club')
  }

  // Verify the team belongs to this club
  const { data: team, error: teamError } = await supabase
    .from('teams')
    .select('id')
    .eq('id', teamId)
    .eq('club_id', profile.club_id)
    .single()

  if (teamError || !team) {
    throw new Error('Team not found')
  }

  const { error } = await supabase
    .from('invites')
    .insert({
      club_id: profile.club_id,
      team_id: teamId,
      role: 'parent',
      status: 'pending',
      expires_at: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
    })

  if (error) throw new Error(`Failed to create invite: ${error.message}`)

  revalidatePath(`/dashboard/teams/${teamId}`)
}
