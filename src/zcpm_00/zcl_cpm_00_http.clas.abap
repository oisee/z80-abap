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
      |    #graphics-container svg \{ display: block; \}{ lv_n }| &&
      |    #terminal-container \{ border: 2px solid #FFB000; border-radius: 8px; padding: 10px; background: #000; box-shadow: 0 0 20px rgba(255, 176, 0, 0.3); overflow: hidden; width: 95vw; max-width: 1400px; \}{ lv_n }| &&
      |    #terminal \{ width: 100%; height: 70vh; \}{ lv_n }| &&
      |    .has-graphics #terminal \{ height: 45vh; \}{ lv_n }| &&
      |    #status \{ color: #888; margin-top: 8px; font-size: 11px; \}{ lv_n }| &&
      |    .connected \{ color: #FFB000 !important; \}{ lv_n }| &&
      |    .disconnected \{ color: #ff4444 !important; \}{ lv_n }| &&
      |    ::-webkit-scrollbar \{ width: 12px; height: 12px; \}{ lv_n }| &&
      |    ::-webkit-scrollbar-track \{ background: #0a0a0a; border: 1px solid #332200; \}{ lv_n }| &&
      |    ::-webkit-scrollbar-thumb \{ background: #AA7000; border: 1px solid #FFB000; border-radius: 2px; \}{ lv_n }| &&
      |    ::-webkit-scrollbar-thumb:hover \{ background: #FFB000; \}{ lv_n }| &&
      |    ::-webkit-scrollbar-corner \{ background: #0a0a0a; \}{ lv_n }| &&
      |    * \{ scrollbar-width: thin; scrollbar-color: #AA7000 #0a0a0a; \}{ lv_n }| &&
      |  </style>{ lv_n }| &&
      |</head>{ lv_n }| &&
      |<body>{ lv_n }| &&
      |  <h1>CP/M on SAP HANA</h1>{ lv_n }| &&
      |  <div id="graphics-container"></div>{ lv_n }| &&
      |  <div id="terminal-container"><div id="terminal"></div></div>{ lv_n }| &&
      |  <div id="status">Disk: <span id="diskName">{ iv_disk }</span> - <span id="statusText" class="disconnected">Connecting...</span> - Ctrl+D: break</div>{ lv_n }| &&
      |  <script src="https://cdn.jsdelivr.net/npm/xterm@5.3.0/lib/xterm.js"></script>{ lv_n }| &&
      |  <script src="https://cdn.jsdelivr.net/npm/xterm-addon-fit@0.8.0/lib/xterm-addon-fit.js"></script>{ lv_n }| &&
      |  <script>{ lv_n }| &&
      |    const APC_PATH = "/sap/bc/apc/sap/zcpm";{ lv_n }| &&
      |    const CPM_DISK = "{ lv_disk_js }";{ lv_n }| &&
      |    let socket = null;{ lv_n }| &&
      |    let currentLine = "";{ lv_n }| &&
      |    const term = new Terminal(\{| &&
      |      cursorBlink: true,| &&
      |      fontFamily: '"Courier New", Courier, monospace',| &&
      |      fontSize: 14,| &&
      |      scrollback: 10000,| &&
      |      theme: \{ background: '#000000', foreground: '#FFB000', cursor: '#FFB000', cursorAccent: '#000000' \}| &&
      |    \});{ lv_n }| &&
      |    const fitAddon = new FitAddon.FitAddon();{ lv_n }| &&
      |    term.loadAddon(fitAddon);{ lv_n }| &&
      |    term.open(document.getElementById('terminal'));{ lv_n }| &&
      |    fitAddon.fit();{ lv_n }| &&
      |    window.addEventListener('resize', () => fitAddon.fit());{ lv_n }| &&
      |    function updateStatus(text, connected) \{| &&
      |      document.getElementById('statusText').textContent = text;| &&
      |      document.getElementById('statusText').className = connected ? 'connected' : 'disconnected';| &&
      |    \}{ lv_n }| &&
      |    function showGraphics(svgContent) \{| &&
      |      const container = document.getElementById('graphics-container');| &&
      |      container.innerHTML = svgContent;| &&
      |      container.style.display = 'block';| &&
      |      document.body.classList.add('has-graphics');| &&
      |      fitAddon.fit();| &&
      |    \}{ lv_n }| &&
      |    function hideGraphics() \{| &&
      |      const container = document.getElementById('graphics-container');| &&
      |      container.style.display = 'none';| &&
      |      container.innerHTML = '';| &&
      |      document.body.classList.remove('has-graphics');| &&
      |      fitAddon.fit();| &&
      |    \}{ lv_n }| &&
      |    function connect() \{| &&
      |      const protocol = location.protocol === 'https:' ? 'wss:' : 'ws:';| &&
      |      const wsUrl = protocol + '//' + location.host + APC_PATH;| &&
      |      term.writeln('\\x1b[33mConnecting to CP/M (Disk: ' + CPM_DISK + ')...\\x1b[0m');| &&
      |      updateStatus('Connecting...', false);| &&
      |      socket = new WebSocket(wsUrl);{ lv_n }| &&
      |      socket.onopen = () => \{| &&
      |        term.writeln('\\x1b[38;2;255;176;0m[CONNECTED]\\x1b[0m\\r\\n');| &&
      |        updateStatus('Connected - CP/M 2.2', true);| &&
      |        socket.send('__DISK__=' + CPM_DISK);| &&
      |      \};{ lv_n }| &&
      |      socket.onmessage = (e) => \{| &&
      |        const data = e.data;| &&
      |        if (data.startsWith('__GFX__')) \{| &&
      |          const svg = data.substring(7);| &&
      |          showGraphics(svg);| &&
      |        \} else \{| &&
      |          term.write(data.replace(/\\r?\\n/g, '\\r\\n'));| &&
      |        \}| &&
      |      \};{ lv_n }| &&
      |      socket.onclose = () => \{| &&
      |        term.writeln('\\r\\n\\x1b[31m[DISCONNECTED]\\x1b[0m');| &&
      |        updateStatus('Disconnected', false);| &&
      |        currentLine = "";| &&
      |        hideGraphics();| &&
      |      \};{ lv_n }| &&
      |      socket.onerror = () => \{| &&
      |        term.writeln('\\r\\n\\x1b[31m[CONNECTION ERROR]\\x1b[0m');| &&
      |        updateStatus('Error', false);| &&
      |      \};{ lv_n }| &&
      |    \}{ lv_n }| &&
      |    term.onData(data => \{| &&
      |      if (!socket \|\| socket.readyState !== WebSocket.OPEN) return;| &&
      |      const code = data.charCodeAt(0);{ lv_n }| &&
      |      if (code === 4) \{| &&
      |        term.writeln('^D');| &&
      |        socket.send('__EOF__');| &&
      |        currentLine = "";| &&
      |        hideGraphics();| &&
      |      \} else if (code === 13) \{| &&
      |        term.write('\\r\\n');| &&
      |        socket.send(currentLine);| &&
      |        currentLine = "";| &&
      |      \} else if (code === 127 \|\| code === 8) \{| &&
      |        if (currentLine.length > 0) \{| &&
      |          currentLine = currentLine.slice(0, -1);| &&
      |          term.write('\\b \\b');| &&
      |        \}| &&
      |      \} else if (code >= 32) \{| &&
      |        currentLine += data;| &&
      |        term.write(data);| &&
      |      \}| &&
      |    \});{ lv_n }| &&
      |    connect();{ lv_n }| &&
      |  </script>{ lv_n }| &&
      |</body>{ lv_n }| &&
      |</html>|.
  ENDMETHOD.

ENDCLASS.
