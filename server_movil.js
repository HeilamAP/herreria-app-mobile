const http = require('http');
const fs = require('fs');
const path = require('path');
const os = require('os');

const PORT = 8085;
const WEB_DIR = path.join(__dirname, 'build', 'web');

function getLocalIp() {
  const nets = os.networkInterfaces();
  // Check Wi-Fi or Ethernet first
  for (const name of Object.keys(nets)) {
    for (const net of nets[name]) {
      if (net.family === 'IPv4' && !net.internal) {
        return net.address;
      }
    }
  }
  return 'localhost';
}

const MIME_TYPES = {
  '.html': 'text/html; charset=UTF-8',
  '.js': 'application/javascript; charset=UTF-8',
  '.mjs': 'application/javascript; charset=UTF-8',
  '.json': 'application/json; charset=UTF-8',
  '.wasm': 'application/wasm',
  '.css': 'text/css; charset=UTF-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
};

function renderQrPage(localIp, port) {
  const targetUrl = `http://${localIp}:${port}`;
  const qrImgUrl = `https://api.qrserver.com/v1/create-qr-code/?size=280x280&margin=10&data=${encodeURIComponent(targetUrl)}`;
  const fallbackQr = `https://quickchart.io/qr?size=280&text=${encodeURIComponent(targetUrl)}`;

  return `<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Abrir en Celular - Ay Oy Herrería</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      background: linear-gradient(135deg, #0B1120 0%, #0F172A 50%, #020617 100%);
      color: #F8FAFC;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 24px;
    }
    .card {
      background: rgba(30, 41, 59, 0.7);
      backdrop-filter: blur(16px);
      -webkit-backdrop-filter: blur(16px);
      border: 1px solid rgba(56, 189, 248, 0.25);
      border-radius: 28px;
      max-width: 480px;
      width: 100%;
      padding: 32px 28px;
      text-align: center;
      box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.6), 0 0 40px rgba(56, 189, 248, 0.15);
    }
    .badge {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 6px 14px;
      background: rgba(16, 185, 129, 0.15);
      border: 1px solid rgba(16, 185, 129, 0.4);
      border-radius: 20px;
      font-size: 13px;
      color: #34D399;
      font-weight: 600;
      margin-bottom: 20px;
    }
    .badge-dot {
      width: 8px;
      height: 8px;
      background: #10B981;
      border-radius: 50%;
      box-shadow: 0 0 10px #10B981;
      animation: pulse 1.8s infinite;
    }
    @keyframes pulse {
      0%, 100% { opacity: 1; transform: scale(1); }
      50% { opacity: 0.4; transform: scale(0.85); }
    }
    h1 {
      font-size: 26px;
      font-weight: 800;
      letter-spacing: -0.5px;
      margin-bottom: 6px;
      color: #FFFFFF;
    }
    .subtitle {
      color: #38BDF8;
      font-size: 15px;
      font-weight: 600;
      margin-bottom: 22px;
    }
    .qr-container {
      background: #FFFFFF;
      border-radius: 20px;
      padding: 16px;
      display: inline-block;
      margin-bottom: 20px;
      box-shadow: 0 12px 24px rgba(0, 0, 0, 0.4);
      border: 3px solid #38BDF8;
    }
    .qr-container img {
      width: 240px;
      height: 240px;
      display: block;
      border-radius: 12px;
    }
    .url-box {
      background: rgba(15, 23, 42, 0.8);
      border: 1px solid rgba(148, 163, 184, 0.2);
      border-radius: 14px;
      padding: 12px 14px;
      margin-bottom: 24px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 10px;
    }
    .url-text {
      font-family: monospace;
      font-size: 15px;
      color: #E2E8F0;
      font-weight: 600;
      word-break: break-all;
      text-align: left;
    }
    .btn-copy {
      background: #0284C7;
      color: white;
      border: none;
      padding: 8px 14px;
      border-radius: 10px;
      font-size: 13px;
      font-weight: 600;
      cursor: pointer;
      white-space: nowrap;
      transition: all 0.2s;
    }
    .btn-copy:hover {
      background: #0369A1;
      transform: translateY(-1px);
    }
    .steps {
      text-align: left;
      background: rgba(15, 23, 42, 0.5);
      border-radius: 16px;
      padding: 18px 16px;
      border: 1px solid rgba(255, 255, 255, 0.05);
      margin-bottom: 20px;
    }
    .steps h3 {
      font-size: 14px;
      font-weight: 700;
      color: #94A3B8;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      margin-bottom: 12px;
    }
    .step-item {
      display: flex;
      align-items: flex-start;
      gap: 12px;
      margin-bottom: 10px;
      font-size: 14px;
      color: #CBD5E1;
      line-height: 1.4;
    }
    .step-item:last-child { margin-bottom: 0; }
    .step-num {
      width: 22px;
      height: 22px;
      background: #0284C7;
      color: white;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 12px;
      font-weight: 700;
      flex-shrink: 0;
      margin-top: 2px;
    }
    .highlight {
      color: #38BDF8;
      font-weight: 600;
    }
    .btn-pc {
      display: block;
      width: 100%;
      text-decoration: none;
      background: rgba(56, 189, 248, 0.12);
      border: 1px solid rgba(56, 189, 248, 0.3);
      color: #38BDF8;
      padding: 12px;
      border-radius: 14px;
      font-size: 14px;
      font-weight: 600;
      transition: all 0.2s;
    }
    .btn-pc:hover {
      background: rgba(56, 189, 248, 0.22);
      color: #FFFFFF;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="badge">
      <span class="badge-dot"></span>
      Servidor Activo en Red Local
    </div>

    <h1>Ay Oy Herrería Artística</h1>
    <p class="subtitle">Escanear para abrir en tu iPhone</p>

    <div class="qr-container">
      <img src="${qrImgUrl}" onerror="this.src='${fallbackQr}'" alt="Código QR">
    </div>

    <div class="url-box">
      <span class="url-text" id="targetUrl">${targetUrl}</span>
      <button class="btn-copy" onclick="copyUrl()">Copiar</button>
    </div>

    <div class="steps">
      <h3>Instrucciones para iPhone:</h3>
      <div class="step-item">
        <span class="step-num">1</span>
        <span>Asegúrate de que tu iPhone esté conectado al <span class="highlight">mismo Wi-Fi</span> que esta PC.</span>
      </div>
      <div class="step-item">
        <span class="step-num">2</span>
        <span>Abre la <span class="highlight">Cámara</span> de tu iPhone y apunta al código QR.</span>
      </div>
      <div class="step-item">
        <span class="step-num">3</span>
        <span>Toca la notificación amarilla de Safari para ingresar a la app.</span>
      </div>
      <div class="step-item">
        <span class="step-num">★</span>
        <span><em>Tip pantalla completa:</em> En Safari toca <span class="highlight">Compartir (⎋)</span> y luego <span class="highlight">"Agregar a pantalla de inicio"</span>.</span>
      </div>
    </div>

    <a href="/" class="btn-pc">🖥️ Abrir App también en esta PC</a>
  </div>

  <script>
    function copyUrl() {
      const text = document.getElementById('targetUrl').innerText;
      navigator.clipboard.writeText(text).then(() => {
        const btn = document.querySelector('.btn-copy');
        btn.innerText = '¡Copiado!';
        setTimeout(() => btn.innerText = 'Copiar', 2000);
      });
    }
  </script>
</body>
</html>`;
}

