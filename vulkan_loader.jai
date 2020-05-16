/*
This file handles loading the entry points for the Vulkan API. Vulkan works
by having a dynamic library deployed on the system that you have to load and get the
entry-points to. You can also link against their own loader and that will give you
the procedures directly, but this would have *some* overhead and we don't want that :)

In this file there is global variables that will hold all the procedure pointers for
each entry-point, and then there is the procedures you can call to fill them.

Usage should be fairly straight-forward, there's 3 types of commands (for our purposes):

    - Those which should be loaded directly from the library
    - Those which depend on the vulkan instance (VkInstance) and should be loaded from it
    - Those which depend on the vulkan device (VkDevice) and should be loaded from it

To load each of the types you have:

    - load_vulkan_loader_procedures
    - load_vulkan_instance_procedures
    - load_vulkan_device_procedures

An Example in Windows would look something like this:

    vulkan_library := LoadLibraryA("vulkan-1.dll");
    load_vulkan_loader_procedures(vulkan_library , GetProcAddress);
    // . . . you do your code to create a VkInstance . . .
    load_vulkan_instance_procedures(your_vk_instance);
    // . . . you do your code to create a VkDevice . . .
    load_vulkan_device_procedures(your_vk_device);
*/


load_vulkan_loader_procedures :: (library_handle : $Library_Handle_Type, $load : $Loader_Procedure_Type)
{
    vkCreateInstance = xx load(library_handle, "vkCreateInstance");
    vkGetInstanceProcAddr = xx load(library_handle, "vkGetInstanceProcAddr");
    vkEnumerateInstanceVersion = xx load(library_handle, "vkEnumerateInstanceVersion");
    vkEnumerateInstanceLayerProperties = xx load(library_handle, "vkEnumerateInstanceLayerProperties");
    vkEnumerateInstanceExtensionProperties = xx load(library_handle, "vkEnumerateInstanceExtensionProperties");
}


load_vulkan_instance_procedures :: (instance : VkInstance)
{
    vkDestroyInstance = xx vkGetInstanceProcAddr(instance, "vkDestroyInstance");
    vkEnumeratePhysicalDevices = xx vkGetInstanceProcAddr(instance, "vkEnumeratePhysicalDevices");
    vkGetDeviceProcAddr = xx vkGetInstanceProcAddr(instance, "vkGetDeviceProcAddr");
    vkGetPhysicalDeviceProperties = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceProperties");
    vkGetPhysicalDeviceQueueFamilyProperties = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceQueueFamilyProperties");
    vkGetPhysicalDeviceMemoryProperties = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceMemoryProperties");
    vkGetPhysicalDeviceFeatures = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceFeatures");
    vkGetPhysicalDeviceFormatProperties = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceFormatProperties");
    vkGetPhysicalDeviceImageFormatProperties = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceImageFormatProperties");
    vkCreateDevice = xx vkGetInstanceProcAddr(instance, "vkCreateDevice");
    vkEnumerateDeviceLayerProperties = xx vkGetInstanceProcAddr(instance, "vkEnumerateDeviceLayerProperties");
    vkEnumerateDeviceExtensionProperties = xx vkGetInstanceProcAddr(instance, "vkEnumerateDeviceExtensionProperties");
    vkGetPhysicalDeviceSparseImageFormatProperties = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceSparseImageFormatProperties");
    vkGetPhysicalDeviceDisplayPropertiesKHR = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceDisplayPropertiesKHR");
    vkGetPhysicalDeviceDisplayPlanePropertiesKHR = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceDisplayPlanePropertiesKHR");
    vkGetDisplayPlaneSupportedDisplaysKHR = xx vkGetInstanceProcAddr(instance, "vkGetDisplayPlaneSupportedDisplaysKHR");
    vkGetDisplayModePropertiesKHR = xx vkGetInstanceProcAddr(instance, "vkGetDisplayModePropertiesKHR");
    vkCreateDisplayModeKHR = xx vkGetInstanceProcAddr(instance, "vkCreateDisplayModeKHR");
    vkGetDisplayPlaneCapabilitiesKHR = xx vkGetInstanceProcAddr(instance, "vkGetDisplayPlaneCapabilitiesKHR");
    vkCreateDisplayPlaneSurfaceKHR = xx vkGetInstanceProcAddr(instance, "vkCreateDisplayPlaneSurfaceKHR");
    vkDestroySurfaceKHR = xx vkGetInstanceProcAddr(instance, "vkDestroySurfaceKHR");
    vkGetPhysicalDeviceSurfaceSupportKHR = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfaceSupportKHR");
    vkGetPhysicalDeviceSurfaceCapabilitiesKHR = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfaceCapabilitiesKHR");
    vkGetPhysicalDeviceSurfaceFormatsKHR = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfaceFormatsKHR");
    vkGetPhysicalDeviceSurfacePresentModesKHR = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfacePresentModesKHR");
    vkCreateViSurfaceNN = xx vkGetInstanceProcAddr(instance, "vkCreateViSurfaceNN");
    vkGetPhysicalDeviceWin32PresentationSupportKHR = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceWin32PresentationSupportKHR");
    vkCreateDebugReportCallbackEXT = xx vkGetInstanceProcAddr(instance, "vkCreateDebugReportCallbackEXT");
    vkDestroyDebugReportCallbackEXT = xx vkGetInstanceProcAddr(instance, "vkDestroyDebugReportCallbackEXT");
    vkDebugReportMessageEXT = xx vkGetInstanceProcAddr(instance, "vkDebugReportMessageEXT");
    vkGetPhysicalDeviceExternalImageFormatPropertiesNV = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceExternalImageFormatPropertiesNV");
    vkGetPhysicalDeviceFeatures2 = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceFeatures2");
    vkGetPhysicalDeviceFeatures2KHR = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceFeatures2KHR");
    vkGetPhysicalDeviceProperties2 = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceProperties2");
    vkGetPhysicalDeviceProperties2KHR = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceProperties2KHR");
    vkGetPhysicalDeviceFormatProperties2 = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceFormatProperties2");
    vkGetPhysicalDeviceFormatProperties2KHR = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceFormatProperties2KHR");
    vkGetPhysicalDeviceImageFormatProperties2 = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceImageFormatProperties2");
    vkGetPhysicalDeviceImageFormatProperties2KHR = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceImageFormatProperties2KHR");
    vkGetPhysicalDeviceQueueFamilyProperties2 = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceQueueFamilyProperties2");
    vkGetPhysicalDeviceQueueFamilyProperties2KHR = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceQueueFamilyProperties2KHR");
    vkGetPhysicalDeviceMemoryProperties2 = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceMemoryProperties2");
    vkGetPhysicalDeviceMemoryProperties2KHR = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceMemoryProperties2KHR");
    vkGetPhysicalDeviceSparseImageFormatProperties2 = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceSparseImageFormatProperties2");
    vkGetPhysicalDeviceSparseImageFormatProperties2KHR = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceSparseImageFormatProperties2KHR");
    vkGetPhysicalDeviceExternalBufferProperties = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceExternalBufferProperties");
    vkGetPhysicalDeviceExternalBufferPropertiesKHR = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceExternalBufferPropertiesKHR");
    vkGetPhysicalDeviceExternalSemaphoreProperties = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceExternalSemaphoreProperties");
    vkGetPhysicalDeviceExternalSemaphorePropertiesKHR = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceExternalSemaphorePropertiesKHR");
    vkGetPhysicalDeviceExternalFenceProperties = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceExternalFenceProperties");
    vkGetPhysicalDeviceExternalFencePropertiesKHR = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceExternalFencePropertiesKHR");
    vkReleaseDisplayEXT = xx vkGetInstanceProcAddr(instance, "vkReleaseDisplayEXT");
    vkGetPhysicalDeviceSurfaceCapabilities2EXT = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfaceCapabilities2EXT");
    vkEnumeratePhysicalDeviceGroups = xx vkGetInstanceProcAddr(instance, "vkEnumeratePhysicalDeviceGroups");
    vkEnumeratePhysicalDeviceGroupsKHR = xx vkGetInstanceProcAddr(instance, "vkEnumeratePhysicalDeviceGroupsKHR");
    vkGetPhysicalDevicePresentRectanglesKHR = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDevicePresentRectanglesKHR");
    vkCreateIOSSurfaceMVK = xx vkGetInstanceProcAddr(instance, "vkCreateIOSSurfaceMVK");
    vkCreateMacOSSurfaceMVK = xx vkGetInstanceProcAddr(instance, "vkCreateMacOSSurfaceMVK");
    vkGetPhysicalDeviceMultisamplePropertiesEXT = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceMultisamplePropertiesEXT");
    vkGetPhysicalDeviceSurfaceCapabilities2KHR = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfaceCapabilities2KHR");
    vkGetPhysicalDeviceSurfaceFormats2KHR = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfaceFormats2KHR");
    vkGetPhysicalDeviceDisplayProperties2KHR = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceDisplayProperties2KHR");
    vkGetPhysicalDeviceDisplayPlaneProperties2KHR = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceDisplayPlaneProperties2KHR");
    vkGetDisplayModeProperties2KHR = xx vkGetInstanceProcAddr(instance, "vkGetDisplayModeProperties2KHR");
    vkGetDisplayPlaneCapabilities2KHR = xx vkGetInstanceProcAddr(instance, "vkGetDisplayPlaneCapabilities2KHR");
    vkGetPhysicalDeviceCalibrateableTimeDomainsEXT = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceCalibrateableTimeDomainsEXT");
    vkCreateDebugUtilsMessengerEXT = xx vkGetInstanceProcAddr(instance, "vkCreateDebugUtilsMessengerEXT");
    vkDestroyDebugUtilsMessengerEXT = xx vkGetInstanceProcAddr(instance, "vkDestroyDebugUtilsMessengerEXT");
    vkSubmitDebugUtilsMessageEXT = xx vkGetInstanceProcAddr(instance, "vkSubmitDebugUtilsMessageEXT");
    vkGetPhysicalDeviceCooperativeMatrixPropertiesNV = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceCooperativeMatrixPropertiesNV");
    vkGetPhysicalDeviceSurfacePresentModes2EXT = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfacePresentModes2EXT");
    vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR = xx vkGetInstanceProcAddr(instance, "vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR");
    vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR");
    vkCreateHeadlessSurfaceEXT = xx vkGetInstanceProcAddr(instance, "vkCreateHeadlessSurfaceEXT");
    vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV");
    vkGetPhysicalDeviceToolPropertiesEXT = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceToolPropertiesEXT");
    #if CURRENT_VULKAN_PLATFORM == Vulkan_Platform.X11
    {
    vkCreateXlibSurfaceKHR = xx vkGetInstanceProcAddr(instance, "vkCreateXlibSurfaceKHR");
    vkGetPhysicalDeviceXlibPresentationSupportKHR = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceXlibPresentationSupportKHR");
    vkAcquireXlibDisplayEXT = xx vkGetInstanceProcAddr(instance, "vkAcquireXlibDisplayEXT");
    vkGetRandROutputDisplayEXT = xx vkGetInstanceProcAddr(instance, "vkGetRandROutputDisplayEXT");
    }
    #if CURRENT_VULKAN_PLATFORM == Vulkan_Platform.Wayland
    {
    vkCreateWaylandSurfaceKHR = xx vkGetInstanceProcAddr(instance, "vkCreateWaylandSurfaceKHR");
    vkGetPhysicalDeviceWaylandPresentationSupportKHR = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceWaylandPresentationSupportKHR");
    }
    #if CURRENT_VULKAN_PLATFORM == Vulkan_Platform.Windows
    {
    vkCreateWin32SurfaceKHR = xx vkGetInstanceProcAddr(instance, "vkCreateWin32SurfaceKHR");
    }
    #if CURRENT_VULKAN_PLATFORM == Vulkan_Platform.XCB
    {
    vkCreateXcbSurfaceKHR = xx vkGetInstanceProcAddr(instance, "vkCreateXcbSurfaceKHR");
    vkGetPhysicalDeviceXcbPresentationSupportKHR = xx vkGetInstanceProcAddr(instance, "vkGetPhysicalDeviceXcbPresentationSupportKHR");
    }
    #if CURRENT_VULKAN_PLATFORM == Vulkan_Platform.Zircon
    {
    vkCreateImagePipeSurfaceFUCHSIA = xx vkGetInstanceProcAddr(instance, "vkCreateImagePipeSurfaceFUCHSIA");
    }
    #if CURRENT_VULKAN_PLATFORM == Vulkan_Platform.GGP
    {
    vkCreateStreamDescriptorSurfaceGGP = xx vkGetInstanceProcAddr(instance, "vkCreateStreamDescriptorSurfaceGGP");
    }
    #if CURRENT_VULKAN_PLATFORM == Vulkan_Platform.Android
    {
    vkCreateAndroidSurfaceKHR = xx vkGetInstanceProcAddr(instance, "vkCreateAndroidSurfaceKHR");
    }
    #if CURRENT_VULKAN_PLATFORM == Vulkan_Platform.MacOS
    {
    vkCreateMetalSurfaceEXT = xx vkGetInstanceProcAddr(instance, "vkCreateMetalSurfaceEXT");
    }
}


