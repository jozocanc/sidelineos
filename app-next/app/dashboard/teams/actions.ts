'use server'

import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { revalidatePath } from 'next/cache'

export async function addTeam(formData: FormData) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/login')

  const teamName = formData.get('teamName') as string
  const ageGroup = formData.get('ageGroup') as string

  if (!teamName?.trim() || !ageGroup) {
    throw new Error('Team name and age group are required')
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
    .from('teams')
    .insert({ name: teamName.trim(), age_group: ageGroup, club_id: profile.club_id })

  if (error) throw new Error(`Failed to create team: ${error.message}`)

  revalidatePath('/dashboard/teams')
}
