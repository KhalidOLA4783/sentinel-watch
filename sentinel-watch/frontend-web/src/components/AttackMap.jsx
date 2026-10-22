import React, { useEffect, useRef } from 'react';
import { Globe } from 'lucide-react';

export default function AttackMap({ vectors = [], target = { name: "HQ DataCenter Paris", lat: 48.8566, lon: 2.3522 } }) {
  const canvasRef = useRef(null);

  // Projection Mercator approximative Canvas
  const project = (lat, lon, width, height) => {
    const x = ((lon + 180) / 360) * width;
    const latRad = (lat * Math.PI) / 180;
    const mercN = Math.log(Math.tan(Math.PI / 4 + latRad / 2));
    const y = height / 2 - (width * mercN) / (2 * Math.PI);
    return { x, y: Math.max(10, Math.min(height - 10, y)) };
  };

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    const width = canvas.width;
    const height = canvas.height;

    // Reset et fond carte sombre SOC
    ctx.clearRect(0, 0, width, height);
    ctx.fillStyle = '#090d16';
    ctx.fillRect(0, 0, width, height);

    // Grille de coordonnées stylisée
    ctx.strokeStyle = '#1e293b';
    ctx.lineWidth = 0.5;
    for (let x = 0; x < width; x += 40) {
      ctx.beginPath();
      ctx.moveTo(x, 0);
      ctx.lineTo(x, height);
      ctx.stroke();
    }
    for (let y = 0; y < height; y += 30) {
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(width, y);
      ctx.stroke();
    }

    const targetPos = project(target.lat || 48.85, target.lon || 2.35, width, height);

    // Dessin des vecteurs d'attaque (arcs de tir)
    vectors.forEach((v) => {
      if (!v.source_lat || !v.source_lon) return;
      const srcPos = project(v.source_lat, v.source_lon, width, height);
      const isCritical = v.is_flagged;

      ctx.beginPath();
      ctx.moveTo(srcPos.x, srcPos.y);

      // Courbure de l'arc balistique
      const midX = (srcPos.x + targetPos.x) / 2;
      const midY = (srcPos.y + targetPos.y) / 2 - 35;
      ctx.quadraticCurveTo(midX, midY, targetPos.x, targetPos.y);

      ctx.strokeStyle = isCritical ? 'rgba(239, 68, 68, 0.75)' : 'rgba(56, 189, 248, 0.45)';
      ctx.lineWidth = isCritical ? 2 : 1;
      ctx.stroke();

      // Point source
      ctx.beginPath();
      ctx.arc(srcPos.x, srcPos.y, isCritical ? 4 : 2.5, 0, Math.PI * 2);
      ctx.fillStyle = isCritical ? '#ef4444' : '#38bdf8';
      ctx.fill();
    });

    // Cible (Notre DataCenter) avec halo radar
    ctx.beginPath();
    ctx.arc(targetPos.x, targetPos.y, 7, 0, Math.PI * 2);
    ctx.fillStyle = '#10b981';
    ctx.fill();
    ctx.strokeStyle = 'rgba(16, 185, 129, 0.4)';
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.arc(targetPos.x, targetPos.y, 14, 0, Math.PI * 2);
    ctx.stroke();

  }, [vectors, target]);

  return (
    <div className="bg-[#0f172a] rounded-xl border border-slate-800 p-4 shadow-xl">
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-2">
          <Globe className="w-5 h-5 text-sky-400" />
          <h2 className="text-lg font-semibold text-white tracking-wide">
            Carte Mondiale des Vecteurs d'Attaque (GeoIP Live)
          </h2>
        </div>
        <span className="text-xs px-2.5 py-1 rounded-full bg-red-950 text-red-400 border border-red-800 animate-pulse">
          Liaison SOC Active
        </span>
      </div>
      <div className="relative overflow-hidden rounded-lg border border-slate-800 bg-[#090d16]">
        <canvas 
          ref={canvasRef} 
          width={800} 
          height={320} 
          className="w-full h-auto block"
        />
        <div className="absolute bottom-2 left-3 text-[11px] text-slate-400 flex gap-4 bg-slate-900/80 px-2 py-1 rounded backdrop-blur">
          <span className="flex items-center gap-1.5"><span className="w-2.5 h-2.5 rounded-full bg-emerald-500 inline-block"></span> Cible : {target.name}</span>
          <span className="flex items-center gap-1.5"><span className="w-2.5 h-2.5 rounded-full bg-red-500 inline-block"></span> Attaque Critique</span>
          <span className="flex items-center gap-1.5"><span className="w-2.5 h-2.5 rounded-full bg-sky-400 inline-block"></span> Trafic Standard</span>
        </div>
      </div>
    </div>
  );
}
