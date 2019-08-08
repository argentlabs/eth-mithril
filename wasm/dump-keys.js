var path = require('path');
var fs = require('fs');
const _oldLoader = require.extensions['.js'];
require.extensions['.js'] = function(mod, filename) {
    if (filename == path.resolve(path.dirname(module.filename), 'build.emscripten/mixer_cli.js')) {
        var content = require('fs').readFileSync(filename, 'utf8');
        content += ";Module['FS']=FS;Module['NODEFS']=NODEFS;\n";
        mod._compile(content, filename);
    } else {
        _oldLoader(mod, filename);
    }
};

const emscripten_api = require('./build.emscripten/mixer_cli.js');
const data = fs.readFileSync('../.keys/mixer.pk.raw');
emscripten_api.FS.createDataFile("/", "pk.raw", data, true, false);
