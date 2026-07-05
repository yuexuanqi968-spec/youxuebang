// Netlify 构建脚本：从环境变量生成 Supabase 配置文件
var fs = require('fs');
var path = require('path');

var config = [
  "window.SUPABASE_URL = '" + process.env.SUPABASE_URL + "';",
  "window.SUPABASE_ANON_KEY = '" + process.env.SUPABASE_ANON_KEY + "';",
  ""
].join('\n');

var dir = 'js';
if (!fs.existsSync(dir)) {
  fs.mkdirSync(dir, { recursive: true });
}

fs.writeFileSync(path.join(dir, 'supabase-config.js'), config, 'utf8');
console.log('✅ js/supabase-config.js generated');
