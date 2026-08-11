import React from 'react';
export function Badge({children,tone='blue'}) {
  const tones={blue:{bg:'var(--blue-100)',fg:'var(--blue-600)'},amber:{bg:'var(--amber-100)',fg:'var(--amber-600)'},green:{bg:'var(--green-100)',fg:'var(--green-600)'},neutral:{bg:'var(--surface-sunken)',fg:'var(--text-secondary)'},dark:{bg:'var(--navy-900)',fg:'#fff'}};
  const t=tones[tone]||tones.blue;
  return React.createElement('span',{style:{background:t.bg,color:t.fg,fontSize:11,fontWeight:700,textTransform:'uppercase',letterSpacing:'0.04em',padding:'4px 10px',borderRadius:'var(--radius-pill)',display:'inline-block'}},children);
}
