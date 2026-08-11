function PapersScreen({onOpenPaper}) {
  const { SegmentedTabs, SubjectCard, SearchInput, IconChip, Badge } = window.KawloSpekoohDesignSystem_10ffa8;
  const [cat,setCat] = React.useState(null);
  const [system,setSystem] = React.useState(null);
  const [examType,setExamType] = React.useState(null);
  const [track,setTrack] = React.useState(null);
  const [subject,setSubject] = React.useState(null);
  const [tab,setTab] = React.useState(0);
  const [q,setQ] = React.useState('');
  const [showFilter,setShowFilter] = React.useState(false);
  const Ic = window.Ic;

  const categories = [
    ['primary','Primary','blue','baby','FSLC · CEP · Common Entrance'],
    ['secondary','Secondary','amber','graduation-cap','BEPC · Probatoire · Bac · O/A Level'],
    ['university','University','blue','landmark','Semester exams · Resits — State & Private'],
    ['tertiary','Tertiary','green','building-2','HND · BTS · AQP/CQP/DQP'],
    ['concours','Concours','purple','award','ENAM · ENSP · UCAC · ESSEC & more'],
    ['reports','Academic Reports','red','book-open','Internship · Mémoire · Thèse — no marking guide']
  ];
  const examTypesByCat = {
    primary: [['FSLC','Anglophone','blue'],['Common Entrance','Anglophone','blue'],['CEP','Francophone','amber'],['Concours d’Entrée en 6ème','Francophone','amber']],
    secondaryFrancophone: [['BEPC','+ BEPC Blanc · Général/Technique','amber'],['Probatoire','+ Probatoire Blanc · Général/Technique','amber'],['Baccalauréat','+ Bac Blanc · Général/Technique','amber']],
    secondaryAnglophone: [['O Level','+ O Level Mock · General only','blue'],['A Level','+ A Level Mock · Sci/Arts/Comm/Tech','blue']],
    universityFrancophone: [['Examen Semestre 1','1er semestre, tous niveaux','amber'],['Examen Semestre 2','2nd semestre, tous niveaux','amber'],['Rattrapage','Session de rattrapage','amber']],
    universityAnglophone: [['Semester 1 Exam','1st semester, all levels','blue'],['Semester 2 Exam','2nd semester, all levels','blue'],['Resit / Makeup','Resit sittings','blue']],
    tertiary: [['HND','Anglophone','blue'],['BTS','Francophone','amber'],['AQP','Vocational training center','green'],['CQP','Vocational training center','green'],['DQP','Vocational training center','green']],
    concours: [['ENAM','École Nat. d’Administration','purple'],['ENSP','Polytechnique Yaoundé/Bamenda','purple'],['ESSEC','Douala / Garoua','purple'],['UCAC','Univ. Catholique d’Afrique Centrale','purple'],['IUT','Douala, Ngaoundéré & more','purple'],['FMSB','Médecine / Pharmacie','purple'],['ENS','Yaoundé / Bambili / Maroua','purple'],['IAI','Institut Africain d’Informatique','purple'],['ESSTIC','Info & Communication','purple'],['EMIA','Officer entrance','purple']]
  };
  const reportTypes = [['internship','Internship Report','HND / Bachelor / Master','blue'],['bachelor','Bachelor’s Report (Mémoire de Licence)','Bachelor / Licence','green'],['hnd','HND Report','Rapport de fin d’études','amber'],['master','Master’s Thesis (Mémoire)','Master','purple'],['phd','PhD Thesis (Thèse)','Doctorat','red']];
  const variantByExam = { FSLC:null, 'Common Entrance':null, CEP:null, 'Concours d’Entrée en 6ème':null, BEPC:'+ BEPC Blanc', Probatoire:'+ Probatoire Blanc', 'Baccalauréat':'+ Bac Blanc', 'O Level':'+ O Level Mock', 'A Level':'+ A Level Mock' };
  const tracksByExam = {
    'A Level':['Science','Arts','Commercial','Technical'],
    'Baccalauréat':['Général','Technique'],
    'Probatoire':['Général','Technique'],
    'BEPC':['Général','Technique'],
    'Semester 1 Exam':['L1','L2','L3','M1','M2'],
    'Semester 2 Exam':['L1','L2','L3','M1','M2'],
    'Resit / Makeup':['L1','L2','L3','M1','M2'],
    'Examen Semestre 1':['L1','L2','L3','M1','M2'],
    'Examen Semestre 2':['L1','L2','L3','M1','M2'],
    'Rattrapage':['L1','L2','L3','M1','M2']
  };
  const subjectsEn = [
    ['accounting','Accounting','amber','file-text','0505'],
    ['biology','Biology','green','leaf','0510'],
    ['chemistry','Chemistry','purple','flask-conical','0515'],
    ['computer science','Computer science','blue','cpu','0595'],
    ['economics','Economics','amber','trending-up','0525'],
    ['physics','Physics','blue','atom','0580']
  ];
  const subjectsFr = [
    ['maths','Mathématiques','blue','sigma','MAT'],
    ['philo','Philosophie','purple','book-open','PHI'],
    ['hist-geo','Histoire-Géo','amber','globe','HGE'],
    ['svt','SVT','green','leaf','SVT'],
    ['physique-chimie','Physique-Chimie','blue','atom','PC'],
    ['anglais','Anglais','amber','languages','ANG']
  ];

  // Step 1: Category
  if (!cat) {
    return (
      <div style={{flex:1,overflowY:'auto',padding:'0 18px 90px'}}>
        <div style={{fontWeight:800,fontSize:20,marginTop:10,color:'var(--text-primary)'}}>Past papers</div>
        <div style={{fontSize:12,color:'var(--text-secondary)',marginTop:4}}>Every level, every system — Primary to Concours des Grandes Écoles.</div>
        <div style={{display:'flex',gap:8,marginTop:14}}>
          <div style={{flex:1}}><SearchInput placeholder="Search exam type or subject..." value={q} onChange={setQ}/></div>
          <button onClick={()=>setShowFilter(!showFilter)} style={{width:44,height:44,flexShrink:0,borderRadius:'var(--radius-md)',border:'1px solid var(--border-subtle)',background:showFilter?'var(--gold-50)':'#fff',display:'flex',alignItems:'center',justifyContent:'center',cursor:'pointer'}}><Ic name="sliders-horizontal"/></button>
        </div>
        {showFilter && (
          <div style={{marginTop:10,background:'#fff',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:14}}>
            <div style={{fontSize:11,fontWeight:700,color:'var(--text-tertiary)',textTransform:'uppercase',letterSpacing:'0.05em'}}>System</div>
            <div style={{display:'flex',gap:8,marginTop:8,flexWrap:'wrap'}}>
              {['All','Anglophone','Francophone'].map(t=>(<span key={t} style={{padding:'6px 12px',borderRadius:999,fontSize:12,fontWeight:700,background:'var(--surface-sunken)',color:'var(--text-secondary)'}}>{t}</span>))}
            </div>
            <div style={{fontSize:11,fontWeight:700,color:'var(--text-tertiary)',textTransform:'uppercase',letterSpacing:'0.05em',marginTop:12}}>Variant</div>
            <div style={{display:'flex',gap:8,marginTop:8,flexWrap:'wrap'}}>
              {['Official','Mock / Blanc'].map(t=>(<span key={t} style={{padding:'6px 12px',borderRadius:999,fontSize:12,fontWeight:700,background:'var(--surface-sunken)',color:'var(--text-secondary)'}}>{t}</span>))}
            </div>
            <div style={{fontSize:11,fontWeight:700,color:'var(--text-tertiary)',textTransform:'uppercase',letterSpacing:'0.05em',marginTop:12}}>Year</div>
            <div style={{display:'flex',gap:8,marginTop:8,flexWrap:'wrap'}}>
              {['2026','2025','2024','2023','Older'].map(t=>(<span key={t} style={{padding:'6px 12px',borderRadius:999,fontSize:12,fontWeight:700,background:'var(--surface-sunken)',color:'var(--text-secondary)'}}>{t}</span>))}
            </div>
          </div>
        )}
        <div style={{fontSize:11,fontWeight:700,color:'var(--text-tertiary)',textTransform:'uppercase',letterSpacing:'0.05em',marginTop:18}}>Category</div>
        <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12,marginTop:10}}>
          {categories.filter(c=>c[1].toLowerCase().includes(q.toLowerCase())).map(([key,title,tint,icon,sub])=>(
            <button key={key} onClick={()=>{setCat(key);setSystem(null);}} style={{textAlign:'left',background:'#fff',border:'none',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:14,cursor:'pointer',display:'flex',flexDirection:'column',gap:8}}>
              <IconChip tint={tint} icon={<Ic name={icon}/>}/>
              <div style={{fontWeight:700,fontSize:14,color:'var(--text-primary)'}}>{title}</div>
              <div style={{fontSize:11,color:'var(--text-secondary)'}}>{sub}</div>
            </button>
          ))}
        </div>
      </div>
    );
  }

  // Step 1b: Academic Reports (separate content type — no marking guide/instructor routing)
  if (cat==='reports') {
    return (
      <div style={{flex:1,overflowY:'auto',padding:'0 18px 90px'}}>
        <div style={{display:'flex',alignItems:'center',gap:10,marginTop:10}}>
          <button onClick={()=>setCat(null)} style={{background:'none',border:'none',cursor:'pointer'}}><Ic name="chevron-left"/></button>
          <div style={{fontWeight:800,fontSize:18,color:'var(--text-primary)'}}>Academic Reports</div>
        </div>
        <div style={{fontSize:12,color:'var(--text-secondary)',marginTop:8,lineHeight:1.5}}>Reference documents, not exam papers — browsable by report type, discipline & year. No marking guide or instructor routing applies here.</div>
        <div style={{marginTop:14}}><SearchInput placeholder="Search by discipline..."/></div>
        <div style={{marginTop:14,display:'flex',flexDirection:'column',gap:10}}>
          {reportTypes.map(([key,title,sub,tint])=>(
            <div key={key} onClick={onOpenPaper} style={{background:'#fff',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:14,display:'flex',alignItems:'center',gap:12,cursor:'pointer'}}>
              <IconChip tint={tint} icon={<Ic name="file-text"/>}/>
              <div style={{flex:1}}><div style={{fontWeight:700,fontSize:14,color:'var(--text-primary)'}}>{title}</div><div style={{fontSize:12,color:'var(--text-secondary)'}}>{sub}</div></div>
              <Ic name="chevron-right"/>
            </div>
          ))}
        </div>
      </div>
    );
  }

  // Step 2 (Secondary/University): System — Francophone / Anglophone
  if ((cat==='secondary'||cat==='university') && !system) {
    const catLabel = cat.charAt(0).toUpperCase()+cat.slice(1);
    const systemOptions = cat==='university'
      ? [['Francophone','Examen Semestre · Rattrapage'],['Anglophone','Semester Exam · Resit']]
      : [['Francophone','BEPC · Probatoire · Baccalauréat'],['Anglophone','O Level · A Level']];
    return (
      <div style={{flex:1,overflowY:'auto',padding:'0 18px 90px'}}>
        <div style={{display:'flex',alignItems:'center',gap:10,marginTop:10}}>
          <button onClick={()=>setCat(null)} style={{background:'none',border:'none',cursor:'pointer'}}><Ic name="chevron-left"/></button>
          <div style={{fontWeight:800,fontSize:18,color:'var(--text-primary)'}}>{catLabel} — choose system</div>
        </div>
        <div style={{display:'flex',flexDirection:'column',gap:10,marginTop:16}}>
          {systemOptions.map(([t,sub])=>(
            <button key={t} onClick={()=>setSystem(t)} style={{textAlign:'left',background:'#fff',border:'none',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:16,cursor:'pointer',display:'flex',alignItems:'center',justifyContent:'space-between'}}>
              <div><div style={{fontWeight:700,fontSize:14,color:'var(--text-primary)'}}>{t}</div><div style={{fontSize:11,color:'var(--text-secondary)',marginTop:2}}>{sub}</div></div>
              <Ic name="chevron-right"/>
            </button>
          ))}
        </div>
      </div>
    );
  }

  // Step 3: Exam type within category (+ system for Secondary)
  if (!examType) {
    const isSysCat = cat==='secondary'||cat==='university';
    const listKey = isSysCat ? (cat+(system==='Francophone'?'Francophone':'Anglophone')) : cat;
    const headerLabel = isSysCat ? `${cat.charAt(0).toUpperCase()+cat.slice(1)} · ${system}` : cat.charAt(0).toUpperCase()+cat.slice(1);
    return (
      <div style={{flex:1,overflowY:'auto',padding:'0 18px 90px'}}>
        <div style={{display:'flex',alignItems:'center',gap:10,marginTop:10}}>
          <button onClick={()=>isSysCat?setSystem(null):setCat(null)} style={{background:'none',border:'none',cursor:'pointer'}}><Ic name="chevron-left"/></button>
          <div style={{fontWeight:800,fontSize:18,color:'var(--text-primary)'}}>{headerLabel}</div>
        </div>
        <div style={{marginTop:12}}><SearchInput placeholder="Search exam type..."/></div>
        <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12,marginTop:14}}>
          {examTypesByCat[listKey].map(([name,sub,tint])=>(
            <button key={name} onClick={()=>setExamType(name)} style={{textAlign:'left',background:'#fff',border:'none',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:14,cursor:'pointer',display:'flex',flexDirection:'column',gap:6}}>
              <Badge tone={variantByExam[name]?(tint==='purple'?'neutral':tint):'neutral'}>{variantByExam[name]?`Official ${variantByExam[name]}`:'Official only'}</Badge>
              <div style={{fontWeight:700,fontSize:14,color:'var(--text-primary)',marginTop:4}}>{name}</div>
              <div style={{fontSize:11,color:'var(--text-secondary)'}}>{sub}</div>
            </button>
          ))}
        </div>
      </div>
    );
  }

  // Step 4: Track (only if applicable)
  if (tracksByExam[examType] && !track) {
    return (
      <div style={{flex:1,overflowY:'auto',padding:'0 18px 90px'}}>
        <div style={{display:'flex',alignItems:'center',gap:10,marginTop:10}}>
          <button onClick={()=>setExamType(null)} style={{background:'none',border:'none',cursor:'pointer'}}><Ic name="chevron-left"/></button>
          <div style={{fontWeight:800,fontSize:18,color:'var(--text-primary)'}}>{examType} — choose track</div>
        </div>
        <div style={{display:'flex',flexDirection:'column',gap:10,marginTop:16}}>
          {tracksByExam[examType].map(t=>(
            <button key={t} onClick={()=>setTrack(t)} style={{textAlign:'left',background:'#fff',border:'none',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:16,cursor:'pointer',display:'flex',alignItems:'center',justifyContent:'space-between'}}>
              <span style={{fontWeight:700,fontSize:14,color:'var(--text-primary)'}}>{t}</span>
              <Ic name="chevron-right"/>
            </button>
          ))}
        </div>
      </div>
    );
  }

  // Step 5: Subjects
  const isFr = ['BEPC','Probatoire','Baccalauréat','CEP','Concours d’Entrée en 6ème','BTS','Examen Semestre 1','Examen Semestre 2','Rattrapage'].includes(examType);
  const subjects = isFr ? subjectsFr : subjectsEn;

  // Step 6: Papers by year/variant, once a subject is picked
  if (subject) {
    const hasVariant = !!variantByExam[examType];
    const variantLabel = hasVariant ? variantByExam[examType].replace('+ ','') : null;
    const years = [2026,2025,2024,2023,2022];
    const rows = [];
    years.forEach(y=>{
      if (!hasVariant || tab!==2) rows.push({year:y,label:'Official'});
      if (hasVariant && tab!==1) rows.push({year:y,label:variantLabel});
    });
    return (
      <div style={{flex:1,overflowY:'auto',padding:'0 18px 90px'}}>
        <div style={{display:'flex',alignItems:'center',gap:10,marginTop:10}}>
          <button onClick={()=>setSubject(null)} style={{background:'none',border:'none',cursor:'pointer'}}><Ic name="chevron-left"/></button>
          <div style={{flex:1}}>
            <div style={{fontWeight:800,fontSize:18,color:'var(--text-primary)'}}>{subject.title}</div>
            <div style={{fontSize:11,color:'var(--text-secondary)'}}>{examType}{track?` · ${track}`:''} · {subject.code}</div>
          </div>
        </div>
        {hasVariant && <div style={{marginTop:12}}><SegmentedTabs options={['All','Official',variantLabel]} active={tab} onChange={setTab}/></div>}
        <div style={{marginTop:14,display:'flex',flexDirection:'column',gap:10}}>
          {rows.map((r,i)=>(
            <div key={i} onClick={()=>onOpenPaper({subject,cat,system,examType,track,year:r.year,variant:r.label})} style={{background:'#fff',borderRadius:'var(--radius-lg)',boxShadow:'var(--shadow-card)',padding:14,display:'flex',alignItems:'center',gap:12,cursor:'pointer'}}>
              <IconChip tint={subject.tint} icon={<Ic name={subject.icon}/>}/>
              <div style={{flex:1}}>
                <div style={{fontWeight:700,fontSize:14,color:'var(--text-primary)'}}>{examType} {r.year}</div>
                <div style={{fontSize:11,color:'var(--text-secondary)'}}>{r.label} · Marking guide included</div>
              </div>
              <Ic name="chevron-right"/>
            </div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div style={{flex:1,overflowY:'auto',padding:'0 18px 90px'}}>
      <div style={{display:'flex',alignItems:'center',gap:10,marginTop:10}}>
        <button onClick={()=>{if(track){setTrack(null);}else{setExamType(null);}}} style={{background:'none',border:'none',cursor:'pointer'}}><Ic name="chevron-left"/></button>
        <div><div style={{fontWeight:800,fontSize:18,color:'var(--text-primary)'}}>{examType}</div>{track&&<div style={{fontSize:11,color:'var(--text-secondary)'}}>{track}</div>}</div>
      </div>
      <div style={{marginTop:12,display:'flex',gap:8}}>
        <div style={{flex:1}}><SearchInput placeholder="Search subjects..."/></div>
        <button style={{width:44,height:44,flexShrink:0,borderRadius:'var(--radius-md)',border:'1px solid var(--border-subtle)',background:'#fff',display:'flex',alignItems:'center',justifyContent:'center',cursor:'pointer'}}><Ic name="sliders-horizontal"/></button>
      </div>
      <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:12,marginTop:14}}>
        {subjects.map(([key,title,tint,icon,code])=>(
          <div key={key} onClick={()=>{setTab(0);setSubject({key,title,tint,icon,code});}} style={{cursor:'pointer'}}>
            <SubjectCard icon={<IconChip tint={tint} icon={<Ic name={icon}/>}/>} title={title} subtitle="Papers + marking guides" badgeText="Papers" code={code}/>
          </div>
        ))}
      </div>
    </div>
  );
}
window.PapersScreen = PapersScreen;
