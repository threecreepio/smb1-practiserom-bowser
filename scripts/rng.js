const initialSeed = [0xA5, 0x00, 0x4A, 0x4A, 0xDE, 0x4B, 0xF7];
//const initialSeed = [0xA5, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
const frameruleFrames = 21;

function hextext(seed) {
    return seed.map(s => s.toString(16).padStart(2, '0').toUpperCase()).join('');
}

function ror(val, carry) {
    return [
        (val >> 1) | (carry ? 0x80 : 0),
        (val & 1) > 0
    ];
}

function advance(seed) {
    var carry = ((seed[0] & 0x02) ^ (seed[1] & 0x02)) > 0;
    var result = [], tmp;
    for (let i=0; i<seed.length; ++i) {
        [tmp, carry] = ror(seed[i], carry);
        result.push(tmp)
    }
    return result;
}

function genQuickResume() {
    var rng = initialSeed;
    var result = [];
    var result_itc = [];
    let itc = 4;
    for (var s=0; s<0x100; ++s) {
        result.push(rng);
        itc -= 4;
        if (itc < 0) itc += 21;
        result_itc.push(itc);
        for (var i=0; i<0x100; ++i) {
            rng = advance(rng);
        }
    }
    return [result, result_itc];
}

function printQuickResume() {
    var [qr, qr_itc] = genQuickResume();
    for (var i=0; i<7; ++i) {
        var values = '$' + qr.map(q => q[i].toString(16).padStart(2, '0')).join(',$');
        console.log('resume_' + i + ': .byte ' + values);
    }
    var values = '$' + qr_itc.map(q => q.toString(16).padStart(2, '0')).join(',$');
    console.log('resume_itc: .byte ' + values);
}

function seekPattern(rng) {
    // F35EB805757F95
    const stripped = String(rng).replace(/[^0-9A-F]/ig, '');
    const pattern = [];
    for (let i=0; i<14; i+=2) {
        pattern.push(parseInt(rng.substring(i, i+2)||0, 16));
    }
    let srng = initialSeed;
    console.log('Searching for RNG pattern: ' + hextext(pattern))
    for (let f=0; f<(3*0xFFFF);++f) {
        const found = srng.findIndex((p, i) => pattern[i] != srng[i]);
        if (found == -1) {
            const pframe = (f).toString(16).padStart(5).toUpperCase();
            console.log(` - ${hextext(srng)} @ frame ${pframe.toString(16).padStart(5)}, framerule ${((f/frameruleFrames)|0).toString().padStart(4)} (x ${((21-(f%frameruleFrames))%21).toString(16).padStart(2)})`);
        }
        srng = advance(srng);
    }
}

function seekPatternAtFrame(frame) {
    let f = 0;
    let srng = initialSeed;
    for (f=0; f<frame; ++f) srng = advance(srng);
    const pframe = (f).toString(16).padStart(5).toUpperCase();
    console.log(` - ${hextext(srng)} @ frame ${pframe.toString(16).padStart(5)}, framerule ${((f/frameruleFrames)|0).toString().padStart(4)} (x ${(21 - (f%frameruleFrames)).toString(16).padStart(2)})`);
}

function seekPatternAtFR(framerule, frame) {
    return seekPatternAtFrame((framerule * frameruleFrames) + frame);
}



//seekPatternAtFrame(100);
//seekPatternAtFrame(0x7FFF);

if (process.argv[2] == 'quick-resume') {
    printQuickResume();
} else {
    for (let i=2; i<process.argv.length; ++i) {
        seekPattern(process.argv[i]);
        console.log();
    }
}
