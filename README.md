<div align = "center"><img src = "https://github.com/ChifiSource/image_dump/blob/main/toolips/toolipsuploader.png" href = "https://toolips.app"></img></div>

The ToolipsUploader extension makes it easy to handle file uploads with a simple ServerExtension and Component.
- [Documentation](doc.toolips.app/extensions/toolips_base64)
- [Toolips](https://github.com/ChifiSource/Toolips.jl)
- [Extension Gallery](https://toolips.app/?page=gallery&selected=uploader)

Toolips uploader makes it possible to create incredibly easy file uploads that clean up after themselves. The module includes both a polling file uploader and a regular file uploader.
#### uploader
In order for the upload Components to work properly, we need to add the `Uploader` extension. It is also recommended to use `ToolipsDefaults` for things like the `:progress` Component. To create the Uploader, we simply provide its constructor with a directory to store temporary uploads and 
###### fileinput
The `fileinput` Component is the main feature that is used to get 
```julia
```
###### FileModifier
```julia
```
###### file modifier methods
```julia
```
###### full example
```julia
```
