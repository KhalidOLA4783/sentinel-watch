import React, { useState, useEffect } from 'react';
import { 
  Shield, Server, AlertTriangle, Lock, Ban, 
  BookOpen, ListCheck, ShieldAlert, Unlock, Activity 
} from 'lucide-react';
import MetricCard from './components/MetricCard';
import AlertItem from './components/AlertItem';
import LogsTable from './components/LogsTable';

const API_BASE = '/api/v1';

export default function App() {
  const [stats, setStats] = useState({ total_logs: 0, total_failed_logins: 0, unique_ips: 0, flagged_logs: 0, recent_activity_count: 0 });
  const [alerts, setAlerts] = useState([]);
  const [logs, setLogs] = useState([]);
  const [blacklist, setBlacklist] = useState([]);
  const [lastSync, setLastSync] = useState(new Date().toLocaleTimeString());

  const fetchData = async () => {
    try {
      setLastSync(new Date().toLocaleTimeString());
      const [resStats, resAlerts, resLogs, resBlacklist] = await Promise.all([
        fetch(`${API_BASE}/logs/stats`),
        fetch(`${API_BASE}/alerts?limit=30`),
        fetch(`${API_BASE}/logs?limit=20`),
        fetch(`${API_BASE}/blacklist`)
      ]);

      if (resStats.ok) setStats(await resStats.json());
      if (resAlerts.ok) setAlerts(await resAlerts.json());
      if (resLogs.ok) setLogs(await resLogs.json());
      if (resBlacklist.ok) setBlacklist(await resBlacklist.json());
    } catch (err) {
      console.error("Erreur de synchronisation API:", err);
    }
  };

  useEffect(() => {
    fetchData();
    const interval = setInterval(fetchData, 2500);
    return () => clearInterval(interval);
  }, []);

  const handleBanIp = async (alertId) => {
    if (!window.confirm(`Bannir l'IP source de l'alerte #${alertId} ?`)) return;
    try {
      const res = await fetch(`${API_BASE}/alerts/${alertId}/ban`, { method: 'POST' });
      if (res.ok) fetchData();
    } catch (e) {
      console.error(e);
    }
  };

  const handleResolveAlert = async (alertId) => {
    try {
      const res = await fetch(`${API_BASE}/alerts/${alertId}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: 'RESOLVED' })
      });
      if (res.ok) fetchData();
    } catch (e) {
      console.error(e);
    }
  };

  const handleUnbanIp = async (ipAddress) => {
    if (!window.confirm(`Débloquer l'IP ${ipAddress} ?`)) return;
    try {
      const res = await fetch(`${API_BASE}/blacklist/${ipAddress}`, { method: 'DELETE' });
      if (res.ok) fetchData();
    } catch (e) {
      console.error(e);
    }
  };

  const pendingAlerts = alerts.filter(a => a.status === 'PENDING');
  const criticalCount = pendingAlerts.filter(a => a.severity === 'CRITICAL').length;

  return (
    <div class="min-h-screen bg-[#090d16] text-slate-100 font-sans pb-12">
      
      {/* HEADER */}
      <header class="border-b border-slate-800 bg-[#0f172a]/90 backdrop-blur sticky top-0 z-50 px-6 py-3.5 flex items-center justify-between shadow-md">
        <div class="flex items-center space-x-3.5">
          <div class="w-10 h-10 rounded-xl bg-gradient-to-tr from-cyan-600 to-blue-600 flex items-center justify-center shadow-lg shadow-cyan-500/20">
            <Shield class="text-white" size={22} />
          </div>
          <div>
            <div class="flex items-center space-x-2">
              <h1 class="text-lg font-bold tracking-wide text-white">Sentinel<span class="text-cyan-400">Watch</span></h1>
              <span class="text-[10px] font-bold px-2 py-0.5 rounded bg-cyan-950 text-cyan-400 border border-cyan-800">SOC PRO</span>
            </div>
            <p class="text-xs text-slate-400">Tour de contrôle de sécurité & Détection d'intrusions IA</p>
          </div>
        </div>

        <div class="flex items-center space-x-5">
          <div class="flex items-center space-x-2 bg-slate-900 border border-slate-800 rounded-full px-3.5 py-1 text-xs">
            <span class="w-2.5 h-2.5 rounded-full bg-emerald-400 animate-ping"></span>
            <span class="text-slate-300 font-medium">Monitoring Actif</span>
            <span class="text-slate-600">|</span>
            <span class="text-cyan-400 font-mono text-[11px]">{lastSync}</span>
          </div>
          <a href="http://localhost:8000/docs" target="_blank" rel="noreferrer" class="text-xs text-slate-400 hover:text-cyan-400 flex items-center space-x-1.5 transition">
            <BookOpen size={14} />
            <span>Swagger API</span>
          </a>
        </div>
      </header>

      {/* MAIN CONTAINER */}
      <main class="p-6 max-w-[1700px] mx-auto space-y-6">

        {/* TOP METRIC CARDS */}
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
          <MetricCard
            title="Logs Ingestion"
            value={stats.total_logs}
            subtitle={<span><Activity size={12} class="inline mr-1 text-cyan-400" />{stats.recent_activity_count} requêtes récentes</span>}
            icon={Server}
            colorClass="bg-blue-500/10 text-blue-400"
          />

          <MetricCard
            title="Alertes Sécurité"
            value={pendingAlerts.length}
            subtitle={
              <span class={`text-[11px] font-bold px-1.5 py-0.5 rounded border ${criticalCount > 0 ? 'bg-red-950 text-red-300 border-red-800' : 'bg-slate-800 text-slate-400 border-slate-700'}`}>
                {criticalCount} CRITICAL
              </span>
            }
            icon={AlertTriangle}
            colorClass="bg-red-500/10 text-red-400"
            borderClass={criticalCount > 0 ? 'border-red-900/60' : 'border-slate-800'}
            isPulsing={criticalCount > 0}
          />

          <MetricCard
            title="Échecs Auth (401)"
            value={stats.total_failed_logins}
            subtitle={<span>{stats.total_logs > 0 ? ((stats.total_failed_logins / stats.total_logs) * 100).toFixed(1) : 0}% du trafic global</span>}
            icon={Lock}
            colorClass="bg-amber-500/10 text-amber-400"
          />

          <MetricCard
            title="Adresses IP Bannies"
            value={blacklist.length}
            subtitle={<span>Filtrage actif immédiat</span>}
            icon={Ban}
            colorClass="bg-purple-500/10 text-purple-400"
          />
        </div>

        {/* 2-COLUMN SPLIT */}
        <div class="grid grid-cols-1 xl:grid-cols-3 gap-6">

          {/* LEFT COLUMN (2 COLS) : LOGS TABLE */}
          <div class="xl:col-span-2 space-y-6">
            <div class="bg-[#0f172a] border border-slate-800 rounded-xl shadow-lg overflow-hidden">
              <div class="p-4 border-b border-slate-800 flex items-center justify-between">
                <div class="flex items-center space-x-2">
                  <ListCheck class="text-cyan-400" size={18} />
                  <h2 class="text-sm font-semibold uppercase tracking-wider text-slate-200">Journal d'Accès Récent</h2>
                  <span class="text-xs font-mono bg-slate-800 text-slate-300 px-2 py-0.5 rounded">{logs.length} affichés</span>
                </div>
                <div class="text-xs text-slate-500 flex items-center space-x-1.5">
                  <span class="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
                  <span>Auto-refresh: 2.5s</span>
                </div>
              </div>

              <LogsTable logs={logs} />
            </div>
          </div>

          {/* RIGHT COLUMN (1 COL) : INCIDENTS & BLACKLIST */}
          <div class="space-y-6">
            
            {/* INCIDENTS PANEL */}
            <div class="bg-[#0f172a] border border-slate-800 rounded-xl shadow-lg p-5">
              <div class="flex items-center justify-between pb-3 border-b border-slate-800 mb-4">
                <div class="flex items-center space-x-2">
                  <ShieldAlert class="text-red-400" size={18} />
                  <h2 class="text-sm font-bold uppercase tracking-wider text-white">Alertes Qualifiées</h2>
                </div>
                <span class="text-xs px-2.5 py-0.5 rounded-full bg-red-950 text-red-300 border border-red-800 font-bold font-mono">
                  {pendingAlerts.length}
                </span>
              </div>

              <div class="space-y-3.5 max-h-[520px] overflow-y-auto pr-1">
                {pendingAlerts.length === 0 ? (
                  <div class="text-center py-12 text-slate-500 text-xs">
                    <Shield class="text-slate-600 mx-auto mb-2" size={28} />
                    Aucun incident en attente d'intervention.
                  </div>
                ) : (
                  pendingAlerts.map(alert => (
                    <AlertItem 
                      key={alert.id} 
                      alert={alert} 
                      onBan={handleBanIp} 
                      onResolve={handleResolveAlert} 
                    />
                  ))
                )}
              </div>
            </div>

            {/* BLACKLIST PANEL */}
            <div class="bg-[#0f172a] border border-slate-800 rounded-xl shadow-lg p-5">
              <div class="flex items-center justify-between pb-3 border-b border-slate-800 mb-3">
                <div class="flex items-center space-x-2">
                  <Ban class="text-purple-400" size={16} />
                  <h2 class="text-sm font-semibold uppercase tracking-wider text-slate-200">Liste Noire d'IPs</h2>
                </div>
                <span class="text-xs font-mono text-slate-400">{blacklist.length} bannies</span>
              </div>

              <div class="space-y-2 max-h-[220px] overflow-y-auto text-xs">
                {blacklist.length === 0 ? (
                  <div class="text-slate-500 py-3 text-center">Aucune IP bannie pour l'instant.</div>
                ) : (
                  blacklist.map(item => (
                    <div key={item.id} class="bg-slate-900 border border-slate-800 rounded p-2 flex items-center justify-between font-mono">
                      <div>
                        <span class="text-red-400 font-bold">{item.ip_address}</span>
                        <p class="text-[10px] text-slate-400 font-sans truncate max-w-[200px]">{item.reason}</p>
                      </div>
                      <button 
                        onClick={() => handleUnbanIp(item.ip_address)} 
                        class="text-xs text-slate-400 hover:text-emerald-400 p-1.5 rounded bg-slate-800 hover:bg-slate-700 transition" 
                        title="Débloquer l'IP"
                      >
                        <Unlock size={12} />
                      </button>
                    </div>
                  ))
                )}
              </div>
            </div>

          </div>

        </div>

      </main>

    </div>
  );
}