load_vulkan_device_procedures :: (device : VkDevice)
{
    vkDestroyDevice = xx vkGetDeviceProcAddr(device, "vkDestroyDevice");
    vkGetDeviceQueue = xx vkGetDeviceProcAddr(device, "vkGetDeviceQueue");
    vkQueueSubmit = xx vkGetDeviceProcAddr(device, "vkQueueSubmit");
    vkQueueWaitIdle = xx vkGetDeviceProcAddr(device, "vkQueueWaitIdle");
    vkDeviceWaitIdle = xx vkGetDeviceProcAddr(device, "vkDeviceWaitIdle");
    vkAllocateMemory = xx vkGetDeviceProcAddr(device, "vkAllocateMemory");
    vkFreeMemory = xx vkGetDeviceProcAddr(device, "vkFreeMemory");
    vkMapMemory = xx vkGetDeviceProcAddr(device, "vkMapMemory");
    vkUnmapMemory = xx vkGetDeviceProcAddr(device, "vkUnmapMemory");
    vkFlushMappedMemoryRanges = xx vkGetDeviceProcAddr(device, "vkFlushMappedMemoryRanges");
    vkInvalidateMappedMemoryRanges = xx vkGetDeviceProcAddr(device, "vkInvalidateMappedMemoryRanges");
    vkGetDeviceMemoryCommitment = xx vkGetDeviceProcAddr(device, "vkGetDeviceMemoryCommitment");
    vkGetBufferMemoryRequirements = xx vkGetDeviceProcAddr(device, "vkGetBufferMemoryRequirements");
    vkBindBufferMemory = xx vkGetDeviceProcAddr(device, "vkBindBufferMemory");
    vkGetImageMemoryRequirements = xx vkGetDeviceProcAddr(device, "vkGetImageMemoryRequirements");
    vkBindImageMemory = xx vkGetDeviceProcAddr(device, "vkBindImageMemory");
    vkGetImageSparseMemoryRequirements = xx vkGetDeviceProcAddr(device, "vkGetImageSparseMemoryRequirements");
    vkQueueBindSparse = xx vkGetDeviceProcAddr(device, "vkQueueBindSparse");
    vkCreateFence = xx vkGetDeviceProcAddr(device, "vkCreateFence");
    vkDestroyFence = xx vkGetDeviceProcAddr(device, "vkDestroyFence");
    vkResetFences = xx vkGetDeviceProcAddr(device, "vkResetFences");
    vkGetFenceStatus = xx vkGetDeviceProcAddr(device, "vkGetFenceStatus");
    vkWaitForFences = xx vkGetDeviceProcAddr(device, "vkWaitForFences");
    vkCreateSemaphore = xx vkGetDeviceProcAddr(device, "vkCreateSemaphore");
    vkDestroySemaphore = xx vkGetDeviceProcAddr(device, "vkDestroySemaphore");
    vkCreateEvent = xx vkGetDeviceProcAddr(device, "vkCreateEvent");
    vkDestroyEvent = xx vkGetDeviceProcAddr(device, "vkDestroyEvent");
    vkGetEventStatus = xx vkGetDeviceProcAddr(device, "vkGetEventStatus");
    vkSetEvent = xx vkGetDeviceProcAddr(device, "vkSetEvent");
    vkResetEvent = xx vkGetDeviceProcAddr(device, "vkResetEvent");
    vkCreateQueryPool = xx vkGetDeviceProcAddr(device, "vkCreateQueryPool");
    vkDestroyQueryPool = xx vkGetDeviceProcAddr(device, "vkDestroyQueryPool");
    vkGetQueryPoolResults = xx vkGetDeviceProcAddr(device, "vkGetQueryPoolResults");
    vkResetQueryPool = xx vkGetDeviceProcAddr(device, "vkResetQueryPool");
    vkResetQueryPoolEXT = xx vkGetDeviceProcAddr(device, "vkResetQueryPoolEXT");
    vkCreateBuffer = xx vkGetDeviceProcAddr(device, "vkCreateBuffer");
    vkDestroyBuffer = xx vkGetDeviceProcAddr(device, "vkDestroyBuffer");
    vkCreateBufferView = xx vkGetDeviceProcAddr(device, "vkCreateBufferView");
    vkDestroyBufferView = xx vkGetDeviceProcAddr(device, "vkDestroyBufferView");
    vkCreateImage = xx vkGetDeviceProcAddr(device, "vkCreateImage");
    vkDestroyImage = xx vkGetDeviceProcAddr(device, "vkDestroyImage");
    vkGetImageSubresourceLayout = xx vkGetDeviceProcAddr(device, "vkGetImageSubresourceLayout");
    vkCreateImageView = xx vkGetDeviceProcAddr(device, "vkCreateImageView");
    vkDestroyImageView = xx vkGetDeviceProcAddr(device, "vkDestroyImageView");
    vkCreateShaderModule = xx vkGetDeviceProcAddr(device, "vkCreateShaderModule");
    vkDestroyShaderModule = xx vkGetDeviceProcAddr(device, "vkDestroyShaderModule");
    vkCreatePipelineCache = xx vkGetDeviceProcAddr(device, "vkCreatePipelineCache");
    vkDestroyPipelineCache = xx vkGetDeviceProcAddr(device, "vkDestroyPipelineCache");
    vkGetPipelineCacheData = xx vkGetDeviceProcAddr(device, "vkGetPipelineCacheData");
    vkMergePipelineCaches = xx vkGetDeviceProcAddr(device, "vkMergePipelineCaches");
    vkCreateGraphicsPipelines = xx vkGetDeviceProcAddr(device, "vkCreateGraphicsPipelines");
    vkCreateComputePipelines = xx vkGetDeviceProcAddr(device, "vkCreateComputePipelines");
    vkDestroyPipeline = xx vkGetDeviceProcAddr(device, "vkDestroyPipeline");
    vkCreatePipelineLayout = xx vkGetDeviceProcAddr(device, "vkCreatePipelineLayout");
    vkDestroyPipelineLayout = xx vkGetDeviceProcAddr(device, "vkDestroyPipelineLayout");
    vkCreateSampler = xx vkGetDeviceProcAddr(device, "vkCreateSampler");
    vkDestroySampler = xx vkGetDeviceProcAddr(device, "vkDestroySampler");
    vkCreateDescriptorSetLayout = xx vkGetDeviceProcAddr(device, "vkCreateDescriptorSetLayout");
    vkDestroyDescriptorSetLayout = xx vkGetDeviceProcAddr(device, "vkDestroyDescriptorSetLayout");
    vkCreateDescriptorPool = xx vkGetDeviceProcAddr(device, "vkCreateDescriptorPool");
    vkDestroyDescriptorPool = xx vkGetDeviceProcAddr(device, "vkDestroyDescriptorPool");
    vkResetDescriptorPool = xx vkGetDeviceProcAddr(device, "vkResetDescriptorPool");
    vkAllocateDescriptorSets = xx vkGetDeviceProcAddr(device, "vkAllocateDescriptorSets");
    vkFreeDescriptorSets = xx vkGetDeviceProcAddr(device, "vkFreeDescriptorSets");
    vkUpdateDescriptorSets = xx vkGetDeviceProcAddr(device, "vkUpdateDescriptorSets");
    vkCreateFramebuffer = xx vkGetDeviceProcAddr(device, "vkCreateFramebuffer");
    vkDestroyFramebuffer = xx vkGetDeviceProcAddr(device, "vkDestroyFramebuffer");
    vkCreateRenderPass = xx vkGetDeviceProcAddr(device, "vkCreateRenderPass");
    vkDestroyRenderPass = xx vkGetDeviceProcAddr(device, "vkDestroyRenderPass");
    vkGetRenderAreaGranularity = xx vkGetDeviceProcAddr(device, "vkGetRenderAreaGranularity");
    vkCreateCommandPool = xx vkGetDeviceProcAddr(device, "vkCreateCommandPool");
    vkDestroyCommandPool = xx vkGetDeviceProcAddr(device, "vkDestroyCommandPool");
    vkResetCommandPool = xx vkGetDeviceProcAddr(device, "vkResetCommandPool");
    vkAllocateCommandBuffers = xx vkGetDeviceProcAddr(device, "vkAllocateCommandBuffers");
    vkFreeCommandBuffers = xx vkGetDeviceProcAddr(device, "vkFreeCommandBuffers");
    vkBeginCommandBuffer = xx vkGetDeviceProcAddr(device, "vkBeginCommandBuffer");
    vkEndCommandBuffer = xx vkGetDeviceProcAddr(device, "vkEndCommandBuffer");
    vkResetCommandBuffer = xx vkGetDeviceProcAddr(device, "vkResetCommandBuffer");
    vkCmdBindPipeline = xx vkGetDeviceProcAddr(device, "vkCmdBindPipeline");
    vkCmdSetViewport = xx vkGetDeviceProcAddr(device, "vkCmdSetViewport");
    vkCmdSetScissor = xx vkGetDeviceProcAddr(device, "vkCmdSetScissor");
    vkCmdSetLineWidth = xx vkGetDeviceProcAddr(device, "vkCmdSetLineWidth");
    vkCmdSetDepthBias = xx vkGetDeviceProcAddr(device, "vkCmdSetDepthBias");
    vkCmdSetBlendConstants = xx vkGetDeviceProcAddr(device, "vkCmdSetBlendConstants");
    vkCmdSetDepthBounds = xx vkGetDeviceProcAddr(device, "vkCmdSetDepthBounds");
    vkCmdSetStencilCompareMask = xx vkGetDeviceProcAddr(device, "vkCmdSetStencilCompareMask");
    vkCmdSetStencilWriteMask = xx vkGetDeviceProcAddr(device, "vkCmdSetStencilWriteMask");
    vkCmdSetStencilReference = xx vkGetDeviceProcAddr(device, "vkCmdSetStencilReference");
    vkCmdBindDescriptorSets = xx vkGetDeviceProcAddr(device, "vkCmdBindDescriptorSets");
    vkCmdBindIndexBuffer = xx vkGetDeviceProcAddr(device, "vkCmdBindIndexBuffer");
    vkCmdBindVertexBuffers = xx vkGetDeviceProcAddr(device, "vkCmdBindVertexBuffers");
    vkCmdDraw = xx vkGetDeviceProcAddr(device, "vkCmdDraw");
    vkCmdDrawIndexed = xx vkGetDeviceProcAddr(device, "vkCmdDrawIndexed");
    vkCmdDrawIndirect = xx vkGetDeviceProcAddr(device, "vkCmdDrawIndirect");
    vkCmdDrawIndexedIndirect = xx vkGetDeviceProcAddr(device, "vkCmdDrawIndexedIndirect");
    vkCmdDispatch = xx vkGetDeviceProcAddr(device, "vkCmdDispatch");
    vkCmdDispatchIndirect = xx vkGetDeviceProcAddr(device, "vkCmdDispatchIndirect");
    vkCmdCopyBuffer = xx vkGetDeviceProcAddr(device, "vkCmdCopyBuffer");
    vkCmdCopyImage = xx vkGetDeviceProcAddr(device, "vkCmdCopyImage");
    vkCmdBlitImage = xx vkGetDeviceProcAddr(device, "vkCmdBlitImage");
    vkCmdCopyBufferToImage = xx vkGetDeviceProcAddr(device, "vkCmdCopyBufferToImage");
    vkCmdCopyImageToBuffer = xx vkGetDeviceProcAddr(device, "vkCmdCopyImageToBuffer");
    vkCmdUpdateBuffer = xx vkGetDeviceProcAddr(device, "vkCmdUpdateBuffer");
    vkCmdFillBuffer = xx vkGetDeviceProcAddr(device, "vkCmdFillBuffer");
    vkCmdClearColorImage = xx vkGetDeviceProcAddr(device, "vkCmdClearColorImage");
    vkCmdClearDepthStencilImage = xx vkGetDeviceProcAddr(device, "vkCmdClearDepthStencilImage");
    vkCmdClearAttachments = xx vkGetDeviceProcAddr(device, "vkCmdClearAttachments");
    vkCmdResolveImage = xx vkGetDeviceProcAddr(device, "vkCmdResolveImage");
    vkCmdSetEvent = xx vkGetDeviceProcAddr(device, "vkCmdSetEvent");
    vkCmdResetEvent = xx vkGetDeviceProcAddr(device, "vkCmdResetEvent");
    vkCmdWaitEvents = xx vkGetDeviceProcAddr(device, "vkCmdWaitEvents");
    vkCmdPipelineBarrier = xx vkGetDeviceProcAddr(device, "vkCmdPipelineBarrier");
    vkCmdBeginQuery = xx vkGetDeviceProcAddr(device, "vkCmdBeginQuery");
    vkCmdEndQuery = xx vkGetDeviceProcAddr(device, "vkCmdEndQuery");
    vkCmdBeginConditionalRenderingEXT = xx vkGetDeviceProcAddr(device, "vkCmdBeginConditionalRenderingEXT");
    vkCmdEndConditionalRenderingEXT = xx vkGetDeviceProcAddr(device, "vkCmdEndConditionalRenderingEXT");
    vkCmdResetQueryPool = xx vkGetDeviceProcAddr(device, "vkCmdResetQueryPool");
    vkCmdWriteTimestamp = xx vkGetDeviceProcAddr(device, "vkCmdWriteTimestamp");
    vkCmdCopyQueryPoolResults = xx vkGetDeviceProcAddr(device, "vkCmdCopyQueryPoolResults");
    vkCmdPushConstants = xx vkGetDeviceProcAddr(device, "vkCmdPushConstants");
    vkCmdBeginRenderPass = xx vkGetDeviceProcAddr(device, "vkCmdBeginRenderPass");
    vkCmdNextSubpass = xx vkGetDeviceProcAddr(device, "vkCmdNextSubpass");
    vkCmdEndRenderPass = xx vkGetDeviceProcAddr(device, "vkCmdEndRenderPass");
    vkCmdExecuteCommands = xx vkGetDeviceProcAddr(device, "vkCmdExecuteCommands");
    vkCreateSharedSwapchainsKHR = xx vkGetDeviceProcAddr(device, "vkCreateSharedSwapchainsKHR");
    vkCreateSwapchainKHR = xx vkGetDeviceProcAddr(device, "vkCreateSwapchainKHR");
    vkDestroySwapchainKHR = xx vkGetDeviceProcAddr(device, "vkDestroySwapchainKHR");
    vkGetSwapchainImagesKHR = xx vkGetDeviceProcAddr(device, "vkGetSwapchainImagesKHR");
    vkAcquireNextImageKHR = xx vkGetDeviceProcAddr(device, "vkAcquireNextImageKHR");
    vkQueuePresentKHR = xx vkGetDeviceProcAddr(device, "vkQueuePresentKHR");
    vkDebugMarkerSetObjectNameEXT = xx vkGetDeviceProcAddr(device, "vkDebugMarkerSetObjectNameEXT");
    vkDebugMarkerSetObjectTagEXT = xx vkGetDeviceProcAddr(device, "vkDebugMarkerSetObjectTagEXT");
    vkCmdDebugMarkerBeginEXT = xx vkGetDeviceProcAddr(device, "vkCmdDebugMarkerBeginEXT");
    vkCmdDebugMarkerEndEXT = xx vkGetDeviceProcAddr(device, "vkCmdDebugMarkerEndEXT");
    vkCmdDebugMarkerInsertEXT = xx vkGetDeviceProcAddr(device, "vkCmdDebugMarkerInsertEXT");
    vkCmdExecuteGeneratedCommandsNV = xx vkGetDeviceProcAddr(device, "vkCmdExecuteGeneratedCommandsNV");
    vkCmdPreprocessGeneratedCommandsNV = xx vkGetDeviceProcAddr(device, "vkCmdPreprocessGeneratedCommandsNV");
    vkCmdBindPipelineShaderGroupNV = xx vkGetDeviceProcAddr(device, "vkCmdBindPipelineShaderGroupNV");
    vkGetGeneratedCommandsMemoryRequirementsNV = xx vkGetDeviceProcAddr(device, "vkGetGeneratedCommandsMemoryRequirementsNV");
    vkCreateIndirectCommandsLayoutNV = xx vkGetDeviceProcAddr(device, "vkCreateIndirectCommandsLayoutNV");
    vkDestroyIndirectCommandsLayoutNV = xx vkGetDeviceProcAddr(device, "vkDestroyIndirectCommandsLayoutNV");
    vkCmdPushDescriptorSetKHR = xx vkGetDeviceProcAddr(device, "vkCmdPushDescriptorSetKHR");
    vkTrimCommandPool = xx vkGetDeviceProcAddr(device, "vkTrimCommandPool");
    vkTrimCommandPoolKHR = xx vkGetDeviceProcAddr(device, "vkTrimCommandPoolKHR");
    vkGetMemoryFdKHR = xx vkGetDeviceProcAddr(device, "vkGetMemoryFdKHR");
    vkGetMemoryFdPropertiesKHR = xx vkGetDeviceProcAddr(device, "vkGetMemoryFdPropertiesKHR");
    vkGetSemaphoreFdKHR = xx vkGetDeviceProcAddr(device, "vkGetSemaphoreFdKHR");
    vkImportSemaphoreFdKHR = xx vkGetDeviceProcAddr(device, "vkImportSemaphoreFdKHR");
    vkGetFenceFdKHR = xx vkGetDeviceProcAddr(device, "vkGetFenceFdKHR");
    vkImportFenceFdKHR = xx vkGetDeviceProcAddr(device, "vkImportFenceFdKHR");
    vkDisplayPowerControlEXT = xx vkGetDeviceProcAddr(device, "vkDisplayPowerControlEXT");
    vkRegisterDeviceEventEXT = xx vkGetDeviceProcAddr(device, "vkRegisterDeviceEventEXT");
    vkRegisterDisplayEventEXT = xx vkGetDeviceProcAddr(device, "vkRegisterDisplayEventEXT");
    vkGetSwapchainCounterEXT = xx vkGetDeviceProcAddr(device, "vkGetSwapchainCounterEXT");
    vkGetDeviceGroupPeerMemoryFeatures = xx vkGetDeviceProcAddr(device, "vkGetDeviceGroupPeerMemoryFeatures");
    vkGetDeviceGroupPeerMemoryFeaturesKHR = xx vkGetDeviceProcAddr(device, "vkGetDeviceGroupPeerMemoryFeaturesKHR");
    vkBindBufferMemory2 = xx vkGetDeviceProcAddr(device, "vkBindBufferMemory2");
    vkBindBufferMemory2KHR = xx vkGetDeviceProcAddr(device, "vkBindBufferMemory2KHR");
    vkBindImageMemory2 = xx vkGetDeviceProcAddr(device, "vkBindImageMemory2");
    vkBindImageMemory2KHR = xx vkGetDeviceProcAddr(device, "vkBindImageMemory2KHR");
    vkCmdSetDeviceMask = xx vkGetDeviceProcAddr(device, "vkCmdSetDeviceMask");
    vkCmdSetDeviceMaskKHR = xx vkGetDeviceProcAddr(device, "vkCmdSetDeviceMaskKHR");
    vkGetDeviceGroupPresentCapabilitiesKHR = xx vkGetDeviceProcAddr(device, "vkGetDeviceGroupPresentCapabilitiesKHR");
    vkGetDeviceGroupSurfacePresentModesKHR = xx vkGetDeviceProcAddr(device, "vkGetDeviceGroupSurfacePresentModesKHR");
    vkAcquireNextImage2KHR = xx vkGetDeviceProcAddr(device, "vkAcquireNextImage2KHR");
    vkCmdDispatchBase = xx vkGetDeviceProcAddr(device, "vkCmdDispatchBase");
    vkCmdDispatchBaseKHR = xx vkGetDeviceProcAddr(device, "vkCmdDispatchBaseKHR");
    vkCreateDescriptorUpdateTemplate = xx vkGetDeviceProcAddr(device, "vkCreateDescriptorUpdateTemplate");
    vkCreateDescriptorUpdateTemplateKHR = xx vkGetDeviceProcAddr(device, "vkCreateDescriptorUpdateTemplateKHR");
    vkDestroyDescriptorUpdateTemplate = xx vkGetDeviceProcAddr(device, "vkDestroyDescriptorUpdateTemplate");
    vkDestroyDescriptorUpdateTemplateKHR = xx vkGetDeviceProcAddr(device, "vkDestroyDescriptorUpdateTemplateKHR");
    vkUpdateDescriptorSetWithTemplate = xx vkGetDeviceProcAddr(device, "vkUpdateDescriptorSetWithTemplate");
    vkUpdateDescriptorSetWithTemplateKHR = xx vkGetDeviceProcAddr(device, "vkUpdateDescriptorSetWithTemplateKHR");
    vkCmdPushDescriptorSetWithTemplateKHR = xx vkGetDeviceProcAddr(device, "vkCmdPushDescriptorSetWithTemplateKHR");
    vkSetHdrMetadataEXT = xx vkGetDeviceProcAddr(device, "vkSetHdrMetadataEXT");
    vkGetSwapchainStatusKHR = xx vkGetDeviceProcAddr(device, "vkGetSwapchainStatusKHR");
    vkGetRefreshCycleDurationGOOGLE = xx vkGetDeviceProcAddr(device, "vkGetRefreshCycleDurationGOOGLE");
    vkGetPastPresentationTimingGOOGLE = xx vkGetDeviceProcAddr(device, "vkGetPastPresentationTimingGOOGLE");
    vkCmdSetViewportWScalingNV = xx vkGetDeviceProcAddr(device, "vkCmdSetViewportWScalingNV");
    vkCmdSetDiscardRectangleEXT = xx vkGetDeviceProcAddr(device, "vkCmdSetDiscardRectangleEXT");
    vkCmdSetSampleLocationsEXT = xx vkGetDeviceProcAddr(device, "vkCmdSetSampleLocationsEXT");
    vkGetBufferMemoryRequirements2 = xx vkGetDeviceProcAddr(device, "vkGetBufferMemoryRequirements2");
    vkGetBufferMemoryRequirements2KHR = xx vkGetDeviceProcAddr(device, "vkGetBufferMemoryRequirements2KHR");
    vkGetImageMemoryRequirements2 = xx vkGetDeviceProcAddr(device, "vkGetImageMemoryRequirements2");
    vkGetImageMemoryRequirements2KHR = xx vkGetDeviceProcAddr(device, "vkGetImageMemoryRequirements2KHR");
    vkGetImageSparseMemoryRequirements2 = xx vkGetDeviceProcAddr(device, "vkGetImageSparseMemoryRequirements2");
    vkGetImageSparseMemoryRequirements2KHR = xx vkGetDeviceProcAddr(device, "vkGetImageSparseMemoryRequirements2KHR");
    vkCreateSamplerYcbcrConversion = xx vkGetDeviceProcAddr(device, "vkCreateSamplerYcbcrConversion");
    vkCreateSamplerYcbcrConversionKHR = xx vkGetDeviceProcAddr(device, "vkCreateSamplerYcbcrConversionKHR");
    vkDestroySamplerYcbcrConversion = xx vkGetDeviceProcAddr(device, "vkDestroySamplerYcbcrConversion");
    vkDestroySamplerYcbcrConversionKHR = xx vkGetDeviceProcAddr(device, "vkDestroySamplerYcbcrConversionKHR");
    vkGetDeviceQueue2 = xx vkGetDeviceProcAddr(device, "vkGetDeviceQueue2");
    vkCreateValidationCacheEXT = xx vkGetDeviceProcAddr(device, "vkCreateValidationCacheEXT");
    vkDestroyValidationCacheEXT = xx vkGetDeviceProcAddr(device, "vkDestroyValidationCacheEXT");
    vkGetValidationCacheDataEXT = xx vkGetDeviceProcAddr(device, "vkGetValidationCacheDataEXT");
    vkMergeValidationCachesEXT = xx vkGetDeviceProcAddr(device, "vkMergeValidationCachesEXT");
    vkGetDescriptorSetLayoutSupport = xx vkGetDeviceProcAddr(device, "vkGetDescriptorSetLayoutSupport");
    vkGetDescriptorSetLayoutSupportKHR = xx vkGetDeviceProcAddr(device, "vkGetDescriptorSetLayoutSupportKHR");
    vkGetSwapchainGrallocUsageANDROID = xx vkGetDeviceProcAddr(device, "vkGetSwapchainGrallocUsageANDROID");
    vkGetSwapchainGrallocUsage2ANDROID = xx vkGetDeviceProcAddr(device, "vkGetSwapchainGrallocUsage2ANDROID");
    vkAcquireImageANDROID = xx vkGetDeviceProcAddr(device, "vkAcquireImageANDROID");
    vkQueueSignalReleaseImageANDROID = xx vkGetDeviceProcAddr(device, "vkQueueSignalReleaseImageANDROID");
    vkGetShaderInfoAMD = xx vkGetDeviceProcAddr(device, "vkGetShaderInfoAMD");
    vkSetLocalDimmingAMD = xx vkGetDeviceProcAddr(device, "vkSetLocalDimmingAMD");
    vkGetCalibratedTimestampsEXT = xx vkGetDeviceProcAddr(device, "vkGetCalibratedTimestampsEXT");
    vkSetDebugUtilsObjectNameEXT = xx vkGetDeviceProcAddr(device, "vkSetDebugUtilsObjectNameEXT");
    vkSetDebugUtilsObjectTagEXT = xx vkGetDeviceProcAddr(device, "vkSetDebugUtilsObjectTagEXT");
    vkQueueBeginDebugUtilsLabelEXT = xx vkGetDeviceProcAddr(device, "vkQueueBeginDebugUtilsLabelEXT");
    vkQueueEndDebugUtilsLabelEXT = xx vkGetDeviceProcAddr(device, "vkQueueEndDebugUtilsLabelEXT");
    vkQueueInsertDebugUtilsLabelEXT = xx vkGetDeviceProcAddr(device, "vkQueueInsertDebugUtilsLabelEXT");
    vkCmdBeginDebugUtilsLabelEXT = xx vkGetDeviceProcAddr(device, "vkCmdBeginDebugUtilsLabelEXT");
    vkCmdEndDebugUtilsLabelEXT = xx vkGetDeviceProcAddr(device, "vkCmdEndDebugUtilsLabelEXT");
    vkCmdInsertDebugUtilsLabelEXT = xx vkGetDeviceProcAddr(device, "vkCmdInsertDebugUtilsLabelEXT");
    vkGetMemoryHostPointerPropertiesEXT = xx vkGetDeviceProcAddr(device, "vkGetMemoryHostPointerPropertiesEXT");
    vkCmdWriteBufferMarkerAMD = xx vkGetDeviceProcAddr(device, "vkCmdWriteBufferMarkerAMD");
    vkCreateRenderPass2 = xx vkGetDeviceProcAddr(device, "vkCreateRenderPass2");
    vkCreateRenderPass2KHR = xx vkGetDeviceProcAddr(device, "vkCreateRenderPass2KHR");
    vkCmdBeginRenderPass2 = xx vkGetDeviceProcAddr(device, "vkCmdBeginRenderPass2");
    vkCmdBeginRenderPass2KHR = xx vkGetDeviceProcAddr(device, "vkCmdBeginRenderPass2KHR");
    vkCmdNextSubpass2 = xx vkGetDeviceProcAddr(device, "vkCmdNextSubpass2");
    vkCmdNextSubpass2KHR = xx vkGetDeviceProcAddr(device, "vkCmdNextSubpass2KHR");
    vkCmdEndRenderPass2 = xx vkGetDeviceProcAddr(device, "vkCmdEndRenderPass2");
    vkCmdEndRenderPass2KHR = xx vkGetDeviceProcAddr(device, "vkCmdEndRenderPass2KHR");
    vkGetSemaphoreCounterValue = xx vkGetDeviceProcAddr(device, "vkGetSemaphoreCounterValue");
    vkGetSemaphoreCounterValueKHR = xx vkGetDeviceProcAddr(device, "vkGetSemaphoreCounterValueKHR");
    vkWaitSemaphores = xx vkGetDeviceProcAddr(device, "vkWaitSemaphores");
    vkWaitSemaphoresKHR = xx vkGetDeviceProcAddr(device, "vkWaitSemaphoresKHR");
    vkSignalSemaphore = xx vkGetDeviceProcAddr(device, "vkSignalSemaphore");
    vkSignalSemaphoreKHR = xx vkGetDeviceProcAddr(device, "vkSignalSemaphoreKHR");
    vkCmdDrawIndirectCount = xx vkGetDeviceProcAddr(device, "vkCmdDrawIndirectCount");
    vkCmdDrawIndirectCountKHR = xx vkGetDeviceProcAddr(device, "vkCmdDrawIndirectCountKHR");
    vkCmdDrawIndirectCountAMD = xx vkGetDeviceProcAddr(device, "vkCmdDrawIndirectCountAMD");
    vkCmdDrawIndexedIndirectCount = xx vkGetDeviceProcAddr(device, "vkCmdDrawIndexedIndirectCount");
    vkCmdDrawIndexedIndirectCountKHR = xx vkGetDeviceProcAddr(device, "vkCmdDrawIndexedIndirectCountKHR");
    vkCmdDrawIndexedIndirectCountAMD = xx vkGetDeviceProcAddr(device, "vkCmdDrawIndexedIndirectCountAMD");
    vkCmdSetCheckpointNV = xx vkGetDeviceProcAddr(device, "vkCmdSetCheckpointNV");
    vkGetQueueCheckpointDataNV = xx vkGetDeviceProcAddr(device, "vkGetQueueCheckpointDataNV");
    vkCmdBindTransformFeedbackBuffersEXT = xx vkGetDeviceProcAddr(device, "vkCmdBindTransformFeedbackBuffersEXT");
    vkCmdBeginTransformFeedbackEXT = xx vkGetDeviceProcAddr(device, "vkCmdBeginTransformFeedbackEXT");
    vkCmdEndTransformFeedbackEXT = xx vkGetDeviceProcAddr(device, "vkCmdEndTransformFeedbackEXT");
    vkCmdBeginQueryIndexedEXT = xx vkGetDeviceProcAddr(device, "vkCmdBeginQueryIndexedEXT");
    vkCmdEndQueryIndexedEXT = xx vkGetDeviceProcAddr(device, "vkCmdEndQueryIndexedEXT");
    vkCmdDrawIndirectByteCountEXT = xx vkGetDeviceProcAddr(device, "vkCmdDrawIndirectByteCountEXT");
    vkCmdSetExclusiveScissorNV = xx vkGetDeviceProcAddr(device, "vkCmdSetExclusiveScissorNV");
    vkCmdBindShadingRateImageNV = xx vkGetDeviceProcAddr(device, "vkCmdBindShadingRateImageNV");
    vkCmdSetViewportShadingRatePaletteNV = xx vkGetDeviceProcAddr(device, "vkCmdSetViewportShadingRatePaletteNV");
    vkCmdSetCoarseSampleOrderNV = xx vkGetDeviceProcAddr(device, "vkCmdSetCoarseSampleOrderNV");
    vkCmdDrawMeshTasksNV = xx vkGetDeviceProcAddr(device, "vkCmdDrawMeshTasksNV");
    vkCmdDrawMeshTasksIndirectNV = xx vkGetDeviceProcAddr(device, "vkCmdDrawMeshTasksIndirectNV");
    vkCmdDrawMeshTasksIndirectCountNV = xx vkGetDeviceProcAddr(device, "vkCmdDrawMeshTasksIndirectCountNV");
    vkCompileDeferredNV = xx vkGetDeviceProcAddr(device, "vkCompileDeferredNV");
    vkCreateAccelerationStructureNV = xx vkGetDeviceProcAddr(device, "vkCreateAccelerationStructureNV");
    vkDestroyAccelerationStructureKHR = xx vkGetDeviceProcAddr(device, "vkDestroyAccelerationStructureKHR");
    vkDestroyAccelerationStructureNV = xx vkGetDeviceProcAddr(device, "vkDestroyAccelerationStructureNV");
    vkGetAccelerationStructureMemoryRequirementsKHR = xx vkGetDeviceProcAddr(device, "vkGetAccelerationStructureMemoryRequirementsKHR");
    vkGetAccelerationStructureMemoryRequirementsNV = xx vkGetDeviceProcAddr(device, "vkGetAccelerationStructureMemoryRequirementsNV");
    vkBindAccelerationStructureMemoryKHR = xx vkGetDeviceProcAddr(device, "vkBindAccelerationStructureMemoryKHR");
    vkBindAccelerationStructureMemoryNV = xx vkGetDeviceProcAddr(device, "vkBindAccelerationStructureMemoryNV");
    vkCmdCopyAccelerationStructureNV = xx vkGetDeviceProcAddr(device, "vkCmdCopyAccelerationStructureNV");
    vkCmdCopyAccelerationStructureKHR = xx vkGetDeviceProcAddr(device, "vkCmdCopyAccelerationStructureKHR");
    vkCopyAccelerationStructureKHR = xx vkGetDeviceProcAddr(device, "vkCopyAccelerationStructureKHR");
    vkCmdCopyAccelerationStructureToMemoryKHR = xx vkGetDeviceProcAddr(device, "vkCmdCopyAccelerationStructureToMemoryKHR");
    vkCopyAccelerationStructureToMemoryKHR = xx vkGetDeviceProcAddr(device, "vkCopyAccelerationStructureToMemoryKHR");
    vkCmdCopyMemoryToAccelerationStructureKHR = xx vkGetDeviceProcAddr(device, "vkCmdCopyMemoryToAccelerationStructureKHR");
    vkCopyMemoryToAccelerationStructureKHR = xx vkGetDeviceProcAddr(device, "vkCopyMemoryToAccelerationStructureKHR");
    vkCmdWriteAccelerationStructuresPropertiesKHR = xx vkGetDeviceProcAddr(device, "vkCmdWriteAccelerationStructuresPropertiesKHR");
    vkCmdWriteAccelerationStructuresPropertiesNV = xx vkGetDeviceProcAddr(device, "vkCmdWriteAccelerationStructuresPropertiesNV");
    vkCmdBuildAccelerationStructureNV = xx vkGetDeviceProcAddr(device, "vkCmdBuildAccelerationStructureNV");
    vkWriteAccelerationStructuresPropertiesKHR = xx vkGetDeviceProcAddr(device, "vkWriteAccelerationStructuresPropertiesKHR");
    vkCmdTraceRaysKHR = xx vkGetDeviceProcAddr(device, "vkCmdTraceRaysKHR");
    vkCmdTraceRaysNV = xx vkGetDeviceProcAddr(device, "vkCmdTraceRaysNV");
    vkGetRayTracingShaderGroupHandlesKHR = xx vkGetDeviceProcAddr(device, "vkGetRayTracingShaderGroupHandlesKHR");
    vkGetRayTracingShaderGroupHandlesNV = xx vkGetDeviceProcAddr(device, "vkGetRayTracingShaderGroupHandlesNV");
    vkGetRayTracingCaptureReplayShaderGroupHandlesKHR = xx vkGetDeviceProcAddr(device, "vkGetRayTracingCaptureReplayShaderGroupHandlesKHR");
    vkGetAccelerationStructureHandleNV = xx vkGetDeviceProcAddr(device, "vkGetAccelerationStructureHandleNV");
    vkCreateRayTracingPipelinesNV = xx vkGetDeviceProcAddr(device, "vkCreateRayTracingPipelinesNV");
    vkCreateRayTracingPipelinesKHR = xx vkGetDeviceProcAddr(device, "vkCreateRayTracingPipelinesKHR");
    vkCmdTraceRaysIndirectKHR = xx vkGetDeviceProcAddr(device, "vkCmdTraceRaysIndirectKHR");
    vkGetDeviceAccelerationStructureCompatibilityKHR = xx vkGetDeviceProcAddr(device, "vkGetDeviceAccelerationStructureCompatibilityKHR");
    vkGetImageViewHandleNVX = xx vkGetDeviceProcAddr(device, "vkGetImageViewHandleNVX");
    vkGetImageViewAddressNVX = xx vkGetDeviceProcAddr(device, "vkGetImageViewAddressNVX");
    vkGetDeviceGroupSurfacePresentModes2EXT = xx vkGetDeviceProcAddr(device, "vkGetDeviceGroupSurfacePresentModes2EXT");
    vkAcquireFullScreenExclusiveModeEXT = xx vkGetDeviceProcAddr(device, "vkAcquireFullScreenExclusiveModeEXT");
    vkReleaseFullScreenExclusiveModeEXT = xx vkGetDeviceProcAddr(device, "vkReleaseFullScreenExclusiveModeEXT");
    vkAcquireProfilingLockKHR = xx vkGetDeviceProcAddr(device, "vkAcquireProfilingLockKHR");
    vkReleaseProfilingLockKHR = xx vkGetDeviceProcAddr(device, "vkReleaseProfilingLockKHR");
    vkGetImageDrmFormatModifierPropertiesEXT = xx vkGetDeviceProcAddr(device, "vkGetImageDrmFormatModifierPropertiesEXT");
    vkGetBufferOpaqueCaptureAddress = xx vkGetDeviceProcAddr(device, "vkGetBufferOpaqueCaptureAddress");
    vkGetBufferOpaqueCaptureAddressKHR = xx vkGetDeviceProcAddr(device, "vkGetBufferOpaqueCaptureAddressKHR");
    vkGetBufferDeviceAddress = xx vkGetDeviceProcAddr(device, "vkGetBufferDeviceAddress");
    vkGetBufferDeviceAddressKHR = xx vkGetDeviceProcAddr(device, "vkGetBufferDeviceAddressKHR");
    vkGetBufferDeviceAddressEXT = xx vkGetDeviceProcAddr(device, "vkGetBufferDeviceAddressEXT");
    vkInitializePerformanceApiINTEL = xx vkGetDeviceProcAddr(device, "vkInitializePerformanceApiINTEL");
    vkUninitializePerformanceApiINTEL = xx vkGetDeviceProcAddr(device, "vkUninitializePerformanceApiINTEL");
    vkCmdSetPerformanceMarkerINTEL = xx vkGetDeviceProcAddr(device, "vkCmdSetPerformanceMarkerINTEL");
    vkCmdSetPerformanceStreamMarkerINTEL = xx vkGetDeviceProcAddr(device, "vkCmdSetPerformanceStreamMarkerINTEL");
    vkCmdSetPerformanceOverrideINTEL = xx vkGetDeviceProcAddr(device, "vkCmdSetPerformanceOverrideINTEL");
    vkAcquirePerformanceConfigurationINTEL = xx vkGetDeviceProcAddr(device, "vkAcquirePerformanceConfigurationINTEL");
    vkReleasePerformanceConfigurationINTEL = xx vkGetDeviceProcAddr(device, "vkReleasePerformanceConfigurationINTEL");
    vkQueueSetPerformanceConfigurationINTEL = xx vkGetDeviceProcAddr(device, "vkQueueSetPerformanceConfigurationINTEL");
    vkGetPerformanceParameterINTEL = xx vkGetDeviceProcAddr(device, "vkGetPerformanceParameterINTEL");
    vkGetDeviceMemoryOpaqueCaptureAddress = xx vkGetDeviceProcAddr(device, "vkGetDeviceMemoryOpaqueCaptureAddress");
    vkGetDeviceMemoryOpaqueCaptureAddressKHR = xx vkGetDeviceProcAddr(device, "vkGetDeviceMemoryOpaqueCaptureAddressKHR");
    vkGetPipelineExecutablePropertiesKHR = xx vkGetDeviceProcAddr(device, "vkGetPipelineExecutablePropertiesKHR");
    vkGetPipelineExecutableStatisticsKHR = xx vkGetDeviceProcAddr(device, "vkGetPipelineExecutableStatisticsKHR");
    vkGetPipelineExecutableInternalRepresentationsKHR = xx vkGetDeviceProcAddr(device, "vkGetPipelineExecutableInternalRepresentationsKHR");
    vkCmdSetLineStippleEXT = xx vkGetDeviceProcAddr(device, "vkCmdSetLineStippleEXT");
    vkCreateAccelerationStructureKHR = xx vkGetDeviceProcAddr(device, "vkCreateAccelerationStructureKHR");
    vkCmdBuildAccelerationStructureKHR = xx vkGetDeviceProcAddr(device, "vkCmdBuildAccelerationStructureKHR");
    vkCmdBuildAccelerationStructureIndirectKHR = xx vkGetDeviceProcAddr(device, "vkCmdBuildAccelerationStructureIndirectKHR");
    vkBuildAccelerationStructureKHR = xx vkGetDeviceProcAddr(device, "vkBuildAccelerationStructureKHR");
    vkGetAccelerationStructureDeviceAddressKHR = xx vkGetDeviceProcAddr(device, "vkGetAccelerationStructureDeviceAddressKHR");
    vkCreateDeferredOperationKHR = xx vkGetDeviceProcAddr(device, "vkCreateDeferredOperationKHR");
    vkDestroyDeferredOperationKHR = xx vkGetDeviceProcAddr(device, "vkDestroyDeferredOperationKHR");
    vkGetDeferredOperationMaxConcurrencyKHR = xx vkGetDeviceProcAddr(device, "vkGetDeferredOperationMaxConcurrencyKHR");
    vkGetDeferredOperationResultKHR = xx vkGetDeviceProcAddr(device, "vkGetDeferredOperationResultKHR");
    vkDeferredOperationJoinKHR = xx vkGetDeviceProcAddr(device, "vkDeferredOperationJoinKHR");
    #if CURRENT_VULKAN_PLATFORM == Vulkan_Platform.Windows
    {
    vkGetMemoryWin32HandleNV = xx vkGetDeviceProcAddr(device, "vkGetMemoryWin32HandleNV");
    vkGetMemoryWin32HandleKHR = xx vkGetDeviceProcAddr(device, "vkGetMemoryWin32HandleKHR");
    vkGetMemoryWin32HandlePropertiesKHR = xx vkGetDeviceProcAddr(device, "vkGetMemoryWin32HandlePropertiesKHR");
    vkGetSemaphoreWin32HandleKHR = xx vkGetDeviceProcAddr(device, "vkGetSemaphoreWin32HandleKHR");
    vkImportSemaphoreWin32HandleKHR = xx vkGetDeviceProcAddr(device, "vkImportSemaphoreWin32HandleKHR");
    vkGetFenceWin32HandleKHR = xx vkGetDeviceProcAddr(device, "vkGetFenceWin32HandleKHR");
    vkImportFenceWin32HandleKHR = xx vkGetDeviceProcAddr(device, "vkImportFenceWin32HandleKHR");
    }
    #if CURRENT_VULKAN_PLATFORM == Vulkan_Platform.Android
    {
    vkGetAndroidHardwareBufferPropertiesANDROID = xx vkGetDeviceProcAddr(device, "vkGetAndroidHardwareBufferPropertiesANDROID");
    vkGetMemoryAndroidHardwareBufferANDROID = xx vkGetDeviceProcAddr(device, "vkGetMemoryAndroidHardwareBufferANDROID");
    }
}


