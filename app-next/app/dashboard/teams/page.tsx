import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import AddTeamForm from './add-team-form'

interface Team {
  id: string
  name: string
  age_group: string
  member_count: number
}

export default async function TeamsPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/login')

  const { data: profile } = await supabase
    .from('profiles')
    .select('club_id')
    .eq('user_id', user.id)
    .single()

  const { data: teamsRaw } = await supabase
    .from('teams')
    .select('id, name, age_group')
    .eq('club_id', profile?.club_id ?? '')
    .order('age_group', { ascending: true })

  // Get member counts for each team
  const teams: Team[] = await Promise.all(
    (teamsRaw ?? []).map(async team => {
      const { count } = await supabase
        .from('team_members')
        .select('id', { count: 'exact', head: true })
        .eq('team_id', team.id)
      return { ...team, member_count: count ?? 0 }
    })
  )

  return (
    <div className="p-6 md:p-10 max-w-5xl mx-auto">
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-3xl font-black tracking-tight">Teams</h1>
          <p className="text-gray text-sm mt-1">{teams.length} team{teams.length !== 1 ? 's' : ''} in your club</p>
        </div>
        <AddTeamForm />
      </div>

      {teams.length === 0 ? (
        <div className="bg-dark-secondary rounded-2xl p-12 text-center border border-white/5">
          <p className="text-gray text-lg">No teams yet.</p>
          <p className="text-gray text-sm mt-1">Use the &quot;Add Team&quot; button to create your first team.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {teams.map(team => (
            <TeamCard key={team.id} team={team} />
          ))}
        </div>
      )}
    </div>
  )
}

function TeamCard({ team }: { team: Team }) {
  return (
    <div className="bg-dark-secondary rounded-2xl p-6 border border-white/5 hover:border-green/20 transition-colors">
      <div className="flex items-start justify-between mb-3">
        <h3 className="font-bold text-lg leading-tight">{team.name}</h3>
        <span className="text-xs font-bold bg-green/10 text-green px-2 py-1 rounded-full shrink-0 ml-2">
          {team.age_group}
        </span>
      </div>
      <p className="text-gray text-sm">
        {team.member_count} member{team.member_count !== 1 ? 's' : ''}
      </p>
    </div>
  )
}
