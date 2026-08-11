import React from 'react';
export function Avatar({src,name,rank,size=44}) {
  const initials=(name||'').split(' ').map(w=>w[0]).slice(0,2).join('').toUpperCase();
  return React.createElement('div',{style:{position:'relative',width:size,height:size}},
    React.createElement('div',{style:{width:size,height:size,borderRadius:'50%',background:'var(--blue-400)',color:'#fff',display:'flex',alignItems:'center',justifyContent:'center',fontWeight:700,fontSize:size*0.36,overflow:'hidden',border:rank===1?'2px solid var(--amber-500)':'2px solid #fff'}},
      src?React.createElement('img',{src,alt:name,style:{width:'100%',height:'100%',objectFit:'cover'}}):initials
    ),
    rank===1&&React.createElement('span',{style:{position:'absolute',top:-14,left:'50%',transform:'translateX(-50%)',fontSize:14}},'★')
  );
}