vkCreateInstance : PFN_vkCreateInstance;
vkGetInstanceProcAddr : PFN_vkGetInstanceProcAddr;
vkEnumerateInstanceVersion : PFN_vkEnumerateInstanceVersion;
vkEnumerateInstanceLayerProperties : PFN_vkEnumerateInstanceLayerProperties;
vkEnumerateInstanceExtensionProperties : PFN_vkEnumerateInstanceExtensionProperties;
vkDestroyInstance : PFN_vkDestroyInstance;
vkEnumeratePhysicalDevices : PFN_vkEnumeratePhysicalDevices;
vkGetDeviceProcAddr : PFN_vkGetDeviceProcAddr;
vkGetPhysicalDeviceProperties : PFN_vkGetPhysicalDeviceProperties;
vkGetPhysicalDeviceQueueFamilyProperties : PFN_vkGetPhysicalDeviceQueueFamilyProperties;
vkGetPhysicalDeviceMemoryProperties : PFN_vkGetPhysicalDeviceMemoryProperties;
vkGetPhysicalDeviceFeatures : PFN_vkGetPhysicalDeviceFeatures;
vkGetPhysicalDeviceFormatProperties : PFN_vkGetPhysicalDeviceFormatProperties;
vkGetPhysicalDeviceImageFormatProperties : PFN_vkGetPhysicalDeviceImageFormatProperties;
vkCreateDevice : PFN_vkCreateDevice;
vkEnumerateDeviceLayerProperties : PFN_vkEnumerateDeviceLayerProperties;
vkEnumerateDeviceExtensionProperties : PFN_vkEnumerateDeviceExtensionProperties;
vkGetPhysicalDeviceSparseImageFormatProperties : PFN_vkGetPhysicalDeviceSparseImageFormatProperties;
vkGetPhysicalDeviceDisplayPropertiesKHR : PFN_vkGetPhysicalDeviceDisplayPropertiesKHR;
vkGetPhysicalDeviceDisplayPlanePropertiesKHR : PFN_vkGetPhysicalDeviceDisplayPlanePropertiesKHR;
vkGetDisplayPlaneSupportedDisplaysKHR : PFN_vkGetDisplayPlaneSupportedDisplaysKHR;
vkGetDisplayModePropertiesKHR : PFN_vkGetDisplayModePropertiesKHR;
vkCreateDisplayModeKHR : PFN_vkCreateDisplayModeKHR;
vkGetDisplayPlaneCapabilitiesKHR : PFN_vkGetDisplayPlaneCapabilitiesKHR;
vkCreateDisplayPlaneSurfaceKHR : PFN_vkCreateDisplayPlaneSurfaceKHR;
vkDestroySurfaceKHR : PFN_vkDestroySurfaceKHR;
vkGetPhysicalDeviceSurfaceSupportKHR : PFN_vkGetPhysicalDeviceSurfaceSupportKHR;
vkGetPhysicalDeviceSurfaceCapabilitiesKHR : PFN_vkGetPhysicalDeviceSurfaceCapabilitiesKHR;
vkGetPhysicalDeviceSurfaceFormatsKHR : PFN_vkGetPhysicalDeviceSurfaceFormatsKHR;
vkGetPhysicalDeviceSurfacePresentModesKHR : PFN_vkGetPhysicalDeviceSurfacePresentModesKHR;
vkCreateViSurfaceNN : PFN_vkCreateViSurfaceNN;
vkGetPhysicalDeviceWin32PresentationSupportKHR : PFN_vkGetPhysicalDeviceWin32PresentationSupportKHR;
vkCreateDebugReportCallbackEXT : PFN_vkCreateDebugReportCallbackEXT;
vkDestroyDebugReportCallbackEXT : PFN_vkDestroyDebugReportCallbackEXT;
vkDebugReportMessageEXT : PFN_vkDebugReportMessageEXT;
vkGetPhysicalDeviceExternalImageFormatPropertiesNV : PFN_vkGetPhysicalDeviceExternalImageFormatPropertiesNV;
vkGetPhysicalDeviceFeatures2 : PFN_vkGetPhysicalDeviceFeatures2;
vkGetPhysicalDeviceFeatures2KHR : PFN_vkGetPhysicalDeviceFeatures2KHR;
vkGetPhysicalDeviceProperties2 : PFN_vkGetPhysicalDeviceProperties2;
vkGetPhysicalDeviceProperties2KHR : PFN_vkGetPhysicalDeviceProperties2KHR;
vkGetPhysicalDeviceFormatProperties2 : PFN_vkGetPhysicalDeviceFormatProperties2;
vkGetPhysicalDeviceFormatProperties2KHR : PFN_vkGetPhysicalDeviceFormatProperties2KHR;
vkGetPhysicalDeviceImageFormatProperties2 : PFN_vkGetPhysicalDeviceImageFormatProperties2;
vkGetPhysicalDeviceImageFormatProperties2KHR : PFN_vkGetPhysicalDeviceImageFormatProperties2KHR;
vkGetPhysicalDeviceQueueFamilyProperties2 : PFN_vkGetPhysicalDeviceQueueFamilyProperties2;
vkGetPhysicalDeviceQueueFamilyProperties2KHR : PFN_vkGetPhysicalDeviceQueueFamilyProperties2KHR;
vkGetPhysicalDeviceMemoryProperties2 : PFN_vkGetPhysicalDeviceMemoryProperties2;
vkGetPhysicalDeviceMemoryProperties2KHR : PFN_vkGetPhysicalDeviceMemoryProperties2KHR;
vkGetPhysicalDeviceSparseImageFormatProperties2 : PFN_vkGetPhysicalDeviceSparseImageFormatProperties2;
vkGetPhysicalDeviceSparseImageFormatProperties2KHR : PFN_vkGetPhysicalDeviceSparseImageFormatProperties2KHR;
vkGetPhysicalDeviceExternalBufferProperties : PFN_vkGetPhysicalDeviceExternalBufferProperties;
vkGetPhysicalDeviceExternalBufferPropertiesKHR : PFN_vkGetPhysicalDeviceExternalBufferPropertiesKHR;
vkGetPhysicalDeviceExternalSemaphoreProperties : PFN_vkGetPhysicalDeviceExternalSemaphoreProperties;
vkGetPhysicalDeviceExternalSemaphorePropertiesKHR : PFN_vkGetPhysicalDeviceExternalSemaphorePropertiesKHR;
vkGetPhysicalDeviceExternalFenceProperties : PFN_vkGetPhysicalDeviceExternalFenceProperties;
vkGetPhysicalDeviceExternalFencePropertiesKHR : PFN_vkGetPhysicalDeviceExternalFencePropertiesKHR;
vkReleaseDisplayEXT : PFN_vkReleaseDisplayEXT;
vkGetPhysicalDeviceSurfaceCapabilities2EXT : PFN_vkGetPhysicalDeviceSurfaceCapabilities2EXT;
vkEnumeratePhysicalDeviceGroups : PFN_vkEnumeratePhysicalDeviceGroups;
vkEnumeratePhysicalDeviceGroupsKHR : PFN_vkEnumeratePhysicalDeviceGroupsKHR;
vkGetPhysicalDevicePresentRectanglesKHR : PFN_vkGetPhysicalDevicePresentRectanglesKHR;
vkCreateIOSSurfaceMVK : PFN_vkCreateIOSSurfaceMVK;
vkCreateMacOSSurfaceMVK : PFN_vkCreateMacOSSurfaceMVK;
vkGetPhysicalDeviceMultisamplePropertiesEXT : PFN_vkGetPhysicalDeviceMultisamplePropertiesEXT;
vkGetPhysicalDeviceSurfaceCapabilities2KHR : PFN_vkGetPhysicalDeviceSurfaceCapabilities2KHR;
vkGetPhysicalDeviceSurfaceFormats2KHR : PFN_vkGetPhysicalDeviceSurfaceFormats2KHR;
vkGetPhysicalDeviceDisplayProperties2KHR : PFN_vkGetPhysicalDeviceDisplayProperties2KHR;
vkGetPhysicalDeviceDisplayPlaneProperties2KHR : PFN_vkGetPhysicalDeviceDisplayPlaneProperties2KHR;
vkGetDisplayModeProperties2KHR : PFN_vkGetDisplayModeProperties2KHR;
vkGetDisplayPlaneCapabilities2KHR : PFN_vkGetDisplayPlaneCapabilities2KHR;
vkGetPhysicalDeviceCalibrateableTimeDomainsEXT : PFN_vkGetPhysicalDeviceCalibrateableTimeDomainsEXT;
vkCreateDebugUtilsMessengerEXT : PFN_vkCreateDebugUtilsMessengerEXT;
vkDestroyDebugUtilsMessengerEXT : PFN_vkDestroyDebugUtilsMessengerEXT;
vkSubmitDebugUtilsMessageEXT : PFN_vkSubmitDebugUtilsMessageEXT;
vkGetPhysicalDeviceCooperativeMatrixPropertiesNV : PFN_vkGetPhysicalDeviceCooperativeMatrixPropertiesNV;
vkGetPhysicalDeviceSurfacePresentModes2EXT : PFN_vkGetPhysicalDeviceSurfacePresentModes2EXT;
vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR : PFN_vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR;
vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR : PFN_vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR;
vkCreateHeadlessSurfaceEXT : PFN_vkCreateHeadlessSurfaceEXT;
vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV : PFN_vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV;
vkGetPhysicalDeviceToolPropertiesEXT : PFN_vkGetPhysicalDeviceToolPropertiesEXT;
vkDestroyDevice : PFN_vkDestroyDevice;
vkGetDeviceQueue : PFN_vkGetDeviceQueue;
vkQueueSubmit : PFN_vkQueueSubmit;
vkQueueWaitIdle : PFN_vkQueueWaitIdle;
vkDeviceWaitIdle : PFN_vkDeviceWaitIdle;
vkAllocateMemory : PFN_vkAllocateMemory;
vkFreeMemory : PFN_vkFreeMemory;
vkMapMemory : PFN_vkMapMemory;
vkUnmapMemory : PFN_vkUnmapMemory;
vkFlushMappedMemoryRanges : PFN_vkFlushMappedMemoryRanges;
vkInvalidateMappedMemoryRanges : PFN_vkInvalidateMappedMemoryRanges;
vkGetDeviceMemoryCommitment : PFN_vkGetDeviceMemoryCommitment;
vkGetBufferMemoryRequirements : PFN_vkGetBufferMemoryRequirements;
vkBindBufferMemory : PFN_vkBindBufferMemory;
vkGetImageMemoryRequirements : PFN_vkGetImageMemoryRequirements;
vkBindImageMemory : PFN_vkBindImageMemory;
vkGetImageSparseMemoryRequirements : PFN_vkGetImageSparseMemoryRequirements;
vkQueueBindSparse : PFN_vkQueueBindSparse;
vkCreateFence : PFN_vkCreateFence;
vkDestroyFence : PFN_vkDestroyFence;
vkResetFences : PFN_vkResetFences;
vkGetFenceStatus : PFN_vkGetFenceStatus;
vkWaitForFences : PFN_vkWaitForFences;
vkCreateSemaphore : PFN_vkCreateSemaphore;
vkDestroySemaphore : PFN_vkDestroySemaphore;
vkCreateEvent : PFN_vkCreateEvent;
vkDestroyEvent : PFN_vkDestroyEvent;
vkGetEventStatus : PFN_vkGetEventStatus;
vkSetEvent : PFN_vkSetEvent;
vkResetEvent : PFN_vkResetEvent;
vkCreateQueryPool : PFN_vkCreateQueryPool;
vkDestroyQueryPool : PFN_vkDestroyQueryPool;
vkGetQueryPoolResults : PFN_vkGetQueryPoolResults;
vkResetQueryPool : PFN_vkResetQueryPool;
vkResetQueryPoolEXT : PFN_vkResetQueryPoolEXT;
vkCreateBuffer : PFN_vkCreateBuffer;
vkDestroyBuffer : PFN_vkDestroyBuffer;
vkCreateBufferView : PFN_vkCreateBufferView;
vkDestroyBufferView : PFN_vkDestroyBufferView;
vkCreateImage : PFN_vkCreateImage;
vkDestroyImage : PFN_vkDestroyImage;
vkGetImageSubresourceLayout : PFN_vkGetImageSubresourceLayout;
vkCreateImageView : PFN_vkCreateImageView;
vkDestroyImageView : PFN_vkDestroyImageView;
vkCreateShaderModule : PFN_vkCreateShaderModule;
vkDestroyShaderModule : PFN_vkDestroyShaderModule;
vkCreatePipelineCache : PFN_vkCreatePipelineCache;
vkDestroyPipelineCache : PFN_vkDestroyPipelineCache;
vkGetPipelineCacheData : PFN_vkGetPipelineCacheData;
vkMergePipelineCaches : PFN_vkMergePipelineCaches;
vkCreateGraphicsPipelines : PFN_vkCreateGraphicsPipelines;
vkCreateComputePipelines : PFN_vkCreateComputePipelines;
vkDestroyPipeline : PFN_vkDestroyPipeline;
vkCreatePipelineLayout : PFN_vkCreatePipelineLayout;
vkDestroyPipelineLayout : PFN_vkDestroyPipelineLayout;
vkCreateSampler : PFN_vkCreateSampler;
vkDestroySampler : PFN_vkDestroySampler;
vkCreateDescriptorSetLayout : PFN_vkCreateDescriptorSetLayout;
vkDestroyDescriptorSetLayout : PFN_vkDestroyDescriptorSetLayout;
vkCreateDescriptorPool : PFN_vkCreateDescriptorPool;
vkDestroyDescriptorPool : PFN_vkDestroyDescriptorPool;
vkResetDescriptorPool : PFN_vkResetDescriptorPool;
vkAllocateDescriptorSets : PFN_vkAllocateDescriptorSets;
vkFreeDescriptorSets : PFN_vkFreeDescriptorSets;
vkUpdateDescriptorSets : PFN_vkUpdateDescriptorSets;
vkCreateFramebuffer : PFN_vkCreateFramebuffer;
vkDestroyFramebuffer : PFN_vkDestroyFramebuffer;
vkCreateRenderPass : PFN_vkCreateRenderPass;
vkDestroyRenderPass : PFN_vkDestroyRenderPass;
vkGetRenderAreaGranularity : PFN_vkGetRenderAreaGranularity;
vkCreateCommandPool : PFN_vkCreateCommandPool;
vkDestroyCommandPool : PFN_vkDestroyCommandPool;
vkResetCommandPool : PFN_vkResetCommandPool;
vkAllocateCommandBuffers : PFN_vkAllocateCommandBuffers;
vkFreeCommandBuffers : PFN_vkFreeCommandBuffers;
vkBeginCommandBuffer : PFN_vkBeginCommandBuffer;
vkEndCommandBuffer : PFN_vkEndCommandBuffer;
vkResetCommandBuffer : PFN_vkResetCommandBuffer;
vkCmdBindPipeline : PFN_vkCmdBindPipeline;
vkCmdSetViewport : PFN_vkCmdSetViewport;
vkCmdSetScissor : PFN_vkCmdSetScissor;
vkCmdSetLineWidth : PFN_vkCmdSetLineWidth;
vkCmdSetDepthBias : PFN_vkCmdSetDepthBias;
vkCmdSetBlendConstants : PFN_vkCmdSetBlendConstants;
vkCmdSetDepthBounds : PFN_vkCmdSetDepthBounds;
vkCmdSetStencilCompareMask : PFN_vkCmdSetStencilCompareMask;
vkCmdSetStencilWriteMask : PFN_vkCmdSetStencilWriteMask;
vkCmdSetStencilReference : PFN_vkCmdSetStencilReference;
vkCmdBindDescriptorSets : PFN_vkCmdBindDescriptorSets;
vkCmdBindIndexBuffer : PFN_vkCmdBindIndexBuffer;
vkCmdBindVertexBuffers : PFN_vkCmdBindVertexBuffers;
vkCmdDraw : PFN_vkCmdDraw;
vkCmdDrawIndexed : PFN_vkCmdDrawIndexed;
vkCmdDrawIndirect : PFN_vkCmdDrawIndirect;
vkCmdDrawIndexedIndirect : PFN_vkCmdDrawIndexedIndirect;
vkCmdDispatch : PFN_vkCmdDispatch;
vkCmdDispatchIndirect : PFN_vkCmdDispatchIndirect;
vkCmdCopyBuffer : PFN_vkCmdCopyBuffer;
vkCmdCopyImage : PFN_vkCmdCopyImage;
vkCmdBlitImage : PFN_vkCmdBlitImage;
vkCmdCopyBufferToImage : PFN_vkCmdCopyBufferToImage;
vkCmdCopyImageToBuffer : PFN_vkCmdCopyImageToBuffer;
vkCmdUpdateBuffer : PFN_vkCmdUpdateBuffer;
vkCmdFillBuffer : PFN_vkCmdFillBuffer;
vkCmdClearColorImage : PFN_vkCmdClearColorImage;
vkCmdClearDepthStencilImage : PFN_vkCmdClearDepthStencilImage;
vkCmdClearAttachments : PFN_vkCmdClearAttachments;
vkCmdResolveImage : PFN_vkCmdResolveImage;
vkCmdSetEvent : PFN_vkCmdSetEvent;
vkCmdResetEvent : PFN_vkCmdResetEvent;
vkCmdWaitEvents : PFN_vkCmdWaitEvents;
vkCmdPipelineBarrier : PFN_vkCmdPipelineBarrier;
vkCmdBeginQuery : PFN_vkCmdBeginQuery;
vkCmdEndQuery : PFN_vkCmdEndQuery;
vkCmdBeginConditionalRenderingEXT : PFN_vkCmdBeginConditionalRenderingEXT;
vkCmdEndConditionalRenderingEXT : PFN_vkCmdEndConditionalRenderingEXT;
vkCmdResetQueryPool : PFN_vkCmdResetQueryPool;
vkCmdWriteTimestamp : PFN_vkCmdWriteTimestamp;
vkCmdCopyQueryPoolResults : PFN_vkCmdCopyQueryPoolResults;
vkCmdPushConstants : PFN_vkCmdPushConstants;
vkCmdBeginRenderPass : PFN_vkCmdBeginRenderPass;
vkCmdNextSubpass : PFN_vkCmdNextSubpass;
vkCmdEndRenderPass : PFN_vkCmdEndRenderPass;
vkCmdExecuteCommands : PFN_vkCmdExecuteCommands;
vkCreateSharedSwapchainsKHR : PFN_vkCreateSharedSwapchainsKHR;
vkCreateSwapchainKHR : PFN_vkCreateSwapchainKHR;
vkDestroySwapchainKHR : PFN_vkDestroySwapchainKHR;
vkGetSwapchainImagesKHR : PFN_vkGetSwapchainImagesKHR;
vkAcquireNextImageKHR : PFN_vkAcquireNextImageKHR;
vkQueuePresentKHR : PFN_vkQueuePresentKHR;
vkDebugMarkerSetObjectNameEXT : PFN_vkDebugMarkerSetObjectNameEXT;
vkDebugMarkerSetObjectTagEXT : PFN_vkDebugMarkerSetObjectTagEXT;
vkCmdDebugMarkerBeginEXT : PFN_vkCmdDebugMarkerBeginEXT;
vkCmdDebugMarkerEndEXT : PFN_vkCmdDebugMarkerEndEXT;
vkCmdDebugMarkerInsertEXT : PFN_vkCmdDebugMarkerInsertEXT;
vkCmdExecuteGeneratedCommandsNV : PFN_vkCmdExecuteGeneratedCommandsNV;
vkCmdPreprocessGeneratedCommandsNV : PFN_vkCmdPreprocessGeneratedCommandsNV;
vkCmdBindPipelineShaderGroupNV : PFN_vkCmdBindPipelineShaderGroupNV;
vkGetGeneratedCommandsMemoryRequirementsNV : PFN_vkGetGeneratedCommandsMemoryRequirementsNV;
vkCreateIndirectCommandsLayoutNV : PFN_vkCreateIndirectCommandsLayoutNV;
vkDestroyIndirectCommandsLayoutNV : PFN_vkDestroyIndirectCommandsLayoutNV;
vkCmdPushDescriptorSetKHR : PFN_vkCmdPushDescriptorSetKHR;
vkTrimCommandPool : PFN_vkTrimCommandPool;
vkTrimCommandPoolKHR : PFN_vkTrimCommandPoolKHR;
vkGetMemoryFdKHR : PFN_vkGetMemoryFdKHR;
vkGetMemoryFdPropertiesKHR : PFN_vkGetMemoryFdPropertiesKHR;
vkGetSemaphoreFdKHR : PFN_vkGetSemaphoreFdKHR;
vkImportSemaphoreFdKHR : PFN_vkImportSemaphoreFdKHR;
vkGetFenceFdKHR : PFN_vkGetFenceFdKHR;
vkImportFenceFdKHR : PFN_vkImportFenceFdKHR;
vkDisplayPowerControlEXT : PFN_vkDisplayPowerControlEXT;
vkRegisterDeviceEventEXT : PFN_vkRegisterDeviceEventEXT;
vkRegisterDisplayEventEXT : PFN_vkRegisterDisplayEventEXT;
vkGetSwapchainCounterEXT : PFN_vkGetSwapchainCounterEXT;
vkGetDeviceGroupPeerMemoryFeatures : PFN_vkGetDeviceGroupPeerMemoryFeatures;
vkGetDeviceGroupPeerMemoryFeaturesKHR : PFN_vkGetDeviceGroupPeerMemoryFeaturesKHR;
vkBindBufferMemory2 : PFN_vkBindBufferMemory2;
vkBindBufferMemory2KHR : PFN_vkBindBufferMemory2KHR;
vkBindImageMemory2 : PFN_vkBindImageMemory2;
vkBindImageMemory2KHR : PFN_vkBindImageMemory2KHR;
vkCmdSetDeviceMask : PFN_vkCmdSetDeviceMask;
vkCmdSetDeviceMaskKHR : PFN_vkCmdSetDeviceMaskKHR;
vkGetDeviceGroupPresentCapabilitiesKHR : PFN_vkGetDeviceGroupPresentCapabilitiesKHR;
vkGetDeviceGroupSurfacePresentModesKHR : PFN_vkGetDeviceGroupSurfacePresentModesKHR;
vkAcquireNextImage2KHR : PFN_vkAcquireNextImage2KHR;
vkCmdDispatchBase : PFN_vkCmdDispatchBase;
vkCmdDispatchBaseKHR : PFN_vkCmdDispatchBaseKHR;
vkCreateDescriptorUpdateTemplate : PFN_vkCreateDescriptorUpdateTemplate;
vkCreateDescriptorUpdateTemplateKHR : PFN_vkCreateDescriptorUpdateTemplateKHR;
vkDestroyDescriptorUpdateTemplate : PFN_vkDestroyDescriptorUpdateTemplate;
vkDestroyDescriptorUpdateTemplateKHR : PFN_vkDestroyDescriptorUpdateTemplateKHR;
vkUpdateDescriptorSetWithTemplate : PFN_vkUpdateDescriptorSetWithTemplate;
vkUpdateDescriptorSetWithTemplateKHR : PFN_vkUpdateDescriptorSetWithTemplateKHR;
vkCmdPushDescriptorSetWithTemplateKHR : PFN_vkCmdPushDescriptorSetWithTemplateKHR;
vkSetHdrMetadataEXT : PFN_vkSetHdrMetadataEXT;
vkGetSwapchainStatusKHR : PFN_vkGetSwapchainStatusKHR;
vkGetRefreshCycleDurationGOOGLE : PFN_vkGetRefreshCycleDurationGOOGLE;
vkGetPastPresentationTimingGOOGLE : PFN_vkGetPastPresentationTimingGOOGLE;
vkCmdSetViewportWScalingNV : PFN_vkCmdSetViewportWScalingNV;
vkCmdSetDiscardRectangleEXT : PFN_vkCmdSetDiscardRectangleEXT;
vkCmdSetSampleLocationsEXT : PFN_vkCmdSetSampleLocationsEXT;
vkGetBufferMemoryRequirements2 : PFN_vkGetBufferMemoryRequirements2;
vkGetBufferMemoryRequirements2KHR : PFN_vkGetBufferMemoryRequirements2KHR;
vkGetImageMemoryRequirements2 : PFN_vkGetImageMemoryRequirements2;
vkGetImageMemoryRequirements2KHR : PFN_vkGetImageMemoryRequirements2KHR;
vkGetImageSparseMemoryRequirements2 : PFN_vkGetImageSparseMemoryRequirements2;
vkGetImageSparseMemoryRequirements2KHR : PFN_vkGetImageSparseMemoryRequirements2KHR;
vkCreateSamplerYcbcrConversion : PFN_vkCreateSamplerYcbcrConversion;
vkCreateSamplerYcbcrConversionKHR : PFN_vkCreateSamplerYcbcrConversionKHR;
vkDestroySamplerYcbcrConversion : PFN_vkDestroySamplerYcbcrConversion;
vkDestroySamplerYcbcrConversionKHR : PFN_vkDestroySamplerYcbcrConversionKHR;
vkGetDeviceQueue2 : PFN_vkGetDeviceQueue2;
vkCreateValidationCacheEXT : PFN_vkCreateValidationCacheEXT;
vkDestroyValidationCacheEXT : PFN_vkDestroyValidationCacheEXT;
vkGetValidationCacheDataEXT : PFN_vkGetValidationCacheDataEXT;
vkMergeValidationCachesEXT : PFN_vkMergeValidationCachesEXT;
vkGetDescriptorSetLayoutSupport : PFN_vkGetDescriptorSetLayoutSupport;
vkGetDescriptorSetLayoutSupportKHR : PFN_vkGetDescriptorSetLayoutSupportKHR;
vkGetSwapchainGrallocUsageANDROID : PFN_vkGetSwapchainGrallocUsageANDROID;
vkGetSwapchainGrallocUsage2ANDROID : PFN_vkGetSwapchainGrallocUsage2ANDROID;
vkAcquireImageANDROID : PFN_vkAcquireImageANDROID;
vkQueueSignalReleaseImageANDROID : PFN_vkQueueSignalReleaseImageANDROID;
vkGetShaderInfoAMD : PFN_vkGetShaderInfoAMD;
vkSetLocalDimmingAMD : PFN_vkSetLocalDimmingAMD;
vkGetCalibratedTimestampsEXT : PFN_vkGetCalibratedTimestampsEXT;
vkSetDebugUtilsObjectNameEXT : PFN_vkSetDebugUtilsObjectNameEXT;
vkSetDebugUtilsObjectTagEXT : PFN_vkSetDebugUtilsObjectTagEXT;
vkQueueBeginDebugUtilsLabelEXT : PFN_vkQueueBeginDebugUtilsLabelEXT;
vkQueueEndDebugUtilsLabelEXT : PFN_vkQueueEndDebugUtilsLabelEXT;
vkQueueInsertDebugUtilsLabelEXT : PFN_vkQueueInsertDebugUtilsLabelEXT;
vkCmdBeginDebugUtilsLabelEXT : PFN_vkCmdBeginDebugUtilsLabelEXT;
vkCmdEndDebugUtilsLabelEXT : PFN_vkCmdEndDebugUtilsLabelEXT;
vkCmdInsertDebugUtilsLabelEXT : PFN_vkCmdInsertDebugUtilsLabelEXT;
vkGetMemoryHostPointerPropertiesEXT : PFN_vkGetMemoryHostPointerPropertiesEXT;
vkCmdWriteBufferMarkerAMD : PFN_vkCmdWriteBufferMarkerAMD;
vkCreateRenderPass2 : PFN_vkCreateRenderPass2;
vkCreateRenderPass2KHR : PFN_vkCreateRenderPass2KHR;
vkCmdBeginRenderPass2 : PFN_vkCmdBeginRenderPass2;
vkCmdBeginRenderPass2KHR : PFN_vkCmdBeginRenderPass2KHR;
vkCmdNextSubpass2 : PFN_vkCmdNextSubpass2;
vkCmdNextSubpass2KHR : PFN_vkCmdNextSubpass2KHR;
vkCmdEndRenderPass2 : PFN_vkCmdEndRenderPass2;
vkCmdEndRenderPass2KHR : PFN_vkCmdEndRenderPass2KHR;
vkGetSemaphoreCounterValue : PFN_vkGetSemaphoreCounterValue;
vkGetSemaphoreCounterValueKHR : PFN_vkGetSemaphoreCounterValueKHR;
vkWaitSemaphores : PFN_vkWaitSemaphores;
vkWaitSemaphoresKHR : PFN_vkWaitSemaphoresKHR;
vkSignalSemaphore : PFN_vkSignalSemaphore;
vkSignalSemaphoreKHR : PFN_vkSignalSemaphoreKHR;
vkCmdDrawIndirectCount : PFN_vkCmdDrawIndirectCount;
vkCmdDrawIndirectCountKHR : PFN_vkCmdDrawIndirectCountKHR;
vkCmdDrawIndirectCountAMD : PFN_vkCmdDrawIndirectCountAMD;
vkCmdDrawIndexedIndirectCount : PFN_vkCmdDrawIndexedIndirectCount;
vkCmdDrawIndexedIndirectCountKHR : PFN_vkCmdDrawIndexedIndirectCountKHR;
vkCmdDrawIndexedIndirectCountAMD : PFN_vkCmdDrawIndexedIndirectCountAMD;
vkCmdSetCheckpointNV : PFN_vkCmdSetCheckpointNV;
vkGetQueueCheckpointDataNV : PFN_vkGetQueueCheckpointDataNV;
vkCmdBindTransformFeedbackBuffersEXT : PFN_vkCmdBindTransformFeedbackBuffersEXT;
vkCmdBeginTransformFeedbackEXT : PFN_vkCmdBeginTransformFeedbackEXT;
vkCmdEndTransformFeedbackEXT : PFN_vkCmdEndTransformFeedbackEXT;
vkCmdBeginQueryIndexedEXT : PFN_vkCmdBeginQueryIndexedEXT;
vkCmdEndQueryIndexedEXT : PFN_vkCmdEndQueryIndexedEXT;
vkCmdDrawIndirectByteCountEXT : PFN_vkCmdDrawIndirectByteCountEXT;
vkCmdSetExclusiveScissorNV : PFN_vkCmdSetExclusiveScissorNV;
vkCmdBindShadingRateImageNV : PFN_vkCmdBindShadingRateImageNV;
vkCmdSetViewportShadingRatePaletteNV : PFN_vkCmdSetViewportShadingRatePaletteNV;
vkCmdSetCoarseSampleOrderNV : PFN_vkCmdSetCoarseSampleOrderNV;
vkCmdDrawMeshTasksNV : PFN_vkCmdDrawMeshTasksNV;
vkCmdDrawMeshTasksIndirectNV : PFN_vkCmdDrawMeshTasksIndirectNV;
vkCmdDrawMeshTasksIndirectCountNV : PFN_vkCmdDrawMeshTasksIndirectCountNV;
vkCompileDeferredNV : PFN_vkCompileDeferredNV;
vkCreateAccelerationStructureNV : PFN_vkCreateAccelerationStructureNV;
vkDestroyAccelerationStructureKHR : PFN_vkDestroyAccelerationStructureKHR;
vkDestroyAccelerationStructureNV : PFN_vkDestroyAccelerationStructureNV;
vkGetAccelerationStructureMemoryRequirementsKHR : PFN_vkGetAccelerationStructureMemoryRequirementsKHR;
vkGetAccelerationStructureMemoryRequirementsNV : PFN_vkGetAccelerationStructureMemoryRequirementsNV;
vkBindAccelerationStructureMemoryKHR : PFN_vkBindAccelerationStructureMemoryKHR;
vkBindAccelerationStructureMemoryNV : PFN_vkBindAccelerationStructureMemoryNV;
vkCmdCopyAccelerationStructureNV : PFN_vkCmdCopyAccelerationStructureNV;
vkCmdCopyAccelerationStructureKHR : PFN_vkCmdCopyAccelerationStructureKHR;
vkCopyAccelerationStructureKHR : PFN_vkCopyAccelerationStructureKHR;
vkCmdCopyAccelerationStructureToMemoryKHR : PFN_vkCmdCopyAccelerationStructureToMemoryKHR;
vkCopyAccelerationStructureToMemoryKHR : PFN_vkCopyAccelerationStructureToMemoryKHR;
vkCmdCopyMemoryToAccelerationStructureKHR : PFN_vkCmdCopyMemoryToAccelerationStructureKHR;
vkCopyMemoryToAccelerationStructureKHR : PFN_vkCopyMemoryToAccelerationStructureKHR;
vkCmdWriteAccelerationStructuresPropertiesKHR : PFN_vkCmdWriteAccelerationStructuresPropertiesKHR;
vkCmdWriteAccelerationStructuresPropertiesNV : PFN_vkCmdWriteAccelerationStructuresPropertiesNV;
vkCmdBuildAccelerationStructureNV : PFN_vkCmdBuildAccelerationStructureNV;
vkWriteAccelerationStructuresPropertiesKHR : PFN_vkWriteAccelerationStructuresPropertiesKHR;
vkCmdTraceRaysKHR : PFN_vkCmdTraceRaysKHR;
vkCmdTraceRaysNV : PFN_vkCmdTraceRaysNV;
vkGetRayTracingShaderGroupHandlesKHR : PFN_vkGetRayTracingShaderGroupHandlesKHR;
vkGetRayTracingShaderGroupHandlesNV : PFN_vkGetRayTracingShaderGroupHandlesNV;
vkGetRayTracingCaptureReplayShaderGroupHandlesKHR : PFN_vkGetRayTracingCaptureReplayShaderGroupHandlesKHR;
vkGetAccelerationStructureHandleNV : PFN_vkGetAccelerationStructureHandleNV;
vkCreateRayTracingPipelinesNV : PFN_vkCreateRayTracingPipelinesNV;
vkCreateRayTracingPipelinesKHR : PFN_vkCreateRayTracingPipelinesKHR;
vkCmdTraceRaysIndirectKHR : PFN_vkCmdTraceRaysIndirectKHR;
vkGetDeviceAccelerationStructureCompatibilityKHR : PFN_vkGetDeviceAccelerationStructureCompatibilityKHR;
vkGetImageViewHandleNVX : PFN_vkGetImageViewHandleNVX;
vkGetImageViewAddressNVX : PFN_vkGetImageViewAddressNVX;
vkGetDeviceGroupSurfacePresentModes2EXT : PFN_vkGetDeviceGroupSurfacePresentModes2EXT;
vkAcquireFullScreenExclusiveModeEXT : PFN_vkAcquireFullScreenExclusiveModeEXT;
vkReleaseFullScreenExclusiveModeEXT : PFN_vkReleaseFullScreenExclusiveModeEXT;
vkAcquireProfilingLockKHR : PFN_vkAcquireProfilingLockKHR;
vkReleaseProfilingLockKHR : PFN_vkReleaseProfilingLockKHR;
vkGetImageDrmFormatModifierPropertiesEXT : PFN_vkGetImageDrmFormatModifierPropertiesEXT;
vkGetBufferOpaqueCaptureAddress : PFN_vkGetBufferOpaqueCaptureAddress;
vkGetBufferOpaqueCaptureAddressKHR : PFN_vkGetBufferOpaqueCaptureAddressKHR;
vkGetBufferDeviceAddress : PFN_vkGetBufferDeviceAddress;
vkGetBufferDeviceAddressKHR : PFN_vkGetBufferDeviceAddressKHR;
vkGetBufferDeviceAddressEXT : PFN_vkGetBufferDeviceAddressEXT;
vkInitializePerformanceApiINTEL : PFN_vkInitializePerformanceApiINTEL;
vkUninitializePerformanceApiINTEL : PFN_vkUninitializePerformanceApiINTEL;
vkCmdSetPerformanceMarkerINTEL : PFN_vkCmdSetPerformanceMarkerINTEL;
vkCmdSetPerformanceStreamMarkerINTEL : PFN_vkCmdSetPerformanceStreamMarkerINTEL;
vkCmdSetPerformanceOverrideINTEL : PFN_vkCmdSetPerformanceOverrideINTEL;
vkAcquirePerformanceConfigurationINTEL : PFN_vkAcquirePerformanceConfigurationINTEL;
vkReleasePerformanceConfigurationINTEL : PFN_vkReleasePerformanceConfigurationINTEL;
vkQueueSetPerformanceConfigurationINTEL : PFN_vkQueueSetPerformanceConfigurationINTEL;
vkGetPerformanceParameterINTEL : PFN_vkGetPerformanceParameterINTEL;
vkGetDeviceMemoryOpaqueCaptureAddress : PFN_vkGetDeviceMemoryOpaqueCaptureAddress;
vkGetDeviceMemoryOpaqueCaptureAddressKHR : PFN_vkGetDeviceMemoryOpaqueCaptureAddressKHR;
vkGetPipelineExecutablePropertiesKHR : PFN_vkGetPipelineExecutablePropertiesKHR;
vkGetPipelineExecutableStatisticsKHR : PFN_vkGetPipelineExecutableStatisticsKHR;
vkGetPipelineExecutableInternalRepresentationsKHR : PFN_vkGetPipelineExecutableInternalRepresentationsKHR;
vkCmdSetLineStippleEXT : PFN_vkCmdSetLineStippleEXT;
vkCreateAccelerationStructureKHR : PFN_vkCreateAccelerationStructureKHR;
vkCmdBuildAccelerationStructureKHR : PFN_vkCmdBuildAccelerationStructureKHR;
vkCmdBuildAccelerationStructureIndirectKHR : PFN_vkCmdBuildAccelerationStructureIndirectKHR;
vkBuildAccelerationStructureKHR : PFN_vkBuildAccelerationStructureKHR;
vkGetAccelerationStructureDeviceAddressKHR : PFN_vkGetAccelerationStructureDeviceAddressKHR;
vkCreateDeferredOperationKHR : PFN_vkCreateDeferredOperationKHR;
vkDestroyDeferredOperationKHR : PFN_vkDestroyDeferredOperationKHR;
vkGetDeferredOperationMaxConcurrencyKHR : PFN_vkGetDeferredOperationMaxConcurrencyKHR;
vkGetDeferredOperationResultKHR : PFN_vkGetDeferredOperationResultKHR;
vkDeferredOperationJoinKHR : PFN_vkDeferredOperationJoinKHR;
#if CURRENT_VULKAN_PLATFORM == Vulkan_Platform.X11
{
vkCreateXlibSurfaceKHR : PFN_vkCreateXlibSurfaceKHR;
vkGetPhysicalDeviceXlibPresentationSupportKHR : PFN_vkGetPhysicalDeviceXlibPresentationSupportKHR;
vkAcquireXlibDisplayEXT : PFN_vkAcquireXlibDisplayEXT;
vkGetRandROutputDisplayEXT : PFN_vkGetRandROutputDisplayEXT;
}
else #if CURRENT_VULKAN_PLATFORM == Vulkan_Platform.Wayland
{
vkCreateWaylandSurfaceKHR : PFN_vkCreateWaylandSurfaceKHR;
vkGetPhysicalDeviceWaylandPresentationSupportKHR : PFN_vkGetPhysicalDeviceWaylandPresentationSupportKHR;
}
else #if CURRENT_VULKAN_PLATFORM == Vulkan_Platform.Windows
{
vkCreateWin32SurfaceKHR : PFN_vkCreateWin32SurfaceKHR;
vkGetMemoryWin32HandleNV : PFN_vkGetMemoryWin32HandleNV;
vkGetMemoryWin32HandleKHR : PFN_vkGetMemoryWin32HandleKHR;
vkGetMemoryWin32HandlePropertiesKHR : PFN_vkGetMemoryWin32HandlePropertiesKHR;
vkGetSemaphoreWin32HandleKHR : PFN_vkGetSemaphoreWin32HandleKHR;
vkImportSemaphoreWin32HandleKHR : PFN_vkImportSemaphoreWin32HandleKHR;
vkGetFenceWin32HandleKHR : PFN_vkGetFenceWin32HandleKHR;
vkImportFenceWin32HandleKHR : PFN_vkImportFenceWin32HandleKHR;
}
else #if CURRENT_VULKAN_PLATFORM == Vulkan_Platform.XCB
{
vkCreateXcbSurfaceKHR : PFN_vkCreateXcbSurfaceKHR;
vkGetPhysicalDeviceXcbPresentationSupportKHR : PFN_vkGetPhysicalDeviceXcbPresentationSupportKHR;
}
else #if CURRENT_VULKAN_PLATFORM == Vulkan_Platform.Zircon
{
vkCreateImagePipeSurfaceFUCHSIA : PFN_vkCreateImagePipeSurfaceFUCHSIA;
}
else #if CURRENT_VULKAN_PLATFORM == Vulkan_Platform.GGP
{
vkCreateStreamDescriptorSurfaceGGP : PFN_vkCreateStreamDescriptorSurfaceGGP;
}
else #if CURRENT_VULKAN_PLATFORM == Vulkan_Platform.Android
{
vkCreateAndroidSurfaceKHR : PFN_vkCreateAndroidSurfaceKHR;
vkGetAndroidHardwareBufferPropertiesANDROID : PFN_vkGetAndroidHardwareBufferPropertiesANDROID;
vkGetMemoryAndroidHardwareBufferANDROID : PFN_vkGetMemoryAndroidHardwareBufferANDROID;
}
else #if CURRENT_VULKAN_PLATFORM == Vulkan_Platform.MacOS
{
vkCreateMetalSurfaceEXT : PFN_vkCreateMetalSurfaceEXT;
}


