// https://gist.github.com/kawanet/5553478

function normalizeKana(src) {
  return src.replace(/[\u30a1-\u30f6]/g, function(match) {
    var chr = match.charCodeAt(0) - 0x60;
    return String.fromCharCode(chr);
  });
}

// http://www13.plala.or.jp/bigdata/kanji_2.html
function normalizeKanji(src) {
  return src
    .replace(/[髙]/g, '高')
    .replace(/[槗𣘺𣘺嵜]/g, '橋')
    .replace(/[斎齊齋]/g, '斉')
    .replace(/[籐]/g, '藤')
    .replace(/[邊邉邉󠄂邉󠄃邉󠄄邉󠄅邉󠄆邉󠄇邉󠄈邉󠄉邉󠄊邉󠄋邉󠄌邉󠄍邉󠄎邊󠄁邊󠄂邊󠄃邊󠄄邊󠄅邊󠄆邊󠄇]/g, '辺')
    .replace(/[𠮷]/g, '吉')
    .replace(/[濱濵]/g, '浜')
    .replace(/[﨑碕嵜]/g, '崎');
}

function normalizeRoma(src) {
  return src
    .replace(/shi/g, 'si')
    .replace(/chi/g, 'ti')
    .replace(/tsu/g, 'tu')
    .replace(/sya/g, 'sha')
    .replace(/syu/g, 'shu')
    .replace(/syo/g, 'sho')
    .replace(/tya/g, 'cha')
    .replace(/tyu/g, 'chu')
    .replace(/tyo/g, 'cho');
}

// http://www.asahi-net.or.jp/~ax2s-kmtn/ref/unicode/u2460.html
function normalizeNumber(src) {
  return src
    .replace(/[\u2460-\u2473]/g, function(match) {
      return (match.charCodeAt(0) - 0x2460 + 1) + '';
    })
    .replace(/[\u2474-\u2487]/g, function(match) {
      return (match.charCodeAt(0) - 0x2474 + 1) + '';
    })
    .replace(/[\u2488-\u249b]/g, function(match) {
      return (match.charCodeAt(0) - 0x2488 + 1) + '';
    });
}

// http://www.asahi-net.or.jp/~ax2s-kmtn/ref/unicode/uff00.html
function normalizeFullWidth(src) {
  return src.replace(/[\uff01-\uff5e]/g, function(match) {
    var chr = match.charCodeAt(0) - 0xff01 + 0x21;
    return String.fromCharCode(chr);
  });
}

// https://github.com/jinjor/ja-en-separator/blob/master/package/content-script.js
function separateJaEn(src) {
  return src
    .replace(/ ?([^\x01-\x7E]+) ?/g, ' $1 ')
    .replace(/^ /, '')
    .replace(/ $/, '');
}

function normalizeSpace(src) {
  return src
    .replace(/[　\r\n\t]+/g, ' ')
    .trim()
    .replace(/[ ]+/g, ' ');
}

function normalize(src) {
  var tmp = src || '';
  tmp = normalizeFullWidth(tmp);
  tmp = normalizeNumber(tmp);
  tmp = tmp.toLowerCase();
  tmp = normalizeKana(tmp);
  tmp = normalizeKanji(tmp);
  tmp = normalizeRoma(tmp);
  tmp = separateJaEn(tmp);
  tmp = normalizeSpace(tmp);
  return tmp;
}

function tokenize(src) {
  return src.split(/[ \/／・]+/g);
}

function getKeys(object) {
  var normalized = normalize(object.name);
  var tokens = tokenize(normalized);
  return tokens;
}

module.exports = {
  normalize: normalize,
  getKeys: getKeys
};
