'use server'

import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { revalidatePath } from 'next/cache'

export async function inviteCoach(formData: FormData) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/login')

  const email = formData.get('email') as string
  const teamId = formData.get('teamId') as string | null

  if (!email?.trim()) {
    throw new Error('Email is required')
  }

  const { data: profile, error: profileError } = await supabase
    .from('profiles')
    .select('club_id')
    .eq('user_id', user.id)
    .single()

  if (profileError || !profile?.club_id) {
    throw new Error('Could not find your club')
  }

  const { error } = await supabase
    .from('invites')
    .insert({
      club_id: profile.club_id,
      team_id: teamId || null,
      email: email.trim(),
      role: 'coach',
      status: 'pending',
      expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
    })

  if (error) throw new Error(`Failed to create invite: ${error.message}`)

  revalidatePath('/dashboard/coaches')
}
