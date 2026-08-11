/* @ds-bundle: {"format":4,"namespace":"KawloSpekoohDesignSystem_10ffa8","components":[{"name":"Badge","sourcePath":"components/core/Badge.jsx"},{"name":"Button","sourcePath":"components/core/Button.jsx"},{"name":"IconChip","sourcePath":"components/core/IconChip.jsx"},{"name":"Avatar","sourcePath":"components/data-display/Avatar.jsx"},{"name":"ListItemRow","sourcePath":"components/data-display/ListItemRow.jsx"},{"name":"StatRow","sourcePath":"components/data-display/StatRow.jsx"},{"name":"SubjectCard","sourcePath":"components/data-display/SubjectCard.jsx"},{"name":"Banner","sourcePath":"components/feedback/Banner.jsx"},{"name":"SearchInput","sourcePath":"components/forms/SearchInput.jsx"},{"name":"Toggle","sourcePath":"components/forms/Toggle.jsx"},{"name":"BottomNav","sourcePath":"components/navigation/BottomNav.jsx"},{"name":"SegmentedTabs","sourcePath":"components/navigation/SegmentedTabs.jsx"}],"sourceHashes":{"components/core/Badge.jsx":"f28d9d141d94","components/core/Button.jsx":"5f37c21f89af","components/core/IconChip.jsx":"8e12ecb11edf","components/data-display/Avatar.jsx":"8bf6801bbc4b","components/data-display/ListItemRow.jsx":"a9ebead9f1d3","components/data-display/StatRow.jsx":"1c80586cc536","components/data-display/SubjectCard.jsx":"42df7d0f989a","components/feedback/Banner.jsx":"fe0af2a2aa35","components/forms/SearchInput.jsx":"c2550aa71077","components/forms/Toggle.jsx":"5d1c181a18f8","components/navigation/BottomNav.jsx":"a9328af5cb70","components/navigation/SegmentedTabs.jsx":"5997a6404d88","ui_kits/spekooh-app/AIAssistant.jsx":"ccc842057334","ui_kits/spekooh-app/ForumScreen.jsx":"01937c1645bb","ui_kits/spekooh-app/HomeScreen.jsx":"4773489e3664","ui_kits/spekooh-app/IconLucide.jsx":"bd104703c2b5","ui_kits/spekooh-app/LoggedInHomeScreen.jsx":"644c3fe3a81e","ui_kits/spekooh-app/NotesScreen.jsx":"5ecf948db0e7","ui_kits/spekooh-app/NotificationsScreen.jsx":"bf3144c2fab1","ui_kits/spekooh-app/PamphletSheet.jsx":"416867726d51","ui_kits/spekooh-app/PaperDetailScreen.jsx":"56fd822694a1","ui_kits/spekooh-app/PapersScreen.jsx":"46642e87d64f","ui_kits/spekooh-app/PaywallSheet.jsx":"9ddab0e203b7","ui_kits/spekooh-app/Phone.jsx":"b14198946e8f","ui_kits/spekooh-app/ProfileScreen.jsx":"2023ae1a48d0","ui_kits/spekooh-app/QuizzesScreen.jsx":"f15bc92ab30a","ui_kits/spekooh-app/SettingsScreen.jsx":"6771620a1dfc","ui_kits/spekooh-app/ShopScreen.jsx":"d7a6fc50774f","ui_kits/spekooh-app/StatusBar.jsx":"75388eceab60","ui_kits/spekooh-app/SubmitScreen.jsx":"00c39a972f0b"},"inlinedExternals":[],"unexposedExports":[]} */

