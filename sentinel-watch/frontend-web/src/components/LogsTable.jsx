import React from 'react';
import { AlertCircle, CheckCircle2 } from 'lucide-react';

export default function LogsTable({ logs }) {
  const formatTime = (iso) => {
    if (!iso) return "";
    return new Date(iso).toLocaleTimeString('fr-FR', {
      hour: '2-digit', minute: '2-digit', second: '2-digit'
    });
  };

  return (
    <div class="overflow-x-auto max-h-[460px] overflow-y-auto">
      <table class="w-full text-left text-xs border-collapse">
        <thead class="bg-slate-900/90 sticky top-0 text-slate-400 border-b border-slate-800">
          <tr>
            <th class="py-2.5 px-3">Heure (UTC)</th>
            <th class="py-2.5 px-3">Utilisateur</th>
            <th class="py-2.5 px-3">IP & Ville</th>
            <th class="py-2.5 px-3">Méthode / Endpoint</th>
            <th class="py-2.5 px-3">Statut</th>
            <th class="py-2.5 px-3">Détection</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-slate-800/80 font-mono">
          {logs.length === 0 ? (
            <tr>
              <td colSpan="6" class="text-center py-8 text-slate-500">
                Aucun journal de connexion pour le moment.
              </td>
            </tr>
          ) : (
            logs.map((log) => {
              let statusBadge = "bg-emerald-950 text-emerald-400 border-emerald-800";
              if (log.http_status >= 400 && log.http_status < 500) statusBadge = "bg-amber-950 text-amber-400 border-amber-800";
              if (log.http_status >= 500) statusBadge = "bg-red-950 text-red-400 border-red-800";

              const cityStr = log.city ? `${log.city} (${log.country_code})` : (log.country_code || '-');

              return (
                <tr key={log.id} class={`${log.is_flagged ? 'bg-red-950/20' : ''} hover:bg-slate-800/40 transition`}>
                  <td class="py-2 px-3 text-slate-400 text-[11px]">{formatTime(log.timestamp)}</td>
                  <td class="py-2 px-3 font-semibold text-slate-200">{log.user_identifier || 'anonymous'}</td>
                  <td class="py-2 px-3 text-slate-300">
                    <span class="text-cyan-400 font-bold">{log.ip_address}</span>
                    <span class="text-slate-500 text-[10px] block">{cityStr}</span>
                  </td>
                  <td class="py-2 px-3">
                    <span class="text-[10px] px-1 py-0.5 rounded bg-slate-800 text-slate-300 font-bold mr-1">{log.http_method}</span>
                    <span class="text-slate-300 text-xs">{log.endpoint}</span>
                  </td>
                  <td class="py-2 px-3">
                    <span class={`px-1.5 py-0.5 rounded text-[10px] font-bold border ${statusBadge}`}>
                      {log.http_status}
                    </span>
                  </td>
                  <td class="py-2 px-3">
                    {log.is_flagged ? (
                      <span class="px-1.5 py-0.5 rounded text-[10px] font-bold bg-red-950 text-red-300 border border-red-800 flex items-center w-fit space-x-1">
                        <AlertCircle size={12} class="mr-1 inline" />
                        <span>{log.flag_reason || 'FLAGGED'}</span>
                      </span>
                    ) : (
                      <span class="text-slate-500 text-[11px] flex items-center space-x-1">
                        <CheckCircle2 size={12} class="text-emerald-500 mr-1 inline" />
                        <span>Normal</span>
                      </span>
                    )}
                  </td>
                </tr>
              );
            })
          )}
        </tbody>
      </table>
    </div>
  );
}
