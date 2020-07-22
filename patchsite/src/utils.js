export function reportIssue(text, icon) {
  let ic = icon;
  if (icon === false) {
    ic = "😭";
  }
  if (icon === true) {
    ic = "😊";
  }

    const el = document.getElementById('warnings');
    el.innerText += (ic ? ic + ' '  : '') + text + '\n';
}


export function base64Decode(base64) {
  var decoded = window.atob(base64);
  const bin = new Uint8Array(decoded.length);
  for (let i=0; i<decoded.length; ++i) {
    bin[i] = decoded.charCodeAt(i);
  }
  return bin;
}

export function parseINES(binary) {
  if (binary[0] !== 0x4E) return false;
  if (binary[1] !== 0x45) return false;
  if (binary[2] !== 0x53) return false;
  if (binary[3] !== 0x1A) return false;

  const prgs = binary[4];
  const chrs = binary[5];

  const mapper = ((binary[6] & 0xF0) >> 4) + ((binary[7] & 0xF0) << 4);

  return {
    mapper: mapper,
    prg: prgs,
    chr: chrs,
  }
}