(() => {

const __ds_ns = (window.KawloSpekoohDesignSystem_10ffa8 = window.KawloSpekoohDesignSystem_10ffa8 || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// components/core/Badge.jsx
try { (() => {
function Badge({
  children,
  tone = 'blue'
}) {
  const tones = {
    blue: {
      bg: 'var(--blue-100)',
      fg: 'var(--blue-600)'
    },
    amber: {
      bg: 'var(--amber-100)',
      fg: 'var(--amber-600)'
    },
    green: {
      bg: 'var(--green-100)',
      fg: 'var(--green-600)'
    },
    neutral: {
      bg: 'var(--surface-sunken)',
      fg: 'var(--text-secondary)'
    },
    dark: {
      bg: 'var(--navy-900)',
      fg: '#fff'
    }
  };
  const t = tones[tone] || tones.blue;
  return React.createElement('span', {
    style: {
      background: t.bg,
      color: t.fg,
      fontSize: 11,
      fontWeight: 700,
      textTransform: 'uppercase',
      letterSpacing: '0.04em',
      padding: '4px 10px',
      borderRadius: 'var(--radius-pill)',
      display: 'inline-block'
    }
  }, children);
}
Object.assign(__ds_scope, { Badge });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Badge.jsx", error: String((e && e.message) || e) }); }

// components/core/Button.jsx
try { (() => {
function Button({
  variant = 'primary',
  size = 'md',
  children,
  disabled,
  onClick,
  style
}) {
  const sizes = {
    sm: {
      padding: '8px 16px',
      fontSize: 13
    },
    md: {
      padding: '13px 20px',
      fontSize: 15
    },
    lg: {
      padding: '16px 24px',
      fontSize: 16
    }
  };
  const base = {
    fontFamily: 'var(--font-sans)',
    fontWeight: 700,
    borderRadius: 'var(--radius-pill)',
    border: 'none',
    cursor: disabled ? 'default' : 'pointer',
    opacity: disabled ? 0.5 : 1,
    display: 'inline-flex',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    transition: 'transform .12s ease, opacity .12s ease',
    ...sizes[size],
    ...style
  };
  const variants = {
    primary: {
      background: 'var(--gradient-primary)',
      color: '#fff',
      boxShadow: 'var(--shadow-button)'
    },
    secondary: {
      background: 'var(--blue-100)',
      color: 'var(--blue-600)'
    },
    outline: {
      background: 'transparent',
      color: 'var(--blue-600)',
      border: '1.5px solid var(--blue-500)'
    },
    ghost: {
      background: 'transparent',
      color: 'var(--blue-600)',
      padding: '4px 0',
      boxShadow: 'none'
    },
    dark: {
      background: 'var(--navy-900)',
      color: '#fff'
    }
  };
  return React.createElement('button', {
    disabled,
    onClick,
    style: {
      ...base,
      ...variants[variant]
    },
    onMouseDown: e => {
      e.currentTarget.style.transform = 'scale(0.97)';
    },
    onMouseUp: e => {
      e.currentTarget.style.transform = 'scale(1)';
    },
    onMouseLeave: e => {
      e.currentTarget.style.transform = 'scale(1)';
    }
  }, children);
}
Object.assign(__ds_scope, { Button });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Button.jsx", error: String((e && e.message) || e) }); }

// components/core/IconChip.jsx
try { (() => {
function IconChip({
  icon,
  tint = 'blue',
  size = 44
}) {
  const tints = {
    blue: {
      bg: 'var(--blue-100)',
      fg: 'var(--blue-600)'
    },
    amber: {
      bg: 'var(--amber-100)',
      fg: 'var(--amber-600)'
    },
    green: {
      bg: 'var(--green-100)',
      fg: 'var(--green-600)'
    },
    purple: {
      bg: 'var(--purple-100)',
      fg: 'var(--purple-500)'
    },
    red: {
      bg: 'var(--red-100)',
      fg: 'var(--red-500)'
    }
  };
  const t = tints[tint] || tints.blue;
  return React.createElement('div', {
    style: {
      width: size,
      height: size,
      borderRadius: 'var(--radius-chip)',
      background: t.bg,
      color: t.fg,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      flexShrink: 0
    }
  }, icon);
}
Object.assign(__ds_scope, { IconChip });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/IconChip.jsx", error: String((e && e.message) || e) }); }

// components/data-display/Avatar.jsx
try { (() => {
function Avatar({
  src,
  name,
  rank,
  size = 44
}) {
  const initials = (name || '').split(' ').map(w => w[0]).slice(0, 2).join('').toUpperCase();
  return React.createElement('div', {
    style: {
      position: 'relative',
      width: size,
      height: size
    }
  }, React.createElement('div', {
    style: {
      width: size,
      height: size,
      borderRadius: '50%',
      background: 'var(--blue-400)',
      color: '#fff',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      fontWeight: 700,
      fontSize: size * 0.36,
      overflow: 'hidden',
      border: rank === 1 ? '2px solid var(--amber-500)' : '2px solid #fff'
    }
  }, src ? React.createElement('img', {
    src,
    alt: name,
    style: {
      width: '100%',
      height: '100%',
      objectFit: 'cover'
    }
  }) : initials), rank === 1 && React.createElement('span', {
    style: {
      position: 'absolute',
      top: -14,
      left: '50%',
      transform: 'translateX(-50%)',
      fontSize: 14
    }
  }, '\u2605'));
}
Object.assign(__ds_scope, { Avatar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/data-display/Avatar.jsx", error: String((e && e.message) || e) }); }

// components/data-display/ListItemRow.jsx
try { (() => {
function ListItemRow({
  icon,
  title,
  subtitle,
  trailing,
  onClick
}) {
  return React.createElement('button', {
    onClick,
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      width: '100%',
      background: 'none',
      border: 'none',
      padding: '14px 4px',
      cursor: onClick ? 'pointer' : 'default',
      textAlign: 'left',
      fontFamily: 'var(--font-sans)'
    }
  }, icon, React.createElement('div', {
    style: {
      flex: 1,
      minWidth: 0
    }
  }, React.createElement('div', {
    style: {
      fontWeight: 700,
      fontSize: 15,
      color: 'var(--text-primary)'
    }
  }, title), subtitle && React.createElement('div', {
    style: {
      fontSize: 13,
      color: 'var(--text-secondary)',
      marginTop: 2
    }
  }, subtitle)), trailing !== undefined ? trailing : React.createElement('span', {
    style: {
      color: 'var(--text-tertiary)',
      fontSize: 18
    }
  }, '\u203A'));
}
Object.assign(__ds_scope, { ListItemRow });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/data-display/ListItemRow.jsx", error: String((e && e.message) || e) }); }

// components/data-display/StatRow.jsx
try { (() => {
function StatRow({
  stats
}) {
  return React.createElement('div', {
    style: {
      display: 'flex',
      background: 'var(--surface-sunken)',
      borderRadius: 'var(--radius-lg)',
      padding: '14px 0'
    }
  }, stats.map((s, i) => React.createElement('div', {
    key: i,
    style: {
      flex: 1,
      textAlign: 'center',
      borderLeft: i > 0 ? '1px solid var(--border-subtle)' : 'none'
    }
  }, s.icon && React.createElement('div', {
    style: {
      marginBottom: 4,
      display: 'flex',
      justifyContent: 'center',
      color: 'var(--text-secondary)'
    }
  }, s.icon), React.createElement('div', {
    style: {
      fontWeight: 800,
      fontSize: 17,
      color: 'var(--text-primary)'
    }
  }, s.value), React.createElement('div', {
    style: {
      fontSize: 11,
      color: 'var(--text-tertiary)',
      marginTop: 2
    }
  }, s.label))));
}
Object.assign(__ds_scope, { StatRow });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/data-display/StatRow.jsx", error: String((e && e.message) || e) }); }

// components/data-display/SubjectCard.jsx
try { (() => {
function SubjectCard({
  icon,
  title,
  subtitle,
  badgeText,
  code,
  onClick
}) {
  return React.createElement('button', {
    onClick,
    style: {
      textAlign: 'left',
      background: '#fff',
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--shadow-card)',
      border: 'none',
      cursor: 'pointer',
      padding: 16,
      display: 'flex',
      flexDirection: 'column',
      gap: 8,
      fontFamily: 'var(--font-sans)',
      position: 'relative',
      width: '100%'
    }
  }, code && React.createElement('span', {
    style: {
      position: 'absolute',
      top: 12,
      right: 14,
      fontSize: 11,
      color: 'var(--text-tertiary)'
    }
  }, code), icon, React.createElement('div', {
    style: {
      fontWeight: 700,
      fontSize: 15,
      color: 'var(--text-primary)'
    }
  }, title), subtitle && React.createElement('div', {
    style: {
      fontSize: 12,
      color: 'var(--text-secondary)'
    }
  }, subtitle), badgeText && React.createElement('span', {
    style: {
      fontSize: 11,
      fontWeight: 700,
      color: 'var(--green-600)',
      textTransform: 'uppercase'
    }
  }, badgeText));
}
Object.assign(__ds_scope, { SubjectCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/data-display/SubjectCard.jsx", error: String((e && e.message) || e) }); }

// components/feedback/Banner.jsx
try { (() => {
function Banner({
  tone = 'green',
  icon,
  children,
  action
}) {
  const tones = {
    green: {
      bg: 'var(--green-100)',
      fg: 'var(--green-600)'
    },
    blue: {
      bg: 'var(--blue-100)',
      fg: 'var(--blue-600)'
    }
  };
  const t = tones[tone] || tones.green;
  return React.createElement('div', {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10,
      background: t.bg,
      color: t.fg,
      borderRadius: 'var(--radius-lg)',
      padding: '12px 16px',
      fontSize: 13,
      fontWeight: 600
    }
  }, icon, React.createElement('span', {
    style: {
      flex: 1
    }
  }, children), action);
}
Object.assign(__ds_scope, { Banner });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/Banner.jsx", error: String((e && e.message) || e) }); }

// components/forms/SearchInput.jsx
try { (() => {
function SearchInput({
  placeholder,
  value,
  onChange,
  icon
}) {
  return React.createElement('div', {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10,
      background: 'var(--surface-card)',
      border: '1px solid var(--border-subtle)',
      borderRadius: 'var(--radius-pill)',
      padding: '12px 18px'
    }
  }, icon || React.createElement('svg', {
    width: 16,
    height: 16,
    viewBox: '0 0 24 24',
    fill: 'none',
    stroke: 'var(--text-tertiary)',
    strokeWidth: 2
  }, React.createElement('circle', {
    cx: 11,
    cy: 11,
    r: 7
  }), React.createElement('line', {
    x1: 21,
    y1: 21,
    x2: 16.65,
    y2: 16.65
  })), React.createElement('input', {
    placeholder,
    value,
    onChange: e => onChange && onChange(e.target.value),
    style: {
      border: 'none',
      outline: 'none',
      flex: 1,
      fontFamily: 'var(--font-sans)',
      fontSize: 14,
      color: 'var(--text-primary)',
      background: 'transparent'
    }
  }));
}
Object.assign(__ds_scope, { SearchInput });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/SearchInput.jsx", error: String((e && e.message) || e) }); }

// components/forms/Toggle.jsx
try { (() => {
function Toggle({
  checked,
  onChange,
  disabled
}) {
  return React.createElement('button', {
    onClick: () => !disabled && onChange(!checked),
    style: {
      width: 44,
      height: 26,
      borderRadius: 'var(--radius-pill)',
      border: 'none',
      cursor: disabled ? 'default' : 'pointer',
      background: checked ? 'var(--green-500)' : '#DADEE8',
      position: 'relative',
      transition: 'background .15s ease',
      opacity: disabled ? 0.5 : 1,
      padding: 0
    }
  }, React.createElement('span', {
    style: {
      position: 'absolute',
      top: 3,
      left: checked ? 21 : 3,
      width: 20,
      height: 20,
      borderRadius: '50%',
      background: '#fff',
      boxShadow: '0 1px 3px rgba(0,0,0,0.2)',
      transition: 'left .15s ease'
    }
  }));
}
Object.assign(__ds_scope, { Toggle });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Toggle.jsx", error: String((e && e.message) || e) }); }

// components/navigation/BottomNav.jsx
try { (() => {
function BottomNav({
  items,
  active,
  onChange
}) {
  return React.createElement('div', {
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      background: '#fff',
      borderTop: '1px solid var(--border-subtle)',
      padding: '10px 18px 14px'
    }
  }, items.map((it, i) => {
    const isActive = i === active;
    const isCenter = it.center;
    if (isCenter) {
      return React.createElement('button', {
        key: i,
        onClick: () => onChange(i),
        style: {
          width: 52,
          height: 52,
          borderRadius: 'var(--radius-lg)',
          background: 'var(--gradient-bot)',
          border: 'none',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          boxShadow: 'var(--shadow-button)',
          cursor: 'pointer',
          marginTop: -24
        }
      }, it.icon);
    }
    return React.createElement('button', {
      key: i,
      onClick: () => onChange(i),
      style: {
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        gap: 3,
        background: 'none',
        border: 'none',
        cursor: 'pointer',
        color: isActive ? 'var(--blue-600)' : 'var(--text-tertiary)',
        fontSize: 11,
        fontWeight: 600,
        fontFamily: 'var(--font-sans)'
      }
    }, it.icon, it.label);
  }));
}
Object.assign(__ds_scope, { BottomNav });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/navigation/BottomNav.jsx", error: String((e && e.message) || e) }); }

// components/navigation/SegmentedTabs.jsx
try { (() => {
function SegmentedTabs({
  options,
  active,
  onChange
}) {
  return React.createElement('div', {
    style: {
      display: 'flex',
      gap: 8,
      overflowX: 'auto'
    }
  }, options.map((opt, i) => React.createElement('button', {
    key: opt,
    onClick: () => onChange(i),
    style: {
      flexShrink: 0,
      padding: '8px 16px',
      borderRadius: 'var(--radius-pill)',
      border: 'none',
      cursor: 'pointer',
      fontFamily: 'var(--font-sans)',
      fontSize: 13,
      fontWeight: 600,
      background: i === active ? 'var(--navy-900)' : 'var(--surface-card)',
      color: i === active ? '#fff' : 'var(--text-secondary)',
      boxShadow: i === active ? 'none' : 'var(--shadow-card)'
    }
  }, opt)));
}
Object.assign(__ds_scope, { SegmentedTabs });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/navigation/SegmentedTabs.jsx", error: String((e && e.message) || e) }); }

// ui_kits/spekooh-app/AIAssistant.jsx
try { (() => {
function AIAssistant() {
  const Ic = window.Ic;
  const [open, setOpen] = React.useState(false);
  const prompts = ['Explain a hard Physics topic', 'Give me 5 Maths practice questions', 'Summarize this paper\u2019s marking guide'];
  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("button", {
    onClick: () => setOpen(true),
    style: {
      position: 'absolute',
      right: 16,
      bottom: 96,
      width: 52,
      height: 52,
      borderRadius: 16,
      background: 'var(--gradient-primary)',
      border: 'none',
      boxShadow: 'var(--shadow-button)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      cursor: 'pointer',
      zIndex: 8
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: "sparkles",
    size: 22,
    style: {
      color: '#fff'
    }
  })), open && /*#__PURE__*/React.createElement("div", {
    onClick: () => setOpen(false),
    style: {
      position: 'absolute',
      inset: 0,
      background: 'rgba(36,26,8,0.45)',
      backdropFilter: 'blur(2px)',
      display: 'flex',
      alignItems: 'flex-end',
      zIndex: 12
    }
  }, /*#__PURE__*/React.createElement("div", {
    onClick: e => e.stopPropagation(),
    style: {
      background: '#fff',
      width: '100%',
      borderRadius: '26px 26px 0 0',
      padding: '10px 20px 24px',
      maxHeight: '70%',
      display: 'flex',
      flexDirection: 'column'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 40,
      height: 4,
      borderRadius: 2,
      background: 'var(--border-subtle)',
      margin: '0 auto 14px'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 36,
      height: 36,
      borderRadius: 12,
      background: 'var(--gradient-primary)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center'
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: "sparkles",
    size: 16,
    style: {
      color: '#fff'
    }
  })), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 800,
      fontSize: 15,
      color: 'var(--text-primary)'
    }
  }, "Spekooh Assistant"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 11,
      color: 'var(--text-secondary)'
    }
  }, "Explains topics using real past papers"))), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      overflowY: 'auto',
      marginTop: 14,
      display: 'flex',
      flexDirection: 'column',
      gap: 8
    }
  }, prompts.map(p => /*#__PURE__*/React.createElement("button", {
    key: p,
    style: {
      textAlign: 'left',
      background: 'var(--surface-sunken)',
      border: '1px solid var(--border-subtle)',
      borderRadius: 'var(--radius-md)',
      padding: '12px 14px',
      fontSize: 13,
      color: 'var(--text-primary)',
      cursor: 'pointer'
    }
  }, p))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 8,
      marginTop: 12,
      alignItems: 'center',
      background: 'var(--surface-sunken)',
      border: '1px solid var(--border-subtle)',
      borderRadius: 999,
      padding: '10px 14px'
    }
  }, /*#__PURE__*/React.createElement("input", {
    placeholder: "Ask about a topic or paper...",
    style: {
      border: 'none',
      outline: 'none',
      flex: 1,
      fontSize: 13,
      background: 'transparent'
    }
  }), /*#__PURE__*/React.createElement(Ic, {
    name: "send",
    size: 16,
    style: {
      color: 'var(--gold-700)'
    }
  })))));
}
window.AIAssistant = AIAssistant;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/spekooh-app/AIAssistant.jsx", error: String((e && e.message) || e) }); }

// ui_kits/spekooh-app/ForumScreen.jsx
try { (() => {
function ForumScreen() {
  const {
    Badge,
    Button
  } = window.KawloSpekoohDesignSystem_10ffa8;
  const Ic = window.Ic;
  const posts = [{
    name: 'The Situation',
    time: '06/06/2026',
    tag: 'Just to Chat',
    title: 'Rescheduling of Baccalauréat 2026',
    body: 'The official press release shared by the Ministry regarding the new exam calendar for both systems…',
    up: 8,
    ans: 180
  }, {
    name: 'Chi Emmanuel',
    time: '2h ago',
    tag: 'Religious Studies',
    title: 'Public Ministry',
    body: 'Give an account of Peter\u2019s confession of Faith as you read Luke 9:18-22 and elaborate more on the story…',
    up: 0,
    ans: 13
  }, {
    name: 'Aïcha N.',
    time: '3h ago',
    tag: 'Philosophie',
    title: 'Dissertation — la liberté',
    body: 'Quelqu\u2019un a-t-il un plan pour ce sujet de dissertation du Probatoire 2024 ?',
    up: 2,
    ans: 21
  }];
  return /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      overflowY: 'auto',
      padding: '0 18px 90px',
      position: 'relative'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center',
      marginTop: 10
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 800,
      fontSize: 20,
      color: 'var(--text-primary)'
    }
  }, "Forum"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 10
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: "search"
  }), /*#__PURE__*/React.createElement(Ic, {
    name: "bell"
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 8,
      marginTop: 12,
      overflowX: 'auto'
    }
  }, ['All', 'My subjects', 'Unanswered', 'Solved'].map((t, i) => /*#__PURE__*/React.createElement("span", {
    key: t,
    style: {
      flexShrink: 0,
      padding: '7px 14px',
      borderRadius: 999,
      fontSize: 12,
      fontWeight: 700,
      background: i === 0 ? 'var(--ink-900)' : '#fff',
      color: i === 0 ? '#fff' : 'var(--text-secondary)',
      boxShadow: i === 0 ? 'none' : 'var(--shadow-card)'
    }
  }, t))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 14,
      display: 'flex',
      flexDirection: 'column',
      gap: 10
    }
  }, posts.map((p, i) => /*#__PURE__*/React.createElement("div", {
    key: i,
    style: {
      background: '#fff',
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--shadow-card)',
      padding: 14
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 8,
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 28,
      height: 28,
      borderRadius: '50%',
      background: 'var(--gold-200)'
    }
  }), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      fontWeight: 700,
      color: 'var(--text-primary)'
    }
  }, p.name), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 10,
      color: 'var(--text-tertiary)'
    }
  }, p.time))), /*#__PURE__*/React.createElement(Badge, {
    tone: "blue"
  }, p.tag)), /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 700,
      fontSize: 14,
      marginTop: 8,
      color: 'var(--text-primary)'
    }
  }, p.title), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      color: 'var(--text-secondary)',
      marginTop: 2
    }
  }, p.body), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 14,
      marginTop: 8,
      fontSize: 12,
      color: 'var(--text-tertiary)',
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement("span", null, '\u2191', " ", p.up), /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 4
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: "message-circle",
    size: 14
  }), p.ans, " answers"))))), /*#__PURE__*/React.createElement("button", {
    style: {
      position: 'absolute',
      bottom: 24,
      right: 18,
      background: 'var(--gradient-primary)',
      color: '#fff',
      border: 'none',
      borderRadius: 999,
      padding: '13px 22px',
      fontWeight: 700,
      fontSize: 14,
      boxShadow: 'var(--shadow-button)'
    }
  }, "+ Ask"));
}
window.ForumScreen = ForumScreen;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/spekooh-app/ForumScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/spekooh-app/HomeScreen.jsx
try { (() => {
function HomeScreen({
  onOpenPaywall,
  onOpenSettings,
  onOpenPaper,
  onOpenPamphlet,
  onOpenProfile,
  onOpenNotes,
  onOpenShop
}) {
  const {
    Button,
    Badge,
    IconChip,
    Banner
  } = window.KawloSpekoohDesignSystem_10ffa8;
  const Ic = window.Ic;
  return /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      overflowY: 'auto',
      padding: '0 18px 90px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center',
      marginTop: 6
    }
  }, /*#__PURE__*/React.createElement("div", {
    onClick: onOpenProfile,
    style: {
      cursor: 'pointer',
      display: 'flex',
      alignItems: 'center',
      gap: 10
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 38,
      height: 38,
      borderRadius: '50%',
      background: 'var(--gold-200)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      fontWeight: 800,
      color: 'var(--gold-700)'
    }
  }, "G"), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      color: 'var(--text-secondary)'
    }
  }, "Bienvenue \xB7 Welcome"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 16,
      fontWeight: 800,
      color: 'var(--text-primary)'
    }
  }, "Guest"))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 8,
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement(Button, {
    variant: "secondary",
    size: "sm"
  }, "Join free"), /*#__PURE__*/React.createElement("button", {
    onClick: onOpenSettings,
    style: {
      width: 38,
      height: 38,
      borderRadius: '50%',
      border: '1px solid var(--border-subtle)',
      background: '#fff',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      cursor: 'pointer'
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: "settings"
  })))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 12,
      display: 'flex',
      gap: 6
    }
  }, /*#__PURE__*/React.createElement(Badge, {
    tone: "neutral"
  }, "Exploring \u2014 no account"), /*#__PURE__*/React.createElement(Badge, {
    tone: "blue"
  }, "EN / FR")), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 14,
      background: 'var(--ink-900)',
      borderRadius: 'var(--radius-lg)',
      padding: 16,
      color: '#fff'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      color: 'var(--text-on-dark-muted)',
      fontWeight: 700,
      letterSpacing: '0.04em',
      textTransform: 'uppercase'
    }
  }, "Free paper views today"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'baseline',
      gap: 6,
      marginTop: 4
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontWeight: 800,
      fontSize: 24
    }
  }, "2"), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 13,
      color: 'var(--text-on-dark-muted)'
    }
  }, "of 3 used")), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      color: 'var(--text-on-dark-muted)',
      marginTop: 6
    }
  }, "Watch an ad for 1 more, or go Pro for unlimited views."), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 8,
      marginTop: 10
    }
  }, /*#__PURE__*/React.createElement("button", {
    style: {
      flex: 1,
      background: 'rgba(255,255,255,0.14)',
      color: '#fff',
      border: 'none',
      borderRadius: 999,
      padding: '10px',
      fontWeight: 700,
      fontSize: 13,
      cursor: 'pointer'
    }
  }, "Watch ad"), /*#__PURE__*/React.createElement("button", {
    onClick: onOpenPaywall,
    style: {
      flex: 1,
      background: 'var(--gradient-primary)',
      color: '#fff',
      border: 'none',
      borderRadius: 999,
      padding: '10px',
      fontWeight: 700,
      fontSize: 13,
      cursor: 'pointer'
    }
  }, "Go Pro"))), /*#__PURE__*/React.createElement("div", {
    onClick: onOpenPaper,
    style: {
      marginTop: 14,
      background: '#fff',
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--shadow-card)',
      padding: 14,
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      cursor: 'pointer'
    }
  }, /*#__PURE__*/React.createElement(IconChip, {
    tint: "purple",
    icon: /*#__PURE__*/React.createElement(Ic, {
      name: "sigma"
    })
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 700,
      fontSize: 14,
      color: 'var(--text-primary)'
    }
  }, "Math\xE9matiques \xB7 Baccalaur\xE9at 2025"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      color: 'var(--text-secondary)',
      marginTop: 2
    }
  }, "Free to view \u2014 marking guide sold separately")), /*#__PURE__*/React.createElement(Ic, {
    name: "chevron-right"
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 22,
      fontWeight: 800,
      fontSize: 17,
      color: 'var(--text-primary)'
    }
  }, "Contribution \u2014 earn credit"), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 10,
      background: '#fff',
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--shadow-card)',
      padding: 14,
      display: 'flex',
      gap: 12,
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement(IconChip, {
    tint: "amber",
    icon: /*#__PURE__*/React.createElement(Ic, {
      name: "upload"
    }),
    size: 48
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 700,
      fontSize: 14,
      color: 'var(--text-primary)'
    }
  }, "Got a past paper or report we don't have?"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      color: 'var(--text-secondary)',
      marginTop: 2
    }
  }, "Snap a photo, tag it, earn bonus credit once it's verified \u2014 first contribution counts."))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: '1fr 1fr',
      gap: 10,
      marginTop: 20
    }
  }, /*#__PURE__*/React.createElement("div", {
    onClick: onOpenNotes,
    style: {
      background: '#fff',
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--shadow-card)',
      padding: 14,
      display: 'flex',
      flexDirection: 'column',
      gap: 8,
      cursor: 'pointer'
    }
  }, /*#__PURE__*/React.createElement(IconChip, {
    tint: "green",
    icon: /*#__PURE__*/React.createElement(Ic, {
      name: "book-open"
    }),
    size: 40
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 700,
      fontSize: 14,
      color: 'var(--text-primary)'
    }
  }, "Notes"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 11,
      color: 'var(--text-secondary)'
    }
  }, "Topic study notes by subject")), /*#__PURE__*/React.createElement("div", {
    onClick: onOpenShop,
    style: {
      background: '#fff',
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--shadow-card)',
      padding: 14,
      display: 'flex',
      flexDirection: 'column',
      gap: 8,
      cursor: 'pointer'
    }
  }, /*#__PURE__*/React.createElement(IconChip, {
    tint: "amber",
    icon: /*#__PURE__*/React.createElement(Ic, {
      name: "shopping-bag"
    }),
    size: 40
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 700,
      fontSize: 14,
      color: 'var(--text-primary)'
    }
  }, "Shop"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 11,
      color: 'var(--text-secondary)'
    }
  }, "Partner pamphlets, QR pickup"))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'baseline',
      marginTop: 22
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 800,
      fontSize: 17,
      color: 'var(--text-primary)'
    }
  }, "Partner pamphlets"), /*#__PURE__*/React.createElement("span", {
    onClick: onOpenShop,
    style: {
      fontSize: 13,
      fontWeight: 700,
      color: 'var(--gold-700)',
      cursor: 'pointer'
    }
  }, "Shop")), /*#__PURE__*/React.createElement("div", {
    onClick: onOpenPamphlet,
    style: {
      marginTop: 10,
      background: '#fff',
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--shadow-card)',
      padding: 14,
      display: 'flex',
      gap: 12,
      alignItems: 'center',
      cursor: 'pointer'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 64,
      height: 64,
      borderRadius: 10,
      background: 'var(--gradient-gold-deep)',
      flexShrink: 0
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 700,
      fontSize: 14,
      color: 'var(--text-primary)'
    }
  }, "Probatoire Philosophy Pamphlet"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      color: 'var(--text-secondary)',
      marginTop: 2
    }
  }, "Sold by Librairie Centrale \xB7 pick up with a QR code."), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 8,
      display: 'flex',
      alignItems: 'center',
      gap: 8
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontWeight: 800,
      color: 'var(--text-primary)'
    }
  }, "7,500 ", /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 11,
      color: 'var(--text-tertiary)',
      fontWeight: 600
    }
  }, "FCFA")), /*#__PURE__*/React.createElement(Button, {
    variant: "primary",
    size: "sm"
  }, "Buy")))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 22,
      fontSize: 12,
      color: 'var(--text-tertiary)',
      fontWeight: 700,
      letterSpacing: '0.05em',
      textTransform: 'uppercase'
    }
  }, "Sign up only when you want to\u2026"), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 10,
      background: '#fff',
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--shadow-card)',
      padding: '2px 16px'
    }
  }, [['flame', 'Earn & redeem contributor credits'], ['file-check', 'Track your contributions'], ['bell', 'Get instructor status alerts'], ['download', 'Sync downloads across phones']].map(([icon, label], i) => /*#__PURE__*/React.createElement("div", {
    key: label,
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      padding: '12px 0',
      borderTop: i > 0 ? '1px solid var(--border-subtle)' : 'none'
    }
  }, /*#__PURE__*/React.createElement(IconChip, {
    tint: "blue",
    icon: /*#__PURE__*/React.createElement(Ic, {
      name: icon
    }),
    size: 36
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      fontSize: 14,
      fontWeight: 600,
      color: 'var(--text-primary)'
    }
  }, label), /*#__PURE__*/React.createElement(Ic, {
    name: "lock",
    size: 16
  })))), /*#__PURE__*/React.createElement("div", {
    style: {
      textAlign: 'center',
      fontSize: 12,
      color: 'var(--text-secondary)',
      marginTop: 14,
      lineHeight: 1.5
    }
  }, "Reading papers stays open to everyone \u2014 3 free views a day, no account needed."));
}
window.HomeScreen = HomeScreen;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/spekooh-app/HomeScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/spekooh-app/IconLucide.jsx
try { (() => {
function Ic({
  name,
  size = 18,
  style
}) {
  const pascal = name.replace(/(^\w|-\w)/g, m => m.replace('-', '').toUpperCase());
  const nodes = window.lucide && window.lucide.icons && window.lucide.icons[pascal] || [];
  const children = nodes.map((n, i) => React.createElement(n[0], {
    key: i,
    ...n[1]
  }));
  return React.createElement('svg', {
    width: size,
    height: size,
    viewBox: '0 0 24 24',
    fill: 'none',
    stroke: 'currentColor',
    strokeWidth: 2,
    strokeLinecap: 'round',
    strokeLinejoin: 'round',
    style: {
      flexShrink: 0,
      ...style
    }
  }, children);
}
window.Ic = Ic;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/spekooh-app/IconLucide.jsx", error: String((e && e.message) || e) }); }

// ui_kits/spekooh-app/LoggedInHomeScreen.jsx
try { (() => {
function LoggedInHomeScreen({
  onOpenSettings,
  onOpenPaper,
  onOpenSubmit,
  onOpenNotifications,
  onOpenProfile,
  onOpenNotes,
  onOpenShop
}) {
  const {
    Badge
  } = window.KawloSpekoohDesignSystem_10ffa8;
  const Ic = window.Ic;
  return /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      overflowY: 'auto',
      padding: '0 18px 90px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      background: 'var(--ink-900)',
      margin: '-1px -18px 0',
      padding: '18px 18px 40px',
      borderRadius: '0 0 32px 32px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement("div", {
    onClick: onOpenProfile,
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10,
      cursor: 'pointer'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 38,
      height: 38,
      borderRadius: '50%',
      background: 'var(--gold-200)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      fontWeight: 800,
      color: 'var(--gold-700)'
    }
  }, "K"), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      color: 'var(--text-on-dark-muted)'
    }
  }, "Good morning"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 15,
      fontWeight: 800,
      color: '#fff'
    }
  }, "Kkk"))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 8,
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      background: 'rgba(255,255,255,0.12)',
      borderRadius: 999,
      padding: 2
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      padding: '5px 10px',
      borderRadius: 999,
      fontSize: 11,
      fontWeight: 800,
      background: '#fff',
      color: 'var(--ink-900)'
    }
  }, "EN"), /*#__PURE__*/React.createElement("span", {
    style: {
      padding: '5px 10px',
      borderRadius: 999,
      fontSize: 11,
      fontWeight: 800,
      color: '#fff'
    }
  }, "FR")), /*#__PURE__*/React.createElement("button", {
    onClick: onOpenSettings,
    style: {
      width: 32,
      height: 32,
      borderRadius: '50%',
      border: 'none',
      background: 'rgba(255,255,255,0.12)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      cursor: 'pointer'
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: "settings",
    size: 15,
    style: {
      color: '#fff'
    }
  })), /*#__PURE__*/React.createElement("button", {
    onClick: onOpenNotifications,
    style: {
      width: 32,
      height: 32,
      borderRadius: '50%',
      border: 'none',
      background: 'rgba(255,255,255,0.12)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      cursor: 'pointer'
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: "bell",
    size: 15,
    style: {
      color: '#fff'
    }
  })))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 8,
      marginTop: 14
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      background: 'rgba(255,255,255,0.12)',
      color: '#fff',
      fontSize: 11,
      fontWeight: 700,
      padding: '6px 12px',
      borderRadius: 999
    }
  }, "GCE A LEVEL \xB7 SCIENCE"), /*#__PURE__*/React.createElement("span", {
    style: {
      background: 'var(--gold-500)',
      color: 'var(--ink-900)',
      fontSize: 11,
      fontWeight: 800,
      padding: '6px 12px',
      borderRadius: 999,
      display: 'flex',
      alignItems: 'center',
      gap: 4
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: "flame",
    size: 12
  }), "START A STREAK"))), /*#__PURE__*/React.createElement("div", {
    onClick: onOpenPaper,
    style: {
      marginTop: -24,
      background: '#fff',
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--shadow-card)',
      padding: 16,
      display: 'flex',
      gap: 12,
      alignItems: 'center',
      cursor: 'pointer'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 48,
      height: 48,
      borderRadius: '50%',
      border: '3px solid var(--green-500)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      flexShrink: 0
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: "target",
    size: 20,
    style: {
      color: 'var(--green-500)'
    }
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 11,
      fontWeight: 700,
      color: 'var(--green-600)',
      textTransform: 'uppercase',
      letterSpacing: '0.04em'
    }
  }, "Practice mode"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 800,
      fontSize: 15,
      color: 'var(--text-primary)',
      marginTop: 2
    }
  }, "Learn without countdown pressure"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      color: 'var(--text-secondary)',
      marginTop: 2
    }
  }, "Start with a paper, quiz, or ask the AI assistant something.")), /*#__PURE__*/React.createElement(Ic, {
    name: "chevron-right"
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 14,
      background: '#fff',
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--shadow-card)',
      padding: 16
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 11,
      fontWeight: 700,
      color: 'var(--gold-700)',
      textTransform: 'uppercase',
      letterSpacing: '0.04em'
    }
  }, "Your free trial"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'flex-start',
      marginTop: 4
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 10,
      alignItems: 'flex-start'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 22,
      height: 22,
      borderRadius: '50%',
      background: 'var(--gold-50)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      flexShrink: 0,
      marginTop: 2
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: "check",
    size: 12,
    style: {
      color: 'var(--gold-700)'
    }
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 800,
      fontSize: 14,
      color: 'var(--text-primary)'
    }
  }, "Open your first marking guide free")), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 11,
      fontWeight: 700,
      color: 'var(--text-secondary)',
      background: 'var(--surface-sunken)',
      padding: '4px 10px',
      borderRadius: 999,
      flexShrink: 0
    }
  }, "7 days left")), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      color: 'var(--text-secondary)',
      marginTop: 8
    }
  }, "Unlimited paper views \xB7 offline downloads \xB7 AI assistant"), /*#__PURE__*/React.createElement("button", {
    style: {
      width: '100%',
      marginTop: 10,
      background: 'var(--gradient-primary)',
      color: '#fff',
      fontWeight: 700,
      border: 'none',
      borderRadius: 999,
      padding: '13px',
      fontSize: 14,
      cursor: 'pointer'
    }
  }, "Keep my access")), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: 'repeat(3,1fr)',
      gap: 8,
      marginTop: 16
    }
  }, [['file-text', 'Papers', undefined], ['book-open', 'Notes', onOpenNotes], ['upload', 'Contribute', onOpenSubmit], ['shopping-bag', 'Shop', onOpenShop], ['message-circle', 'Forum', undefined], ['download', 'Offline', undefined]].map(([icon, label, fn]) => /*#__PURE__*/React.createElement("div", {
    key: label,
    onClick: fn,
    style: {
      background: '#fff',
      borderRadius: 'var(--radius-md)',
      boxShadow: 'var(--shadow-card)',
      padding: '12px 4px',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      gap: 6,
      cursor: fn ? 'pointer' : 'default'
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: icon,
    size: 18,
    style: {
      color: 'var(--gold-700)'
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 11,
      fontWeight: 700,
      color: 'var(--text-primary)'
    }
  }, label)))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 16,
      background: 'var(--ink-900)',
      borderRadius: 'var(--radius-lg)',
      padding: 16,
      display: 'flex',
      gap: 12,
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 800,
      fontSize: 13,
      color: '#fff'
    }
  }, "Daily challenge"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 11,
      color: 'var(--text-on-dark-muted)',
      marginTop: 2
    }
  }, "5-minute mixed quiz \xB7 earn +50 XP"), /*#__PURE__*/React.createElement("button", {
    style: {
      marginTop: 8,
      background: 'var(--gold-500)',
      color: 'var(--ink-900)',
      border: 'none',
      borderRadius: 999,
      padding: '8px 16px',
      fontWeight: 800,
      fontSize: 12,
      cursor: 'pointer'
    }
  }, "Play now")), /*#__PURE__*/React.createElement("div", {
    style: {
      width: 1,
      height: 44,
      background: 'rgba(255,255,255,0.15)'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      textAlign: 'center'
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: "flame",
    size: 22,
    style: {
      color: 'var(--gold-500)'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 800,
      fontSize: 13,
      color: '#fff',
      marginTop: 4
    }
  }, "Start"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 10,
      color: 'var(--text-on-dark-muted)'
    }
  }, "Play a quiz to begin"))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'baseline',
      marginTop: 20
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 800,
      fontSize: 15,
      color: 'var(--text-primary)'
    }
  }, "Ready offline"), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 12,
      fontWeight: 700,
      color: 'var(--gold-700)'
    }
  }, "Downloads \xB7 1")), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 8,
      background: '#fff',
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--shadow-card)',
      padding: 14,
      display: 'flex',
      alignItems: 'center',
      gap: 12
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 40,
      height: 40,
      borderRadius: 'var(--radius-chip)',
      background: 'var(--green-100)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center'
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: "download",
    size: 18,
    style: {
      color: 'var(--green-600)'
    }
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 700,
      fontSize: 13,
      color: 'var(--text-primary)'
    }
  }, "Biology O-Level marking guide"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 11,
      color: 'var(--green-600)',
      fontWeight: 700,
      marginTop: 2
    }
  }, "\u2713 OFFLINE READY")), /*#__PURE__*/React.createElement(Ic, {
    name: "chevron-right"
  })));
}
window.LoggedInHomeScreen = LoggedInHomeScreen;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/spekooh-app/LoggedInHomeScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/spekooh-app/NotesScreen.jsx
try { (() => {
function NotesScreen({
  onBack
}) {
  const {
    IconChip,
    SearchInput
  } = window.KawloSpekoohDesignSystem_10ffa8;
  const Ic = window.Ic;
  const notes = [['Mechanics — Newton\u2019s Laws', 'Physics · A Level', 'blue', 'atom'], ['Cell Structure & Function', 'Biology · O Level', 'green', 'leaf'], ['La Dissertation Philosophique', 'Philosophie · Baccalauréat', 'purple', 'book-open'], ['Acids, Bases & Salts', 'Chemistry · O Level', 'purple', 'flask-conical'], ['Les Nombres Complexes', 'Mathématiques · Terminale', 'blue', 'sigma']];
  return /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      overflowY: 'auto',
      padding: '0 18px 90px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10,
      marginTop: 10
    }
  }, /*#__PURE__*/React.createElement("button", {
    onClick: onBack,
    style: {
      width: 36,
      height: 36,
      borderRadius: '50%',
      border: '1px solid var(--border-subtle)',
      background: '#fff'
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: "chevron-left"
  })), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 800,
      fontSize: 19,
      color: 'var(--text-primary)'
    }
  }, "Notes"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      color: 'var(--text-secondary)'
    }
  }, "Topic study notes, contributed alongside papers"))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 14
    }
  }, /*#__PURE__*/React.createElement(SearchInput, {
    placeholder: "Search topics..."
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 14,
      display: 'flex',
      flexDirection: 'column',
      gap: 10
    }
  }, notes.map(([title, sub, tint, icon]) => /*#__PURE__*/React.createElement("div", {
    key: title,
    style: {
      background: '#fff',
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--shadow-card)',
      padding: 14,
      display: 'flex',
      alignItems: 'center',
      gap: 12
    }
  }, /*#__PURE__*/React.createElement(IconChip, {
    tint: tint,
    icon: /*#__PURE__*/React.createElement(Ic, {
      name: icon
    })
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 700,
      fontSize: 14,
      color: 'var(--text-primary)'
    }
  }, title), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      color: 'var(--text-secondary)'
    }
  }, sub)), /*#__PURE__*/React.createElement(Ic, {
    name: "chevron-right"
  })))));
}
window.NotesScreen = NotesScreen;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/spekooh-app/NotesScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/spekooh-app/NotificationsScreen.jsx
try { (() => {
function NotificationsScreen({
  onBack
}) {
  const Ic = window.Ic;
  return /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      overflowY: 'auto',
      padding: '0 18px 90px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10,
      marginTop: 10
    }
  }, /*#__PURE__*/React.createElement("button", {
    onClick: onBack,
    style: {
      width: 36,
      height: 36,
      borderRadius: '50%',
      border: '1px solid var(--border-subtle)',
      background: '#fff'
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: "chevron-left"
  })), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 800,
      fontSize: 19,
      color: 'var(--text-primary)'
    }
  }, "Notifications"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      color: 'var(--text-secondary)'
    }
  }, "All caught up"))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 16,
      background: '#fff',
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--shadow-card)',
      padding: 14,
      display: 'flex',
      gap: 12,
      alignItems: 'flex-start'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 36,
      height: 36,
      borderRadius: 'var(--radius-chip)',
      background: 'var(--gold-50)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      flexShrink: 0
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: "sparkles",
    size: 16,
    style: {
      color: 'var(--gold-700)'
    }
  })), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 700,
      fontSize: 13,
      color: 'var(--text-primary)'
    }
  }, "Welcome to Spekooh \uD83C\uDF89"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      color: 'var(--text-secondary)',
      marginTop: 2
    }
  }, "You've got 7 days free: all marking guides, unlimited AI assistant and downloads."), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 11,
      color: 'var(--text-tertiary)',
      marginTop: 4
    }
  }, "12 min ago"))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 10,
      background: '#fff',
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--shadow-card)',
      padding: 14,
      display: 'flex',
      gap: 12,
      alignItems: 'flex-start'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 36,
      height: 36,
      borderRadius: 'var(--radius-chip)',
      background: 'var(--green-100)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      flexShrink: 0
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: "check",
    size: 16,
    style: {
      color: 'var(--green-600)'
    }
  })), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 700,
      fontSize: 13,
      color: 'var(--text-primary)'
    }
  }, "Physics paper published"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      color: 'var(--text-secondary)',
      marginTop: 2
    }
  }, "Your submission's marking guide is live \u2014 you earned 150 credits."), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 11,
      color: 'var(--text-tertiary)',
      marginTop: 4
    }
  }, "1 day ago"))));
}
window.NotificationsScreen = NotificationsScreen;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/spekooh-app/NotificationsScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/spekooh-app/PamphletSheet.jsx
try { (() => {
function PamphletSheet({
  onClose
}) {
  const {
    Button
  } = window.KawloSpekoohDesignSystem_10ffa8;
  const Ic = window.Ic;
  const [paid, setPaid] = React.useState(false);
  return /*#__PURE__*/React.createElement("div", {
    onClick: onClose,
    style: {
      position: 'absolute',
      inset: 0,
      background: 'rgba(36,26,8,0.45)',
      backdropFilter: 'blur(2px)',
      display: 'flex',
      alignItems: 'flex-end',
      zIndex: 10
    }
  }, /*#__PURE__*/React.createElement("div", {
    onClick: e => e.stopPropagation(),
    style: {
      background: '#fff',
      width: '100%',
      borderRadius: '26px 26px 0 0',
      padding: '10px 22px 26px',
      boxShadow: 'var(--shadow-sheet)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 40,
      height: 4,
      borderRadius: 2,
      background: 'var(--border-subtle)',
      margin: '0 auto 16px'
    }
  }), !paid ? /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 12,
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 56,
      height: 56,
      borderRadius: 12,
      background: 'var(--gradient-gold-deep)',
      flexShrink: 0
    }
  }), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 800,
      fontSize: 16,
      color: 'var(--text-primary)'
    }
  }, "Probatoire Philosophy Pamphlet"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      color: 'var(--text-secondary)',
      marginTop: 2
    }
  }, "Sold by Librairie Centrale"))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 14,
      fontSize: 12,
      color: 'var(--text-secondary)',
      lineHeight: 1.5
    }
  }, "Spekooh holds your payment in escrow. You'll get a one-time QR ticket to collect it at the bookshop \u2014 payment only releases to the partner once they scan it."), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 14,
      border: '1.5px solid var(--gold-400)',
      borderRadius: 'var(--radius-lg)',
      padding: '12px 16px',
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 11,
      fontWeight: 800,
      color: 'var(--text-secondary)',
      letterSpacing: '0.04em'
    }
  }, "PICKUP \xB7 IN-STORE"), /*#__PURE__*/React.createElement("span", {
    style: {
      fontWeight: 800,
      fontSize: 17,
      color: 'var(--text-primary)'
    }
  }, "7,500 ", /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 11,
      color: 'var(--text-tertiary)',
      fontWeight: 600
    }
  }, "FCFA"))), /*#__PURE__*/React.createElement(Button, {
    variant: "primary",
    style: {
      width: '100%',
      marginTop: 14
    },
    onClick: () => setPaid(true)
  }, "Pay & reserve \u2014 7,500 FCFA"), /*#__PURE__*/React.createElement("div", {
    style: {
      textAlign: 'center',
      fontSize: 11,
      color: 'var(--text-tertiary)',
      marginTop: 10
    }
  }, "Held in escrow \xB7 released to partner only after pickup is confirmed \xB7 5% platform commission")) : /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      gap: 10,
      textAlign: 'center',
      padding: '6px 0 4px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 150,
      height: 150,
      background: 'repeating-linear-gradient(45deg,var(--ink-900) 0 6px,#fff 6px 12px)',
      borderRadius: 12
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 800,
      fontSize: 16,
      color: 'var(--text-primary)'
    }
  }, "Pickup ticket ready"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      color: 'var(--text-secondary)',
      maxWidth: 260
    }
  }, "Show this QR at Librairie Centrale. Single-use \u2014 expires in 30 days. Payment releases to the partner once they scan it."), /*#__PURE__*/React.createElement(Button, {
    variant: "secondary",
    onClick: onClose
  }, "Done"))));
}
window.PamphletSheet = PamphletSheet;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/spekooh-app/PamphletSheet.jsx", error: String((e && e.message) || e) }); }

