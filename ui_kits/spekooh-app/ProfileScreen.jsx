function ProfileScreen({onBack,onOpenSettings}) {
  const { Badge } = window.KawloSpekoohDesignSystem_10ffa8;
  const Ic = window.Ic;
  const items = [
    {title:'Physics — GCE A Level 2025',status:'Live',tone:'green',date:'Published · earned 150 credits'},
    {title:'Further Maths — GCE A Level 2024',status:'Approved',tone:'blue',date:'Marking guide in progress'},
    {title:'Biology — GCE O Level 2025',status:'Under review',tone:'amber',date:'Checking for duplicates'},
    {title:'History — Baccalauréat 2023',status:'Received',tone:'neutral',date:'Just submitted'}
  ];
  const badges = [['flame','Spark',true],['flame','Ember',true],['flame','Inferno',false],['book-open','Scholar I',false]];
  return (
    <div style={{flex:1,overflowY:'auto',padding:'0 18px 90px'}}>
      <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginTop:10}}>
        <div style={{display:'flex',alignItems:'center',gap:10}}>
          <button onClick={onBack} style={{width:36,height:36,borderRadius:'50%',border:'1px solid var(--border-subtle)',background:'#fff'}}><Ic name="chevron-left"/></button>
          <div style={{fontWeight:800,fontSize:19,color:'var(--text-primary)'}}>Profile</div>
        </div>
        <button onClick={onOpenSettings} style={{width:36,height:36,borderRadius:'50%',border:'1px solid var(--border-subtle)',background:'#fff'}}><Ic name="settings" size={16}/></button>
      </div>

      <div style={{marginTop:14,background:'#fff',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:16,display:'flex',alignItems:'center',gap:12}}>
        <div style={{width:52,height:52,borderRadius:'50%',background:'var(--gold-200)',display:'flex',alignItems:'center',justifyContent:'center',fontWeight:800,fontSize:18,color:'var(--gold-700)'}}>G</div>
        <div style={{flex:1}}>
          <div style={{fontWeight:800,fontSize:16,color:'var(--text-primary)'}}>Guest</div>
          <div style={{fontSize:12,color:'var(--text-secondary)'}}>Joined Jul 2026</div>
          <div style={{display:'flex',gap:8,marginTop:6}}><Badge tone="blue">24 submissions</Badge><Badge tone="amber">4 quizzes</Badge></div>
        </div>
      </div>

      <div style={{display:'flex',justifyContent:'space-between',alignItems:'baseline',marginTop:20}}>
        <div style={{fontWeight:800,fontSize:15,color:'var(--text-primary)'}}>Badges</div>
        <span style={{fontSize:12,fontWeight:700,color:'var(--gold-700)'}}>All 15</span>
      </div>
      <div style={{display:'grid',gridTemplateColumns:'repeat(4,1fr)',gap:8,marginTop:10}}>
        {badges.map(([icon,label,earned])=>(
          <div key={label} style={{background:'#fff',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:'12px 6px',display:'flex',flexDirection:'column',alignItems:'center',gap:6,opacity:earned?1:0.45}}>
            <Ic name={icon} size={20} style={{color:'var(--gold-600)'}}/>
            <span style={{fontSize:10,fontWeight:700,color:'var(--text-primary)',textAlign:'center'}}>{label}</span>
          </div>
        ))}
      </div>

      <div style={{marginTop:14,background:'var(--gradient-primary)',borderRadius:'var(--radius-lg)',padding:18,color:'#fff'}}>
        <div style={{fontSize:12,color:'rgba(255,255,255,0.8)',fontWeight:700,letterSpacing:'0.04em',textTransform:'uppercase'}}>Bonus credit balance</div>
        <div style={{fontWeight:800,fontSize:28,marginTop:4}}>2,150 <span style={{fontSize:13,fontWeight:600}}>pts</span></div>
        <div style={{fontSize:12,marginTop:6,color:'rgba(255,255,255,0.85)'}}>24 papers submitted · redeem code value scales with your contributions</div>
      </div>

      <div style={{marginTop:14,background:'#fff',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:16}}>
        <div style={{display:'flex',justifyContent:'space-between',alignItems:'center'}}>
          <div>
            <div style={{fontWeight:700,fontSize:14,color:'var(--text-primary)'}}>Redeem code ready</div>
            <div style={{fontSize:12,color:'var(--text-secondary)',marginTop:2}}>25% off any marking-guide unlock · expires in 30 days</div>
          </div>
          <Ic name="ticket" size={22}/>
        </div>
        <div style={{marginTop:12,background:'var(--surface-sunken)',border:'1px dashed var(--border-subtle)',borderRadius:'var(--radius-md)',padding:'10px 14px',display:'flex',justifyContent:'space-between',alignItems:'center'}}>
          <span style={{fontFamily:'var(--font-mono)',fontWeight:700,fontSize:15,letterSpacing:'0.06em',color:'var(--text-primary)'}}>SPKH-24GT-Q3</span>
          <button style={{background:'none',border:'none',color:'var(--gold-700)',fontWeight:700,fontSize:12,cursor:'pointer'}}>Share</button>
        </div>
      </div>

      <div style={{marginTop:20,fontSize:11,fontWeight:700,color:'var(--text-tertiary)',textTransform:'uppercase',letterSpacing:'0.05em'}}>Submission status</div>
      <div style={{marginTop:8,background:'#fff',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:'2px 16px'}}>
        {items.map((it,i)=>(
          <div key={it.title} style={{display:'flex',alignItems:'center',gap:12,padding:'13px 0',borderTop:i>0?'1px solid var(--border-subtle)':'none'}}>
            <div style={{flex:1}}>
              <div style={{fontWeight:700,fontSize:13,color:'var(--text-primary)'}}>{it.title}</div>
              <div style={{fontSize:11,color:'var(--text-secondary)',marginTop:2}}>{it.date}</div>
            </div>
            <Badge tone={it.tone}>{it.status}</Badge>
          </div>
        ))}
      </div>

      <div style={{marginTop:20,fontSize:11,fontWeight:700,color:'var(--text-tertiary)',textTransform:'uppercase',letterSpacing:'0.05em'}}>Account</div>
      <div style={{marginTop:8,background:'#fff',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:'0 16px'}}>
        <div style={{display:'flex',alignItems:'center',gap:12,padding:'13px 0'}}><Ic name="download"/><div style={{flex:1,fontSize:14,fontWeight:600,color:'var(--text-primary)'}}>My downloads</div><Ic name="chevron-right"/></div>
        <div style={{borderTop:'1px solid var(--border-subtle)'}}/>
        <div style={{display:'flex',alignItems:'center',gap:12,padding:'13px 0'}}><Ic name="message-circle"/><div style={{flex:1,fontSize:14,fontWeight:600,color:'var(--text-primary)'}}>My forum activity</div><Ic name="chevron-right"/></div>
      </div>
    </div>
  );
}
window.ProfileScreen = ProfileScreen;
