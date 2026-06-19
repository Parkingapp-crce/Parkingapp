const fs = require('fs');
const sourceMap = require('source-map');

async function decode() {
  const rawSourceMap = fs.readFileSync('mobile/apps/user_app/build/web/main.dart.js.map', 'utf8');
  const consumer = await new sourceMap.SourceMapConsumer(rawSourceMap);
  
  const stack = `    at bbF (http://localhost:8101/main.dart.js:6425:19)
    at aUv (http://localhost:8101/main.dart.js:6570:3)
    at $0 (http://localhost:8101/main.dart.js:47108:8)
    at bjB (http://localhost:8101/main.dart.js:5476:5)
    at bjS (http://localhost:8101/main.dart.js:5478:7)
    at $1 (http://localhost:8101/main.dart.js:45850:3)`;

  const regex = /main\.dart\.js:(\d+):(\d+)/g;
  let match;
  while ((match = regex.exec(stack)) !== null) {
    const line = parseInt(match[1]);
    const column = parseInt(match[2]);
    const pos = consumer.originalPositionFor({ line, column });
    console.log(`Line ${line}:${column} -> ${pos.source}:${pos.line}:${pos.column} (${pos.name || ''})`);
  }
  
  consumer.destroy();
}

decode();
