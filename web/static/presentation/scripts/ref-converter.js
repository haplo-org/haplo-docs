(function() {
    var idToRef = function(id) { 
        if(typeof(id) !== "number") { return; }
        var hex = id.toString(16), output = "";
        for(var i = 0; i < hex.length; i++) {
            var code = hex.charCodeAt(i);
            if(code === 97) { output += 'q'; }
            else if(code > 97) { output += String.fromCharCode(code+20); }
            else { output += hex[i]; }
        }
        return output;
    };

    var refToId = function(ref) { 
        if(typeof(ref) !== "string") { return; }
        if(!/^[0-9|q|v-z]+$/.test(ref)) { return; }
        var untranslated = "";
        for(var i = 0; i < ref.length; i++) {
            var code = ref.charCodeAt(i);
            if(code === 113) { untranslated += 'a'; }
            else if(code > 116) { untranslated += String.fromCharCode(code-20); }
            else { untranslated += ref[i]; }
        }
        var id = parseInt(untranslated, 16);
        return id;
    };

    var idInput = document.querySelector('input[name=ref-converter-id]');
    var refInput = document.querySelector('input[name=ref-converter-ref]');
    idInput.addEventListener('input', function() {
        if(!idInput.value) { refInput.value = ""; return; }
        var id = parseInt(idInput.value, 10);
        if(!id) { refInput.value = ""; }
        if(!isNaN(id)) {
            var ref = idToRef(id);
            refInput.value = ref ? ref : "Invalid id";
        } else { refInput.value = "Invalid id"; }
    });
    refInput.addEventListener('input', function() {
        if(!refInput.value) { idInput.value = ""; return; }
        var id = refToId(refInput.value);
        idInput.value = typeof(id) === "number" ? id : "Invalid ref";
    });
})();
