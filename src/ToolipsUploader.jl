module ToolipsUploader
using Toolips
import Toolips: ServerExtension
using ToolipsSession

mutable struct Uploader <: ServerExtension
    type::Vector{Symbol}
    directory::String
    lastupload::Dict{String, String}
    f::Function
    function Uploader(directory::String = "uploads",
        upload_f::Function = uploadsave)
        f(rs::Dict{String, Function}, es::Dict{Symbol, ServerExtension}) = begin
            rs["/uploader/upload"] = upload_f
        end
        new([:routing, :connection], directory, f)
    end
end

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
