"""
Created in July, 2022 by
[chifi - an open source software dynasty.](https://github.com/orgs/ChifiSource)
by team
[toolips](https://github.com/orgs/ChifiSource/teams/toolips)
This software is MIT-licensed.
### ToolipsUploader
The toolips uploader provides both a server extension for handling incoming server
    uploads, as well as some component upload buttons that can be written to send
    files to the server.
##### Module Composition
- [**Toolips**](https://github.com/ChifiSource/Toolips.jl)
"""
module ToolipsUploader
import Base: read
using Toolips
using Toolips.Components
import Toolips: AbstractRoute, Modifier
using ToolipsSession
import ToolipsSession: AbstractComponentModifier, InputMap, bind, do_session_command, register!

struct StreamFileInfo
    size::Int64
    loaded::Int64
    data::AbstractString
end

function default_complete(cm::ComponentModifier)
    push!(cm.changes, "console.log('upload complete');")
end

function default_progress(cm::ComponentModifier, info::StreamFileInfo)
    push!(cm.changes, "console.log('sent info to server');")
    @info "unhandled uploaded file bytes (no progress function): $(info.loaded) / $(info.size)"
end

function default_init(cm::ComponentModifier, filesize::Integer, name::AbstractString)
    push!(cm.changes, "console.log('started upload');")
end

mutable struct UploadMap <: InputMap
    init::Function
    progress::Function
    complete::Function
    UploadMap() = new(default_init, default_progress, default_complete)::UploadMap
end

function do_session_command(c::AbstractConnection, command::Type{ToolipsSession.SessionCommand{:UPL}}, raw::String)
    raw = replace(raw, "UPL|!|" => "")
    argsplits = split(raw, ";!;")
    fs = c[:uploads][argsplits[2]]
    inp_cmd = argsplits[1]
    cm = nothing
    if inp_cmd == "1"
        # upload continue
        cm = ComponentModifier("")
        datastr = String([parse(UInt8, val) for val in split(argsplits[5], ",")])
        info = StreamFileInfo(parse(Int64, argsplits[4]), parse(Int64, argsplits[3]), datastr)
        fs[2](cm, info)
    else
        # upload start
        cm = ComponentModifier(string(argsplits[5]))
        fs[1](cm, parse(Int64, argsplits[3]), argsplits[4])
    end
    write!(c, cm)
end

function bind(c::AbstractConnection, fileinput::Component{:fileinput}, um::UploadMap)
    complete_ref = Toolips.gen_ref(8)
    register!(c, complete_ref) do cm::ComponentModifier
        sleep(1)
        delete!(c[:uploads], complete_ref)
        um.complete(cm)
    end
    upload_id::String = Toolips.gen_ref(10)
    
    scr = script(text = """setTimeout(function () { document.getElementById("$(fileinput.name)").onchange = async () => {
            let fileInput = document.getElementById("$(fileinput.name)");
			let file = fileInput.files[0];
			let totalBytes = file.size;
			let chunkSize = 1024 * 64; // 64 KB
			let offset = 0;
            var bodyHtml = document.getElementsByTagName('body')[0].innerHTML;
            sendinfo('UPL|!|' + "0" + ';!;' + "$upload_id" + ';!;' + totalBytes + ';!;' + file.name + ';!;' + bodyHtml);
			while (offset < totalBytes) {
				let slice = file.slice(offset, offset + chunkSize);
				let chunk = await slice.arrayBuffer();       // raw bytes
				let bytes = new Uint8Array(chunk);           // Uint8Array view

				offset += bytes.length;
				// here you literally have the raw `bytes`
				// e.g., bytes[0], bytes[1], etc.
                sendinfo('UPL|!|' + "1" + ';!;' + "$upload_id" + ';!;' + offset + ';!;' + totalBytes + ';!;' + bytes);
			}
            sendpage("$complete_ref")
        };}, 500);""")
    push!(fileinput[:extras], scr)
    if ~(haskey(c.data, :uploads))
        push!(c.data, :uploads => Dict{String, Tuple{Function, Function}}(upload_id => (um.init, um.progress)))
    else
        push!(c.data[:uploads], upload_id => (um.init, um.progress))
    end
    nothing::Nothing
end

function fileinput(name::String = "", p::Pair{String, String} ... ; args ...)
    Component{:fileinput}(name, p ..., type = "file", files = "-", tag = "input"; args ...)
end

function area_fileinput()

end

export fileinput, StreamFileInfo
end # module
