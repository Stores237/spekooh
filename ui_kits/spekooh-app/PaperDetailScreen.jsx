function PaperDetailScreen({onBack,paper}) {
  const { Button, StatRow, Badge } = window.KawloSpekoohDesignSystem_10ffa8;
  const Ic = window.Ic;
  const [unlocked,setUnlocked] = React.useState(false);
  const title = paper ? `${paper.subject.title} — ${paper.examType}${paper.track?' '+paper.track:''} ${paper.year}` : 'Physics — A Level 2025';
  const meta = paper ? [paper.cat && (paper.cat.charAt(0).toUpperCase()+paper.cat.slice(1)), paper.system].filter(Boolean).join(' · ') : 'Secondary · Anglophone';
  return (
    <div style={{flex:1,overflowY:'auto',padding:'0 18px 90px'}}>
      <div style={{display:'flex',alignItems:'center',gap:10,marginTop:10}}>
        <button onClick={onBack} style={{background:'none',border:'none',cursor:'pointer'}}><Ic name="chevron-left"/></button>
        <div style={{flex:1}}>
          <div style={{fontWeight:800,fontSize:16,color:'var(--text-primary)'}}>{title}</div>
          <div style={{fontSize:11,color:'var(--text-secondary)',marginTop:2}}>{meta}</div>
        </div>
        {paper && <Badge tone="neutral">{paper.variant}</Badge>}
      </div>
      <div style={{marginTop:14,background:'#fff',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:16,minHeight:220,display:'flex',alignItems:'center',justifyContent:'center',color:'var(--text-tertiary)',fontSize:13}}>Question paper preview (scanned pages)</div>
      <div style={{marginTop:12}}><StatRow stats={[{value:8,label:'questions'},{value:2,label:'MCQ (in-house key)'},{value:'2,341',label:'views'}]}/></div>
      <div style={{marginTop:16,background:'#fff',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:16}}>
        <div style={{display:'flex',justifyContent:'space-between',alignItems:'center'}}>
          <div>
            <div style={{fontWeight:700,fontSize:14,color:'var(--text-primary)'}}>Marking guide</div>
            <div style={{fontSize:12,color:'var(--text-secondary)',marginTop:2}}>Instructor-authored + in-house MCQ key</div>
          </div>
          <Ic name={unlocked?'lock-open':'lock'} size={18}/>
        </div>
        {unlocked ? (
          <div style={{marginTop:12,fontSize:13,color:'var(--green-600)',fontWeight:600}}>Unlocked — full solutions below.</div>
        ) : (
          <div style={{marginTop:12,display:'flex',gap:8,alignItems:'center'}}>
            <Button variant="primary" size="sm" onClick={()=>setUnlocked(true)}>Unlock — 400 FCFA</Button>
            <button style={{background:'none',border:'none',color:'var(--gold-700)',fontWeight:700,fontSize:12,cursor:'pointer'}}>Have a redeem code?</button>
          </div>
        )}
      </div>
      <div style={{marginTop:14,display:'flex',alignItems:'center',gap:10,background:'var(--gold-50)',borderRadius:'var(--radius-lg)',padding:'12px 14px'}}>
        <Ic name="info" size={18} style={{color:'var(--gold-700)'}}/>
        <span style={{fontSize:12,color:'var(--gold-700)',fontWeight:600,flex:1}}>Objective/MCQ answers are marked in-house by the Spekooh review team, not the instructor.</span>
      </div>
    </div>
  );
}
window.PaperDetailScreen = PaperDetailScreen;
