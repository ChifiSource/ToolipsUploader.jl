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
```julia

```
"""
module ToolipsUploader
import Base: read
using Toolips
using Toolips.Components
import Toolips: AbstractRoute, Modifier
using ToolipsSession
import ToolipsSession: AbstractComponentModifier, InputMap, bind, do_session_command, register!

"""
```julia
struct StreamFileInfo{T <: AbstractString}
```
- `size`**::Int64**
- `loaded`**::Int64**
- `data`**::T**

`StreamFileInfo` contains information on a currently uploading file. This structure is passed, 
alongside a `ComponentModifier`, to a *progress* function for an upload map. In this progress function, 
the `size` and `data` can be used to get an upload percentage and `loaded` holds the currently loaded data, which 
could easily be written to a file. Make sure to check out `UploadMap` before learning more about this structure.
```julia
StreamFileInfo(::Int64, ::Int64, ::AbstractString)
```
example
```julia
function upmprog(cm::ComponentModifier, info::StreamFileInfo)
    upl_data = upl_data * info.data
end
```
- See also: `UploadMap`, `Components.bind`, `fileinput`
"""
struct StreamFileInfo{T <: AbstractString}
    size::Int64
    loaded::Int64
    data::T
    StreamFileInfo(size::Integer, loaded::Integer, data::AbstractString) = new{typeof(data)}(size, loaded, data)
end

"""
```julia
default_complete(cm::ComponentModifier) -> ::Nothing
```
The default *complete* function for an `UploadMap`. Simply `console.logs` `upload complete`.
```julia
```
- See also: `default_progress`, `default_init`, `UploadMap`
"""
function default_complete(cm::ComponentModifier)
    push!(cm.changes, "console.log('upload complete');")
end

"""
```julia
default_progress(cm::ComponentModifier, info::StreamFileInfo) -> ::Nothing
```
The default *progress* function for an `UploadMap`. When binded, presents a warning message 
as not binding progress makes the uploader effectively useless.

- See also: `StreamFileInfo`, `default_init`, `default_complete`, `UploadMap`
"""
function default_progress(cm::ComponentModifier, info::StreamFileInfo)
    push!(cm.changes, "console.log('sent info to server');")
    @info "unhandled uploaded file bytes (no progress function): $(info.loaded) / $(info.size)"
end

"""
```julia
default_init(cm::ComponentModifier, filesize::Integer, name::AbstractString) -> ::Nothing
```
The default *init* function for an `UploadMap`. The init function will take a `ComponentModifier`, the filesize, 
and the name of the file. There is currently no way to reject an incoming upload, this will be added in a future version.

- See also: `StreamFileInfo`, `default_init`, `default_complete`, `UploadMap`
"""
function default_init(cm::ComponentModifier, filesize::Integer, name::AbstractString)
    push!(cm.changes, "console.log('started upload');")
end

"""
```julia
mutable struct UploadMap <: InputMap
```
- `init`**::Function**
- `progress`**::Function**
- `complete`**::Function**

The `UploadMap` stores multiple upload bindings for application on one `fileinput`
    `Component`. `:init`, `:progress`, and `:complete` can all be bound using `Components.bind`. Each of these functions
    takes different arguments.
```julia
# init:
# runs when the upload starts, provides filesize in bytes and file name
(cm::ComponentModifier, filesize::Integer, name::AbstractString)
# --
# progress:
# runs each time the upload polls, provides raw file data, current bytecount, 
 # and total byte count via `FileStreamInfo`.
(cm::ComponentModifier, info::StreamFileInfo)
# --
# complete:
# runs when the upload finishes.
(cm::ComponentModifier)
```
example:
```julia
```
- See also: `FileStreamInfo`, `ToolipsUploader`, `default_init`, `default_progress`, `Components.bind`
"""
mutable struct UploadMap <: InputMap
    init::Function
    progress::Function
    complete::Function
    UploadMap(complete = default_complete) = new(default_init, default_progress, complete)::UploadMap
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
        info = nothing
    else
        # upload start
        cm = ComponentModifier(string(argsplits[5]))
        fs[1](cm, parse(Int64, argsplits[3]), argsplits[4])
    end
    write!(c, cm)
end

"""
#### toolips uploader upload map bind bindings
```julia
# binds functions to `UploadMap`:
bind(f::Function, um::UploadMap, funcname::Symbol) -> ::Nothing
# binds `UploadMap` to components:
bind(c::AbstractConnection, fileinput::Component{:fileinput}, um::UploadMap)

# special binding, binds component to trigger upload. (For alternate upload button.)
bind(component::Component{<:Any}, fileinp::Component{:fileinput}, hide::Bool = true; 
    bindto::Symbol = :onclick)
```
These bindings are used to bind a given `Function` to an `UploadMap` command. These are 
`:init`, `:progress`, and `:complete`. For more information on creating these bindings, see 
`UploadMap`.
- See also: `UploadMap`, `default_init`, `fileinput`, `trigger!`, `StreamFileInfo`
"""
function bind(f::Function, um::UploadMap, funcname::Symbol)
    if ~(funcname in (:init, :progress, :complete))
        throw(":$funcname is not an upload map option (:init, :progress, :complete)")
    end
    setfield!(um, funcname, f)
    nothing::Nothing
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

"""
```julia
fileinput(name::String = "", p::Pair{String, String} ... ; args ...) -> ::Component{:fileinput}
```
Creates a `fileinput` `Component` for use with an `UploadMap`.
```julia
```
- See also: `UploadMap`, `Components.bind`, `ToolipsUploader`, `StreamFileInfo`
"""
function fileinput(name::String = "", p::Pair{String, String} ... ; args ...)
    Component{:fileinput}(name, p ..., type = "file", files = "-", tag = "input"; args ...)
end

function bind(component::Component{<:Any}, fileinp::Component{:fileinput}, hide::Bool = true; 
    bindto::Symbol = :onclick)
    component[bindto] = "'document.getElementById(\"$(fileinp.name)\").click();'"
    if hide
        style!(fileinp, "display" => "none")
    end
    nothing
end

"""
```julia
trigger!(cm::AbstractComponentModifier, comp::Any) -> ::Nothing
```
Triggers a `Component` by clicking on it.
```julia
```
- See also: `UploadMap`, `Components.bind`, `fileinput`
"""
function trigger!(cm::AbstractComponentModifier, finp::Any)
    if typeof(finp) <: AbstractComponent
        finp = finp.name
    end
    push!(cm.changes, "document.getElementById('$(finp)').click();")
    nothing::Nothing
end

export fileinput, StreamFileInfo
end # module
