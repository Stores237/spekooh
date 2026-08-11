import React from 'react';
export function Banner({tone='green',icon,children,action}) {
  const tones={green:{bg:'var(--green-100)',fg:'var(--green-600)'},blue:{bg:'var(--blue-100)',fg:'var(--blue-600)'}};
  const t=tones[tone]||tones.green;
  return React.createElement('div',{style:{display:'flex',alignItems:'center',gap:10,background:t.bg,color:t.fg,borderRadius:'var(--radius-lg)',padding:'12px 16px',fontSize:13,fontWeight:600}},
    icon,React.createElement('span',{style:{flex:1}},children),action
  );
}