const server = http.createServer((req, res) => {
  // Normalize URL
  const reqUrl = req.url.split('?')[0];

  // QR landing page
  if (reqUrl === '/qr' || reqUrl === '/qr.html') {
    const localIp = getLocalIp();
    res.writeHead(200, { 'Content-Type': 'text/html; charset=UTF-8' });
    res.end(renderQrPage(localIp, PORT));
    return;
  }

  // Check if build/web exists
  if (!fs.existsSync(WEB_DIR)) {
    res.writeHead(503, { 'Content-Type': 'text/html; charset=UTF-8' });
    res.end(`<h2>Compilando versión web...</h2><p>Por favor ejecuta 'flutter build web --release' primero.</p>`);
    return;
  }

  // Resolve file path
  let relativePath = reqUrl === '/' ? 'index.html' : reqUrl.replace(/^\//, '');
  let filePath = path.join(WEB_DIR, relativePath);

  // Security check: prevent directory traversal
  if (!filePath.startsWith(WEB_DIR)) {
    res.writeHead(403);
    res.end('Acceso denegado');
    return;
  }

  // Check if requested file exists, otherwise fallback to index.html (SPA)
  if (!fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
    filePath = path.join(WEB_DIR, 'index.html');
  }

  const ext = path.extname(filePath).toLowerCase();
  const contentType = MIME_TYPES[ext] || 'application/octet-stream';

  fs.readFile(filePath, (err, content) => {
    if (err) {
      res.writeHead(500, { 'Content-Type': 'text/plain; charset=UTF-8' });
      res.end('Error al leer archivo: ' + err.message);
      return;
    }
    res.writeHead(200, {
      'Content-Type': contentType,
      'Cache-Control': 'no-cache',
    });
    res.end(content);
  });
});

server.listen(PORT, '0.0.0.0', () => {
  const localIp = getLocalIp();
  console.log('================================================================');
  console.log('  SERVIDOR MOVIL INICIADO - AY OY HERRERIA ARTISTICA');
  console.log('================================================================');
  console.log(`  IP Local Wi-Fi: http://${localIp}:${PORT}`);
  console.log(`  Pantalla con Codigo QR: http://localhost:${PORT}/qr`);
  console.log('================================================================');
  console.log('  1. Conecta tu iPhone al mismo Wi-Fi que esta PC');
  console.log('  2. Escanea el codigo QR con la Camara de tu iPhone');
  console.log('  3. Pulsa Ctrl+C en esta ventana para detener el servidor');
  console.log('================================================================\n');
});
