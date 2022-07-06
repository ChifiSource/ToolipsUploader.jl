module ToolipsUploader
using Toolips
import Toolips: ServerExtension
using ToolipsSession

mutable struct Uploader <: ServerExtension
    type::Vector{Symbol}
    directory::String
    f::Function
    function Uploader(directory::String = "public/uploads",
        upload_f::Function = uploadsave)
        f(rs::Dict{String, Function}, es::Dict{Symbol, ServerExtension}) = begin
            rs["/uploader/upload"] = upload_f
            if ~(isdir(directory))
                try
                    mkdir(directory)
                catch
                    throw("""No directory $directory , server tried to create
                    directory but was not able to.
                    """)
                end
            end

        end
        new([:routing, :connection], directory, f)
    end
end

function fileinput(name::String = "")
    inp::Component = input(name * "input", type = "file", name = "fname")
    inp["onchange"] = """readFile(this);"""
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
      xhr.send(body + "?UP?:" reader.result + "/" + file.name);
  };

  reader.onerror = function() {
    console.log(reader.error);
  };

}""")
    push!(inp.extras, sendscript)
    inp
end

function fileinput(f::Function, name::String = "")
    inp::Component = fileinput(name)
    sc = Toolips.SpoofConnection()
    cm = ComponentModifier("<body></body>")
    f(cm)
    commands = join(cm.changes)
    jsf = """function () {$commands };"""
    inp[extras][1][:text] = """function readFile(input) {
  let file = input.files[0];

  let reader = new FileReader();

  reader.readAsText(file);
  var body = document.getElementsByTagName('body')[0].innerHTML;
  reader.onload = function() {
      let xhr = new XMLHttpRequest();
      xhr.open("POST", "/uploader/upload");
      xhr.setRequestHeader("Accept", "application/json");
      xhr.setRequestHeader("Content-Type", "application/json");
      xhr.onload = $jsf
      xhr.send(body + "?UP?:" reader.result + "/" + file.name);
  };

  reader.onerror = function() {
    console.log(reader.error);
  };

}
    """
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
    touch(c[:Uploader].directory * "/$name")
    open(c[:Uploader].directory * "/$name", "w") do io
        write(io, file)
    end
    write!(c, "File uploaded successfully")
end


export Uploader, fileinput
end # module
