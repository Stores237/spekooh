import React from 'react';
export function SubjectCard({icon,title,subtitle,badgeText,code,onClick}) {
  return React.createElement('button',{onClick,style:{textAlign:'left',background:'#fff',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',border:'none',cursor:'pointer',padding:16,display:'flex',flexDirection:'column',gap:8,fontFamily:'var(--font-sans)',position:'relative',width:'100%'}},
    code&&React.createElement('span',{style:{position:'absolute',top:12,right:14,fontSize:11,color:'var(--text-tertiary)'}},code),
    icon,
    React.createElement('div',{style:{fontWeight:700,fontSize:15,color:'var(--text-primary)'}},title),
    subtitle&&React.createElement('div',{style:{fontSize:12,color:'var(--text-secondary)'}},subtitle),
    badgeText&&React.createElement('span',{style:{fontSize:11,fontWeight:700,color:'var(--green-600)',textTransform:'uppercase'}},badgeText)
  );
}