// ui_kits/spekooh-app/PaperDetailScreen.jsx
try { (() => {
function PaperDetailScreen({
  onBack,
  paper
}) {
  const {
    Button,
    StatRow,
    Badge
  } = window.KawloSpekoohDesignSystem_10ffa8;
  const Ic = window.Ic;
  const [unlocked, setUnlocked] = React.useState(false);
  const title = paper ? `${paper.subject.title} — ${paper.examType}${paper.track ? ' ' + paper.track : ''} ${paper.year}` : 'Physics — A Level 2025';
  const meta = paper ? [paper.cat && paper.cat.charAt(0).toUpperCase() + paper.cat.slice(1), paper.system].filter(Boolean).join(' · ') : 'Secondary · Anglophone';
  return /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      overflowY: 'auto',
      padding: '0 18px 90px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10,
      marginTop: 10
    }
  }, /*#__PURE__*/React.createElement("button", {
    onClick: onBack,
    style: {
      background: 'none',
      border: 'none',
      cursor: 'pointer'
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: "chevron-left"
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 800,
      fontSize: 16,
      color: 'var(--text-primary)'
    }
  }, title), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 11,
      color: 'var(--text-secondary)',
      marginTop: 2
    }
  }, meta)), paper && /*#__PURE__*/React.createElement(Badge, {
    tone: "neutral"
  }, paper.variant)), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 14,
      background: '#fff',
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--shadow-card)',
      padding: 16,
      minHeight: 220,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      color: 'var(--text-tertiary)',
      fontSize: 13
    }
  }, "Question paper preview (scanned pages)"), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 12
    }
  }, /*#__PURE__*/React.createElement(StatRow, {
    stats: [{
      value: 8,
      label: 'questions'
    }, {
      value: 2,
      label: 'MCQ (in-house key)'
    }, {
      value: '2,341',
      label: 'views'
    }]
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 16,
      background: '#fff',
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--shadow-card)',
      padding: 16
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 700,
      fontSize: 14,
      color: 'var(--text-primary)'
    }
  }, "Marking guide"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      color: 'var(--text-secondary)',
      marginTop: 2
    }
  }, "Instructor-authored + in-house MCQ key")), /*#__PURE__*/React.createElement(Ic, {
    name: unlocked ? 'lock-open' : 'lock',
    size: 18
  })), unlocked ? /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 12,
      fontSize: 13,
      color: 'var(--green-600)',
      fontWeight: 600
    }
  }, "Unlocked \u2014 full solutions below.") : /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 12,
      display: 'flex',
      gap: 8,
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement(Button, {
    variant: "primary",
    size: "sm",
    onClick: () => setUnlocked(true)
  }, "Unlock \u2014 400 FCFA"), /*#__PURE__*/React.createElement("button", {
    style: {
      background: 'none',
      border: 'none',
      color: 'var(--gold-700)',
      fontWeight: 700,
      fontSize: 12,
      cursor: 'pointer'
    }
  }, "Have a redeem code?"))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 14,
      display: 'flex',
      alignItems: 'center',
      gap: 10,
      background: 'var(--gold-50)',
      borderRadius: 'var(--radius-lg)',
      padding: '12px 14px'
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: "info",
    size: 18,
    style: {
      color: 'var(--gold-700)'
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 12,
      color: 'var(--gold-700)',
      fontWeight: 600,
      flex: 1
    }
  }, "Objective/MCQ answers are marked in-house by the Spekooh review team, not the instructor.")));
}
window.PaperDetailScreen = PaperDetailScreen;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/spekooh-app/PaperDetailScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/spekooh-app/PapersScreen.jsx
try { (() => {
function PapersScreen({
  onOpenPaper
}) {
  const {
    SegmentedTabs,
    SubjectCard,
    SearchInput,
    IconChip,
    Badge
  } = window.KawloSpekoohDesignSystem_10ffa8;
  const [cat, setCat] = React.useState(null);
  const [system, setSystem] = React.useState(null);
  const [examType, setExamType] = React.useState(null);
  const [track, setTrack] = React.useState(null);
  const [subject, setSubject] = React.useState(null);
  const [tab, setTab] = React.useState(0);
  const [q, setQ] = React.useState('');
  const [showFilter, setShowFilter] = React.useState(false);
  const Ic = window.Ic;
  const categories = [['primary', 'Primary', 'blue', 'baby', 'FSLC · CEP · Common Entrance'], ['secondary', 'Secondary', 'amber', 'graduation-cap', 'BEPC · Probatoire · Bac · O/A Level'], ['university', 'University', 'blue', 'landmark', 'Semester exams · Resits — State & Private'], ['tertiary', 'Tertiary', 'green', 'building-2', 'HND · BTS · AQP/CQP/DQP'], ['concours', 'Concours', 'purple', 'award', 'ENAM · ENSP · UCAC · ESSEC & more'], ['reports', 'Academic Reports', 'red', 'book-open', 'Internship · Mémoire · Thèse — no marking guide']];
  const examTypesByCat = {
    primary: [['FSLC', 'Anglophone', 'blue'], ['Common Entrance', 'Anglophone', 'blue'], ['CEP', 'Francophone', 'amber'], ['Concours d\u2019Entrée en 6ème', 'Francophone', 'amber']],
    secondaryFrancophone: [['BEPC', '+ BEPC Blanc · Général/Technique', 'amber'], ['Probatoire', '+ Probatoire Blanc · Général/Technique', 'amber'], ['Baccalauréat', '+ Bac Blanc · Général/Technique', 'amber']],
    secondaryAnglophone: [['O Level', '+ O Level Mock · General only', 'blue'], ['A Level', '+ A Level Mock · Sci/Arts/Comm/Tech', 'blue']],
    universityFrancophone: [['Examen Semestre 1', '1er semestre, tous niveaux', 'amber'], ['Examen Semestre 2', '2nd semestre, tous niveaux', 'amber'], ['Rattrapage', 'Session de rattrapage', 'amber']],
    universityAnglophone: [['Semester 1 Exam', '1st semester, all levels', 'blue'], ['Semester 2 Exam', '2nd semester, all levels', 'blue'], ['Resit / Makeup', 'Resit sittings', 'blue']],
    tertiary: [['HND', 'Anglophone', 'blue'], ['BTS', 'Francophone', 'amber'], ['AQP', 'Vocational training center', 'green'], ['CQP', 'Vocational training center', 'green'], ['DQP', 'Vocational training center', 'green']],
    concours: [['ENAM', 'École Nat. d\u2019Administration', 'purple'], ['ENSP', 'Polytechnique Yaoundé/Bamenda', 'purple'], ['ESSEC', 'Douala / Garoua', 'purple'], ['UCAC', 'Univ. Catholique d\u2019Afrique Centrale', 'purple'], ['IUT', 'Douala, Ngaoundéré & more', 'purple'], ['FMSB', 'Médecine / Pharmacie', 'purple'], ['ENS', 'Yaoundé / Bambili / Maroua', 'purple'], ['IAI', 'Institut Africain d\u2019Informatique', 'purple'], ['ESSTIC', 'Info & Communication', 'purple'], ['EMIA', 'Officer entrance', 'purple']]
  };
  const reportTypes = [['internship', 'Internship Report', 'HND / Bachelor / Master', 'blue'], ['bachelor', 'Bachelor\u2019s Report (Mémoire de Licence)', 'Bachelor / Licence', 'green'], ['hnd', 'HND Report', 'Rapport de fin d\u2019études', 'amber'], ['master', 'Master\u2019s Thesis (Mémoire)', 'Master', 'purple'], ['phd', 'PhD Thesis (Thèse)', 'Doctorat', 'red']];
  const variantByExam = {
    FSLC: null,
    'Common Entrance': null,
    CEP: null,
    'Concours d\u2019Entrée en 6ème': null,
    BEPC: '+ BEPC Blanc',
    Probatoire: '+ Probatoire Blanc',
    'Baccalauréat': '+ Bac Blanc',
    'O Level': '+ O Level Mock',
    'A Level': '+ A Level Mock'
  };
  const tracksByExam = {
    'A Level': ['Science', 'Arts', 'Commercial', 'Technical'],
    'Baccalauréat': ['Général', 'Technique'],
    'Probatoire': ['Général', 'Technique'],
    'BEPC': ['Général', 'Technique'],
    'Semester 1 Exam': ['L1', 'L2', 'L3', 'M1', 'M2'],
    'Semester 2 Exam': ['L1', 'L2', 'L3', 'M1', 'M2'],
    'Resit / Makeup': ['L1', 'L2', 'L3', 'M1', 'M2'],
    'Examen Semestre 1': ['L1', 'L2', 'L3', 'M1', 'M2'],
    'Examen Semestre 2': ['L1', 'L2', 'L3', 'M1', 'M2'],
    'Rattrapage': ['L1', 'L2', 'L3', 'M1', 'M2']
  };
  const subjectsEn = [['accounting', 'Accounting', 'amber', 'file-text', '0505'], ['biology', 'Biology', 'green', 'leaf', '0510'], ['chemistry', 'Chemistry', 'purple', 'flask-conical', '0515'], ['computer science', 'Computer science', 'blue', 'cpu', '0595'], ['economics', 'Economics', 'amber', 'trending-up', '0525'], ['physics', 'Physics', 'blue', 'atom', '0580']];
  const subjectsFr = [['maths', 'Mathématiques', 'blue', 'sigma', 'MAT'], ['philo', 'Philosophie', 'purple', 'book-open', 'PHI'], ['hist-geo', 'Histoire-Géo', 'amber', 'globe', 'HGE'], ['svt', 'SVT', 'green', 'leaf', 'SVT'], ['physique-chimie', 'Physique-Chimie', 'blue', 'atom', 'PC'], ['anglais', 'Anglais', 'amber', 'languages', 'ANG']];

  // Step 1: Category
  if (!cat) {
    return /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        overflowY: 'auto',
        padding: '0 18px 90px'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        fontWeight: 800,
        fontSize: 20,
        marginTop: 10,
        color: 'var(--text-primary)'
      }
    }, "Past papers"), /*#__PURE__*/React.createElement("div", {
      style: {
        fontSize: 12,
        color: 'var(--text-secondary)',
        marginTop: 4
      }
    }, "Every level, every system \u2014 Primary to Concours des Grandes \xC9coles."), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        gap: 8,
        marginTop: 14
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1
      }
    }, /*#__PURE__*/React.createElement(SearchInput, {
      placeholder: "Search exam type or subject...",
      value: q,
      onChange: setQ
    })), /*#__PURE__*/React.createElement("button", {
      onClick: () => setShowFilter(!showFilter),
      style: {
        width: 44,
        height: 44,
        flexShrink: 0,
        borderRadius: 'var(--radius-md)',
        border: '1px solid var(--border-subtle)',
        background: showFilter ? 'var(--gold-50)' : '#fff',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        cursor: 'pointer'
      }
    }, /*#__PURE__*/React.createElement(Ic, {
      name: "sliders-horizontal"
    }))), showFilter && /*#__PURE__*/React.createElement("div", {
      style: {
        marginTop: 10,
        background: '#fff',
        borderRadius: 'var(--radius-lg)',
        boxShadow: 'var(--shadow-card)',
        padding: 14
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        fontSize: 11,
        fontWeight: 700,
        color: 'var(--text-tertiary)',
        textTransform: 'uppercase',
        letterSpacing: '0.05em'
      }
    }, "System"), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        gap: 8,
        marginTop: 8,
        flexWrap: 'wrap'
      }
    }, ['All', 'Anglophone', 'Francophone'].map(t => /*#__PURE__*/React.createElement("span", {
      key: t,
      style: {
        padding: '6px 12px',
        borderRadius: 999,
        fontSize: 12,
        fontWeight: 700,
        background: 'var(--surface-sunken)',
        color: 'var(--text-secondary)'
      }
    }, t))), /*#__PURE__*/React.createElement("div", {
      style: {
        fontSize: 11,
        fontWeight: 700,
        color: 'var(--text-tertiary)',
        textTransform: 'uppercase',
        letterSpacing: '0.05em',
        marginTop: 12
      }
    }, "Variant"), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        gap: 8,
        marginTop: 8,
        flexWrap: 'wrap'
      }
    }, ['Official', 'Mock / Blanc'].map(t => /*#__PURE__*/React.createElement("span", {
      key: t,
      style: {
        padding: '6px 12px',
        borderRadius: 999,
        fontSize: 12,
        fontWeight: 700,
        background: 'var(--surface-sunken)',
        color: 'var(--text-secondary)'
      }
    }, t))), /*#__PURE__*/React.createElement("div", {
      style: {
        fontSize: 11,
        fontWeight: 700,
        color: 'var(--text-tertiary)',
        textTransform: 'uppercase',
        letterSpacing: '0.05em',
        marginTop: 12
      }
    }, "Year"), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        gap: 8,
        marginTop: 8,
        flexWrap: 'wrap'
      }
    }, ['2026', '2025', '2024', '2023', 'Older'].map(t => /*#__PURE__*/React.createElement("span", {
      key: t,
      style: {
        padding: '6px 12px',
        borderRadius: 999,
        fontSize: 12,
        fontWeight: 700,
        background: 'var(--surface-sunken)',
        color: 'var(--text-secondary)'
      }
    }, t)))), /*#__PURE__*/React.createElement("div", {
      style: {
        fontSize: 11,
        fontWeight: 700,
        color: 'var(--text-tertiary)',
        textTransform: 'uppercase',
        letterSpacing: '0.05em',
        marginTop: 18
      }
    }, "Category"), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'grid',
        gridTemplateColumns: '1fr 1fr',
        gap: 12,
        marginTop: 10
      }
    }, categories.filter(c => c[1].toLowerCase().includes(q.toLowerCase())).map(([key, title, tint, icon, sub]) => /*#__PURE__*/React.createElement("button", {
      key: key,
      onClick: () => {
        setCat(key);
        setSystem(null);
      },
      style: {
        textAlign: 'left',
        background: '#fff',
        border: 'none',
        borderRadius: 'var(--radius-lg)',
        boxShadow: 'var(--shadow-card)',
        padding: 14,
        cursor: 'pointer',
        display: 'flex',
        flexDirection: 'column',
        gap: 8
      }
    }, /*#__PURE__*/React.createElement(IconChip, {
      tint: tint,
      icon: /*#__PURE__*/React.createElement(Ic, {
        name: icon
      })
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        fontWeight: 700,
        fontSize: 14,
        color: 'var(--text-primary)'
      }
    }, title), /*#__PURE__*/React.createElement("div", {
      style: {
        fontSize: 11,
        color: 'var(--text-secondary)'
      }
    }, sub)))));
  }

  // Step 1b: Academic Reports (separate content type — no marking guide/instructor routing)
  if (cat === 'reports') {
    return /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        overflowY: 'auto',
        padding: '0 18px 90px'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        alignItems: 'center',
        gap: 10,
        marginTop: 10
      }
    }, /*#__PURE__*/React.createElement("button", {
      onClick: () => setCat(null),
      style: {
        background: 'none',
        border: 'none',
        cursor: 'pointer'
      }
    }, /*#__PURE__*/React.createElement(Ic, {
      name: "chevron-left"
    })), /*#__PURE__*/React.createElement("div", {
      style: {
        fontWeight: 800,
        fontSize: 18,
        color: 'var(--text-primary)'
      }
    }, "Academic Reports")), /*#__PURE__*/React.createElement("div", {
      style: {
        fontSize: 12,
        color: 'var(--text-secondary)',
        marginTop: 8,
        lineHeight: 1.5
      }
    }, "Reference documents, not exam papers \u2014 browsable by report type, discipline & year. No marking guide or instructor routing applies here."), /*#__PURE__*/React.createElement("div", {
      style: {
        marginTop: 14
      }
    }, /*#__PURE__*/React.createElement(SearchInput, {
      placeholder: "Search by discipline..."
    })), /*#__PURE__*/React.createElement("div", {
      style: {
        marginTop: 14,
        display: 'flex',
        flexDirection: 'column',
        gap: 10
      }
    }, reportTypes.map(([key, title, sub, tint]) => /*#__PURE__*/React.createElement("div", {
      key: key,
      onClick: onOpenPaper,
      style: {
        background: '#fff',
        borderRadius: 'var(--radius-lg)',
        boxShadow: 'var(--shadow-card)',
        padding: 14,
        display: 'flex',
        alignItems: 'center',
        gap: 12,
        cursor: 'pointer'
      }
    }, /*#__PURE__*/React.createElement(IconChip, {
      tint: tint,
      icon: /*#__PURE__*/React.createElement(Ic, {
        name: "file-text"
      })
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        fontWeight: 700,
        fontSize: 14,
        color: 'var(--text-primary)'
      }
    }, title), /*#__PURE__*/React.createElement("div", {
      style: {
        fontSize: 12,
        color: 'var(--text-secondary)'
      }
    }, sub)), /*#__PURE__*/React.createElement(Ic, {
      name: "chevron-right"
    })))));
  }

  // Step 2 (Secondary/University): System — Francophone / Anglophone
  if ((cat === 'secondary' || cat === 'university') && !system) {
    const catLabel = cat.charAt(0).toUpperCase() + cat.slice(1);
    const systemOptions = cat === 'university' ? [['Francophone', 'Examen Semestre · Rattrapage'], ['Anglophone', 'Semester Exam · Resit']] : [['Francophone', 'BEPC · Probatoire · Baccalauréat'], ['Anglophone', 'O Level · A Level']];
    return /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        overflowY: 'auto',
        padding: '0 18px 90px'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        alignItems: 'center',
        gap: 10,
        marginTop: 10
      }
    }, /*#__PURE__*/React.createElement("button", {
      onClick: () => setCat(null),
      style: {
        background: 'none',
        border: 'none',
        cursor: 'pointer'
      }
    }, /*#__PURE__*/React.createElement(Ic, {
      name: "chevron-left"
    })), /*#__PURE__*/React.createElement("div", {
      style: {
        fontWeight: 800,
        fontSize: 18,
        color: 'var(--text-primary)'
      }
    }, catLabel, " \u2014 choose system")), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        flexDirection: 'column',
        gap: 10,
        marginTop: 16
      }
    }, systemOptions.map(([t, sub]) => /*#__PURE__*/React.createElement("button", {
      key: t,
      onClick: () => setSystem(t),
      style: {
        textAlign: 'left',
        background: '#fff',
        border: 'none',
        borderRadius: 'var(--radius-lg)',
        boxShadow: 'var(--shadow-card)',
        padding: 16,
        cursor: 'pointer',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between'
      }
    }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
      style: {
        fontWeight: 700,
        fontSize: 14,
        color: 'var(--text-primary)'
      }
    }, t), /*#__PURE__*/React.createElement("div", {
      style: {
        fontSize: 11,
        color: 'var(--text-secondary)',
        marginTop: 2
      }
    }, sub)), /*#__PURE__*/React.createElement(Ic, {
      name: "chevron-right"
    })))));
  }

  // Step 3: Exam type within category (+ system for Secondary)
  if (!examType) {
    const isSysCat = cat === 'secondary' || cat === 'university';
    const listKey = isSysCat ? cat + (system === 'Francophone' ? 'Francophone' : 'Anglophone') : cat;
    const headerLabel = isSysCat ? `${cat.charAt(0).toUpperCase() + cat.slice(1)} · ${system}` : cat.charAt(0).toUpperCase() + cat.slice(1);
    return /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        overflowY: 'auto',
        padding: '0 18px 90px'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        alignItems: 'center',
        gap: 10,
        marginTop: 10
      }
    }, /*#__PURE__*/React.createElement("button", {
      onClick: () => isSysCat ? setSystem(null) : setCat(null),
      style: {
        background: 'none',
        border: 'none',
        cursor: 'pointer'
      }
    }, /*#__PURE__*/React.createElement(Ic, {
      name: "chevron-left"
    })), /*#__PURE__*/React.createElement("div", {
      style: {
        fontWeight: 800,
        fontSize: 18,
        color: 'var(--text-primary)'
      }
    }, headerLabel)), /*#__PURE__*/React.createElement("div", {
      style: {
        marginTop: 12
      }
    }, /*#__PURE__*/React.createElement(SearchInput, {
      placeholder: "Search exam type..."
    })), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'grid',
        gridTemplateColumns: '1fr 1fr',
        gap: 12,
        marginTop: 14
      }
    }, examTypesByCat[listKey].map(([name, sub, tint]) => /*#__PURE__*/React.createElement("button", {
      key: name,
      onClick: () => setExamType(name),
      style: {
        textAlign: 'left',
        background: '#fff',
        border: 'none',
        borderRadius: 'var(--radius-lg)',
        boxShadow: 'var(--shadow-card)',
        padding: 14,
        cursor: 'pointer',
        display: 'flex',
        flexDirection: 'column',
        gap: 6
      }
    }, /*#__PURE__*/React.createElement(Badge, {
      tone: variantByExam[name] ? tint === 'purple' ? 'neutral' : tint : 'neutral'
    }, variantByExam[name] ? `Official ${variantByExam[name]}` : 'Official only'), /*#__PURE__*/React.createElement("div", {
      style: {
        fontWeight: 700,
        fontSize: 14,
        color: 'var(--text-primary)',
        marginTop: 4
      }
    }, name), /*#__PURE__*/React.createElement("div", {
      style: {
        fontSize: 11,
        color: 'var(--text-secondary)'
      }
    }, sub)))));
  }

  // Step 4: Track (only if applicable)
  if (tracksByExam[examType] && !track) {
    return /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        overflowY: 'auto',
        padding: '0 18px 90px'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        alignItems: 'center',
        gap: 10,
        marginTop: 10
      }
    }, /*#__PURE__*/React.createElement("button", {
      onClick: () => setExamType(null),
      style: {
        background: 'none',
        border: 'none',
        cursor: 'pointer'
      }
    }, /*#__PURE__*/React.createElement(Ic, {
      name: "chevron-left"
    })), /*#__PURE__*/React.createElement("div", {
      style: {
        fontWeight: 800,
        fontSize: 18,
        color: 'var(--text-primary)'
      }
    }, examType, " \u2014 choose track")), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        flexDirection: 'column',
        gap: 10,
        marginTop: 16
      }
    }, tracksByExam[examType].map(t => /*#__PURE__*/React.createElement("button", {
      key: t,
      onClick: () => setTrack(t),
      style: {
        textAlign: 'left',
        background: '#fff',
        border: 'none',
        borderRadius: 'var(--radius-lg)',
        boxShadow: 'var(--shadow-card)',
        padding: 16,
        cursor: 'pointer',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between'
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        fontWeight: 700,
        fontSize: 14,
        color: 'var(--text-primary)'
      }
    }, t), /*#__PURE__*/React.createElement(Ic, {
      name: "chevron-right"
    })))));
  }

  // Step 5: Subjects
  const isFr = ['BEPC', 'Probatoire', 'Baccalauréat', 'CEP', 'Concours d\u2019Entrée en 6ème', 'BTS', 'Examen Semestre 1', 'Examen Semestre 2', 'Rattrapage'].includes(examType);
  const subjects = isFr ? subjectsFr : subjectsEn;

  // Step 6: Papers by year/variant, once a subject is picked
  if (subject) {
    const hasVariant = !!variantByExam[examType];
    const variantLabel = hasVariant ? variantByExam[examType].replace('+ ', '') : null;
    const years = [2026, 2025, 2024, 2023, 2022];
    const rows = [];
    years.forEach(y => {
      if (!hasVariant || tab !== 2) rows.push({
        year: y,
        label: 'Official'
      });
      if (hasVariant && tab !== 1) rows.push({
        year: y,
        label: variantLabel
      });
    });
    return /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        overflowY: 'auto',
        padding: '0 18px 90px'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        alignItems: 'center',
        gap: 10,
        marginTop: 10
      }
    }, /*#__PURE__*/React.createElement("button", {
      onClick: () => setSubject(null),
      style: {
        background: 'none',
        border: 'none',
        cursor: 'pointer'
      }
    }, /*#__PURE__*/React.createElement(Ic, {
      name: "chevron-left"
    })), /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        fontWeight: 800,
        fontSize: 18,
        color: 'var(--text-primary)'
      }
    }, subject.title), /*#__PURE__*/React.createElement("div", {
      style: {
        fontSize: 11,
        color: 'var(--text-secondary)'
      }
    }, examType, track ? ` · ${track}` : '', " \xB7 ", subject.code))), hasVariant && /*#__PURE__*/React.createElement("div", {
      style: {
        marginTop: 12
      }
    }, /*#__PURE__*/React.createElement(SegmentedTabs, {
      options: ['All', 'Official', variantLabel],
      active: tab,
      onChange: setTab
    })), /*#__PURE__*/React.createElement("div", {
      style: {
        marginTop: 14,
        display: 'flex',
        flexDirection: 'column',
        gap: 10
      }
    }, rows.map((r, i) => /*#__PURE__*/React.createElement("div", {
      key: i,
      onClick: () => onOpenPaper({
        subject,
        cat,
        system,
        examType,
        track,
        year: r.year,
        variant: r.label
      }),
      style: {
        background: '#fff',
        borderRadius: 'var(--radius-lg)',
        boxShadow: 'var(--shadow-card)',
        padding: 14,
        display: 'flex',
        alignItems: 'center',
        gap: 12,
        cursor: 'pointer'
      }
    }, /*#__PURE__*/React.createElement(IconChip, {
      tint: subject.tint,
      icon: /*#__PURE__*/React.createElement(Ic, {
        name: subject.icon
      })
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        fontWeight: 700,
        fontSize: 14,
        color: 'var(--text-primary)'
      }
    }, examType, " ", r.year), /*#__PURE__*/React.createElement("div", {
      style: {
        fontSize: 11,
        color: 'var(--text-secondary)'
      }
    }, r.label, " \xB7 Marking guide included")), /*#__PURE__*/React.createElement(Ic, {
      name: "chevron-right"
    })))));
  }
  return /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      overflowY: 'auto',
      padding: '0 18px 90px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10,
      marginTop: 10
    }
  }, /*#__PURE__*/React.createElement("button", {
    onClick: () => {
      if (track) {
        setTrack(null);
      } else {
        setExamType(null);
      }
    },
    style: {
      background: 'none',
      border: 'none',
      cursor: 'pointer'
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: "chevron-left"
  })), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 800,
      fontSize: 18,
      color: 'var(--text-primary)'
    }
  }, examType), track && /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 11,
      color: 'var(--text-secondary)'
    }
  }, track))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 12,
      display: 'flex',
      gap: 8
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement(SearchInput, {
    placeholder: "Search subjects..."
  })), /*#__PURE__*/React.createElement("button", {
    style: {
      width: 44,
      height: 44,
      flexShrink: 0,
      borderRadius: 'var(--radius-md)',
      border: '1px solid var(--border-subtle)',
      background: '#fff',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      cursor: 'pointer'
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: "sliders-horizontal"
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: '1fr 1fr',
      gap: 12,
      marginTop: 14
    }
  }, subjects.map(([key, title, tint, icon, code]) => /*#__PURE__*/React.createElement("div", {
    key: key,
    onClick: () => {
      setTab(0);
      setSubject({
        key,
        title,
        tint,
        icon,
        code
      });
    },
    style: {
      cursor: 'pointer'
    }
  }, /*#__PURE__*/React.createElement(SubjectCard, {
    icon: /*#__PURE__*/React.createElement(IconChip, {
      tint: tint,
      icon: /*#__PURE__*/React.createElement(Ic, {
        name: icon
      })
    }),
    title: title,
    subtitle: "Papers + marking guides",
    badgeText: "Papers",
    code: code
  })))));
}
window.PapersScreen = PapersScreen;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/spekooh-app/PapersScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/spekooh-app/PaywallSheet.jsx
try { (() => {
function PaywallSheet({
  onClose
}) {
  const {
    Button
  } = window.KawloSpekoohDesignSystem_10ffa8;
  const Ic = window.Ic;
  return /*#__PURE__*/React.createElement("div", {
    onClick: onClose,
    style: {
      position: 'absolute',
      inset: 0,
      background: 'rgba(24,36,81,0.45)',
      backdropFilter: 'blur(2px)',
      display: 'flex',
      alignItems: 'flex-end',
      zIndex: 10
    }
  }, /*#__PURE__*/React.createElement("div", {
    onClick: e => e.stopPropagation(),
    style: {
      background: '#fff',
      width: '100%',
      borderRadius: '26px 26px 0 0',
      padding: '10px 22px 26px',
      boxShadow: 'var(--shadow-sheet)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 40,
      height: 4,
      borderRadius: 2,
      background: 'var(--border-subtle)',
      margin: '0 auto 16px'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'center'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 60,
      height: 60,
      borderRadius: 16,
      background: 'var(--gradient-primary)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center'
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: "star",
    size: 26
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      textAlign: 'center',
      fontWeight: 800,
      fontSize: 20,
      marginTop: 12,
      color: 'var(--text-primary)'
    }
  }, "Get Spekooh Pro"), /*#__PURE__*/React.createElement("div", {
    style: {
      textAlign: 'center',
      fontSize: 13,
      color: 'var(--text-secondary)',
      marginTop: 6
    }
  }, "Unlimited question-paper views and an ad-free app. Marking guides are always unlocked separately."), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 16,
      background: 'var(--surface-sunken)',
      borderRadius: 'var(--radius-lg)',
      padding: '2px 16px'
    }
  }, [['eye', 'Unlimited question paper views'], ['ban', 'Zero ads while you study'], ['bell', 'Instructor status alerts']].map(([icon, label], i) => /*#__PURE__*/React.createElement("div", {
    key: label,
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10,
      padding: '11px 0',
      borderTop: i > 0 ? '1px solid var(--border-subtle)' : 'none'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 26,
      height: 26,
      borderRadius: '50%',
      background: 'var(--green-100)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      color: 'var(--green-600)'
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: icon,
    size: 14
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 13,
      color: 'var(--text-primary)'
    }
  }, label)))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 14,
      border: '1.5px solid var(--blue-400)',
      borderRadius: 'var(--radius-lg)',
      padding: '12px 16px',
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 11,
      fontWeight: 800,
      color: 'var(--text-secondary)',
      letterSpacing: '0.04em'
    }
  }, "SPEKOOH PRO"), /*#__PURE__*/React.createElement("span", {
    style: {
      fontWeight: 800,
      fontSize: 17,
      color: 'var(--text-primary)'
    }
  }, "500 ", /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 11,
      color: 'var(--text-tertiary)',
      fontWeight: 600
    }
  }, "FCFA/mo"))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 14,
      fontSize: 11,
      fontWeight: 700,
      color: 'var(--text-tertiary)',
      textTransform: 'uppercase',
      letterSpacing: '0.05em'
    }
  }, "MTN MoMo or Orange Money number"), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 6,
      display: 'flex',
      alignItems: 'center',
      gap: 8,
      background: '#fff',
      border: '1px solid var(--border-subtle)',
      borderRadius: 'var(--radius-md)',
      padding: '12px 14px'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'var(--text-secondary)',
      fontWeight: 600
    }
  }, "+237"), /*#__PURE__*/React.createElement("input", {
    placeholder: "670 12 34 56",
    style: {
      border: 'none',
      outline: 'none',
      flex: 1,
      fontSize: 14
    }
  })), /*#__PURE__*/React.createElement(Button, {
    variant: "primary",
    style: {
      width: '100%',
      marginTop: 14
    }
  }, "Pay 500 FCFA"), /*#__PURE__*/React.createElement("div", {
    style: {
      textAlign: 'center',
      fontSize: 11,
      color: 'var(--text-tertiary)',
      marginTop: 10
    }
  }, "Official Spekooh merchant \xB7 we never ask for your PIN \xB7 receipt + SMS within 2 min")));
}
window.PaywallSheet = PaywallSheet;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/spekooh-app/PaywallSheet.jsx", error: String((e && e.message) || e) }); }

