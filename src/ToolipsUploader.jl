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
using ToolipsDefaults
import Base: read
import Toolips: ServerExtension, AbstractRoute, Modifier
using ToolipsSession

"""
### Uploader <: Toolips.ServerExtension
- type::Vector{Symbol} - the type of this extension. In the case of `Uploader`,
this will always be [:routing, :connection].
- directory::String - The directory to put temporary uploads. By default this is
`uploads/`. Uploader will remove these files after the `FileModifier` function
provided is ran. This is provided by the `upload_f argument.`
- lastupload::Dict{String, String} - A dictionary containing ips and files for the last
upload of each `Connection`.
- f::Function - The routing extension function that creates the upload route.\n
The Uploader ServerExtension handles incoming client uploads on the server side.
As an end user, do not worry about this.
##### example
```
tree .
- src
   = Example.jl
= Project.toml
= Manifest.toml
- public
- uploads
```
```
using Toolips
using ToolipsUploader

```
------------------
##### constructors
- Uploader(upload_f::Function = uploadsave, directory::String = "uploads")
"""
mutable struct Uploader <: ServerExtension
    type::Vector{Symbol}
    directory::String
    lastupload::Dict{String, Any}
    f::Function
    function Uploader(upload_f::Function = uploadsave,
        directory::String = "uploads")
        lastupload = Dict{String, String}()
        f(rs::Vector{AbstractRoute}, es::Vector{ServerExtension}) = begin
            rs["/uploader/upload"] = upload_f
        end
        new([:routing, :connection], directory, lastupload, f)
    end
end

function uploadsave(c::Connection)
    pdata::String = getpost(c)
    if contains(pdata, "?UP?:")
        data = split(pdata, "?UP?:")
        name = string(data[2])
        file = string(data[1])
        directory = c[:Uploader].directory
        if ~(isdir(directory))
            mkdir(directory)
        end
        c[:Uploader].lastupload[getip(c)] = directory * "/$name"
        touch(c[:Uploader].directory * "/$name")
        open(c[:Uploader].directory * "/$name", "w") do io
            write(io, file)
        end
        write!(c, "File uploaded successfully")
    elseif contains(pdata, "?POLLUP?:")
        data = split(pdata, "?POLL?:")
        name = string(data[1])
        c[:Uploader].lastupload[getip(c)] = [0, ""]
    elseif contains(pdata, "?POLL?:")
        data = split(pdata, "?POLL?:")
        c[:Uploader].lastupload[getip(c)] = [0, ""]
    end
end

"""
"""
mutable struct FileComponenttModifier <: AbstractComponentModifier
    rootc::Dict{String, Component}
    f::Function
    changes::Vector{String}
    message::String
    progress::Float64
    bytes::Pair{Int64, Int64}
    file::Toolips.File
    function FileModifier(cm::ComponentModifier, dir::String)
        rootc = cm.rootc
        changes = cm.changes
        f = cm.f
        new(rootc, f, changes, File(dir))
    end
    function FileModifier(html::String, dir::String)
        rootc = ToolipsSession.htmlcomponent(html)
        f(c::Connection) = begin
            write!(c, join(changes))
        end
        changes = Vector{String}()
        new(rootc, f, changes, File(dir))
    end
end

#==
TODO
The FileModifier interface. Each of these will be primarily ClientModifier-based
functions all with the argument "client", Bool, default true, key-word. This
will allow us to determine whether or not to send it to Julia. Eventually I would
also like to have an abort! function to trigger the event abort() in the document.
==#
verify(f::Function, finput::Component{:input}) = begin

end

progress!(finput::Component{:input}, prog::Component{:progress}) = begin

end

error!(f::Function, fm::FileModifier) = begin

end

abort!(f::Function, fm::FileModifier) = begin

end

read(f::Function, fm::FileModifier, a::String) = read(f, fm.file, a)

read(fm::FileModifier, T::Type) = read(fm.file, T)

"""
**Uploader Interface**
### fileinput(name::String = "", f::Function, c::Connection)
------------------
Creates a new fileinput Component, which will upload files to an `Uploader`.
The `f` function should take a ComponentModifier and a String as positional
arguments. Files will be removed automatically so long as an exception is not
thrown.
#### example
```
myuploader = ToolipsUploader.fileinput(c,
"pizza") do cm::ComponentModifier, file::String
    try
        readstr = read(file, String)
        style!(cm, uploaderbox, "height" => "250px")
        set_children!(cm, "uploaderbox", components(tmd("customtmd", readstr)))
    catch
        rm(file)
        errora = a("errora",
        text = "Error! You probably uploaded the wrong type of file, didn't you?")
        style!(errora, "color" => "red")
        style!(cm, uploaderbox, "height" => "20px")
        set_children!(cm, "uploaderbox", components(errora))
    end
end
```
"""
function fileinput(f::Function, c::Connection, name::String = "",
    p::Pair{String, String} ... ; args ...)
    inp::Component{:input} = input(name * "input", type = "file",
     name = "fname", p ..., args ...)
    inp["oninput"] = """readFile$name(this);"""
    # we will need to concat at //CUTOFF in the future.
    sendscript::Component{:script} = script("readscript$name", text = """
    function readFile$name(input) {
        var file = _("$name").files[0];
        try{
            // future do function to restrict filetype
            // file.name file.size file.type
        }
    catch
        {

        }
        var formdata = new FormData();
        formdata.append("file1", file);
        var ajax = new XMLHttpRequest();
        try{
        // ajax.upload.addEventListener("progress", $(name)progressHandler, false);
        }
        try{
        ajax.addEventListener("load", $(name)completeHandler, false);
        }
    catch{

        }
        try{
        ajax.addEventListener("error", $(name)errorHandler, false);
        }
    catch{
        }
        try{
        ajax.addEventListener("error", $(name)errorHandler, false);
        }
    catch{
        }
        ajax.open("POST", "/uploader/upload");
        ajax.send(formdata);
  };

}""")
    push!(inp.extras, sendscript)
    ip = getip(c)
    on(c, inp, "change") do cm::ComponentModifier
        sleep(1)
        fname = c[:Uploader].lastupload[ip]
        f(FileModifier(cm, fname))
        rm(c[:Uploader].lastupload[ip])
    end
    inp::Component{:input}
end

function area_fileinput()

end

export Uploader, fileinput
end # module
