import React from 'react';
export function Toggle({checked,onChange,disabled}) {
  return React.createElement('button',{onClick:()=>!disabled&&onChange(!checked),style:{width:44,height:26,borderRadius:'var(--radius-pill)',border:'none',cursor:disabled?'default':'pointer',background:checked?'var(--green-500)':'#DADEE8',position:'relative',transition:'background .15s ease',opacity:disabled?0.5:1,padding:0}},
    React.createElement('span',{style:{position:'absolute',top:3,left:checked?21:3,width:20,height:20,borderRadius:'50%',background:'#fff',boxShadow:'0 1px 3px rgba(0,0,0,0.2)',transition:'left .15s ease'}})
  );
}