// ui_kits/spekooh-app/Phone.jsx
try { (() => {
function Phone({
  children
}) {
  return React.createElement('div', {
    style: {
      width: 390,
      height: 800,
      background: 'var(--surface-bg)',
      borderRadius: 36,
      overflow: 'hidden',
      position: 'relative',
      display: 'flex',
      flexDirection: 'column',
      fontFamily: 'var(--font-sans)',
      boxShadow: '0 20px 60px rgba(24,36,81,0.25)',
      border: '8px solid #14162A'
    }
  }, children);
}
window.Phone = Phone;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/spekooh-app/Phone.jsx", error: String((e && e.message) || e) }); }

// ui_kits/spekooh-app/ProfileScreen.jsx
try { (() => {
function ProfileScreen({
  onBack,
  onOpenSettings
}) {
  const {
    Badge
  } = window.KawloSpekoohDesignSystem_10ffa8;
  const Ic = window.Ic;
  const items = [{
    title: 'Physics — GCE A Level 2025',
    status: 'Live',
    tone: 'green',
    date: 'Published · earned 150 credits'
  }, {
    title: 'Further Maths — GCE A Level 2024',
    status: 'Approved',
    tone: 'blue',
    date: 'Marking guide in progress'
  }, {
    title: 'Biology — GCE O Level 2025',
    status: 'Under review',
    tone: 'amber',
    date: 'Checking for duplicates'
  }, {
    title: 'History — Baccalauréat 2023',
    status: 'Received',
    tone: 'neutral',
    date: 'Just submitted'
  }];
  const badges = [['flame', 'Spark', true], ['flame', 'Ember', true], ['flame', 'Inferno', false], ['book-open', 'Scholar I', false]];
  return /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      overflowY: 'auto',
      padding: '0 18px 90px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center',
      marginTop: 10
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10
    }
  }, /*#__PURE__*/React.createElement("button", {
    onClick: onBack,
    style: {
      width: 36,
      height: 36,
      borderRadius: '50%',
      border: '1px solid var(--border-subtle)',
      background: '#fff'
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: "chevron-left"
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 800,
      fontSize: 19,
      color: 'var(--text-primary)'
    }
  }, "Profile")), /*#__PURE__*/React.createElement("button", {
    onClick: onOpenSettings,
    style: {
      width: 36,
      height: 36,
      borderRadius: '50%',
      border: '1px solid var(--border-subtle)',
      background: '#fff'
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: "settings",
    size: 16
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 14,
      background: '#fff',
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--shadow-card)',
      padding: 16,
      display: 'flex',
      alignItems: 'center',
      gap: 12
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 52,
      height: 52,
      borderRadius: '50%',
      background: 'var(--gold-200)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      fontWeight: 800,
      fontSize: 18,
      color: 'var(--gold-700)'
    }
  }, "G"), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 800,
      fontSize: 16,
      color: 'var(--text-primary)'
    }
  }, "Guest"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      color: 'var(--text-secondary)'
    }
  }, "Joined Jul 2026"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 8,
      marginTop: 6
    }
  }, /*#__PURE__*/React.createElement(Badge, {
    tone: "blue"
  }, "24 submissions"), /*#__PURE__*/React.createElement(Badge, {
    tone: "amber"
  }, "4 quizzes")))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'baseline',
      marginTop: 20
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 800,
      fontSize: 15,
      color: 'var(--text-primary)'
    }
  }, "Badges"), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 12,
      fontWeight: 700,
      color: 'var(--gold-700)'
    }
  }, "All 15")), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: 'repeat(4,1fr)',
      gap: 8,
      marginTop: 10
    }
  }, badges.map(([icon, label, earned]) => /*#__PURE__*/React.createElement("div", {
    key: label,
    style: {
      background: '#fff',
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--shadow-card)',
      padding: '12px 6px',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      gap: 6,
      opacity: earned ? 1 : 0.45
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: icon,
    size: 20,
    style: {
      color: 'var(--gold-600)'
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 10,
      fontWeight: 700,
      color: 'var(--text-primary)',
      textAlign: 'center'
    }
  }, label)))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 14,
      background: 'var(--gradient-primary)',
      borderRadius: 'var(--radius-lg)',
      padding: 18,
      color: '#fff'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      color: 'rgba(255,255,255,0.8)',
      fontWeight: 700,
      letterSpacing: '0.04em',
      textTransform: 'uppercase'
    }
  }, "Bonus credit balance"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 800,
      fontSize: 28,
      marginTop: 4
    }
  }, "2,150 ", /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 13,
      fontWeight: 600
    }
  }, "pts")), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      marginTop: 6,
      color: 'rgba(255,255,255,0.85)'
    }
  }, "24 papers submitted \xB7 redeem code value scales with your contributions")), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 14,
      background: '#fff',
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--shadow-card)',
      padding: 16
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 700,
      fontSize: 14,
      color: 'var(--text-primary)'
    }
  }, "Redeem code ready"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      color: 'var(--text-secondary)',
      marginTop: 2
    }
  }, "25% off any marking-guide unlock \xB7 expires in 30 days")), /*#__PURE__*/React.createElement(Ic, {
    name: "ticket",
    size: 22
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 12,
      background: 'var(--surface-sunken)',
      border: '1px dashed var(--border-subtle)',
      borderRadius: 'var(--radius-md)',
      padding: '10px 14px',
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: 'var(--font-mono)',
      fontWeight: 700,
      fontSize: 15,
      letterSpacing: '0.06em',
      color: 'var(--text-primary)'
    }
  }, "SPKH-24GT-Q3"), /*#__PURE__*/React.createElement("button", {
    style: {
      background: 'none',
      border: 'none',
      color: 'var(--gold-700)',
      fontWeight: 700,
      fontSize: 12,
      cursor: 'pointer'
    }
  }, "Share"))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 20,
      fontSize: 11,
      fontWeight: 700,
      color: 'var(--text-tertiary)',
      textTransform: 'uppercase',
      letterSpacing: '0.05em'
    }
  }, "Submission status"), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 8,
      background: '#fff',
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--shadow-card)',
      padding: '2px 16px'
    }
  }, items.map((it, i) => /*#__PURE__*/React.createElement("div", {
    key: it.title,
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      padding: '13px 0',
      borderTop: i > 0 ? '1px solid var(--border-subtle)' : 'none'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 700,
      fontSize: 13,
      color: 'var(--text-primary)'
    }
  }, it.title), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 11,
      color: 'var(--text-secondary)',
      marginTop: 2
    }
  }, it.date)), /*#__PURE__*/React.createElement(Badge, {
    tone: it.tone
  }, it.status)))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 20,
      fontSize: 11,
      fontWeight: 700,
      color: 'var(--text-tertiary)',
      textTransform: 'uppercase',
      letterSpacing: '0.05em'
    }
  }, "Account"), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 8,
      background: '#fff',
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--shadow-card)',
      padding: '0 16px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      padding: '13px 0'
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: "download"
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      fontSize: 14,
      fontWeight: 600,
      color: 'var(--text-primary)'
    }
  }, "My downloads"), /*#__PURE__*/React.createElement(Ic, {
    name: "chevron-right"
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      borderTop: '1px solid var(--border-subtle)'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      padding: '13px 0'
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: "message-circle"
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      fontSize: 14,
      fontWeight: 600,
      color: 'var(--text-primary)'
    }
  }, "My forum activity"), /*#__PURE__*/React.createElement(Ic, {
    name: "chevron-right"
  }))));
}
window.ProfileScreen = ProfileScreen;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/spekooh-app/ProfileScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/spekooh-app/QuizzesScreen.jsx
try { (() => {
function QuizzesScreen() {
  const {
    StatRow,
    Avatar,
    SearchInput
  } = window.KawloSpekoohDesignSystem_10ffa8;
  const [detail, setDetail] = React.useState(false);
  const [filter, setFilter] = React.useState('All');
  const [q, setQ] = React.useState('');
  const Ic = window.Ic;
  const subjects = [['leaf', 'Biology quiz', '18 topics', 'green'], ['flask-conical', 'Chemistry quizzes', '22 topics', 'purple'], ['globe', 'Geography quizzes', '2 topics', 'amber'], ['cpu', 'Computer science', '1 topics', 'blue']];
  if (detail) {
    return /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        overflowY: 'auto',
        padding: '0 18px 90px'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        alignItems: 'center',
        gap: 10,
        marginTop: 10
      }
    }, /*#__PURE__*/React.createElement("button", {
      onClick: () => setDetail(false),
      style: {
        background: 'none',
        border: 'none',
        cursor: 'pointer'
      }
    }, /*#__PURE__*/React.createElement(Ic, {
      name: "chevron-left"
    }))), /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        marginTop: 10,
        gap: 10
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        width: 64,
        height: 64,
        borderRadius: 16,
        background: 'var(--gold-50)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        color: 'var(--gold-700)',
        fontWeight: 800,
        fontSize: 26
      }
    }, "\u03A3"), /*#__PURE__*/React.createElement("div", {
      style: {
        fontWeight: 800,
        fontSize: 19,
        color: 'var(--text-primary)'
      }
    }, "Enzyme Quiz 2"), /*#__PURE__*/React.createElement("div", {
      style: {
        fontSize: 13,
        color: 'var(--text-secondary)',
        textAlign: 'center'
      }
    }, "Practice questions drawn from Biology past papers, checked against the instructor-authored marking guide.")), /*#__PURE__*/React.createElement("div", {
      style: {
        marginTop: 16
      }
    }, /*#__PURE__*/React.createElement(StatRow, {
      stats: [{
        value: 15,
        label: 'questions'
      }, {
        value: '8 min',
        label: 'suggested'
      }, {
        value: 5564,
        label: 'played'
      }]
    })), /*#__PURE__*/React.createElement("div", {
      style: {
        marginTop: 16,
        background: '#fff',
        borderRadius: 'var(--radius-lg)',
        boxShadow: 'var(--shadow-card)',
        padding: '2px 16px'
      }
    }, [['clock', 'Timer 8:00', true], ['lightbulb', 'Hints  2 available', true], ['refresh-cw', 'Shuffle questions', false]].map(([icon, label, on], i) => /*#__PURE__*/React.createElement("div", {
      key: label,
      style: {
        display: 'flex',
        alignItems: 'center',
        gap: 12,
        padding: '12px 0',
        borderTop: i > 0 ? '1px solid var(--border-subtle)' : 'none'
      }
    }, /*#__PURE__*/React.createElement(Ic, {
      name: icon
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        fontSize: 14,
        color: 'var(--text-primary)'
      }
    }, label), /*#__PURE__*/React.createElement("div", {
      style: {
        width: 40,
        height: 24,
        borderRadius: 999,
        background: on ? 'var(--green-500)' : 'var(--border-subtle)',
        position: 'relative'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        position: 'absolute',
        top: 2,
        left: on ? 18 : 2,
        width: 20,
        height: 20,
        borderRadius: '50%',
        background: '#fff'
      }
    }))))), /*#__PURE__*/React.createElement("button", {
      style: {
        width: '100%',
        marginTop: 18,
        background: 'var(--gradient-primary)',
        color: '#fff',
        fontWeight: 700,
        border: 'none',
        borderRadius: 999,
        padding: '15px',
        fontSize: 15,
        boxShadow: 'var(--shadow-button)'
      }
    }, "Start quiz"));
  }
  return /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      overflowY: 'auto',
      padding: '0 18px 90px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 800,
      fontSize: 20,
      marginTop: 10,
      color: 'var(--text-primary)'
    }
  }, "Quiz"), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 14,
      background: 'var(--ink-900)',
      borderRadius: 'var(--radius-lg)',
      padding: 16,
      color: '#fff'
    },
    onClick: () => setDetail(true)
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'space-between',
      fontSize: 12,
      color: 'var(--text-on-dark-muted)'
    }
  }, /*#__PURE__*/React.createElement("span", null, "DAILY CHALLENGE"), /*#__PURE__*/React.createElement("span", null, "Resets in 7h 23m")), /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 800,
      fontSize: 17,
      marginTop: 6
    }
  }, "Group VII the Halogens Quiz"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      color: 'var(--text-on-dark-muted)',
      marginTop: 2
    }
  }, "15 questions \xB7 1308 students played"), /*#__PURE__*/React.createElement("button", {
    style: {
      marginTop: 12,
      width: '100%',
      background: 'var(--gold-500)',
      color: 'var(--ink-900)',
      fontWeight: 800,
      border: 'none',
      borderRadius: 999,
      padding: '13px',
      fontSize: 14,
      cursor: 'pointer'
    }
  }, "Play daily challenge")), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: '1fr 1fr',
      gap: 10,
      marginTop: 14
    }
  }, [['clock', 'Timed practice', 'Exam conditions'], ['refresh-cw', 'Revision mode', 'No timer, hints on']].map(([icon, t, s]) => /*#__PURE__*/React.createElement("div", {
    key: t,
    style: {
      background: '#fff',
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--shadow-card)',
      padding: 14
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: icon
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 700,
      fontSize: 13,
      marginTop: 8,
      color: 'var(--text-primary)'
    }
  }, t), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 11,
      color: 'var(--text-secondary)',
      marginTop: 2
    }
  }, s)))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 14,
      background: '#fff',
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--shadow-card)',
      padding: '2px 16px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    onClick: () => setDetail(true),
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      padding: '14px 0',
      cursor: 'pointer'
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: "zap"
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 700,
      fontSize: 14,
      color: 'var(--text-primary)'
    }
  }, "Past-paper practice"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      color: 'var(--text-secondary)'
    }
  }, "Generated from submitted papers \xB7 every sector & level")), /*#__PURE__*/React.createElement(Ic, {
    name: "chevron-right"
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      borderTop: '1px solid var(--border-subtle)'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      padding: '14px 0'
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: "trophy"
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 700,
      fontSize: 14,
      color: 'var(--text-primary)'
    }
  }, "Friday Arena"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      color: 'var(--text-secondary)'
    }
  }, "Live elimination quiz \xB7 everyone plays for prizes")), /*#__PURE__*/React.createElement(Ic, {
    name: "chevron-right"
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 14,
      background: 'var(--ink-900)',
      borderRadius: 'var(--radius-lg)',
      padding: 16
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 700,
      color: '#fff',
      fontSize: 14,
      marginBottom: 14
    }
  }, "Top players ", /*#__PURE__*/React.createElement("span", {
    style: {
      float: 'right',
      fontSize: 12,
      color: 'var(--text-on-dark-muted)',
      fontWeight: 600
    }
  }, "See all")), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'space-around'
    }
  }, [['Julliete', 2], ['Jojo B.', 1], ['Billionaire K.', 3]].map(([n, r]) => /*#__PURE__*/React.createElement("div", {
    key: n,
    style: {
      textAlign: 'center'
    }
  }, /*#__PURE__*/React.createElement(Avatar, {
    name: n,
    rank: r
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      color: '#fff',
      fontSize: 11,
      fontWeight: 700,
      marginTop: 6
    }
  }, n), /*#__PURE__*/React.createElement("div", {
    style: {
      color: 'var(--text-on-dark-muted)',
      fontSize: 10
    }
  }, r === 1 ? '39 QUIZZES' : r === 2 ? '35 QUIZZES' : '14 QUIZZES'))))), /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 800,
      fontSize: 17,
      marginTop: 22,
      color: 'var(--text-primary)'
    }
  }, "By subject"), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 10
    }
  }, /*#__PURE__*/React.createElement(SearchInput, {
    placeholder: "Search subjects...",
    value: q,
    onChange: setQ
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 8,
      marginTop: 10,
      overflowX: 'auto'
    }
  }, ['All', 'Sciences', 'Arts', 'Commercial'].map(t => /*#__PURE__*/React.createElement("span", {
    key: t,
    onClick: () => setFilter(t),
    style: {
      flexShrink: 0,
      padding: '7px 14px',
      borderRadius: 999,
      fontSize: 12,
      fontWeight: 700,
      cursor: 'pointer',
      background: filter === t ? 'var(--ink-900)' : '#fff',
      color: filter === t ? '#fff' : 'var(--text-secondary)',
      boxShadow: filter === t ? 'none' : 'var(--shadow-card)'
    }
  }, t))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 12,
      display: 'flex',
      flexDirection: 'column',
      gap: 10
    }
  }, subjects.filter(s => s[1].toLowerCase().includes(q.toLowerCase())).map(([icon, title, sub, tint]) => /*#__PURE__*/React.createElement("div", {
    key: title,
    onClick: () => setDetail(true),
    style: {
      background: '#fff',
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--shadow-card)',
      padding: 14,
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      cursor: 'pointer'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 44,
      height: 44,
      borderRadius: 'var(--radius-chip)',
      background: `var(--${tint}-100)`,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center'
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: icon,
    style: {
      color: `var(--${tint}-600)`
    }
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 700,
      fontSize: 14,
      color: 'var(--text-primary)'
    }
  }, title), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      color: 'var(--text-secondary)'
    }
  }, sub)), /*#__PURE__*/React.createElement(Ic, {
    name: "chevron-right"
  })))));
}
window.QuizzesScreen = QuizzesScreen;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/spekooh-app/QuizzesScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/spekooh-app/SettingsScreen.jsx
try { (() => {
function SettingsScreen({
  onLogin
}) {
  const {
    IconChip,
    Toggle
  } = window.KawloSpekoohDesignSystem_10ffa8;
  const [lang, setLang] = React.useState('en');
  const Ic = window.Ic;
  const Row = ({
    icon,
    title,
    sub,
    trailing
  }) => /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      padding: '13px 0'
    }
  }, /*#__PURE__*/React.createElement(IconChip, {
    tint: "blue",
    icon: /*#__PURE__*/React.createElement(Ic, {
      name: icon
    }),
    size: 38
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 700,
      fontSize: 14,
      color: 'var(--text-primary)'
    }
  }, title), sub && /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      color: 'var(--text-secondary)'
    }
  }, sub)), trailing || /*#__PURE__*/React.createElement(Ic, {
    name: "chevron-right"
  }));
  return /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      overflowY: 'auto',
      padding: '0 18px 90px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10,
      marginTop: 10
    }
  }, /*#__PURE__*/React.createElement("button", {
    style: {
      width: 36,
      height: 36,
      borderRadius: '50%',
      border: '1px solid var(--border-subtle)',
      background: '#fff'
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: "chevron-left"
  })), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 800,
      fontSize: 19,
      color: 'var(--text-primary)'
    }
  }, "Settings"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      color: 'var(--text-secondary)'
    }
  }, "Account & app"))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 16,
      background: '#fff',
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--shadow-card)',
      padding: 14,
      display: 'flex',
      alignItems: 'center',
      gap: 12
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 44,
      height: 44,
      borderRadius: 'var(--radius-chip)',
      background: 'var(--gold-200)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center'
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: "star",
    size: 20
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 700,
      fontSize: 14,
      color: 'var(--text-primary)'
    }
  }, "Spekooh Pro"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      color: 'var(--text-secondary)'
    }
  }, "Unlimited paper views \xB7 no ads")), /*#__PURE__*/React.createElement(Ic, {
    name: "chevron-right"
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 20,
      fontSize: 11,
      fontWeight: 700,
      color: 'var(--text-tertiary)',
      textTransform: 'uppercase',
      letterSpacing: '0.06em'
    }
  }, "Language"), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 8,
      background: '#fff',
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--shadow-card)',
      padding: '0 16px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    onClick: () => setLang('en'),
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      padding: '13px 0',
      cursor: 'pointer'
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: "globe"
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      fontWeight: 700,
      fontSize: 14,
      color: 'var(--text-primary)'
    }
  }, "English"), lang === 'en' && /*#__PURE__*/React.createElement(Ic, {
    name: "check"
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      borderTop: '1px solid var(--border-subtle)'
    }
  }), /*#__PURE__*/React.createElement("div", {
    onClick: () => setLang('fr'),
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      padding: '13px 0',
      cursor: 'pointer'
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: "globe"
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      fontWeight: 700,
      fontSize: 14,
      color: 'var(--text-primary)'
    }
  }, "Fran\xE7ais"), lang === 'fr' && /*#__PURE__*/React.createElement(Ic, {
    name: "check"
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 20,
      fontSize: 11,
      fontWeight: 700,
      color: 'var(--text-tertiary)',
      textTransform: 'uppercase',
      letterSpacing: '0.06em'
    }
  }, "Help"), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 8,
      background: '#fff',
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--shadow-card)',
      padding: '0 16px'
    }
  }, /*#__PURE__*/React.createElement(Row, {
    icon: "phone",
    title: "Help & support",
    sub: "Chat with a real person"
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      borderTop: '1px solid var(--border-subtle)'
    }
  }), /*#__PURE__*/React.createElement(Row, {
    icon: "message-circle",
    title: "Join our WhatsApp group",
    sub: "Tips & updates"
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      borderTop: '1px solid var(--border-subtle)'
    }
  }), /*#__PURE__*/React.createElement(Row, {
    icon: "user",
    title: "Contact us",
    sub: "Questions or feedback"
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 20,
      fontSize: 11,
      fontWeight: 700,
      color: 'var(--text-tertiary)',
      textTransform: 'uppercase',
      letterSpacing: '0.06em'
    }
  }, "About"), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 8,
      background: '#fff',
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--shadow-card)',
      padding: '0 16px'
    }
  }, /*#__PURE__*/React.createElement(Row, {
    icon: "globe",
    title: "Visit our website",
    sub: "spekooh.app"
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      borderTop: '1px solid var(--border-subtle)'
    }
  }), /*#__PURE__*/React.createElement(Row, {
    icon: "lock",
    title: "Privacy policy"
  })), /*#__PURE__*/React.createElement("button", {
    style: {
      width: '100%',
      marginTop: 24,
      background: 'var(--gradient-primary)',
      color: '#fff',
      fontWeight: 700,
      border: 'none',
      borderRadius: 999,
      padding: '15px',
      fontSize: 15,
      boxShadow: 'var(--shadow-button)',
      cursor: 'pointer'
    },
    onClick: onLogin
  }, "Log in"));
}
window.SettingsScreen = SettingsScreen;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/spekooh-app/SettingsScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/spekooh-app/ShopScreen.jsx
try { (() => {
function ShopScreen({
  onBack,
  onOpenPamphlet
}) {
  const {
    SearchInput,
    Button
  } = window.KawloSpekoohDesignSystem_10ffa8;
  const Ic = window.Ic;
  const items = [['Probatoire Philosophy Pamphlet', 'Librairie Centrale', '7,500'], ['GCE A Level Further Maths Pack', 'Presbook Bookshop', '6,000'], ['Baccalauréat SVT Revision Guide', 'Librairie Centrale', '5,500']];
  return /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      overflowY: 'auto',
      padding: '0 18px 90px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10,
      marginTop: 10
    }
  }, /*#__PURE__*/React.createElement("button", {
    onClick: onBack,
    style: {
      width: 36,
      height: 36,
      borderRadius: '50%',
      border: '1px solid var(--border-subtle)',
      background: '#fff'
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: "chevron-left"
  })), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 800,
      fontSize: 19,
      color: 'var(--text-primary)'
    }
  }, "Shop"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      color: 'var(--text-secondary)'
    }
  }, "Partner pamphlets \xB7 pay in-app, pick up with a QR code"))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 14
    }
  }, /*#__PURE__*/React.createElement(SearchInput, {
    placeholder: "Search pamphlets..."
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 14,
      display: 'flex',
      flexDirection: 'column',
      gap: 10
    }
  }, items.map(([title, partner, price]) => /*#__PURE__*/React.createElement("div", {
    key: title,
    onClick: onOpenPamphlet,
    style: {
      background: '#fff',
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--shadow-card)',
      padding: 14,
      display: 'flex',
      gap: 12,
      alignItems: 'center',
      cursor: 'pointer'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 56,
      height: 56,
      borderRadius: 10,
      background: 'var(--gradient-gold-deep)',
      flexShrink: 0
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 700,
      fontSize: 14,
      color: 'var(--text-primary)'
    }
  }, title), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      color: 'var(--text-secondary)',
      marginTop: 2
    }
  }, "Sold by ", partner, " \xB7 QR pickup"), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 6,
      fontWeight: 800,
      color: 'var(--text-primary)'
    }
  }, price, " ", /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 11,
      color: 'var(--text-tertiary)',
      fontWeight: 600
    }
  }, "FCFA")))))));
}
window.ShopScreen = ShopScreen;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/spekooh-app/ShopScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/spekooh-app/StatusBar.jsx
try { (() => {
function StatusBar() {
  return React.createElement('div', {
    style: {
      display: 'flex',
      justifyContent: 'space-between',
      padding: '10px 20px 4px',
      fontSize: 13,
      fontWeight: 700,
      color: 'var(--navy-900)'
    }
  }, React.createElement('span', null, '16:32'), React.createElement('span', null, '••• LTE 100%'));
}
window.StatusBar = StatusBar;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/spekooh-app/StatusBar.jsx", error: String((e && e.message) || e) }); }

// ui_kits/spekooh-app/SubmitScreen.jsx
try { (() => {
function SubmitScreen() {
  const {
    Button,
    IconChip,
    Badge
  } = window.KawloSpekoohDesignSystem_10ffa8;
  const Ic = window.Ic;
  const [type, setType] = React.useState('paper');
  const [step, setStep] = React.useState(0);
  if (step === 1) {
    return /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '0 24px',
        gap: 14,
        textAlign: 'center'
      }
    }, /*#__PURE__*/React.createElement(IconChip, {
      tint: "green",
      icon: /*#__PURE__*/React.createElement(Ic, {
        name: "check",
        size: 28
      }),
      size: 64
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        fontWeight: 800,
        fontSize: 19,
        color: 'var(--text-primary)'
      }
    }, "Contribution received"), /*#__PURE__*/React.createElement("div", {
      style: {
        fontSize: 13,
        color: 'var(--text-secondary)'
      }
    }, type === 'paper' ? "We'll check it against existing papers first — if it's new, it moves to instructor review. Track it under Profile." : "Thanks — academic reports are added straight to the library, browsable by discipline & year."), /*#__PURE__*/React.createElement(Button, {
      variant: "primary",
      onClick: () => setStep(0)
    }, "Submit another"));
  }
  return /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      overflowY: 'auto',
      padding: '0 18px 90px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 800,
      fontSize: 20,
      marginTop: 10,
      color: 'var(--text-primary)'
    }
  }, "Contribution"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      color: 'var(--text-secondary)',
      marginTop: 4
    }
  }, "Share a past paper or an academic report \u2014 every contribution helps another student."), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 8,
      marginTop: 14,
      background: 'var(--surface-sunken)',
      borderRadius: 999,
      padding: 4
    }
  }, [['paper', 'Exam paper'], ['report', 'Academic report']].map(([key, label]) => /*#__PURE__*/React.createElement("button", {
    key: key,
    onClick: () => setType(key),
    style: {
      flex: 1,
      border: 'none',
      borderRadius: 999,
      padding: '9px 0',
      fontWeight: 700,
      fontSize: 13,
      cursor: 'pointer',
      background: type === key ? '#fff' : 'transparent',
      color: type === key ? 'var(--text-primary)' : 'var(--text-secondary)',
      boxShadow: type === key ? 'var(--shadow-card)' : 'none'
    }
  }, label))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 16,
      border: '1.5px dashed var(--gold-400)',
      borderRadius: 'var(--radius-lg)',
      background: 'var(--gold-50)',
      padding: 26,
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      gap: 8,
      cursor: 'pointer'
    }
  }, /*#__PURE__*/React.createElement(IconChip, {
    tint: "amber",
    icon: /*#__PURE__*/React.createElement(Ic, {
      name: "camera",
      size: 22
    }),
    size: 52
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      fontWeight: 700,
      fontSize: 14,
      color: 'var(--text-primary)'
    }
  }, "Take a photo or upload a PDF"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      color: 'var(--text-secondary)'
    }
  }, "JPG, PNG or PDF \xB7 up to 20MB")), type === 'paper' ? /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 18,
      display: 'flex',
      flexDirection: 'column',
      gap: 10
    }
  }, [['Subject', 'Physics'], ['Education level', 'A-Level'], ['Exam type', 'GCE final'], ['Year', '2025'], ['Exam board / school (optional)', '—']].map(([label, val]) => /*#__PURE__*/React.createElement("div", {
    key: label,
    style: {
      background: '#fff',
      borderRadius: 'var(--radius-md)',
      boxShadow: 'var(--shadow-card)',
      padding: '12px 14px',
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 13,
      color: 'var(--text-secondary)'
    }
  }, label), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 13,
      fontWeight: 700,
      color: 'var(--text-primary)',
      display: 'flex',
      alignItems: 'center',
      gap: 6
    }
  }, val, /*#__PURE__*/React.createElement(Ic, {
    name: "chevron-right",
    size: 14
  }))))) : /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 18,
      display: 'flex',
      flexDirection: 'column',
      gap: 10
    }
  }, [['Report type', 'Bachelor\u2019s Report'], ['Discipline', 'Computer Science'], ['Institution', 'University of Buea'], ['Year', '2025']].map(([label, val]) => /*#__PURE__*/React.createElement("div", {
    key: label,
    style: {
      background: '#fff',
      borderRadius: 'var(--radius-md)',
      boxShadow: 'var(--shadow-card)',
      padding: '12px 14px',
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 13,
      color: 'var(--text-secondary)'
    }
  }, label), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 13,
      fontWeight: 700,
      color: 'var(--text-primary)',
      display: 'flex',
      alignItems: 'center',
      gap: 6
    }
  }, val, /*#__PURE__*/React.createElement(Ic, {
    name: "chevron-right",
    size: 14
  }))))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 14,
      display: 'flex',
      alignItems: 'center',
      gap: 10,
      background: 'var(--green-100)',
      borderRadius: 'var(--radius-lg)',
      padding: '12px 14px'
    }
  }, /*#__PURE__*/React.createElement(Ic, {
    name: "gift",
    size: 18,
    style: {
      color: 'var(--green-600)'
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 12,
      color: 'var(--green-600)',
      fontWeight: 600,
      flex: 1
    }
  }, type === 'paper' ? 'New, verified submissions earn bonus credit — redeemable toward marking-guide unlocks.' : 'Academic reports are browsable references — no marking guide, but you still earn contributor credit.')), /*#__PURE__*/React.createElement(Button, {
    variant: "primary",
    onClick: () => setStep(1),
    style: {
      width: '100%',
      marginTop: 18
    }
  }, type === 'paper' ? 'Submit paper' : 'Submit report'));
}
window.SubmitScreen = SubmitScreen;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/spekooh-app/SubmitScreen.jsx", error: String((e && e.message) || e) }); }

__ds_ns.Badge = __ds_scope.Badge;

__ds_ns.Button = __ds_scope.Button;

__ds_ns.IconChip = __ds_scope.IconChip;

__ds_ns.Avatar = __ds_scope.Avatar;

__ds_ns.ListItemRow = __ds_scope.ListItemRow;

__ds_ns.StatRow = __ds_scope.StatRow;

__ds_ns.SubjectCard = __ds_scope.SubjectCard;

__ds_ns.Banner = __ds_scope.Banner;

__ds_ns.SearchInput = __ds_scope.SearchInput;

__ds_ns.Toggle = __ds_scope.Toggle;

__ds_ns.BottomNav = __ds_scope.BottomNav;

__ds_ns.SegmentedTabs = __ds_scope.SegmentedTabs;

})();
