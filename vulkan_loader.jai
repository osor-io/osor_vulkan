/*
This file handles loading the entry points for the Vulkan API. Vulkan works
by having a dynamic library deployed on the system that you have to load and get the
entry-points to. You can also link against their own loader and that will give you
the procedures directly, but this would have *some* overhead and we don't want that :)

In this file there is global variables that will hold all the procedure pointers for
each entry-point, and then there is the procedures you can call to fill them. If you want
to load the procedures into your own structures and not the global variables here,
you can pass in the data structure to fill in each of the load_vulkan_* procedures.

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


load_vulkan_loader_procedures :: (library_handle : $Library_Handle_Type, $load : $Loader_Procedure_Type, loader_commands : *Vulkan_Loader_Commands = null)
{
    loader_commands = ifx loader_commands then loader_commands else *_vulkan_loader_commands;
    info := type_info(type_of(loader_commands.*));
    for member: info.members
    {
        member_to_set := cast(**void)((cast(*u8)loader_commands) + member.offset_in_bytes);
        member_to_set.* = cast(*void) load(library_handle, member.name.data);
    }
}


load_vulkan_instance_procedures :: (instance : VkInstance, instance_commands : *Vulkan_Instance_Commands = null)
{
    instance_commands = ifx instance_commands then instance_commands else *_vulkan_instance_commands;
    info := type_info(type_of(instance_commands.*));
    for member: info.members
    {
        member_to_set := cast(**void)((cast(*u8)instance_commands) + member.offset_in_bytes);
        member_to_set.* = cast(*void) vkGetInstanceProcAddr(instance, member.name.data);
    }
}


load_vulkan_device_procedures :: (device: VkDevice, device_commands : *Vulkan_Device_Commands = null)
{
    device_commands = ifx device_commands then device_commands else *_vulkan_device_commands;
    info := type_info(type_of(device_commands.*));
    for member: info.members
    {
        member_to_set := cast(**void)((cast(*u8)device_commands) + member.offset_in_bytes);
        member_to_set.* = cast(*void) vkGetDeviceProcAddr(device, member.name.data);
    }
}


using _vulkan_all_commands : Vulkan_All_Commands;
Vulkan_All_Commands :: struct
{
    using _vulkan_loader_commands : Vulkan_Loader_Commands;
    Vulkan_Loader_Commands :: struct #type_info_no_size_complaint
    {
        vkCreateInstance : PFN_vkCreateInstance;
        vkGetInstanceProcAddr : PFN_vkGetInstanceProcAddr;
        vkEnumerateInstanceVersion : PFN_vkEnumerateInstanceVersion;
        vkEnumerateInstanceLayerProperties : PFN_vkEnumerateInstanceLayerProperties;
        vkEnumerateInstanceExtensionProperties : PFN_vkEnumerateInstanceExtensionProperties;
    }

    using _vulkan_instance_commands : Vulkan_Instance_Commands;
    Vulkan_Instance_Commands :: struct #type_info_no_size_complaint
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
        vkGetPhysicalDeviceMultisamplePropertiesEXT : PFN_vkGetPhysicalDeviceMultisamplePropertiesEXT;
        vkGetPhysicalDeviceSurfaceCapabilities2KHR : PFN_vkGetPhysicalDeviceSurfaceCapabilities2KHR;
        vkGetPhysicalDeviceSurfaceFormats2KHR : PFN_vkGetPhysicalDeviceSurfaceFormats2KHR;
        vkGetPhysicalDeviceDisplayProperties2KHR : PFN_vkGetPhysicalDeviceDisplayProperties2KHR;
        vkGetPhysicalDeviceDisplayPlaneProperties2KHR : PFN_vkGetPhysicalDeviceDisplayPlaneProperties2KHR;
        vkGetDisplayModeProperties2KHR : PFN_vkGetDisplayModeProperties2KHR;
        vkGetDisplayPlaneCapabilities2KHR : PFN_vkGetDisplayPlaneCapabilities2KHR;
        vkGetPhysicalDeviceCalibrateableTimeDomainsKHR : PFN_vkGetPhysicalDeviceCalibrateableTimeDomainsKHR;
        vkGetPhysicalDeviceCalibrateableTimeDomainsEXT : PFN_vkGetPhysicalDeviceCalibrateableTimeDomainsEXT;
        vkSetDebugUtilsObjectNameEXT : PFN_vkSetDebugUtilsObjectNameEXT;
        vkSetDebugUtilsObjectTagEXT : PFN_vkSetDebugUtilsObjectTagEXT;
        vkQueueBeginDebugUtilsLabelEXT : PFN_vkQueueBeginDebugUtilsLabelEXT;
        vkQueueEndDebugUtilsLabelEXT : PFN_vkQueueEndDebugUtilsLabelEXT;
        vkQueueInsertDebugUtilsLabelEXT : PFN_vkQueueInsertDebugUtilsLabelEXT;
        vkCmdBeginDebugUtilsLabelEXT : PFN_vkCmdBeginDebugUtilsLabelEXT;
        vkCmdEndDebugUtilsLabelEXT : PFN_vkCmdEndDebugUtilsLabelEXT;
        vkCmdInsertDebugUtilsLabelEXT : PFN_vkCmdInsertDebugUtilsLabelEXT;
        vkCreateDebugUtilsMessengerEXT : PFN_vkCreateDebugUtilsMessengerEXT;
        vkDestroyDebugUtilsMessengerEXT : PFN_vkDestroyDebugUtilsMessengerEXT;
        vkSubmitDebugUtilsMessageEXT : PFN_vkSubmitDebugUtilsMessageEXT;
        vkGetPhysicalDeviceCooperativeMatrixPropertiesNV : PFN_vkGetPhysicalDeviceCooperativeMatrixPropertiesNV;
        vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR : PFN_vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR;
        vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR : PFN_vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR;
        vkCreateHeadlessSurfaceEXT : PFN_vkCreateHeadlessSurfaceEXT;
        vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV : PFN_vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV;
        vkGetPhysicalDeviceToolProperties : PFN_vkGetPhysicalDeviceToolProperties;
        vkGetPhysicalDeviceToolPropertiesEXT : PFN_vkGetPhysicalDeviceToolPropertiesEXT;
        vkGetPhysicalDeviceRefreshableObjectTypesKHR : PFN_vkGetPhysicalDeviceRefreshableObjectTypesKHR;
        vkGetPhysicalDeviceFragmentShadingRatesKHR : PFN_vkGetPhysicalDeviceFragmentShadingRatesKHR;
        vkGetPhysicalDeviceVideoCapabilitiesKHR : PFN_vkGetPhysicalDeviceVideoCapabilitiesKHR;
        vkGetPhysicalDeviceVideoFormatPropertiesKHR : PFN_vkGetPhysicalDeviceVideoFormatPropertiesKHR;
        vkGetPhysicalDeviceVideoEncodeQualityLevelPropertiesKHR : PFN_vkGetPhysicalDeviceVideoEncodeQualityLevelPropertiesKHR;
        vkAcquireDrmDisplayEXT : PFN_vkAcquireDrmDisplayEXT;
        vkGetDrmDisplayEXT : PFN_vkGetDrmDisplayEXT;
        vkGetPhysicalDeviceOpticalFlowImageFormatsNV : PFN_vkGetPhysicalDeviceOpticalFlowImageFormatsNV;
        vkGetPhysicalDeviceCooperativeMatrixPropertiesKHR : PFN_vkGetPhysicalDeviceCooperativeMatrixPropertiesKHR;
        vkGetPhysicalDeviceCooperativeMatrixFlexibleDimensionsPropertiesNV : PFN_vkGetPhysicalDeviceCooperativeMatrixFlexibleDimensionsPropertiesNV;
        vkGetPhysicalDeviceCooperativeVectorPropertiesNV : PFN_vkGetPhysicalDeviceCooperativeVectorPropertiesNV;
        vkGetPhysicalDeviceExternalTensorPropertiesARM : PFN_vkGetPhysicalDeviceExternalTensorPropertiesARM;
        vkGetPhysicalDeviceQueueFamilyDataGraphPropertiesARM : PFN_vkGetPhysicalDeviceQueueFamilyDataGraphPropertiesARM;
        vkGetPhysicalDeviceQueueFamilyDataGraphProcessingEnginePropertiesARM : PFN_vkGetPhysicalDeviceQueueFamilyDataGraphProcessingEnginePropertiesARM;
        vkEnumeratePhysicalDeviceQueueFamilyPerformanceCountersByRegionARM : PFN_vkEnumeratePhysicalDeviceQueueFamilyPerformanceCountersByRegionARM;
        #if VULKAN_PLATFORM == .X11
        {
            vkCreateXlibSurfaceKHR : PFN_vkCreateXlibSurfaceKHR;
            vkGetPhysicalDeviceXlibPresentationSupportKHR : PFN_vkGetPhysicalDeviceXlibPresentationSupportKHR;
            vkAcquireXlibDisplayEXT : PFN_vkAcquireXlibDisplayEXT;
            vkGetRandROutputDisplayEXT : PFN_vkGetRandROutputDisplayEXT;
        }
        #if VULKAN_PLATFORM == .Wayland
        {
            vkCreateWaylandSurfaceKHR : PFN_vkCreateWaylandSurfaceKHR;
            vkGetPhysicalDeviceWaylandPresentationSupportKHR : PFN_vkGetPhysicalDeviceWaylandPresentationSupportKHR;
        }
        #if VULKAN_PLATFORM == .Windows
        {
            vkCreateWin32SurfaceKHR : PFN_vkCreateWin32SurfaceKHR;
            vkGetPhysicalDeviceWin32PresentationSupportKHR : PFN_vkGetPhysicalDeviceWin32PresentationSupportKHR;
            vkAcquireWinrtDisplayNV : PFN_vkAcquireWinrtDisplayNV;
            vkGetWinrtDisplayNV : PFN_vkGetWinrtDisplayNV;
            vkGetPhysicalDeviceSurfacePresentModes2EXT : PFN_vkGetPhysicalDeviceSurfacePresentModes2EXT;
        }
        #if VULKAN_PLATFORM == .Vi
        {
            vkCreateViSurfaceNN : PFN_vkCreateViSurfaceNN;
        }
        #if VULKAN_PLATFORM == .XCB
        {
            vkCreateXcbSurfaceKHR : PFN_vkCreateXcbSurfaceKHR;
            vkGetPhysicalDeviceXcbPresentationSupportKHR : PFN_vkGetPhysicalDeviceXcbPresentationSupportKHR;
        }
        #if VULKAN_PLATFORM == .Fuchsia
        {
            vkCreateImagePipeSurfaceFUCHSIA : PFN_vkCreateImagePipeSurfaceFUCHSIA;
        }
        #if VULKAN_PLATFORM == .GGP
        {
            vkCreateStreamDescriptorSurfaceGGP : PFN_vkCreateStreamDescriptorSurfaceGGP;
        }
        #if VULKAN_PLATFORM == .Android
        {
            vkCreateAndroidSurfaceKHR : PFN_vkCreateAndroidSurfaceKHR;
        }
        #if VULKAN_PLATFORM == .MacOS
        {
            vkCreateIOSSurfaceMVK : PFN_vkCreateIOSSurfaceMVK;
            vkCreateMacOSSurfaceMVK : PFN_vkCreateMacOSSurfaceMVK;
            vkCreateMetalSurfaceEXT : PFN_vkCreateMetalSurfaceEXT;
        }
        #if VULKAN_PLATFORM == .IDirectFB
        {
            vkCreateDirectFBSurfaceEXT : PFN_vkCreateDirectFBSurfaceEXT;
            vkGetPhysicalDeviceDirectFBPresentationSupportEXT : PFN_vkGetPhysicalDeviceDirectFBPresentationSupportEXT;
        }
        #if VULKAN_PLATFORM == .Screen
        {
            vkCreateScreenSurfaceQNX : PFN_vkCreateScreenSurfaceQNX;
            vkGetPhysicalDeviceScreenPresentationSupportQNX : PFN_vkGetPhysicalDeviceScreenPresentationSupportQNX;
        }
        #if VULKAN_PLATFORM == .Jetson
        {
            vkGetPhysicalDeviceExternalMemorySciBufPropertiesNV : PFN_vkGetPhysicalDeviceExternalMemorySciBufPropertiesNV;
            vkGetPhysicalDeviceSciBufAttributesNV : PFN_vkGetPhysicalDeviceSciBufAttributesNV;
            vkGetPhysicalDeviceSciSyncAttributesNV : PFN_vkGetPhysicalDeviceSciSyncAttributesNV;
        }
        #if VULKAN_PLATFORM == .OHOS
        {
            vkCreateSurfaceOHOS : PFN_vkCreateSurfaceOHOS;
        }
    }

    using _vulkan_device_commands : Vulkan_Device_Commands;
    Vulkan_Device_Commands :: struct #type_info_no_size_complaint
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
        vkCreatePipelineBinariesKHR : PFN_vkCreatePipelineBinariesKHR;
        vkDestroyPipelineBinaryKHR : PFN_vkDestroyPipelineBinaryKHR;
        vkGetPipelineKeyKHR : PFN_vkGetPipelineKeyKHR;
        vkGetPipelineBinaryDataKHR : PFN_vkGetPipelineBinaryDataKHR;
        vkReleaseCapturedPipelineDataKHR : PFN_vkReleaseCapturedPipelineDataKHR;
        vkCreateGraphicsPipelines : PFN_vkCreateGraphicsPipelines;
        vkCreateComputePipelines : PFN_vkCreateComputePipelines;
        vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI : PFN_vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI;
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
        vkGetRenderingAreaGranularity : PFN_vkGetRenderingAreaGranularity;
        vkGetRenderingAreaGranularityKHR : PFN_vkGetRenderingAreaGranularityKHR;
        vkCreateCommandPool : PFN_vkCreateCommandPool;
        vkDestroyCommandPool : PFN_vkDestroyCommandPool;
        vkResetCommandPool : PFN_vkResetCommandPool;
        vkAllocateCommandBuffers : PFN_vkAllocateCommandBuffers;
        vkFreeCommandBuffers : PFN_vkFreeCommandBuffers;
        vkBeginCommandBuffer : PFN_vkBeginCommandBuffer;
        vkEndCommandBuffer : PFN_vkEndCommandBuffer;
        vkResetCommandBuffer : PFN_vkResetCommandBuffer;
        vkCmdBindPipeline : PFN_vkCmdBindPipeline;
        vkCmdSetAttachmentFeedbackLoopEnableEXT : PFN_vkCmdSetAttachmentFeedbackLoopEnableEXT;
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
        vkCmdDrawMultiEXT : PFN_vkCmdDrawMultiEXT;
        vkCmdDrawMultiIndexedEXT : PFN_vkCmdDrawMultiIndexedEXT;
        vkCmdDrawIndirect : PFN_vkCmdDrawIndirect;
        vkCmdDrawIndexedIndirect : PFN_vkCmdDrawIndexedIndirect;
        vkCmdDispatch : PFN_vkCmdDispatch;
        vkCmdDispatchIndirect : PFN_vkCmdDispatchIndirect;
        vkCmdSubpassShadingHUAWEI : PFN_vkCmdSubpassShadingHUAWEI;
        vkCmdDrawClusterHUAWEI : PFN_vkCmdDrawClusterHUAWEI;
        vkCmdDrawClusterIndirectHUAWEI : PFN_vkCmdDrawClusterIndirectHUAWEI;
        vkCmdUpdatePipelineIndirectBufferNV : PFN_vkCmdUpdatePipelineIndirectBufferNV;
        vkCmdCopyBuffer : PFN_vkCmdCopyBuffer;
        vkCmdCopyImage : PFN_vkCmdCopyImage;
        vkCmdBlitImage : PFN_vkCmdBlitImage;
        vkCmdCopyBufferToImage : PFN_vkCmdCopyBufferToImage;
        vkCmdCopyImageToBuffer : PFN_vkCmdCopyImageToBuffer;
        vkCmdCopyMemoryIndirectNV : PFN_vkCmdCopyMemoryIndirectNV;
        vkCmdCopyMemoryIndirectKHR : PFN_vkCmdCopyMemoryIndirectKHR;
        vkCmdCopyMemoryToImageIndirectNV : PFN_vkCmdCopyMemoryToImageIndirectNV;
        vkCmdCopyMemoryToImageIndirectKHR : PFN_vkCmdCopyMemoryToImageIndirectKHR;
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
        vkCmdBeginCustomResolveEXT : PFN_vkCmdBeginCustomResolveEXT;
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
        vkCmdExecuteGeneratedCommandsEXT : PFN_vkCmdExecuteGeneratedCommandsEXT;
        vkCmdPreprocessGeneratedCommandsEXT : PFN_vkCmdPreprocessGeneratedCommandsEXT;
        vkGetGeneratedCommandsMemoryRequirementsEXT : PFN_vkGetGeneratedCommandsMemoryRequirementsEXT;
        vkCreateIndirectCommandsLayoutEXT : PFN_vkCreateIndirectCommandsLayoutEXT;
        vkDestroyIndirectCommandsLayoutEXT : PFN_vkDestroyIndirectCommandsLayoutEXT;
        vkCreateIndirectExecutionSetEXT : PFN_vkCreateIndirectExecutionSetEXT;
        vkDestroyIndirectExecutionSetEXT : PFN_vkDestroyIndirectExecutionSetEXT;
        vkUpdateIndirectExecutionSetPipelineEXT : PFN_vkUpdateIndirectExecutionSetPipelineEXT;
        vkUpdateIndirectExecutionSetShaderEXT : PFN_vkUpdateIndirectExecutionSetShaderEXT;
        vkCmdPushDescriptorSet : PFN_vkCmdPushDescriptorSet;
        vkCmdPushDescriptorSetKHR : PFN_vkCmdPushDescriptorSetKHR;
        vkTrimCommandPool : PFN_vkTrimCommandPool;
        vkTrimCommandPoolKHR : PFN_vkTrimCommandPoolKHR;
        vkGetMemoryFdKHR : PFN_vkGetMemoryFdKHR;
        vkGetMemoryFdPropertiesKHR : PFN_vkGetMemoryFdPropertiesKHR;
        vkGetMemoryRemoteAddressNV : PFN_vkGetMemoryRemoteAddressNV;
        vkGetSemaphoreFdKHR : PFN_vkGetSemaphoreFdKHR;
        vkImportSemaphoreFdKHR : PFN_vkImportSemaphoreFdKHR;
        vkGetFenceFdKHR : PFN_vkGetFenceFdKHR;
        vkImportFenceFdKHR : PFN_vkImportFenceFdKHR;
        vkGetFenceSciSyncFenceNV : PFN_vkGetFenceSciSyncFenceNV;
        vkGetFenceSciSyncObjNV : PFN_vkGetFenceSciSyncObjNV;
        vkImportFenceSciSyncFenceNV : PFN_vkImportFenceSciSyncFenceNV;
        vkImportFenceSciSyncObjNV : PFN_vkImportFenceSciSyncObjNV;
        vkGetSemaphoreSciSyncObjNV : PFN_vkGetSemaphoreSciSyncObjNV;
        vkImportSemaphoreSciSyncObjNV : PFN_vkImportSemaphoreSciSyncObjNV;
        vkDestroySemaphoreSciSyncPoolNV : PFN_vkDestroySemaphoreSciSyncPoolNV;
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
        vkCmdPushDescriptorSetWithTemplate : PFN_vkCmdPushDescriptorSetWithTemplate;
        vkCmdPushDescriptorSetWithTemplateKHR : PFN_vkCmdPushDescriptorSetWithTemplateKHR;
        vkSetHdrMetadataEXT : PFN_vkSetHdrMetadataEXT;
        vkGetSwapchainStatusKHR : PFN_vkGetSwapchainStatusKHR;
        vkGetRefreshCycleDurationGOOGLE : PFN_vkGetRefreshCycleDurationGOOGLE;
        vkGetPastPresentationTimingGOOGLE : PFN_vkGetPastPresentationTimingGOOGLE;
        vkCmdSetViewportWScalingNV : PFN_vkCmdSetViewportWScalingNV;
        vkCmdSetDiscardRectangleEXT : PFN_vkCmdSetDiscardRectangleEXT;
        vkCmdSetDiscardRectangleEnableEXT : PFN_vkCmdSetDiscardRectangleEnableEXT;
        vkCmdSetDiscardRectangleModeEXT : PFN_vkCmdSetDiscardRectangleModeEXT;
        vkCmdSetSampleLocationsEXT : PFN_vkCmdSetSampleLocationsEXT;
        vkGetBufferMemoryRequirements2 : PFN_vkGetBufferMemoryRequirements2;
        vkGetBufferMemoryRequirements2KHR : PFN_vkGetBufferMemoryRequirements2KHR;
        vkGetImageMemoryRequirements2 : PFN_vkGetImageMemoryRequirements2;
        vkGetImageMemoryRequirements2KHR : PFN_vkGetImageMemoryRequirements2KHR;
        vkGetImageSparseMemoryRequirements2 : PFN_vkGetImageSparseMemoryRequirements2;
        vkGetImageSparseMemoryRequirements2KHR : PFN_vkGetImageSparseMemoryRequirements2KHR;
        vkGetDeviceBufferMemoryRequirements : PFN_vkGetDeviceBufferMemoryRequirements;
        vkGetDeviceBufferMemoryRequirementsKHR : PFN_vkGetDeviceBufferMemoryRequirementsKHR;
        vkGetDeviceImageMemoryRequirements : PFN_vkGetDeviceImageMemoryRequirements;
        vkGetDeviceImageMemoryRequirementsKHR : PFN_vkGetDeviceImageMemoryRequirementsKHR;
        vkGetDeviceImageSparseMemoryRequirements : PFN_vkGetDeviceImageSparseMemoryRequirements;
        vkGetDeviceImageSparseMemoryRequirementsKHR : PFN_vkGetDeviceImageSparseMemoryRequirementsKHR;
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
        vkGetShaderInfoAMD : PFN_vkGetShaderInfoAMD;
        vkSetLocalDimmingAMD : PFN_vkSetLocalDimmingAMD;
        vkGetCalibratedTimestampsKHR : PFN_vkGetCalibratedTimestampsKHR;
        vkGetCalibratedTimestampsEXT : PFN_vkGetCalibratedTimestampsEXT;
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
        vkCmdSetExclusiveScissorEnableNV : PFN_vkCmdSetExclusiveScissorEnableNV;
        vkCmdBindShadingRateImageNV : PFN_vkCmdBindShadingRateImageNV;
        vkCmdSetViewportShadingRatePaletteNV : PFN_vkCmdSetViewportShadingRatePaletteNV;
        vkCmdSetCoarseSampleOrderNV : PFN_vkCmdSetCoarseSampleOrderNV;
        vkCmdDrawMeshTasksNV : PFN_vkCmdDrawMeshTasksNV;
        vkCmdDrawMeshTasksIndirectNV : PFN_vkCmdDrawMeshTasksIndirectNV;
        vkCmdDrawMeshTasksIndirectCountNV : PFN_vkCmdDrawMeshTasksIndirectCountNV;
        vkCmdDrawMeshTasksEXT : PFN_vkCmdDrawMeshTasksEXT;
        vkCmdDrawMeshTasksIndirectEXT : PFN_vkCmdDrawMeshTasksIndirectEXT;
        vkCmdDrawMeshTasksIndirectCountEXT : PFN_vkCmdDrawMeshTasksIndirectCountEXT;
        vkCompileDeferredNV : PFN_vkCompileDeferredNV;
        vkCreateAccelerationStructureNV : PFN_vkCreateAccelerationStructureNV;
        vkCmdBindInvocationMaskHUAWEI : PFN_vkCmdBindInvocationMaskHUAWEI;
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
        vkCmdTraceRaysIndirect2KHR : PFN_vkCmdTraceRaysIndirect2KHR;
        vkGetClusterAccelerationStructureBuildSizesNV : PFN_vkGetClusterAccelerationStructureBuildSizesNV;
        vkCmdBuildClusterAccelerationStructureIndirectNV : PFN_vkCmdBuildClusterAccelerationStructureIndirectNV;
        vkGetDeviceAccelerationStructureCompatibilityKHR : PFN_vkGetDeviceAccelerationStructureCompatibilityKHR;
        vkGetRayTracingShaderGroupStackSizeKHR : PFN_vkGetRayTracingShaderGroupStackSizeKHR;
        vkCmdSetRayTracingPipelineStackSizeKHR : PFN_vkCmdSetRayTracingPipelineStackSizeKHR;
        vkGetImageViewHandleNVX : PFN_vkGetImageViewHandleNVX;
        vkGetImageViewHandle64NVX : PFN_vkGetImageViewHandle64NVX;
        vkGetImageViewAddressNVX : PFN_vkGetImageViewAddressNVX;
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
        vkCmdSetLineStipple : PFN_vkCmdSetLineStipple;
        vkCmdSetLineStippleKHR : PFN_vkCmdSetLineStippleKHR;
        vkCmdSetLineStippleEXT : PFN_vkCmdSetLineStippleEXT;
        vkGetFaultData : PFN_vkGetFaultData;
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
        vkGetPipelineIndirectMemoryRequirementsNV : PFN_vkGetPipelineIndirectMemoryRequirementsNV;
        vkGetPipelineIndirectDeviceAddressNV : PFN_vkGetPipelineIndirectDeviceAddressNV;
        vkAntiLagUpdateAMD : PFN_vkAntiLagUpdateAMD;
        vkCmdSetCullMode : PFN_vkCmdSetCullMode;
        vkCmdSetCullModeEXT : PFN_vkCmdSetCullModeEXT;
        vkCmdSetFrontFace : PFN_vkCmdSetFrontFace;
        vkCmdSetFrontFaceEXT : PFN_vkCmdSetFrontFaceEXT;
        vkCmdSetPrimitiveTopology : PFN_vkCmdSetPrimitiveTopology;
        vkCmdSetPrimitiveTopologyEXT : PFN_vkCmdSetPrimitiveTopologyEXT;
        vkCmdSetViewportWithCount : PFN_vkCmdSetViewportWithCount;
        vkCmdSetViewportWithCountEXT : PFN_vkCmdSetViewportWithCountEXT;
        vkCmdSetScissorWithCount : PFN_vkCmdSetScissorWithCount;
        vkCmdSetScissorWithCountEXT : PFN_vkCmdSetScissorWithCountEXT;
        vkCmdBindIndexBuffer2 : PFN_vkCmdBindIndexBuffer2;
        vkCmdBindIndexBuffer2KHR : PFN_vkCmdBindIndexBuffer2KHR;
        vkCmdBindVertexBuffers2 : PFN_vkCmdBindVertexBuffers2;
        vkCmdBindVertexBuffers2EXT : PFN_vkCmdBindVertexBuffers2EXT;
        vkCmdSetDepthTestEnable : PFN_vkCmdSetDepthTestEnable;
        vkCmdSetDepthTestEnableEXT : PFN_vkCmdSetDepthTestEnableEXT;
        vkCmdSetDepthWriteEnable : PFN_vkCmdSetDepthWriteEnable;
        vkCmdSetDepthWriteEnableEXT : PFN_vkCmdSetDepthWriteEnableEXT;
        vkCmdSetDepthCompareOp : PFN_vkCmdSetDepthCompareOp;
        vkCmdSetDepthCompareOpEXT : PFN_vkCmdSetDepthCompareOpEXT;
        vkCmdSetDepthBoundsTestEnable : PFN_vkCmdSetDepthBoundsTestEnable;
        vkCmdSetDepthBoundsTestEnableEXT : PFN_vkCmdSetDepthBoundsTestEnableEXT;
        vkCmdSetStencilTestEnable : PFN_vkCmdSetStencilTestEnable;
        vkCmdSetStencilTestEnableEXT : PFN_vkCmdSetStencilTestEnableEXT;
        vkCmdSetStencilOp : PFN_vkCmdSetStencilOp;
        vkCmdSetStencilOpEXT : PFN_vkCmdSetStencilOpEXT;
        vkCmdSetPatchControlPointsEXT : PFN_vkCmdSetPatchControlPointsEXT;
        vkCmdSetRasterizerDiscardEnable : PFN_vkCmdSetRasterizerDiscardEnable;
        vkCmdSetRasterizerDiscardEnableEXT : PFN_vkCmdSetRasterizerDiscardEnableEXT;
        vkCmdSetDepthBiasEnable : PFN_vkCmdSetDepthBiasEnable;
        vkCmdSetDepthBiasEnableEXT : PFN_vkCmdSetDepthBiasEnableEXT;
        vkCmdSetLogicOpEXT : PFN_vkCmdSetLogicOpEXT;
        vkCmdSetPrimitiveRestartEnable : PFN_vkCmdSetPrimitiveRestartEnable;
        vkCmdSetPrimitiveRestartEnableEXT : PFN_vkCmdSetPrimitiveRestartEnableEXT;
        vkCmdSetTessellationDomainOriginEXT : PFN_vkCmdSetTessellationDomainOriginEXT;
        vkCmdSetDepthClampEnableEXT : PFN_vkCmdSetDepthClampEnableEXT;
        vkCmdSetPolygonModeEXT : PFN_vkCmdSetPolygonModeEXT;
        vkCmdSetRasterizationSamplesEXT : PFN_vkCmdSetRasterizationSamplesEXT;
        vkCmdSetSampleMaskEXT : PFN_vkCmdSetSampleMaskEXT;
        vkCmdSetAlphaToCoverageEnableEXT : PFN_vkCmdSetAlphaToCoverageEnableEXT;
        vkCmdSetAlphaToOneEnableEXT : PFN_vkCmdSetAlphaToOneEnableEXT;
        vkCmdSetLogicOpEnableEXT : PFN_vkCmdSetLogicOpEnableEXT;
        vkCmdSetColorBlendEnableEXT : PFN_vkCmdSetColorBlendEnableEXT;
        vkCmdSetColorBlendEquationEXT : PFN_vkCmdSetColorBlendEquationEXT;
        vkCmdSetColorWriteMaskEXT : PFN_vkCmdSetColorWriteMaskEXT;
        vkCmdSetRasterizationStreamEXT : PFN_vkCmdSetRasterizationStreamEXT;
        vkCmdSetConservativeRasterizationModeEXT : PFN_vkCmdSetConservativeRasterizationModeEXT;
        vkCmdSetExtraPrimitiveOverestimationSizeEXT : PFN_vkCmdSetExtraPrimitiveOverestimationSizeEXT;
        vkCmdSetDepthClipEnableEXT : PFN_vkCmdSetDepthClipEnableEXT;
        vkCmdSetSampleLocationsEnableEXT : PFN_vkCmdSetSampleLocationsEnableEXT;
        vkCmdSetColorBlendAdvancedEXT : PFN_vkCmdSetColorBlendAdvancedEXT;
        vkCmdSetProvokingVertexModeEXT : PFN_vkCmdSetProvokingVertexModeEXT;
        vkCmdSetLineRasterizationModeEXT : PFN_vkCmdSetLineRasterizationModeEXT;
        vkCmdSetLineStippleEnableEXT : PFN_vkCmdSetLineStippleEnableEXT;
        vkCmdSetDepthClipNegativeOneToOneEXT : PFN_vkCmdSetDepthClipNegativeOneToOneEXT;
        vkCmdSetViewportWScalingEnableNV : PFN_vkCmdSetViewportWScalingEnableNV;
        vkCmdSetViewportSwizzleNV : PFN_vkCmdSetViewportSwizzleNV;
        vkCmdSetCoverageToColorEnableNV : PFN_vkCmdSetCoverageToColorEnableNV;
        vkCmdSetCoverageToColorLocationNV : PFN_vkCmdSetCoverageToColorLocationNV;
        vkCmdSetCoverageModulationModeNV : PFN_vkCmdSetCoverageModulationModeNV;
        vkCmdSetCoverageModulationTableEnableNV : PFN_vkCmdSetCoverageModulationTableEnableNV;
        vkCmdSetCoverageModulationTableNV : PFN_vkCmdSetCoverageModulationTableNV;
        vkCmdSetShadingRateImageEnableNV : PFN_vkCmdSetShadingRateImageEnableNV;
        vkCmdSetCoverageReductionModeNV : PFN_vkCmdSetCoverageReductionModeNV;
        vkCmdSetRepresentativeFragmentTestEnableNV : PFN_vkCmdSetRepresentativeFragmentTestEnableNV;
        vkCreatePrivateDataSlot : PFN_vkCreatePrivateDataSlot;
        vkCreatePrivateDataSlotEXT : PFN_vkCreatePrivateDataSlotEXT;
        vkDestroyPrivateDataSlot : PFN_vkDestroyPrivateDataSlot;
        vkDestroyPrivateDataSlotEXT : PFN_vkDestroyPrivateDataSlotEXT;
        vkSetPrivateData : PFN_vkSetPrivateData;
        vkSetPrivateDataEXT : PFN_vkSetPrivateDataEXT;
        vkGetPrivateData : PFN_vkGetPrivateData;
        vkGetPrivateDataEXT : PFN_vkGetPrivateDataEXT;
        vkCmdCopyBuffer2 : PFN_vkCmdCopyBuffer2;
        vkCmdCopyBuffer2KHR : PFN_vkCmdCopyBuffer2KHR;
        vkCmdCopyImage2 : PFN_vkCmdCopyImage2;
        vkCmdCopyImage2KHR : PFN_vkCmdCopyImage2KHR;
        vkCmdBlitImage2 : PFN_vkCmdBlitImage2;
        vkCmdBlitImage2KHR : PFN_vkCmdBlitImage2KHR;
        vkCmdCopyBufferToImage2 : PFN_vkCmdCopyBufferToImage2;
        vkCmdCopyBufferToImage2KHR : PFN_vkCmdCopyBufferToImage2KHR;
        vkCmdCopyImageToBuffer2 : PFN_vkCmdCopyImageToBuffer2;
        vkCmdCopyImageToBuffer2KHR : PFN_vkCmdCopyImageToBuffer2KHR;
        vkCmdResolveImage2 : PFN_vkCmdResolveImage2;
        vkCmdResolveImage2KHR : PFN_vkCmdResolveImage2KHR;
        vkCmdRefreshObjectsKHR : PFN_vkCmdRefreshObjectsKHR;
        vkCmdSetFragmentShadingRateKHR : PFN_vkCmdSetFragmentShadingRateKHR;
        vkCmdSetFragmentShadingRateEnumNV : PFN_vkCmdSetFragmentShadingRateEnumNV;
        vkGetAccelerationStructureBuildSizesKHR : PFN_vkGetAccelerationStructureBuildSizesKHR;
        vkCmdSetVertexInputEXT : PFN_vkCmdSetVertexInputEXT;
        vkCmdSetColorWriteEnableEXT : PFN_vkCmdSetColorWriteEnableEXT;
        vkCmdSetEvent2 : PFN_vkCmdSetEvent2;
        vkCmdSetEvent2KHR : PFN_vkCmdSetEvent2KHR;
        vkCmdResetEvent2 : PFN_vkCmdResetEvent2;
        vkCmdResetEvent2KHR : PFN_vkCmdResetEvent2KHR;
        vkCmdWaitEvents2 : PFN_vkCmdWaitEvents2;
        vkCmdWaitEvents2KHR : PFN_vkCmdWaitEvents2KHR;
        vkCmdPipelineBarrier2 : PFN_vkCmdPipelineBarrier2;
        vkCmdPipelineBarrier2KHR : PFN_vkCmdPipelineBarrier2KHR;
        vkQueueSubmit2 : PFN_vkQueueSubmit2;
        vkQueueSubmit2KHR : PFN_vkQueueSubmit2KHR;
        vkCmdWriteTimestamp2 : PFN_vkCmdWriteTimestamp2;
        vkCmdWriteTimestamp2KHR : PFN_vkCmdWriteTimestamp2KHR;
        vkCmdWriteBufferMarker2AMD : PFN_vkCmdWriteBufferMarker2AMD;
        vkGetQueueCheckpointData2NV : PFN_vkGetQueueCheckpointData2NV;
        vkCopyMemoryToImage : PFN_vkCopyMemoryToImage;
        vkCopyMemoryToImageEXT : PFN_vkCopyMemoryToImageEXT;
        vkCopyImageToMemory : PFN_vkCopyImageToMemory;
        vkCopyImageToMemoryEXT : PFN_vkCopyImageToMemoryEXT;
        vkCopyImageToImage : PFN_vkCopyImageToImage;
        vkCopyImageToImageEXT : PFN_vkCopyImageToImageEXT;
        vkTransitionImageLayout : PFN_vkTransitionImageLayout;
        vkTransitionImageLayoutEXT : PFN_vkTransitionImageLayoutEXT;
        vkGetCommandPoolMemoryConsumption : PFN_vkGetCommandPoolMemoryConsumption;
        vkCreateVideoSessionKHR : PFN_vkCreateVideoSessionKHR;
        vkDestroyVideoSessionKHR : PFN_vkDestroyVideoSessionKHR;
        vkCreateVideoSessionParametersKHR : PFN_vkCreateVideoSessionParametersKHR;
        vkUpdateVideoSessionParametersKHR : PFN_vkUpdateVideoSessionParametersKHR;
        vkGetEncodedVideoSessionParametersKHR : PFN_vkGetEncodedVideoSessionParametersKHR;
        vkDestroyVideoSessionParametersKHR : PFN_vkDestroyVideoSessionParametersKHR;
        vkGetVideoSessionMemoryRequirementsKHR : PFN_vkGetVideoSessionMemoryRequirementsKHR;
        vkBindVideoSessionMemoryKHR : PFN_vkBindVideoSessionMemoryKHR;
        vkCmdDecodeVideoKHR : PFN_vkCmdDecodeVideoKHR;
        vkCmdBeginVideoCodingKHR : PFN_vkCmdBeginVideoCodingKHR;
        vkCmdControlVideoCodingKHR : PFN_vkCmdControlVideoCodingKHR;
        vkCmdEndVideoCodingKHR : PFN_vkCmdEndVideoCodingKHR;
        vkCmdEncodeVideoKHR : PFN_vkCmdEncodeVideoKHR;
        vkCmdDecompressMemoryNV : PFN_vkCmdDecompressMemoryNV;
        vkCmdDecompressMemoryIndirectCountNV : PFN_vkCmdDecompressMemoryIndirectCountNV;
        vkGetPartitionedAccelerationStructuresBuildSizesNV : PFN_vkGetPartitionedAccelerationStructuresBuildSizesNV;
        vkCmdBuildPartitionedAccelerationStructuresNV : PFN_vkCmdBuildPartitionedAccelerationStructuresNV;
        vkCmdDecompressMemoryEXT : PFN_vkCmdDecompressMemoryEXT;
        vkCmdDecompressMemoryIndirectCountEXT : PFN_vkCmdDecompressMemoryIndirectCountEXT;
        vkCreateCuModuleNVX : PFN_vkCreateCuModuleNVX;
        vkCreateCuFunctionNVX : PFN_vkCreateCuFunctionNVX;
        vkDestroyCuModuleNVX : PFN_vkDestroyCuModuleNVX;
        vkDestroyCuFunctionNVX : PFN_vkDestroyCuFunctionNVX;
        vkCmdCuLaunchKernelNVX : PFN_vkCmdCuLaunchKernelNVX;
        vkGetDescriptorSetLayoutSizeEXT : PFN_vkGetDescriptorSetLayoutSizeEXT;
        vkGetDescriptorSetLayoutBindingOffsetEXT : PFN_vkGetDescriptorSetLayoutBindingOffsetEXT;
        vkGetDescriptorEXT : PFN_vkGetDescriptorEXT;
        vkCmdBindDescriptorBuffersEXT : PFN_vkCmdBindDescriptorBuffersEXT;
        vkCmdSetDescriptorBufferOffsetsEXT : PFN_vkCmdSetDescriptorBufferOffsetsEXT;
        vkCmdBindDescriptorBufferEmbeddedSamplersEXT : PFN_vkCmdBindDescriptorBufferEmbeddedSamplersEXT;
        vkGetBufferOpaqueCaptureDescriptorDataEXT : PFN_vkGetBufferOpaqueCaptureDescriptorDataEXT;
        vkGetImageOpaqueCaptureDescriptorDataEXT : PFN_vkGetImageOpaqueCaptureDescriptorDataEXT;
        vkGetImageViewOpaqueCaptureDescriptorDataEXT : PFN_vkGetImageViewOpaqueCaptureDescriptorDataEXT;
        vkGetSamplerOpaqueCaptureDescriptorDataEXT : PFN_vkGetSamplerOpaqueCaptureDescriptorDataEXT;
        vkGetAccelerationStructureOpaqueCaptureDescriptorDataEXT : PFN_vkGetAccelerationStructureOpaqueCaptureDescriptorDataEXT;
        vkSetDeviceMemoryPriorityEXT : PFN_vkSetDeviceMemoryPriorityEXT;
        vkWaitForPresent2KHR : PFN_vkWaitForPresent2KHR;
        vkWaitForPresentKHR : PFN_vkWaitForPresentKHR;
        vkCmdBeginRendering : PFN_vkCmdBeginRendering;
        vkCmdBeginRenderingKHR : PFN_vkCmdBeginRenderingKHR;
        vkCmdEndRendering : PFN_vkCmdEndRendering;
        vkCmdEndRendering2KHR : PFN_vkCmdEndRendering2KHR;
        vkCmdEndRendering2EXT : PFN_vkCmdEndRendering2EXT;
        vkCmdEndRenderingKHR : PFN_vkCmdEndRenderingKHR;
        vkGetDescriptorSetLayoutHostMappingInfoVALVE : PFN_vkGetDescriptorSetLayoutHostMappingInfoVALVE;
        vkGetDescriptorSetHostMappingVALVE : PFN_vkGetDescriptorSetHostMappingVALVE;
        vkCreateMicromapEXT : PFN_vkCreateMicromapEXT;
        vkCmdBuildMicromapsEXT : PFN_vkCmdBuildMicromapsEXT;
        vkBuildMicromapsEXT : PFN_vkBuildMicromapsEXT;
        vkDestroyMicromapEXT : PFN_vkDestroyMicromapEXT;
        vkCmdCopyMicromapEXT : PFN_vkCmdCopyMicromapEXT;
        vkCopyMicromapEXT : PFN_vkCopyMicromapEXT;
        vkCmdCopyMicromapToMemoryEXT : PFN_vkCmdCopyMicromapToMemoryEXT;
        vkCopyMicromapToMemoryEXT : PFN_vkCopyMicromapToMemoryEXT;
        vkCmdCopyMemoryToMicromapEXT : PFN_vkCmdCopyMemoryToMicromapEXT;
        vkCopyMemoryToMicromapEXT : PFN_vkCopyMemoryToMicromapEXT;
        vkCmdWriteMicromapsPropertiesEXT : PFN_vkCmdWriteMicromapsPropertiesEXT;
        vkWriteMicromapsPropertiesEXT : PFN_vkWriteMicromapsPropertiesEXT;
        vkGetDeviceMicromapCompatibilityEXT : PFN_vkGetDeviceMicromapCompatibilityEXT;
        vkGetMicromapBuildSizesEXT : PFN_vkGetMicromapBuildSizesEXT;
        vkGetShaderModuleIdentifierEXT : PFN_vkGetShaderModuleIdentifierEXT;
        vkGetShaderModuleCreateInfoIdentifierEXT : PFN_vkGetShaderModuleCreateInfoIdentifierEXT;
        vkGetImageSubresourceLayout2 : PFN_vkGetImageSubresourceLayout2;
        vkGetImageSubresourceLayout2KHR : PFN_vkGetImageSubresourceLayout2KHR;
        vkGetImageSubresourceLayout2EXT : PFN_vkGetImageSubresourceLayout2EXT;
        vkGetPipelinePropertiesEXT : PFN_vkGetPipelinePropertiesEXT;
        vkCmdBindTileMemoryQCOM : PFN_vkCmdBindTileMemoryQCOM;
        vkGetFramebufferTilePropertiesQCOM : PFN_vkGetFramebufferTilePropertiesQCOM;
        vkGetDynamicRenderingTilePropertiesQCOM : PFN_vkGetDynamicRenderingTilePropertiesQCOM;
        vkCreateOpticalFlowSessionNV : PFN_vkCreateOpticalFlowSessionNV;
        vkDestroyOpticalFlowSessionNV : PFN_vkDestroyOpticalFlowSessionNV;
        vkBindOpticalFlowSessionImageNV : PFN_vkBindOpticalFlowSessionImageNV;
        vkCmdOpticalFlowExecuteNV : PFN_vkCmdOpticalFlowExecuteNV;
        vkGetDeviceFaultInfoEXT : PFN_vkGetDeviceFaultInfoEXT;
        vkCmdSetDepthBias2EXT : PFN_vkCmdSetDepthBias2EXT;
        vkReleaseSwapchainImagesKHR : PFN_vkReleaseSwapchainImagesKHR;
        vkReleaseSwapchainImagesEXT : PFN_vkReleaseSwapchainImagesEXT;
        vkGetDeviceImageSubresourceLayout : PFN_vkGetDeviceImageSubresourceLayout;
        vkGetDeviceImageSubresourceLayoutKHR : PFN_vkGetDeviceImageSubresourceLayoutKHR;
        vkMapMemory2 : PFN_vkMapMemory2;
        vkMapMemory2KHR : PFN_vkMapMemory2KHR;
        vkUnmapMemory2 : PFN_vkUnmapMemory2;
        vkUnmapMemory2KHR : PFN_vkUnmapMemory2KHR;
        vkCreateShadersEXT : PFN_vkCreateShadersEXT;
        vkDestroyShaderEXT : PFN_vkDestroyShaderEXT;
        vkGetShaderBinaryDataEXT : PFN_vkGetShaderBinaryDataEXT;
        vkCmdBindShadersEXT : PFN_vkCmdBindShadersEXT;
        vkSetSwapchainPresentTimingQueueSizeEXT : PFN_vkSetSwapchainPresentTimingQueueSizeEXT;
        vkGetSwapchainTimingPropertiesEXT : PFN_vkGetSwapchainTimingPropertiesEXT;
        vkGetSwapchainTimeDomainPropertiesEXT : PFN_vkGetSwapchainTimeDomainPropertiesEXT;
        vkGetPastPresentationTimingEXT : PFN_vkGetPastPresentationTimingEXT;
        vkCmdBindDescriptorSets2 : PFN_vkCmdBindDescriptorSets2;
        vkCmdBindDescriptorSets2KHR : PFN_vkCmdBindDescriptorSets2KHR;
        vkCmdPushConstants2 : PFN_vkCmdPushConstants2;
        vkCmdPushConstants2KHR : PFN_vkCmdPushConstants2KHR;
        vkCmdPushDescriptorSet2 : PFN_vkCmdPushDescriptorSet2;
        vkCmdPushDescriptorSet2KHR : PFN_vkCmdPushDescriptorSet2KHR;
        vkCmdPushDescriptorSetWithTemplate2 : PFN_vkCmdPushDescriptorSetWithTemplate2;
        vkCmdPushDescriptorSetWithTemplate2KHR : PFN_vkCmdPushDescriptorSetWithTemplate2KHR;
        vkCmdSetDescriptorBufferOffsets2EXT : PFN_vkCmdSetDescriptorBufferOffsets2EXT;
        vkCmdBindDescriptorBufferEmbeddedSamplers2EXT : PFN_vkCmdBindDescriptorBufferEmbeddedSamplers2EXT;
        vkSetLatencySleepModeNV : PFN_vkSetLatencySleepModeNV;
        vkLatencySleepNV : PFN_vkLatencySleepNV;
        vkSetLatencyMarkerNV : PFN_vkSetLatencyMarkerNV;
        vkGetLatencyTimingsNV : PFN_vkGetLatencyTimingsNV;
        vkQueueNotifyOutOfBandNV : PFN_vkQueueNotifyOutOfBandNV;
        vkCmdSetRenderingAttachmentLocations : PFN_vkCmdSetRenderingAttachmentLocations;
        vkCmdSetRenderingAttachmentLocationsKHR : PFN_vkCmdSetRenderingAttachmentLocationsKHR;
        vkCmdSetRenderingInputAttachmentIndices : PFN_vkCmdSetRenderingInputAttachmentIndices;
        vkCmdSetRenderingInputAttachmentIndicesKHR : PFN_vkCmdSetRenderingInputAttachmentIndicesKHR;
        vkCmdSetDepthClampRangeEXT : PFN_vkCmdSetDepthClampRangeEXT;
        vkConvertCooperativeVectorMatrixNV : PFN_vkConvertCooperativeVectorMatrixNV;
        vkCmdConvertCooperativeVectorMatrixNV : PFN_vkCmdConvertCooperativeVectorMatrixNV;
        vkCmdDispatchTileQCOM : PFN_vkCmdDispatchTileQCOM;
        vkCmdBeginPerTileExecutionQCOM : PFN_vkCmdBeginPerTileExecutionQCOM;
        vkCmdEndPerTileExecutionQCOM : PFN_vkCmdEndPerTileExecutionQCOM;
        vkCreateExternalComputeQueueNV : PFN_vkCreateExternalComputeQueueNV;
        vkDestroyExternalComputeQueueNV : PFN_vkDestroyExternalComputeQueueNV;
        vkGetExternalComputeQueueDataNV : PFN_vkGetExternalComputeQueueDataNV;
        vkCreateTensorARM : PFN_vkCreateTensorARM;
        vkDestroyTensorARM : PFN_vkDestroyTensorARM;
        vkCreateTensorViewARM : PFN_vkCreateTensorViewARM;
        vkDestroyTensorViewARM : PFN_vkDestroyTensorViewARM;
        vkGetTensorMemoryRequirementsARM : PFN_vkGetTensorMemoryRequirementsARM;
        vkBindTensorMemoryARM : PFN_vkBindTensorMemoryARM;
        vkGetDeviceTensorMemoryRequirementsARM : PFN_vkGetDeviceTensorMemoryRequirementsARM;
        vkCmdCopyTensorARM : PFN_vkCmdCopyTensorARM;
        vkGetTensorOpaqueCaptureDescriptorDataARM : PFN_vkGetTensorOpaqueCaptureDescriptorDataARM;
        vkGetTensorViewOpaqueCaptureDescriptorDataARM : PFN_vkGetTensorViewOpaqueCaptureDescriptorDataARM;
        vkCreateDataGraphPipelinesARM : PFN_vkCreateDataGraphPipelinesARM;
        vkCreateDataGraphPipelineSessionARM : PFN_vkCreateDataGraphPipelineSessionARM;
        vkGetDataGraphPipelineSessionBindPointRequirementsARM : PFN_vkGetDataGraphPipelineSessionBindPointRequirementsARM;
        vkGetDataGraphPipelineSessionMemoryRequirementsARM : PFN_vkGetDataGraphPipelineSessionMemoryRequirementsARM;
        vkBindDataGraphPipelineSessionMemoryARM : PFN_vkBindDataGraphPipelineSessionMemoryARM;
        vkDestroyDataGraphPipelineSessionARM : PFN_vkDestroyDataGraphPipelineSessionARM;
        vkCmdDispatchDataGraphARM : PFN_vkCmdDispatchDataGraphARM;
        vkGetDataGraphPipelineAvailablePropertiesARM : PFN_vkGetDataGraphPipelineAvailablePropertiesARM;
        vkGetDataGraphPipelinePropertiesARM : PFN_vkGetDataGraphPipelinePropertiesARM;
        #if VULKAN_PLATFORM == .Windows
        {
            vkGetMemoryWin32HandleNV : PFN_vkGetMemoryWin32HandleNV;
            vkGetMemoryWin32HandleKHR : PFN_vkGetMemoryWin32HandleKHR;
            vkGetMemoryWin32HandlePropertiesKHR : PFN_vkGetMemoryWin32HandlePropertiesKHR;
            vkGetSemaphoreWin32HandleKHR : PFN_vkGetSemaphoreWin32HandleKHR;
            vkImportSemaphoreWin32HandleKHR : PFN_vkImportSemaphoreWin32HandleKHR;
            vkGetFenceWin32HandleKHR : PFN_vkGetFenceWin32HandleKHR;
            vkImportFenceWin32HandleKHR : PFN_vkImportFenceWin32HandleKHR;
            vkGetDeviceGroupSurfacePresentModes2EXT : PFN_vkGetDeviceGroupSurfacePresentModes2EXT;
            vkAcquireFullScreenExclusiveModeEXT : PFN_vkAcquireFullScreenExclusiveModeEXT;
            vkReleaseFullScreenExclusiveModeEXT : PFN_vkReleaseFullScreenExclusiveModeEXT;
        }
        #if VULKAN_PLATFORM == .Fuchsia
        {
            vkGetMemoryZirconHandleFUCHSIA : PFN_vkGetMemoryZirconHandleFUCHSIA;
            vkGetMemoryZirconHandlePropertiesFUCHSIA : PFN_vkGetMemoryZirconHandlePropertiesFUCHSIA;
            vkGetSemaphoreZirconHandleFUCHSIA : PFN_vkGetSemaphoreZirconHandleFUCHSIA;
            vkImportSemaphoreZirconHandleFUCHSIA : PFN_vkImportSemaphoreZirconHandleFUCHSIA;
            vkCreateBufferCollectionFUCHSIA : PFN_vkCreateBufferCollectionFUCHSIA;
            vkSetBufferCollectionBufferConstraintsFUCHSIA : PFN_vkSetBufferCollectionBufferConstraintsFUCHSIA;
            vkSetBufferCollectionImageConstraintsFUCHSIA : PFN_vkSetBufferCollectionImageConstraintsFUCHSIA;
            vkDestroyBufferCollectionFUCHSIA : PFN_vkDestroyBufferCollectionFUCHSIA;
            vkGetBufferCollectionPropertiesFUCHSIA : PFN_vkGetBufferCollectionPropertiesFUCHSIA;
        }
        #if VULKAN_PLATFORM == .Android
        {
            vkGetAndroidHardwareBufferPropertiesANDROID : PFN_vkGetAndroidHardwareBufferPropertiesANDROID;
            vkGetMemoryAndroidHardwareBufferANDROID : PFN_vkGetMemoryAndroidHardwareBufferANDROID;
        }
        #if VULKAN_PLATFORM == .MacOS
        {
            vkExportMetalObjectsEXT : PFN_vkExportMetalObjectsEXT;
            vkGetMemoryMetalHandleEXT : PFN_vkGetMemoryMetalHandleEXT;
            vkGetMemoryMetalHandlePropertiesEXT : PFN_vkGetMemoryMetalHandlePropertiesEXT;
        }
        #if VULKAN_PLATFORM == .Screen
        {
            vkGetScreenBufferPropertiesQNX : PFN_vkGetScreenBufferPropertiesQNX;
        }
        #if VULKAN_PLATFORM == .Jetson
        {
            vkGetMemorySciBufNV : PFN_vkGetMemorySciBufNV;
            vkCreateSemaphoreSciSyncPoolNV : PFN_vkCreateSemaphoreSciSyncPoolNV;
        }
        #if VK_ENABLE_BETA_EXTENSIONS
        {
            vkCreateCudaModuleNV : PFN_vkCreateCudaModuleNV;
            vkGetCudaModuleCacheNV : PFN_vkGetCudaModuleCacheNV;
            vkCreateCudaFunctionNV : PFN_vkCreateCudaFunctionNV;
            vkDestroyCudaModuleNV : PFN_vkDestroyCudaModuleNV;
            vkDestroyCudaFunctionNV : PFN_vkDestroyCudaFunctionNV;
            vkCmdCudaLaunchKernelNV : PFN_vkCmdCudaLaunchKernelNV;
            vkGetExecutionGraphPipelineScratchSizeAMDX : PFN_vkGetExecutionGraphPipelineScratchSizeAMDX;
            vkGetExecutionGraphPipelineNodeIndexAMDX : PFN_vkGetExecutionGraphPipelineNodeIndexAMDX;
            vkCreateExecutionGraphPipelinesAMDX : PFN_vkCreateExecutionGraphPipelinesAMDX;
            vkCmdInitializeGraphScratchMemoryAMDX : PFN_vkCmdInitializeGraphScratchMemoryAMDX;
            vkCmdDispatchGraphAMDX : PFN_vkCmdDispatchGraphAMDX;
            vkCmdDispatchGraphIndirectAMDX : PFN_vkCmdDispatchGraphIndirectAMDX;
            vkCmdDispatchGraphIndirectCountAMDX : PFN_vkCmdDispatchGraphIndirectCountAMDX;
        }
        #if VULKAN_PLATFORM == .OHOS
        {
            vkGetNativeBufferPropertiesOHOS : PFN_vkGetNativeBufferPropertiesOHOS;
            vkGetMemoryNativeBufferOHOS : PFN_vkGetMemoryNativeBufferOHOS;
            vkGetSwapchainGrallocUsageOHOS : PFN_vkGetSwapchainGrallocUsageOHOS;
            vkAcquireImageOHOS : PFN_vkAcquireImageOHOS;
            vkQueueSignalReleaseImageOHOS : PFN_vkQueueSignalReleaseImageOHOS;
        }
    }
}
