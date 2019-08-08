// Nasty hack to write files to local directory
// Requires access to the FS and NODEFS local variables
// These aren't accessible via the modules interface

var path = require('path');
const _oldLoader = require.extensions['.js'];
require.extensions['.js'] = function(mod, filename) {
    if (filename == path.resolve(path.dirname(module.filename), 'build.emscripten/mixer_selftest.js')) {
        var content = require('fs').readFileSync(filename, 'utf8');
        content += ";Module['FS']=FS;Module['NODEFS']=NODEFS;\n";
        mod._compile(content, filename);
    } else {
        _oldLoader(mod, filename);
    }
};

const emscripten_api = require('./build.emscripten/mixer_selftest.js');
emscripten_api['FS'].mkdir('/working');
emscripten_api['FS'].mount(emscripten_api['NODEFS'], { root: '.'}, '/working');
emscripten_api.arguments = ['/working/test.pk.raw', '/working/test.vk.json', '/working/test.proof.json', '/working/test.inputs.json'];
