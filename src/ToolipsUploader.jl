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

function empty_binding(cm::ComponentModifier) end

mutable struct UploadMap <: InputMap
    init::Function
    progress::Function
    complete::Function
    UploadMap() = new(empty_binding, empty_binding, empty_binding)::UploadMap
end

function do_session_command(c::AbstractConnection, command::Type{ToolipsSession.SessionCommand{:UPL}}, raw::String)
    @warn raw
    write!(c, "alert('hi');")
end

function bind(c::AbstractConnection, fileinput::Component{:fileinput}, um::UploadMap)
    init_ref = Toolips.gen_ref(8)
    complete_ref = Toolips.gen_ref(8)
    upload_id::String = Toolips.gen_ref(10)
    register!(um.init, c, init_ref)
    register!(um.complete, c, complete_ref)
    scr = script(text = """setTimeout(function () { document.getElementById("$(fileinput.name)").onchange = async () => {
            let fileInput = document.getElementById("$(fileinput.name)");
			let file = fileInput.files[0];
			let totalBytes = file.size;
			let chunkSize = 1024 * 64; // 64 KB
			let offset = 0;

            sendpage("$init_ref")
			while (offset < totalBytes) {
				let slice = file.slice(offset, offset + chunkSize);
				let chunk = await slice.arrayBuffer();       // raw bytes
				let bytes = new Uint8Array(chunk);           // Uint8Array view

				offset += bytes.length;
				// here you literally have the raw `bytes`
				// e.g., bytes[0], bytes[1], etc.
                sendinfo('UPL|!|' + offset + ';!;' + totalBytes + ';!;' + bytes);
			}
            sendpage("$complete_ref")
        };}, 500);""")
    push!(fileinput[:extras], scr)
    if ~(haskey(c.data, :uploads))

    else
        push!(c.data[:uploads], )
    end
    nothing::Nothing
end

function fileinput(name::String = "", p::Pair{String, String} ... ; args ...)
    Component{:fileinput}(name, p ..., type = "file", files = "-", tag = "input"; args ...)
end

function area_fileinput()

end

export Uploader, fileinput
end # module
