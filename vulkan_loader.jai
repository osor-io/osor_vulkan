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
    info := type_info(type_of(_vulkan_loader_commands));
    for member: info.members 
    {
        member_to_set := cast(**void)((cast(*u8)*_vulkan_loader_commands) + member.offset_in_bytes);
        <<member_to_set = cast(*void) load(library_handle, member.name.data);
    }
}


load_vulkan_instance_procedures :: (instance : VkInstance)
{
    info := type_info(type_of(_vulkan_instance_commands));
    for member: info.members 
    {
        member_to_set := cast(**void)((cast(*u8)*_vulkan_instance_commands) + member.offset_in_bytes);
        <<member_to_set = cast(*void) vkGetInstanceProcAddr(instance, member.name.data);
    }
}


load_vulkan_device_procedures :: (device: VkDevice)
{
    info := type_info(type_of(_vulkan_device_commands));
    for member: info.members 
    {
        member_to_set := cast(**void)((cast(*u8)*_vulkan_device_commands) + member.offset_in_bytes);
        <<member_to_set = cast(*void) vkGetDeviceProcAddr(device, member.name.data);
    }
}


using _vulkan_all_commands : Vulkan_All_Commands;
Vulkan_All_Commands :: struct
{
    using _vulkan_loader_commands : Vulkan_Loader_Commands;
    Vulkan_Loader_Commands :: struct
    {
        vkCreateInstance : PFN_vkCreateInstance;
        vkGetInstanceProcAddr : PFN_vkGetInstanceProcAddr;
        vkEnumerateInstanceVersion : PFN_vkEnumerateInstanceVersion;
        vkEnumerateInstanceLayerProperties : PFN_vkEnumerateInstanceLayerProperties;
        vkEnumerateInstanceExtensionProperties : PFN_vkEnumerateInstanceExtensionProperties;
    }

    using _vulkan_instance_commands : Vulkan_Instance_Commands;
    Vulkan_Instance_Commands :: struct
    {
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
        vkAcquireWinrtDisplayNV : PFN_vkAcquireWinrtDisplayNV;
        vkGetWinrtDisplayNV : PFN_vkGetWinrtDisplayNV;
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
        vkGetPhysicalDeviceFragmentShadingRatesKHR : PFN_vkGetPhysicalDeviceFragmentShadingRatesKHR;
        #if VULKAN_PLATFORM == .X11
        {
            vkCreateXlibSurfaceKHR : PFN_vkCreateXlibSurfaceKHR;
            vkGetPhysicalDeviceXlibPresentationSupportKHR : PFN_vkGetPhysicalDeviceXlibPresentationSupportKHR;
            vkAcquireXlibDisplayEXT : PFN_vkAcquireXlibDisplayEXT;
            vkGetRandROutputDisplayEXT : PFN_vkGetRandROutputDisplayEXT;
        }
        else #if VULKAN_PLATFORM == .Wayland
        {
            vkCreateWaylandSurfaceKHR : PFN_vkCreateWaylandSurfaceKHR;
            vkGetPhysicalDeviceWaylandPresentationSupportKHR : PFN_vkGetPhysicalDeviceWaylandPresentationSupportKHR;
        }
        else #if VULKAN_PLATFORM == .Windows
        {
            vkCreateWin32SurfaceKHR : PFN_vkCreateWin32SurfaceKHR;
        }
        else #if VULKAN_PLATFORM == .XCB
        {
            vkCreateXcbSurfaceKHR : PFN_vkCreateXcbSurfaceKHR;
            vkGetPhysicalDeviceXcbPresentationSupportKHR : PFN_vkGetPhysicalDeviceXcbPresentationSupportKHR;
        }
        else #if VULKAN_PLATFORM == .Zircon
        {
            vkCreateImagePipeSurfaceFUCHSIA : PFN_vkCreateImagePipeSurfaceFUCHSIA;
        }
        else #if VULKAN_PLATFORM == .GGP
        {
            vkCreateStreamDescriptorSurfaceGGP : PFN_vkCreateStreamDescriptorSurfaceGGP;
        }
        else #if VULKAN_PLATFORM == .Android
        {
            vkCreateAndroidSurfaceKHR : PFN_vkCreateAndroidSurfaceKHR;
        }
        else #if VULKAN_PLATFORM == .MacOS
        {
            vkCreateMetalSurfaceEXT : PFN_vkCreateMetalSurfaceEXT;
        }
        else #if VULKAN_PLATFORM == .IDirectFB
        {
            vkCreateDirectFBSurfaceEXT : PFN_vkCreateDirectFBSurfaceEXT;
            vkGetPhysicalDeviceDirectFBPresentationSupportEXT : PFN_vkGetPhysicalDeviceDirectFBPresentationSupportEXT;
        }
    }

    using _vulkan_device_commands : Vulkan_Device_Commands;
    Vulkan_Device_Commands :: struct
    {
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
        vkGetAccelerationStructureMemoryRequirementsNV : PFN_vkGetAccelerationStructureMemoryRequirementsNV;
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
        vkGetRayTracingShaderGroupStackSizeKHR : PFN_vkGetRayTracingShaderGroupStackSizeKHR;
        vkCmdSetRayTracingPipelineStackSizeKHR : PFN_vkCmdSetRayTracingPipelineStackSizeKHR;
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
        vkCmdBuildAccelerationStructuresKHR : PFN_vkCmdBuildAccelerationStructuresKHR;
        vkCmdBuildAccelerationStructuresIndirectKHR : PFN_vkCmdBuildAccelerationStructuresIndirectKHR;
        vkBuildAccelerationStructuresKHR : PFN_vkBuildAccelerationStructuresKHR;
        vkGetAccelerationStructureDeviceAddressKHR : PFN_vkGetAccelerationStructureDeviceAddressKHR;
        vkCreateDeferredOperationKHR : PFN_vkCreateDeferredOperationKHR;
        vkDestroyDeferredOperationKHR : PFN_vkDestroyDeferredOperationKHR;
        vkGetDeferredOperationMaxConcurrencyKHR : PFN_vkGetDeferredOperationMaxConcurrencyKHR;
        vkGetDeferredOperationResultKHR : PFN_vkGetDeferredOperationResultKHR;
        vkDeferredOperationJoinKHR : PFN_vkDeferredOperationJoinKHR;
        vkCmdSetCullModeEXT : PFN_vkCmdSetCullModeEXT;
        vkCmdSetFrontFaceEXT : PFN_vkCmdSetFrontFaceEXT;
        vkCmdSetPrimitiveTopologyEXT : PFN_vkCmdSetPrimitiveTopologyEXT;
        vkCmdSetViewportWithCountEXT : PFN_vkCmdSetViewportWithCountEXT;
        vkCmdSetScissorWithCountEXT : PFN_vkCmdSetScissorWithCountEXT;
        vkCmdBindVertexBuffers2EXT : PFN_vkCmdBindVertexBuffers2EXT;
        vkCmdSetDepthTestEnableEXT : PFN_vkCmdSetDepthTestEnableEXT;
        vkCmdSetDepthWriteEnableEXT : PFN_vkCmdSetDepthWriteEnableEXT;
        vkCmdSetDepthCompareOpEXT : PFN_vkCmdSetDepthCompareOpEXT;
        vkCmdSetDepthBoundsTestEnableEXT : PFN_vkCmdSetDepthBoundsTestEnableEXT;
        vkCmdSetStencilTestEnableEXT : PFN_vkCmdSetStencilTestEnableEXT;
        vkCmdSetStencilOpEXT : PFN_vkCmdSetStencilOpEXT;
        vkCreatePrivateDataSlotEXT : PFN_vkCreatePrivateDataSlotEXT;
        vkDestroyPrivateDataSlotEXT : PFN_vkDestroyPrivateDataSlotEXT;
        vkSetPrivateDataEXT : PFN_vkSetPrivateDataEXT;
        vkGetPrivateDataEXT : PFN_vkGetPrivateDataEXT;
        vkCmdCopyBuffer2KHR : PFN_vkCmdCopyBuffer2KHR;
        vkCmdCopyImage2KHR : PFN_vkCmdCopyImage2KHR;
        vkCmdBlitImage2KHR : PFN_vkCmdBlitImage2KHR;
        vkCmdCopyBufferToImage2KHR : PFN_vkCmdCopyBufferToImage2KHR;
        vkCmdCopyImageToBuffer2KHR : PFN_vkCmdCopyImageToBuffer2KHR;
        vkCmdResolveImage2KHR : PFN_vkCmdResolveImage2KHR;
        vkCmdSetFragmentShadingRateKHR : PFN_vkCmdSetFragmentShadingRateKHR;
        vkCmdSetFragmentShadingRateEnumNV : PFN_vkCmdSetFragmentShadingRateEnumNV;
        vkGetAccelerationStructureBuildSizesKHR : PFN_vkGetAccelerationStructureBuildSizesKHR;
        #if VULKAN_PLATFORM == .Windows
        {
            vkGetMemoryWin32HandleNV : PFN_vkGetMemoryWin32HandleNV;
            vkGetMemoryWin32HandleKHR : PFN_vkGetMemoryWin32HandleKHR;
            vkGetMemoryWin32HandlePropertiesKHR : PFN_vkGetMemoryWin32HandlePropertiesKHR;
            vkGetSemaphoreWin32HandleKHR : PFN_vkGetSemaphoreWin32HandleKHR;
            vkImportSemaphoreWin32HandleKHR : PFN_vkImportSemaphoreWin32HandleKHR;
            vkGetFenceWin32HandleKHR : PFN_vkGetFenceWin32HandleKHR;
            vkImportFenceWin32HandleKHR : PFN_vkImportFenceWin32HandleKHR;
        }
        else #if VULKAN_PLATFORM == .Android
        {
            vkGetAndroidHardwareBufferPropertiesANDROID : PFN_vkGetAndroidHardwareBufferPropertiesANDROID;
            vkGetMemoryAndroidHardwareBufferANDROID : PFN_vkGetMemoryAndroidHardwareBufferANDROID;
        }
    }
}
