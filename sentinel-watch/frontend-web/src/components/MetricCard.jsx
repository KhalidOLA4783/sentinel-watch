import React from 'react';

export default function MetricCard({ title, value, subtitle, icon: Icon, colorClass, borderClass, isPulsing }) {
  return (
    <div class={`bg-[#0f172a] border ${borderClass || 'border-slate-800'} rounded-xl p-5 shadow-lg relative overflow-hidden ${isPulsing ? 'pulse-danger' : ''}`}>
      <div class="flex items-center justify-between">
        <span class="text-xs font-semibold uppercase tracking-wider text-slate-400">{title}</span>
        {Icon && (
          <div class={`w-8 h-8 rounded-lg flex items-center justify-center ${colorClass || 'bg-blue-500/10 text-blue-400'}`}>
            <Icon size={18} />
          </div>
        )}
      </div>
      <div class="mt-3 flex items-baseline space-x-2">
        <span class="text-3xl font-extrabold text-white font-mono">{value}</span>
      </div>
      {subtitle && (
        <div class="mt-2 text-xs text-slate-400 flex items-center space-x-1">
          {subtitle}
        </div>
      )}
    </div>
  );
}
