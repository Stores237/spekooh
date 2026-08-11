function NotesScreen({onBack}) {
  const { IconChip, SearchInput } = window.KawloSpekoohDesignSystem_10ffa8;
  const Ic = window.Ic;
  const notes = [
    ['Mechanics — Newton’s Laws','Physics · A Level','blue','atom'],
    ['Cell Structure & Function','Biology · O Level','green','leaf'],
    ['La Dissertation Philosophique','Philosophie · Baccalauréat','purple','book-open'],
    ['Acids, Bases & Salts','Chemistry · O Level','purple','flask-conical'],
    ['Les Nombres Complexes','Mathématiques · Terminale','blue','sigma']
  ];
  return (
    <div style={{flex:1,overflowY:'auto',padding:'0 18px 90px'}}>
      <div style={{display:'flex',alignItems:'center',gap:10,marginTop:10}}>
        <button onClick={onBack} style={{width:36,height:36,borderRadius:'50%',border:'1px solid var(--border-subtle)',background:'#fff'}}><Ic name="chevron-left"/></button>
        <div><div style={{fontWeight:800,fontSize:19,color:'var(--text-primary)'}}>Notes</div><div style={{fontSize:12,color:'var(--text-secondary)'}}>Topic study notes, contributed alongside papers</div></div>
      </div>
      <div style={{marginTop:14}}><SearchInput placeholder="Search topics..."/></div>
      <div style={{marginTop:14,display:'flex',flexDirection:'column',gap:10}}>
        {notes.map(([title,sub,tint,icon])=>(
          <div key={title} style={{background:'#fff',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:14,display:'flex',alignItems:'center',gap:12}}>
            <IconChip tint={tint} icon={<Ic name={icon}/>}/>
            <div style={{flex:1}}><div style={{fontWeight:700,fontSize:14,color:'var(--text-primary)'}}>{title}</div><div style={{fontSize:12,color:'var(--text-secondary)'}}>{sub}</div></div>
            <Ic name="chevron-right"/>
          </div>
        ))}
      </div>
    </div>
  );
}
window.NotesScreen = NotesScreen;
