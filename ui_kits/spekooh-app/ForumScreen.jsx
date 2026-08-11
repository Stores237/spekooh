function ForumScreen() {
  const { Badge, Button } = window.KawloSpekoohDesignSystem_10ffa8;
  const Ic = window.Ic;
  const posts = [
    {name:'The Situation',time:'06/06/2026',tag:'Just to Chat',title:'Rescheduling of Baccalauréat 2026',body:'The official press release shared by the Ministry regarding the new exam calendar for both systems…',up:8,ans:180},
    {name:'Chi Emmanuel',time:'2h ago',tag:'Religious Studies',title:'Public Ministry',body:'Give an account of Peter’s confession of Faith as you read Luke 9:18-22 and elaborate more on the story…',up:0,ans:13},
    {name:'Aïcha N.',time:'3h ago',tag:'Philosophie',title:'Dissertation — la liberté',body:'Quelqu’un a-t-il un plan pour ce sujet de dissertation du Probatoire 2024 ?',up:2,ans:21}
  ];
  return (
    <div style={{flex:1,overflowY:'auto',padding:'0 18px 90px',position:'relative'}}>
      <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginTop:10}}>
        <div style={{fontWeight:800,fontSize:20,color:'var(--text-primary)'}}>Forum</div>
        <div style={{display:'flex',gap:10}}><Ic name="search"/><Ic name="bell"/></div>
      </div>
      <div style={{display:'flex',gap:8,marginTop:12,overflowX:'auto'}}>
        {['All','My subjects','Unanswered','Solved'].map((t,i)=>(
          <span key={t} style={{flexShrink:0,padding:'7px 14px',borderRadius:999,fontSize:12,fontWeight:700,background:i===0?'var(--ink-900)':'#fff',color:i===0?'#fff':'var(--text-secondary)',boxShadow:i===0?'none':'var(--shadow-card)'}}>{t}</span>
        ))}
      </div>
      <div style={{marginTop:14,display:'flex',flexDirection:'column',gap:10}}>
        {posts.map((p,i)=>(
          <div key={i} style={{background:'#fff',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:14}}>
            <div style={{display:'flex',justifyContent:'space-between',alignItems:'center'}}>
              <div style={{display:'flex',gap:8,alignItems:'center'}}>
                <div style={{width:28,height:28,borderRadius:'50%',background:'var(--gold-200)'}}/>
                <div><div style={{fontSize:12,fontWeight:700,color:'var(--text-primary)'}}>{p.name}</div><div style={{fontSize:10,color:'var(--text-tertiary)'}}>{p.time}</div></div>
              </div>
              <Badge tone="blue">{p.tag}</Badge>
            </div>
            <div style={{fontWeight:700,fontSize:14,marginTop:8,color:'var(--text-primary)'}}>{p.title}</div>
            <div style={{fontSize:12,color:'var(--text-secondary)',marginTop:2}}>{p.body}</div>
            <div style={{display:'flex',gap:14,marginTop:8,fontSize:12,color:'var(--text-tertiary)',alignItems:'center'}}><span>{'↑'} {p.up}</span><span style={{display:'flex',alignItems:'center',gap:4}}><Ic name="message-circle" size={14}/>{p.ans} answers</span></div>
          </div>
        ))}
      </div>
      <button style={{position:'absolute',bottom:24,right:18,background:'var(--gradient-primary)',color:'#fff',border:'none',borderRadius:999,padding:'13px 22px',fontWeight:700,fontSize:14,boxShadow:'var(--shadow-button)'}}>+ Ask</button>
    </div>
  );
}
window.ForumScreen = ForumScreen;
