# :volcano: A Vulkan Module for Jai

Just a module to use Vulkan in Jai. Both the header and the loader are generated from vk.xml by the code in this repository.

## [Header](vulkan_header.jai)

Not much to say about [the header](vulkan_header.jai). It should just pick up the types from `vk.xml` and try to format them in Jai with some hopefully useful comments.

## [Loader](vulkan_loader.jai)

There are instructions for usage of the loader in [the file itself](vulkan_loader.jai). It defines globals that will hold the procedure pointers to the API procedures. Then by using the three `load_vulkan_*` procedures you'll be able to fill all these global procedure pointers and start using them.

## Notes

**This module is not super active** at the moment because I'm not personally using Vulkan too much these days. It's somewhat likely to fall behind in which Vulkan version it currently has on the provided header and loader. In a similar fashion, most of this module was written in the very early days of Jai's closed beta so it's possible that some things in it don't compile with the latest versions of the language/compiler.

The way `vk.xml` is modified doesn't make it particularly easy to keep track of all of the stuff they are adding either, and since I'm not using Vulkan too much I can't justify the bandwidth of reacting to everything they add that doesn't follow previous conventions. The code that parses `vk.xml` was the first thing I wrote in the language, and can be done much better, while also accounting for all the changes that the xml file has had since then.

## License

I want people to be able to just use this without thinking about licensing, although give me a shout if you do use it and attribution is appreciated 😊. Replicating STB's (https://github.com/nothings/stb) licensing stuff where you can choose to use public domain or MIT.
