module.exports = process.argv.includes('--mock') ? {
  region: 'ap-northeast-1',
  endpoint: 'http://localhost:4569',
  // port: 4569
} : undefined;
