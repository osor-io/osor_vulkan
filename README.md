# A Vulkan Module for Jai

Just a module to use Vulkan in Jai. Both the header and the loader are generated from vk.xml by the code in this repository.

## [Header](vulkan_header.jai)

Not much to say about [the header](vulkan_header.jai). It should just pick up the types from vk.xml and try to format them in Jai with some hopefully useful comments.

## [Loader](vulkan_loader.jai)

There is instructions for usage of the loader in [the file itself](vulkan_loader.jai). It defines globals that will hold the procedure pointers to the API procedures. Then by using the three `load_vulkan_*` procedure you'll be able to fill all these global procedure pointers and start using them.

## License

I want people to be able to just use this without thinking about licensing, although give me a shout if you do use it and attribution is appreciated 😊. Replicating STB's (https://github.com/nothings/stb) licensing stuff where you can choose to use public domain or MIT.
