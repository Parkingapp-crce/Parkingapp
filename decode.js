const fs = require('fs');
const sourceMap = require('source-map');

async function decode() {
  const rawSourceMap = fs.readFileSync('mobile/apps/user_app/build/web/main.dart.js.map', 'utf8');
  const consumer = await new sourceMap.SourceMapConsumer(rawSourceMap);
  
  const positions = [
    { line: 6425, column: 19 },
    { line: 6570, column: 3 },
    { line: 47108, column: 8 }
  ];
  
  for (const pos of positions) {
    const originalPosition = consumer.originalPositionFor({
      line: pos.line,
      column: pos.column
    });
    console.log(`Line ${pos.line}:${pos.column} -> ${originalPosition.source}:${originalPosition.line}:${originalPosition.column}`);
  }
  
  consumer.destroy();
}

decode();
