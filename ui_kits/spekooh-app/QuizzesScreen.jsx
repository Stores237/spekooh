function QuizzesScreen() {
  const { StatRow, Avatar, SearchInput } = window.KawloSpekoohDesignSystem_10ffa8;
  const [detail,setDetail] = React.useState(false);
  const [filter,setFilter] = React.useState('All');
  const [q,setQ] = React.useState('');
  const Ic = window.Ic;
  const subjects = [
    ['leaf','Biology quiz','18 topics','green'],
    ['flask-conical','Chemistry quizzes','22 topics','purple'],
    ['globe','Geography quizzes','2 topics','amber'],
    ['cpu','Computer science','1 topics','blue']
  ];
  if (detail) {
    return (
      <div style={{flex:1,overflowY:'auto',padding:'0 18px 90px'}}>
        <div style={{display:'flex',alignItems:'center',gap:10,marginTop:10}}>
          <button onClick={()=>setDetail(false)} style={{background:'none',border:'none',cursor:'pointer'}}><Ic name="chevron-left"/></button>
        </div>
        <div style={{display:'flex',flexDirection:'column',alignItems:'center',marginTop:10,gap:10}}>
          <div style={{width:64,height:64,borderRadius:16,background:'var(--gold-50)',display:'flex',alignItems:'center',justifyContent:'center',color:'var(--gold-700)',fontWeight:800,fontSize:26}}>Σ</div>
          <div style={{fontWeight:800,fontSize:19,color:'var(--text-primary)'}}>Enzyme Quiz 2</div>
          <div style={{fontSize:13,color:'var(--text-secondary)',textAlign:'center'}}>Practice questions drawn from Biology past papers, checked against the instructor-authored marking guide.</div>
        </div>
        <div style={{marginTop:16}}><StatRow stats={[{value:15,label:'questions'},{value:'8 min',label:'suggested'},{value:5564,label:'played'}]}/></div>
        <div style={{marginTop:16,background:'#fff',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:'2px 16px'}}>
          {[['clock','Timer 8:00',true],['lightbulb','Hints  2 available',true],['refresh-cw','Shuffle questions',false]].map(([icon,label,on],i)=>(
            <div key={label} style={{display:'flex',alignItems:'center',gap:12,padding:'12px 0',borderTop:i>0?'1px solid var(--border-subtle)':'none'}}>
              <Ic name={icon}/><div style={{flex:1,fontSize:14,color:'var(--text-primary)'}}>{label}</div>
              <div style={{width:40,height:24,borderRadius:999,background:on?'var(--green-500)':'var(--border-subtle)',position:'relative'}}><div style={{position:'absolute',top:2,left:on?18:2,width:20,height:20,borderRadius:'50%',background:'#fff'}}/></div>
            </div>
          ))}
        </div>
        <button style={{width:'100%',marginTop:18,background:'var(--gradient-primary)',color:'#fff',fontWeight:700,border:'none',borderRadius:999,padding:'15px',fontSize:15,boxShadow:'var(--shadow-button)'}}>Start quiz</button>
      </div>
    );
  }
  return (
    <div style={{flex:1,overflowY:'auto',padding:'0 18px 90px'}}>
      <div style={{fontWeight:800,fontSize:20,marginTop:10,color:'var(--text-primary)'}}>Quiz</div>
      <div style={{marginTop:14,background:'var(--ink-900)',borderRadius:'var(--radius-lg)',padding:16,color:'#fff'}} onClick={()=>setDetail(true)}>
        <div style={{display:'flex',justifyContent:'space-between',fontSize:12,color:'var(--text-on-dark-muted)'}}><span>DAILY CHALLENGE</span><span>Resets in 7h 23m</span></div>
        <div style={{fontWeight:800,fontSize:17,marginTop:6}}>Group VII the Halogens Quiz</div>
        <div style={{fontSize:12,color:'var(--text-on-dark-muted)',marginTop:2}}>15 questions · 1308 students played</div>
        <button style={{marginTop:12,width:'100%',background:'var(--gold-500)',color:'var(--ink-900)',fontWeight:800,border:'none',borderRadius:999,padding:'13px',fontSize:14,cursor:'pointer'}}>Play daily challenge</button>
      </div>
      <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10,marginTop:14}}>
        {[['clock','Timed practice','Exam conditions'],['refresh-cw','Revision mode','No timer, hints on']].map(([icon,t,s])=>(
          <div key={t} style={{background:'#fff',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:14}}>
            <Ic name={icon}/>
            <div style={{fontWeight:700,fontSize:13,marginTop:8,color:'var(--text-primary)'}}>{t}</div>
            <div style={{fontSize:11,color:'var(--text-secondary)',marginTop:2}}>{s}</div>
          </div>
        ))}
      </div>
      <div style={{marginTop:14,background:'#fff',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:'2px 16px'}}>
        <div onClick={()=>setDetail(true)} style={{display:'flex',alignItems:'center',gap:12,padding:'14px 0',cursor:'pointer'}}><Ic name="zap"/><div style={{flex:1}}><div style={{fontWeight:700,fontSize:14,color:'var(--text-primary)'}}>Past-paper practice</div><div style={{fontSize:12,color:'var(--text-secondary)'}}>Generated from submitted papers · every sector & level</div></div><Ic name="chevron-right"/></div>
        <div style={{borderTop:'1px solid var(--border-subtle)'}}/>
        <div style={{display:'flex',alignItems:'center',gap:12,padding:'14px 0'}}><Ic name="trophy"/><div style={{flex:1}}><div style={{fontWeight:700,fontSize:14,color:'var(--text-primary)'}}>Friday Arena</div><div style={{fontSize:12,color:'var(--text-secondary)'}}>Live elimination quiz · everyone plays for prizes</div></div><Ic name="chevron-right"/></div>
      </div>
      <div style={{marginTop:14,background:'var(--ink-900)',borderRadius:'var(--radius-lg)',padding:16}}>
        <div style={{fontWeight:700,color:'#fff',fontSize:14,marginBottom:14}}>Top players <span style={{float:'right',fontSize:12,color:'var(--text-on-dark-muted)',fontWeight:600}}>See all</span></div>
        <div style={{display:'flex',justifyContent:'space-around'}}>
          {[['Julliete',2],['Jojo B.',1],['Billionaire K.',3]].map(([n,r])=>(
            <div key={n} style={{textAlign:'center'}}><Avatar name={n} rank={r}/><div style={{color:'#fff',fontSize:11,fontWeight:700,marginTop:6}}>{n}</div><div style={{color:'var(--text-on-dark-muted)',fontSize:10}}>{r===1?'39 QUIZZES':r===2?'35 QUIZZES':'14 QUIZZES'}</div></div>
          ))}
        </div>
      </div>
      <div style={{fontWeight:800,fontSize:17,marginTop:22,color:'var(--text-primary)'}}>By subject</div>
      <div style={{marginTop:10}}><SearchInput placeholder="Search subjects..." value={q} onChange={setQ}/></div>
      <div style={{display:'flex',gap:8,marginTop:10,overflowX:'auto'}}>
        {['All','Sciences','Arts','Commercial'].map(t=>(
          <span key={t} onClick={()=>setFilter(t)} style={{flexShrink:0,padding:'7px 14px',borderRadius:999,fontSize:12,fontWeight:700,cursor:'pointer',background:filter===t?'var(--ink-900)':'#fff',color:filter===t?'#fff':'var(--text-secondary)',boxShadow:filter===t?'none':'var(--shadow-card)'}}>{t}</span>
        ))}
      </div>
      <div style={{marginTop:12,display:'flex',flexDirection:'column',gap:10}}>
        {subjects.filter(s=>s[1].toLowerCase().includes(q.toLowerCase())).map(([icon,title,sub,tint])=>(
          <div key={title} onClick={()=>setDetail(true)} style={{background:'#fff',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:14,display:'flex',alignItems:'center',gap:12,cursor:'pointer'}}>
            <div style={{width:44,height:44,borderRadius:'var(--radius-chip)',background:`var(--${tint}-100)`,display:'flex',alignItems:'center',justifyContent:'center'}}><Ic name={icon} style={{color:`var(--${tint}-600)`}}/></div>
            <div style={{flex:1}}><div style={{fontWeight:700,fontSize:14,color:'var(--text-primary)'}}>{title}</div><div style={{fontSize:12,color:'var(--text-secondary)'}}>{sub}</div></div>
            <Ic name="chevron-right"/>
          </div>
        ))}
      </div>
    </div>
  );
}
window.QuizzesScreen = QuizzesScreen;
