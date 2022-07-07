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
using Toolips
import Toolips: ServerExtension
using ToolipsSession

"""
### Uploader <: Toolips.ServerExtension
- type::Vector{Symbol} - the type of this extension.
- directory::String - The directory to put temporary uploads.
- lastupload::Dict{String, String} - A dictionary containing ips and files for the last
upload of each `Connection`.
- f::Function - The routing extension function that creates the upload route.\n
The Uploader ServerExtension handles incoming client uploads on the server side.
##### example
```

```
------------------
##### constructors
- Uploader(directory::String = "uploads", upload_f::Function = uploadsave)
"""
mutable struct Uploader <: ServerExtension
    type::Vector{Symbol}
    directory::String
    lastupload::Dict{String, String}
    f::Function
    function Uploader(directory::String = "uploads",
        upload_f::Function = uploadsave)
        lastupload = Dict{String, String}()
        f(rs::Dict{String, Function}, es::Dict{Symbol, ServerExtension}) = begin
            rs["/uploader/upload"] = upload_f
        end
        new([:routing, :connection], directory, lastupload, f)
    end
end

"""
**Uploader Interface**
### fileinput(f::Function, c::Connection, name::String = "")
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
function fileinput(f::Function, c::Connection, name::String = "")
    inp::Component = input(name * "input", type = "file", name = "fname")
    inp["oninput"] = """readFile(this);"""
    sendscript::Component = script("readscript$name", text = """function readFile(input) {
  let file = input.files[0];

  let reader = new FileReader();

  reader.readAsText(file);
  var body = document.getElementsByTagName('body')[0].innerHTML;
  reader.onload = function() {
      let xhr = new XMLHttpRequest();
      xhr.open("POST", "/uploader/upload");
      xhr.setRequestHeader("Accept", "application/json");
      xhr.setRequestHeader("Content-Type", "application/json");
      xhr.onload = eval(xhr.responseText);
      xhr.send(reader.result + "?UP?:" + file.name);
  };

  reader.onerror = function() {
    console.log(reader.error);
  };

}""")
    push!(inp.extras, sendscript)
    ip = getip(c)
    on(c, inp, "change") do cm::ComponentModifier
        sleep(1)
        fname = c[:Uploader].lastupload[ip]
        f(cm, fname)
        rm(c[:Uploader].lastupload[ip])
    end
    inp
end

function customfileinput()

end

function multifileinput()

end

function pollinginput(c::Connection)

end


function uploadsave(c::Connection)
    data = split(getpost(c), "?UP?:")
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
end

export Uploader, fileinput
end # module
