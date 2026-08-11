function PamphletSheet({onClose}) {
  const { Button } = window.KawloSpekoohDesignSystem_10ffa8;
  const Ic = window.Ic;
  const [paid,setPaid] = React.useState(false);
  return (
    <div onClick={onClose} style={{position:'absolute',inset:0,background:'rgba(36,26,8,0.45)',backdropFilter:'blur(2px)',display:'flex',alignItems:'flex-end',zIndex:10}}>
      <div onClick={e=>e.stopPropagation()} style={{background:'#fff',width:'100%',borderRadius:'26px 26px 0 0',padding:'10px 22px 26px',boxShadow:'var(--shadow-sheet)'}}>
        <div style={{width:40,height:4,borderRadius:2,background:'var(--border-subtle)',margin:'0 auto 16px'}}/>
        {!paid ? (
          <React.Fragment>
            <div style={{display:'flex',gap:12,alignItems:'center'}}>
              <div style={{width:56,height:56,borderRadius:12,background:'var(--gradient-gold-deep)',flexShrink:0}}/>
              <div>
                <div style={{fontWeight:800,fontSize:16,color:'var(--text-primary)'}}>Probatoire Philosophy Pamphlet</div>
                <div style={{fontSize:12,color:'var(--text-secondary)',marginTop:2}}>Sold by Librairie Centrale</div>
              </div>
            </div>
            <div style={{marginTop:14,fontSize:12,color:'var(--text-secondary)',lineHeight:1.5}}>Spekooh holds your payment in escrow. You'll get a one-time QR ticket to collect it at the bookshop — payment only releases to the partner once they scan it.</div>
            <div style={{marginTop:14,border:'1.5px solid var(--gold-400)',borderRadius:'var(--radius-lg)',padding:'12px 16px',display:'flex',justifyContent:'space-between',alignItems:'center'}}>
              <span style={{fontSize:11,fontWeight:800,color:'var(--text-secondary)',letterSpacing:'0.04em'}}>PICKUP · IN-STORE</span>
              <span style={{fontWeight:800,fontSize:17,color:'var(--text-primary)'}}>7,500 <span style={{fontSize:11,color:'var(--text-tertiary)',fontWeight:600}}>FCFA</span></span>
            </div>
            <Button variant="primary" style={{width:'100%',marginTop:14}} onClick={()=>setPaid(true)}>Pay & reserve — 7,500 FCFA</Button>
            <div style={{textAlign:'center',fontSize:11,color:'var(--text-tertiary)',marginTop:10}}>Held in escrow · released to partner only after pickup is confirmed · 5% platform commission</div>
          </React.Fragment>
        ) : (
          <div style={{display:'flex',flexDirection:'column',alignItems:'center',gap:10,textAlign:'center',padding:'6px 0 4px'}}>
            <div style={{width:150,height:150,background:'repeating-linear-gradient(45deg,var(--ink-900) 0 6px,#fff 6px 12px)',borderRadius:12}}/>
            <div style={{fontWeight:800,fontSize:16,color:'var(--text-primary)'}}>Pickup ticket ready</div>
            <div style={{fontSize:12,color:'var(--text-secondary)',maxWidth:260}}>Show this QR at Librairie Centrale. Single-use — expires in 30 days. Payment releases to the partner once they scan it.</div>
            <Button variant="secondary" onClick={onClose}>Done</Button>
          </div>
        )}
      </div>
    </div>
  );
}
window.PamphletSheet = PamphletSheet;
