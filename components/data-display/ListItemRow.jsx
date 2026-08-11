import React from 'react';
export function ListItemRow({icon,title,subtitle,trailing,onClick}) {
  return React.createElement('button',{onClick,style:{display:'flex',alignItems:'center',gap:12,width:'100%',background:'none',border:'none',padding:'14px 4px',cursor:onClick?'pointer':'default',textAlign:'left',fontFamily:'var(--font-sans)'}},
    icon,
    React.createElement('div',{style:{flex:1,minWidth:0}},
      React.createElement('div',{style:{fontWeight:700,fontSize:15,color:'var(--text-primary)'}},title),
      subtitle&&React.createElement('div',{style:{fontSize:13,color:'var(--text-secondary)',marginTop:2}},subtitle)
    ),
    trailing!==undefined?trailing:React.createElement('span',{style:{color:'var(--text-tertiary)',fontSize:18}},'›')
  );
}
