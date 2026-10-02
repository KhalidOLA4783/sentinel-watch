import React from 'react';
import { AlertTriangle, Plane, Key, Radar, Brain, Ban, Check } from 'lucide-react';

export default function AlertItem({ alert, onBan, onResolve }) {
  let sevBorder = "border-red-600 bg-red-950/40 text-red-400";
  let badgeStyle = "bg-red-950 text-red-300 border-red-800";
  if (alert.severity === 'HIGH') {
    sevBorder = "border-amber-600 bg-amber-950/30 text-amber-400";
    badgeStyle = "bg-amber-950 text-amber-300 border-amber-800";
  } else if (alert.severity === 'MEDIUM') {
    sevBorder = "border-yellow-600 bg-yellow-950/20 text-yellow-300";
    badgeStyle = "bg-yellow-950 text-yellow-300 border-yellow-800";
  }

  const renderIcon = () => {
    switch (alert.alert_type) {
      case 'IMPOSSIBLE_TRAVEL': return <Plane size={16} />;
      case 'BRUTE_FORCE': return <Key size={16} />;
      case 'RECON_SCAN': return <Radar size={16} />;
      case 'ML_ANOMALY': return <Brain size={16} />;
      default: return <AlertTriangle size={16} />;
    }
  };

  const timeStr = new Date(alert.timestamp).toLocaleTimeString('fr-FR', {
    hour: '2-digit', minute: '2-digit', second: '2-digit'
  });

  return (
    <div class={`border-l-4 ${sevBorder} p-3.5 rounded-r-lg bg-[#0f172a] border border-slate-800 shadow transition hover:border-slate-700`}>
      <div class="flex items-start justify-between">
        <div class="flex items-center space-x-2">
          {renderIcon()}
          <span class="font-bold text-xs tracking-wide text-white">{alert.alert_type}</span>
        </div>
        <span class={`text-[10px] font-bold px-2 py-0.5 rounded border ${badgeStyle}`}>
          {alert.severity}
        </span>
      </div>

      <p class="text-xs text-slate-200 mt-2 leading-relaxed">{alert.description}</p>

      <div class="mt-2.5 pt-2 border-t border-slate-800/80 flex items-center justify-between text-[11px] font-mono text-slate-400">
        <span>IP: <strong class="text-cyan-400">{alert.source_ip}</strong></span>
        <span>{timeStr}</span>
      </div>

      <div class="mt-3 flex items-center space-x-2">
        <button
          onClick={() => onBan(alert.id)}
          class="flex-1 bg-red-600/90 hover:bg-red-600 text-white font-semibold py-1 px-2.5 rounded text-xs transition flex items-center justify-center space-x-1.5 shadow"
        >
          <Ban size={12} />
          <span>Bannir l'IP</span>
        </button>
        <button
          onClick={() => onResolve(alert.id)}
          class="bg-slate-800 hover:bg-slate-700 text-slate-300 py-1 px-2.5 rounded text-xs transition flex items-center space-x-1.5"
        >
          <Check size={12} />
          <span>Acquitter</span>
        </button>
      </div>
    </div>
  );
}
