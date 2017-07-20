module.exports = process.env.EXEC_MODE === 'test' ? {
  region: 'ap-northeast-1',
  endpoint: 'http://localhost:4569'
} : undefined;
