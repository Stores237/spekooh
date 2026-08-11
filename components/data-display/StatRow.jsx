import React from 'react';
export function StatRow({stats}) {
  return React.createElement('div',{style:{display:'flex',background:'var(--surface-sunken)',borderRadius:'var(--radius-lg)',padding:'14px 0'}},
    stats.map((s,i)=>React.createElement('div',{key:i,style:{flex:1,textAlign:'center',borderLeft:i>0?'1px solid var(--border-subtle)':'none'}},
      s.icon&&React.createElement('div',{style:{marginBottom:4,display:'flex',justifyContent:'center',color:'var(--text-secondary)'}},s.icon),
      React.createElement('div',{style:{fontWeight:800,fontSize:17,color:'var(--text-primary)'}},s.value),
      React.createElement('div',{style:{fontSize:11,color:'var(--text-tertiary)',marginTop:2}},s.label)
    ))
  );
}
