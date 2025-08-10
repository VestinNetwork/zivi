const http = require('http');
const createHandler = require('github-webhook-handler');
const { exec } = require('child_process');

const handler = createHandler({ path: '/webhook', secret: 'rahasia-ku' });

http.createServer((req, res) => {
  handler(req, res, err => {
    res.statusCode = 404;
    res.end('No such location');
  });
}).listen(7777, () => {
  console.log('🚀 Webhook server listening on port 7777');
});

handler.on('push', event => {
  console.log(`📩 Push received for ${event.payload.repository.name}`);
  exec('cd /var/www/project/games && ./deploy.sh', (err, stdout, stderr) => {
    if (err) {
      console.error(`❌ Deployment error: ${err}`);
      return;
    }
    console.log(stdout);
    console.error(stderr);
  });
});

