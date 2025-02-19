mergeInto(LibraryManager.library, {
    openFilePicker: function () {
        showOpenFilePicker({
            multiple: false,
            excludeAcceptAllOption: true,
            types: [
                {
                    description: "Jazz2 Level",
                    accept: {
                        "application/x-jazz2-level": ".j2l"
                    }
                }
            ]
        }).then(function (files) {
            files[0].getFile().then(function (file) {
                console.log(file);
                file.arrayBuffer().then(function (buffer) {
                    let ptrName = Module.stringToNewUTF8(file.name);
                    let ptrData = Module._malloc(buffer.byteLength);
                    let dataHeap = new Uint8Array(Module.HEAPU8.buffer, ptrData, buffer.byteLength);
                    dataHeap.set(new Uint8Array(buffer));
                    _openFileCompleted(ptrName, buffer.byteLength, dataHeap.byteOffset);
                    Module._free(ptrData);
                    Module._free(ptrName);
                })
            })
        }).catch(function (err) {
            console.log("file pick aborted", err);
        });
    }
});
