import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'

export default async function DashboardPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) redirect('/login')

  return (
    <main className="min-h-screen flex items-center justify-center bg-dark">
      <div className="text-center">
        <h1 className="text-3xl font-black uppercase tracking-tight mb-4">
          Sideline<span className="text-green">OS</span>
        </h1>
        <p className="text-gray text-lg mb-2">Welcome, {user.email}</p>
        <p className="text-gray text-sm">Dashboard coming soon</p>
      </div>
    </main>
  )
}
