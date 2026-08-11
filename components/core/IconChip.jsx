import React from 'react';
export function IconChip({icon,tint='blue',size=44}) {
  const tints={blue:{bg:'var(--blue-100)',fg:'var(--blue-600)'},amber:{bg:'var(--amber-100)',fg:'var(--amber-600)'},green:{bg:'var(--green-100)',fg:'var(--green-600)'},purple:{bg:'var(--purple-100)',fg:'var(--purple-500)'},red:{bg:'var(--red-100)',fg:'var(--red-500)'}};
  const t=tints[tint]||tints.blue;
  return React.createElement('div',{style:{width:size,height:size,borderRadius:'var(--radius-chip)',background:t.bg,color:t.fg,display:'flex',alignItems:'center',justifyContent:'center',flexShrink:0}},icon);
}
