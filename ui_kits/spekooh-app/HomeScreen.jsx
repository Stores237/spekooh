function HomeScreen({onOpenPaywall,onOpenSettings,onOpenPaper,onOpenPamphlet,onOpenProfile,onOpenNotes,onOpenShop}) {
  const { Button, Badge, IconChip, Banner } = window.KawloSpekoohDesignSystem_10ffa8;
  const Ic = window.Ic;
  return (
    <div style={{flex:1,overflowY:'auto',padding:'0 18px 90px'}}>
      <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginTop:6}}>
        <div onClick={onOpenProfile} style={{cursor:'pointer',display:'flex',alignItems:'center',gap:10}}>
          <div style={{width:38,height:38,borderRadius:'50%',background:'var(--gold-200)',display:'flex',alignItems:'center',justifyContent:'center',fontWeight:800,color:'var(--gold-700)'}}>G</div>
          <div>
            <div style={{fontSize:12,color:'var(--text-secondary)'}}>Bienvenue · Welcome</div>
            <div style={{fontSize:16,fontWeight:800,color:'var(--text-primary)'}}>Guest</div>
          </div>
        </div>
        <div style={{display:'flex',gap:8,alignItems:'center'}}>
          <Button variant="secondary" size="sm">Join free</Button>
          <button onClick={onOpenSettings} style={{width:38,height:38,borderRadius:'50%',border:'1px solid var(--border-subtle)',background:'#fff',display:'flex',alignItems:'center',justifyContent:'center',cursor:'pointer'}}><Ic name="settings"/></button>
        </div>
      </div>
      <div style={{marginTop:12,display:'flex',gap:6}}><Badge tone="neutral">Exploring — no account</Badge><Badge tone="blue">EN / FR</Badge></div>

      <div style={{marginTop:14,background:'var(--ink-900)',borderRadius:'var(--radius-lg)',padding:16,color:'#fff'}}>
        <div style={{fontSize:12,color:'var(--text-on-dark-muted)',fontWeight:700,letterSpacing:'0.04em',textTransform:'uppercase'}}>Free paper views today</div>
        <div style={{display:'flex',alignItems:'baseline',gap:6,marginTop:4}}><span style={{fontWeight:800,fontSize:24}}>2</span><span style={{fontSize:13,color:'var(--text-on-dark-muted)'}}>of 3 used</span></div>
        <div style={{fontSize:12,color:'var(--text-on-dark-muted)',marginTop:6}}>Watch an ad for 1 more, or go Pro for unlimited views.</div>
        <div style={{display:'flex',gap:8,marginTop:10}}>
          <button style={{flex:1,background:'rgba(255,255,255,0.14)',color:'#fff',border:'none',borderRadius:999,padding:'10px',fontWeight:700,fontSize:13,cursor:'pointer'}}>Watch ad</button>
          <button onClick={onOpenPaywall} style={{flex:1,background:'var(--gradient-primary)',color:'#fff',border:'none',borderRadius:999,padding:'10px',fontWeight:700,fontSize:13,cursor:'pointer'}}>Go Pro</button>
        </div>
      </div>

      <div onClick={onOpenPaper} style={{marginTop:14,background:'#fff',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:14,display:'flex',alignItems:'center',gap:12,cursor:'pointer'}}>
        <IconChip tint="purple" icon={<Ic name="sigma"/>}/>
        <div style={{flex:1}}>
          <div style={{fontWeight:700,fontSize:14,color:'var(--text-primary)'}}>Mathématiques · Baccalauréat 2025</div>
          <div style={{fontSize:12,color:'var(--text-secondary)',marginTop:2}}>Free to view — marking guide sold separately</div>
        </div>
        <Ic name="chevron-right"/>
      </div>

      <div style={{marginTop:22,fontWeight:800,fontSize:17,color:'var(--text-primary)'}}>Contribution — earn credit</div>
      <div style={{marginTop:10,background:'#fff',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:14,display:'flex',gap:12,alignItems:'center'}}>
        <IconChip tint="amber" icon={<Ic name="upload"/>} size={48}/>
        <div style={{flex:1}}>
          <div style={{fontWeight:700,fontSize:14,color:'var(--text-primary)'}}>Got a past paper or report we don't have?</div>
          <div style={{fontSize:12,color:'var(--text-secondary)',marginTop:2}}>Snap a photo, tag it, earn bonus credit once it's verified — first contribution counts.</div>
        </div>
      </div>

      <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10,marginTop:20}}>
        <div onClick={onOpenNotes} style={{background:'#fff',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:14,display:'flex',flexDirection:'column',gap:8,cursor:'pointer'}}>
          <IconChip tint="green" icon={<Ic name="book-open"/>} size={40}/>
          <div style={{fontWeight:700,fontSize:14,color:'var(--text-primary)'}}>Notes</div>
          <div style={{fontSize:11,color:'var(--text-secondary)'}}>Topic study notes by subject</div>
        </div>
        <div onClick={onOpenShop} style={{background:'#fff',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:14,display:'flex',flexDirection:'column',gap:8,cursor:'pointer'}}>
          <IconChip tint="amber" icon={<Ic name="shopping-bag"/>} size={40}/>
          <div style={{fontWeight:700,fontSize:14,color:'var(--text-primary)'}}>Shop</div>
          <div style={{fontSize:11,color:'var(--text-secondary)'}}>Partner pamphlets, QR pickup</div>
        </div>
      </div>

      <div style={{display:'flex',justifyContent:'space-between',alignItems:'baseline',marginTop:22}}>
        <div style={{fontWeight:800,fontSize:17,color:'var(--text-primary)'}}>Partner pamphlets</div>
        <span onClick={onOpenShop} style={{fontSize:13,fontWeight:700,color:'var(--gold-700)',cursor:'pointer'}}>Shop</span>
      </div>
      <div onClick={onOpenPamphlet} style={{marginTop:10,background:'#fff',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:14,display:'flex',gap:12,alignItems:'center',cursor:'pointer'}}>
        <div style={{width:64,height:64,borderRadius:10,background:'var(--gradient-gold-deep)',flexShrink:0}}/>
        <div style={{flex:1}}>
          <div style={{fontWeight:700,fontSize:14,color:'var(--text-primary)'}}>Probatoire Philosophy Pamphlet</div>
          <div style={{fontSize:12,color:'var(--text-secondary)',marginTop:2}}>Sold by Librairie Centrale · pick up with a QR code.</div>
          <div style={{marginTop:8,display:'flex',alignItems:'center',gap:8}}>
            <span style={{fontWeight:800,color:'var(--text-primary)'}}>7,500 <span style={{fontSize:11,color:'var(--text-tertiary)',fontWeight:600}}>FCFA</span></span>
            <Button variant="primary" size="sm">Buy</Button>
          </div>
        </div>
      </div>

      <div style={{marginTop:22,fontSize:12,color:'var(--text-tertiary)',fontWeight:700,letterSpacing:'0.05em',textTransform:'uppercase'}}>Sign up only when you want to…</div>
      <div style={{marginTop:10,background:'#fff',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:'2px 16px'}}>
        {[['flame','Earn & redeem contributor credits'],['file-check','Track your contributions'],['bell','Get instructor status alerts'],['download','Sync downloads across phones']].map(([icon,label],i)=>(
          <div key={label} style={{display:'flex',alignItems:'center',gap:12,padding:'12px 0',borderTop:i>0?'1px solid var(--border-subtle)':'none'}}>
            <IconChip tint="blue" icon={<Ic name={icon}/>} size={36}/>
            <div style={{flex:1,fontSize:14,fontWeight:600,color:'var(--text-primary)'}}>{label}</div>
            <Ic name="lock" size={16}/>
          </div>
        ))}
      </div>
      <div style={{textAlign:'center',fontSize:12,color:'var(--text-secondary)',marginTop:14,lineHeight:1.5}}>Reading papers stays open to everyone — 3 free views a day, no account needed.</div>
    </div>
  );
}
window.HomeScreen = HomeScreen;
