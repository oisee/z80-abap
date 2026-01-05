CLASS zcl_cpm_00_http DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_http_extension.

  PRIVATE SECTION.
    METHODS get_html
      IMPORTING
        iv_disk TYPE string DEFAULT 'A'
      RETURNING VALUE(rv_html) TYPE string.
ENDCLASS.

CLASS zcl_cpm_00_http IMPLEMENTATION.

  METHOD if_http_extension~handle_request.
    DATA(lv_disk) = server->request->get_form_field( 'disk' ).
    IF lv_disk IS INITIAL.
      lv_disk = 'A'.
    ELSE.
      lv_disk = to_upper( lv_disk ).
    ENDIF.

    DATA(lv_html) = get_html( iv_disk = lv_disk ).

    server->response->set_header_field(
      name  = 'Content-Type'
      value = 'text/html; charset=utf-8' ).

    server->response->set_cdata( lv_html ).
  ENDMETHOD.

  METHOD get_html.
    DATA(lv_n) = cl_abap_char_utilities=>newline.
    DATA(lv_disk_js) = iv_disk.

    rv_html =
      |<!DOCTYPE html>{ lv_n }| &&
      |<html>{ lv_n }| &&
      |<head>{ lv_n }| &&
      |  <title>CP/M on SAP HANA - Disk { iv_disk }</title>{ lv_n }| &&
      |  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/xterm@5.3.0/css/xterm.css" />{ lv_n }| &&
      |  <style>{ lv_n }| &&
      |    * \{ box-sizing: border-box; \}{ lv_n }| &&
      |    body \{ background-color: #0a0a0a; display: flex; flex-direction: column; justify-content: center; align-items: center; min-height: 100vh; margin: 0; padding: 10px; font-family: 'Courier New', monospace; \}{ lv_n }| &&
      |    h1 \{ color: #FFB000; text-shadow: 0 0 10px #FFB000; margin-bottom: 10px; font-size: 1.5em; \}{ lv_n }| &&
      |    #graphics-container \{ display: none; margin-bottom: 10px; border: 2px solid #0f0; border-radius: 8px; padding: 5px; background: #000; box-shadow: 0 0 20px rgba(0, 255, 0, 0.3); \}{ lv_n }| &&
      |    #graphics-container canvas \{ display: block; image-rendering: pixelated; \}{ lv_n }| &&
      |    #terminal-container \{ border: 2px solid #FFB000; border-radius: 8px; padding: 10px; background: #000; box-shadow: 0 0 20px rgba(255, 176, 0, 0.3); overflow: hidden; width: 95vw; max-width: 1400px; \}{ lv_n }| &&
      |    #terminal \{ width: 100%; height: 70vh; \}{ lv_n }| &&
      |    .has-graphics #terminal \{ height: 45vh; \}{ lv_n }| &&
      |    #status \{ color: #888; margin-top: 8px; font-size: 11px; \}{ lv_n }| &&
      |    .connected \{ color: #FFB000 !important; \}{ lv_n }| &&
      |    .disconnected \{ color: #ff4444 !important; \}{ lv_n }| &&
      |  </style>{ lv_n }| &&
      |</head>{ lv_n }| &&
      |<body>{ lv_n }| &&
      |  <h1>CP/M on SAP HANA</h1>{ lv_n }| &&
      |  <div id="graphics-container"></div>{ lv_n }| &&
      |  <div id="terminal-container"><div id="terminal"></div></div>{ lv_n }| &&
      |  <div id="status">Disk: <span id="diskName">{ iv_disk }</span> - <span id="statusText" class="disconnected">Connecting...</span> - ^D:break n/p:nav s/a/h:mode 1-8:pal</div>{ lv_n }| &&
      |  <script src="https://cdn.jsdelivr.net/npm/xterm@5.3.0/lib/xterm.js"></script>{ lv_n }| &&
      |  <script src="https://cdn.jsdelivr.net/npm/xterm-addon-fit@0.8.0/lib/xterm-addon-fit.js"></script>{ lv_n }| &&
      |  <script>{ lv_n }| &&
      |    const APC_PATH = "/sap/bc/apc/sap/zcpm";{ lv_n }| &&
      |    const CPM_DISK = "{ lv_disk_js }";{ lv_n }| &&
      |    let socket = null, currentLine = "";{ lv_n }| &&
      |    const term = new Terminal(\{ cursorBlink:true, fontFamily:'"Courier New",monospace', fontSize:14, scrollback:10000,| &&
      |      theme:\{background:'#000',foreground:'#FFB000',cursor:'#FFB000',cursorAccent:'#000'\} \});{ lv_n }| &&
      |    const fitAddon = new FitAddon.FitAddon();{ lv_n }| &&
      |    term.loadAddon(fitAddon); term.open(document.getElementById('terminal')); fitAddon.fit();{ lv_n }| &&
      |    window.addEventListener('resize', () => fitAddon.fit());{ lv_n }| &&
      |    function updateStatus(t,c) \{ const s=document.getElementById('statusText'); s.textContent=t; s.className=c?'connected':'disconnected'; \}{ lv_n }| &&
      |    // Graphics Engine - Modes: 0=ZX attrs, 1=HiRes 256x128, 2=Smooth 512x256{ lv_n }| &&
      |    const PALETTES = [{ lv_n }| &&
      |      ['#000000','#0000D7','#D70000','#D700D7','#00D700','#00D7D7','#D7D700','#D7D7D7'],{ lv_n }| &&
      |      ['#000000','#0000AA','#AA0000','#AA00AA','#00AA00','#00AAAA','#AA5500','#AAAAAA'],{ lv_n }| &&
      |      ['#0F380F','#306230','#8BAC0F','#9BBC0F','#0F380F','#306230','#8BAC0F','#9BBC0F'],{ lv_n }| &&
      |      ['#000000','#331100','#662200','#994400','#CC6600','#FF9900','#FFBB33','#FFDD77'],{ lv_n }| &&
      |      ['#000000','#001100','#003300','#005500','#007700','#00AA00','#00DD00','#00FF00'],{ lv_n }| &&
      |      ['#000000','#242424','#494949','#6D6D6D','#929292','#B6B6B6','#DBDBDB','#FFFFFF'],{ lv_n }| &&
      |      ['#1A1C2C','#5D275D','#B13E53','#EF7D57','#FFCD75','#A7F070','#38B764','#257179'],{ lv_n }| &&
      |      ['#000000','#1D2B53','#7E2553','#008751','#AB5236','#5F574F','#C2C3C7','#FFF1E8']{ lv_n }| &&
      |    ];{ lv_n }| &&
      |    const PALNAMES = ['Spectrum','CGA','Gameboy','Amber','Green','Gray','Pico8','Retro'];{ lv_n }| &&
      |    let gfxMode=1, gfxPalette=0, gfxCanvas=null, gfxCtx=null, gfxLastData=null, gfxViewerMode=false;{ lv_n }| &&
      |    let gfxPixels=new Uint8Array(512*256), gfxBits=new Uint8Array(512*256);{ lv_n }| &&
      |    let gfxInk=new Uint8Array(64*32), gfxPaper=new Uint8Array(64*32), gfxBg=7;{ lv_n }| &&
      |    const gfxW=()=>gfxMode===2?512:256, gfxH=()=>gfxMode===2?256:128, gfxS=()=>gfxMode===2?2:1;{ lv_n }| &&
      |    function gfxClear(bg,fg) \{ gfxPixels.fill(bg); gfxBits.fill(0); gfxInk.fill(fg); gfxPaper.fill(bg); gfxBg=bg; \}{ lv_n }| &&
      |    function gfxPixelRaw(px,py,c) \{| &&
      |      const w=gfxW(),h=gfxH(); if(px<0\|\|px>=w\|\|py<0\|\|py>=h)return;| &&
      |      gfxPixels[py*w+px]=c; gfxBits[py*w+px]=1;| &&
      |    \}{ lv_n }| &&
      |    function gfxPixel(x,y,c) \{| &&
      |      const s=gfxS(); gfxPixelRaw(x*s,y*s,c);| &&
      |      if(gfxMode===0)\{ const ax=x>>3,ay=y>>3,ai=ay*32+ax; if(gfxPaper[ai]===c)gfxInk[ai]=c^7; else gfxInk[ai]=c; \}| &&
      |    \}{ lv_n }| &&
      |    function gfxLineSmooth(x0,y0,x1,y1,c) \{| &&
      |      let dx=Math.abs(x1-x0), dy=Math.abs(y1-y0);| &&
      |      let sx=x0<x1?1:-1, sy=y0<y1?1:-1, err=dx-dy;| &&
      |      while(true) \{| &&
      |        gfxPixelRaw(x0,y0,c);| &&
      |        if(x0===x1&&y0===y1)break;| &&
      |        let e2=2*err;| &&
      |        if(e2>-dy)\{err-=dy;x0+=sx;\} if(e2<dx)\{err+=dx;y0+=sy;\}| &&
      |      \}| &&
      |    \}{ lv_n }| &&
      |    function gfxLine(x,y,c,d,n,m) \{| &&
      |      const s=gfxS(), m0=m; let lastX=x*s,lastY=y*s;| &&
      |      if(d&1) \{| &&
      |        do \{| &&
      |          const cx=x*s,cy=y*s;| &&
      |          if(s>1)gfxLineSmooth(lastX,lastY,cx,cy,c); else gfxPixelRaw(cx,cy,c);| &&
      |          lastX=cx;lastY=cy;| &&
      |          if(d&2)\{if(y<127)y++;else return[x,y];\}else\{if(y>0)y--;else return[x,y];\}| &&
      |          if(m--<=0)\{m=m0;if(d&4)\{if(x>0)x--;else return[x,y];\}else\{if(x<255)x++;else return[x,y];\}\}| &&
      |        \}while(n-->0);| &&
      |      \}else\{| &&
      |        do \{| &&
      |          const cx=x*s,cy=y*s;| &&
      |          if(s>1)gfxLineSmooth(lastX,lastY,cx,cy,c); else gfxPixelRaw(cx,cy,c);| &&
      |          lastX=cx;lastY=cy;| &&
      |          if(d&4)\{if(x>0)x--;else return[x,y];\}else\{if(x<255)x++;else return[x,y];\}| &&
      |          if(m--<=0)\{m=m0;if(d&2)\{if(y<127)y++;else return[x,y];\}else\{if(y>0)y--;else return[x,y];\}\}| &&
      |        \}while(n-->0);| &&
      |      \}| &&
      |      return[x,y];| &&
      |    \}{ lv_n }| &&
      |    function gfxFill(sx,sy,c) \{| &&
      |      const s=gfxS(),w=gfxW(),h=gfxH(); sx*=s;sy*=s;| &&
      |      if(sx<0\|\|sx>=w\|\|sy<0\|\|sy>=h)return;| &&
      |      const target=gfxPixels[sy*w+sx]; if(target===c)return;| &&
      |      const stk=[[sx,sy]];| &&
      |      while(stk.length>0&&stk.length<100000) \{| &&
      |        const[x,y]=stk.pop(); if(x<0\|\|x>=w\|\|y<0\|\|y>=h)continue;| &&
      |        if(gfxPixels[y*w+x]!==target)continue;| &&
      |        gfxPixels[y*w+x]=c;| &&
      |        stk.push([x+1,y],[x-1,y],[x,y+1],[x,y-1]);| &&
      |      \}| &&
      |    \}{ lv_n }| &&
      |    function gfxPaint(a,c,d,n) \{| &&
      |      const s=gfxS(),w=gfxW(),bs=8*s;| &&
      |      do \{| &&
      |        if(a>=0&&a<512) \{| &&
      |          const bx=(a%32)*8*s,by=Math.floor(a/32)*8*s;| &&
      |          for(let py=0;py<bs;py++)for(let px=0;px<bs;px++)\{| &&
      |            const x=bx+px,y=by+py;if(x<w&&y<w/2)\{const idx=y*w+x;if(gfxPixels[idx]===gfxBg)gfxPixels[idx]=c;\}| &&
      |          \}| &&
      |        \}| &&
      |        if(d===0&&a>31)a-=32;else if(d===1&&a<511)a++;else if(d===2&&a<480)a+=32;else if(d===3&&a>0)a--;| &&
      |      \}while(n-->0);| &&
      |      return a;| &&
      |    \}{ lv_n }| &&
      |    function gfxRefresh() \{| &&
      |      if(!gfxCtx)return; const w=gfxW(),h=gfxH(),pal=PALETTES[gfxPalette];| &&
      |      const id=gfxCtx.createImageData(w,h);| &&
      |      for(let y=0;y<h;y++)for(let x=0;x<w;x++)\{| &&
      |        const i=y*w+x; let ci;| &&
      |        ci=gfxPixels[i];| &&
      |        const col=pal[ci]\|\|'#000',j=i*4;| &&
      |        id.data[j]=parseInt(col.substr(1,2),16);id.data[j+1]=parseInt(col.substr(3,2),16);| &&
      |        id.data[j+2]=parseInt(col.substr(5,2),16);id.data[j+3]=255;| &&
      |      \}| &&
      |      gfxCtx.putImageData(id,0,0);| &&
      |    \}{ lv_n }| &&
      |    function gfxSetMode(mode,pal) \{| &&
      |      const old=gfxMode; gfxMode=mode; gfxPalette=pal;| &&
      |      const mn=['Classic ZX','HiRes','Smooth 2x'];| &&
      |      term.writeln('\\r\\n[GFX: '+mn[mode]+' / '+PALNAMES[pal]+']');| &&
      |      if(gfxLastData&&old!==mode)\{resizeCanvas();gfxDraw(gfxLastData);\}| &&
      |      gfxRefresh();| &&
      |    \}{ lv_n }| &&
      |    function resizeCanvas() \{| &&
      |      if(!gfxCanvas)return; const w=gfxW(),h=gfxH();| &&
      |      gfxCanvas.width=w;gfxCanvas.height=h;| &&
      |      gfxCanvas.style.width=(w*2)+'px';gfxCanvas.style.height=(h*2)+'px';| &&
      |      gfxCtx=gfxCanvas.getContext('2d');| &&
      |    \}{ lv_n }| &&
      |    function gfxDraw(data) \{| &&
      |      let pc=0; const border=data[pc++]; let bg=(data[pc]>>3)&7,fg=data[pc++]&7;| &&
      |      if(bg===0&&fg===0)\{bg=0;fg=7;\}| &&
      |      gfxClear(bg,fg); let x=0,y=0,c=fg,op;| &&
      |      while(pc<data.length) \{| &&
      |        op=data[pc++]; if(op===0)break;| &&
      |        if(op===8)\{x=data[pc++];y=127-data[pc++];gfxPixel(x,y,c);\}| &&
      |        else if(op>0x7f)\{const nb=data[pc++];[x,y]=gfxLine(x,y,c,op&7,nb&0x3f,((op&0x78)>>1)+((nb&0xc0)>>6));\}| &&
      |        else if(op>0x3f)\{const fx=data[pc++],fy=127-data[pc++];gfxFill(fx,fy,op&7);\}| &&
      |        else if(op>0x1f)\{const H=data[pc++],L=data[pc++];let a=(H*256+L)-0x5800;| &&
      |          while(pc<data.length&&data[pc]!==0xff)\{const db=data[pc++];a=gfxPaint(a,op&7,db&3,(db&0xfc)>>2);\}| &&
      |          if(data[pc]===0xff)pc++;| &&
      |        \}| &&
      |      \}| &&
      |      return border;| &&
      |    \}{ lv_n }| &&
      |    function showGraphics(hex) \{| &&
      |      try \{| &&
      |        const cont=document.getElementById('graphics-container'),w=gfxW(),h=gfxH();| &&
      |        if(!gfxCanvas)\{| &&
      |          gfxCanvas=document.createElement('canvas');gfxCanvas.tabIndex=0;| &&
      |          gfxCanvas.style.outline='none';gfxCanvas.style.cursor='pointer';| &&
      |          cont.innerHTML='';cont.appendChild(gfxCanvas);| &&
      |          gfxCanvas.onkeydown=handleGfxKey;cont.onclick=()=>gfxCanvas.focus();| &&
      |        \}| &&
      |        gfxCanvas.width=w;gfxCanvas.height=h;| &&
      |        gfxCanvas.style.width=(w*2)+'px';gfxCanvas.style.height=(h*2)+'px';| &&
      |        gfxCtx=gfxCanvas.getContext('2d');| &&
      |        const m=hex.match(/../g); if(!m)return;| &&
      |        const bytes=new Uint8Array(m.map(h=>parseInt(h,16))); gfxLastData=bytes;| &&
      |        const border=gfxDraw(bytes); cont.style.borderColor=PALETTES[gfxPalette][border];| &&
      |        gfxRefresh(); cont.style.display='block'; gfxCanvas.focus();| &&
      |        document.body.classList.add('has-graphics'); fitAddon.fit();| &&
      |      \}catch(e)\{console.error('GFX:',e);\}| &&
      |    \}{ lv_n }| &&
      |    function hideGraphics() \{| &&
      |      const c=document.getElementById('graphics-container');c.style.display='none';c.innerHTML='';gfxCanvas=null;gfxViewerMode=false;| &&
      |      document.body.classList.remove('has-graphics');fitAddon.fit();| &&
      |    \}| &&
      |    function handleGfxKey(e) \{| &&
      |      if(!gfxViewerMode)return;| &&
      |      const k=e.key.toLowerCase();| &&
      |      if(k==='n')\{e.preventDefault();socket.send('__NEXT__');\}| &&
      |      else if(k==='p')\{e.preventDefault();socket.send('__PREV__');\}| &&
      |      else if(k==='s')\{e.preventDefault();gfxSetMode(0,gfxPalette);\}| &&
      |      else if(k==='a')\{e.preventDefault();gfxSetMode(1,gfxPalette);\}| &&
      |      else if(k==='h')\{e.preventDefault();gfxSetMode(2,gfxPalette);\}| &&
      |      else if(k>='1'&&k<='8')\{e.preventDefault();gfxSetMode(gfxMode,parseInt(k)-1);\}| &&
      |      else if(k==='9')\{e.preventDefault();gfxSetMode(gfxMode,(gfxPalette+1)%8);\}| &&
      |      else if(k==='0')\{e.preventDefault();gfxSetMode(gfxMode,(gfxPalette+7)%8);\}| &&
      |    \}{ lv_n }| &&
      |    function connect() \{| &&
      |      const proto=location.protocol==='https:'?'wss:':'ws:';| &&
      |      const url=proto+'//'+location.host+APC_PATH;| &&
      |      term.writeln('\\x1b[33mConnecting to CP/M (Disk: '+CPM_DISK+')...\\x1b[0m');| &&
      |      updateStatus('Connecting...',false); socket=new WebSocket(url);{ lv_n }| &&
      |      socket.onopen=()=>\{term.writeln('\\x1b[38;2;255;176;0m[CONNECTED]\\x1b[0m\\r\\n');updateStatus('Connected',true);socket.send('__DISK__='+CPM_DISK);\};{ lv_n }| &&
      |      socket.onmessage=(e)=>\{const d=e.data;| &&
      |        if(d.startsWith('__GFXV__'))\{gfxViewerMode=d.charAt(8)==='1';\}else if(d.startsWith('__GFX__'))showGraphics(d.substring(7));| &&
      |        else if(d.startsWith('__GFXMODE__'))\{const p=d.substring(11).split(',');gfxSetMode(parseInt(p[0])\|\|1,parseInt(p[1])\|\|0);\}| &&
      |        else term.write(d.replace(/\\r?\\n/g,'\\r\\n'));| &&
      |      \};{ lv_n }| &&
      |      socket.onclose=()=>\{term.writeln('\\r\\n\\x1b[31m[DISCONNECTED]\\x1b[0m');updateStatus('Disconnected',false);currentLine='';hideGraphics();\};{ lv_n }| &&
      |      socket.onerror=()=>\{term.writeln('\\r\\n\\x1b[31m[ERROR]\\x1b[0m');updateStatus('Error',false);\};| &&
      |    \}{ lv_n }| &&
      |    term.onData(data=>\{| &&
      |      if(!socket\|\|socket.readyState!==WebSocket.OPEN)return; const code=data.charCodeAt(0);| &&
      |      if(code===4)\{term.writeln('^D');socket.send('__EOF__');currentLine='';hideGraphics();\}| &&
      |      else if(code===13)\{term.write('\\r\\n');socket.send(currentLine);currentLine='';\}| &&
      |      else if(code===127\|\|code===8)\{if(currentLine.length>0)\{currentLine=currentLine.slice(0,-1);term.write('\\b \\b');\}\}| &&
      |      else if(code>=32)\{currentLine+=data;term.write(data);\}| &&
      |    \});{ lv_n }| &&
      |    connect();{ lv_n }| &&
      |  </script>{ lv_n }| &&
      |</body></html>|.
  ENDMETHOD.

ENDCLASS.
