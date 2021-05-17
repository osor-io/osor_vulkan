/*

This file tries to be a simple example of how to do some stuff in Vulkan. It's not trying
to be a super robust solution for a Vulkan renderer but a starting point to see how things are
kinda done with the API and with the current version of this Vulkan module for Jai.

There's some things that could be improved upon that should be annotated throughout the code, some
others are in a decent place already to the point you could reuse some of that for your own code.

Feel free to request changes here :)

*/

#import "Basic";
#import "Math";
#import "File";
#import "String";
#import "Windows";
#import "Input";
#import "Vulkan";
#import "Window_Creation";
#import "Debug";



main :: ()
{
    window_handle := create_window(window_name="Vulkan Example", width=1920, height=1080);

    // # Creates the instance, surface and device 
    vulkan_context : Vulkan_Context;
    vulkan_init(*vulkan_context, window_handle);
    defer vulkan_deinit(*vulkan_context);

    // # Create the swapchain, its images and its views
    success := vulkan_create_swapchain(*vulkan_context); 
    assert(success);

    // # Creating the command pools we can use for each in-flight frame
    vulkan_create_command_pools(*vulkan_context);
    
    // # Load the vertex and fragment shaders for this example
    fullscreen_vertex_shader_module   := vulkan_create_shader_module(*vulkan_context, Assets.Example_Fullscreen_Vertex_Shader_Code);
    fullscreen_fragment_shader_module := vulkan_create_shader_module(*vulkan_context, Assets.Example_Fullscreen_Fragment_Shader_Code);
    defer vulkan_destroy_shader_module(*vulkan_context, *fullscreen_vertex_shader_module);
    defer vulkan_destroy_shader_module(*vulkan_context, *fullscreen_fragment_shader_module);
    model_vertex_shader_module   := vulkan_create_shader_module(*vulkan_context, Assets.Example_Model_Vertex_Shader_Code);
    model_fragment_shader_module := vulkan_create_shader_module(*vulkan_context, Assets.Example_Model_Fragment_Shader_Code);
    defer vulkan_destroy_shader_module(*vulkan_context, *model_vertex_shader_module);
    defer vulkan_destroy_shader_module(*vulkan_context, *model_fragment_shader_module);

    // # Create a Graphics Pipeline (which needs a layout and a compatible render pass to the one that's going to use it)
    fullscreen_graphics_pipeline, 
    fullscreen_compatible_render_pass, 
    fullscreen_pipeline_layout, 
    fullscreen_descriptor_set_layouts := vulkan_example_create_graphics_pipeline(*vulkan_context, 
                                                                                fullscreen_vertex_shader_module, 
                                                                                fullscreen_fragment_shader_module,
                                                                                has_vertex_stuff = false);
    defer vulkan_destroy_graphics_pipeline(*vulkan_context, 
                                           *fullscreen_graphics_pipeline, 
                                           *fullscreen_compatible_render_pass, 
                                           *fullscreen_pipeline_layout, 
                                           fullscreen_descriptor_set_layouts);

    model_graphics_pipeline, 
    model_compatible_render_pass, 
    model_pipeline_layout, 
    model_descriptor_set_layouts := vulkan_example_create_graphics_pipeline(*vulkan_context, 
                                                                            model_vertex_shader_module, 
                                                                            model_fragment_shader_module,
                                                                            has_vertex_stuff = true);
    defer vulkan_destroy_graphics_pipeline(*vulkan_context, 
                                           *model_graphics_pipeline, 
                                           *model_compatible_render_pass, 
                                           *model_pipeline_layout, 
                                           model_descriptor_set_layouts);

    common_pipeline_layout := model_pipeline_layout;
    per_frame_descriptor_set_layout  := model_descriptor_set_layouts[0];
    per_view_descriptor_set_layout   := model_descriptor_set_layouts[1];
    per_object_descriptor_set_layout := model_descriptor_set_layouts[2];

    // # Creating the render pass tha we actually want to use to render
    render_pass := vulkan_example_create_render_pass(*vulkan_context);
    defer vulkan_destroy_render_pass(*vulkan_context, *render_pass);

    // # Creating the framebuffers for the images on the swapchains
    framebuffers := vulkan_example_make_framebuffers_for_renderpass_to_render_to_current_swapchain(*vulkan_context, render_pass);
    defer vulkan_destroy_framebuffers(*vulkan_context, *framebuffers);

    // # Creating buffer for our per-frame per-buffer and per-object data for the shader
    per_frame_uniform_buffers, per_frame_uniform_buffer_memories := vulkan_create_uniform_buffers(*vulkan_context, Per_Frame_Data);
    defer vulkan_destroy_uniform_buffers(*vulkan_context, *per_frame_uniform_buffers, *per_frame_uniform_buffer_memories);
    per_view_uniform_buffers, per_view_uniform_buffer_memories := vulkan_create_uniform_buffers(*vulkan_context, Per_View_Data);
    defer vulkan_destroy_uniform_buffers(*vulkan_context, *per_view_uniform_buffers, *per_view_uniform_buffer_memories);
    per_object_uniform_buffers, per_object_uniform_buffer_memories := vulkan_create_uniform_buffers(*vulkan_context, Per_Object_Data);
    defer vulkan_destroy_uniform_buffers(*vulkan_context, *per_object_uniform_buffers, *per_object_uniform_buffer_memories);

    // # Making a vertex and index buffer with some contents to draw!
    vertices, indices := make_vertex_and_index_buffer_for_cube();
    vertex_buffer, vertex_buffer_memory, 
    index_buffer, index_buffer_memory,
    semaphore_vertex_data_is_ready,
    fence_vertex_data_is_ready := vulkan_make_vertex_and_index_buffer(*vulkan_context, vertices, indices);
    defer
    {
        vulkan_destroy_buffer(*vulkan_context, *vertex_buffer, *vertex_buffer_memory);
        vulkan_destroy_buffer(*vulkan_context, *index_buffer, *index_buffer_memory);
        vulkan_destroy_semaphore(*vulkan_context, *semaphore_vertex_data_is_ready);
        vulkan_destroy_fence(*vulkan_context, *fence_vertex_data_is_ready);
    }
    waited_for_vertex_buffer := false;

    // # Main Loop
    last_time := get_time() - 1.0/60.0;
    need_to_recreate_framebuffers := false;
    run_main_loop := true;
    while run_main_loop 
    {
        reset_temporary_storage();

        mouse_position_x : s32;
        mouse_position_y : s32;
        {
            mouse_x, mouse_y, success := get_mouse_pointer_position();
            if success {
                mouse_position_x = xx mouse_x;
                mouse_position_y = xx mouse_y;
            }
        }
        
        now := get_time();
        delta_time : float64 = now - last_time;
        last_time = now;

        update_window_events();
        for event : events_this_frame
        {
            if (event.type == Event_Type.QUIT) || (event.key_code == Key_Code.ESCAPE && event.key_pressed)
            {
                run_main_loop = false;
                break;
            }
        }
        if !run_main_loop break;

        window_resized, record := is_a_window_resized();
        if window_resized
        {
            success := vulkan_create_swapchain(*vulkan_context, width = record.width, height = record.height);
            need_to_recreate_framebuffers = success;
        }

        // ## Get image from the swapchain we can render to
        can_render,
        swapchain_image, 
        swapchain_image_view, 
        swapchain_image_index, 
        image_acquired_semaphore, 
        rendering_finished_semaphore, 
        rendering_finished_fence, 
        recreated_swapchain := vulkan_begin_frame_and_acquire_swapchain_image_to_render_to(*vulkan_context);

        // ## Ignore rendering if we can't render (duh...)
        if !can_render
            continue;

        // ## Recreate Framebuffers for render pass if swapchain has changed and has new images
        need_to_recreate_framebuffers = need_to_recreate_framebuffers || recreated_swapchain;
        if need_to_recreate_framebuffers
        {
            need_to_recreate_framebuffers = false;
            framebuffers = vulkan_example_make_framebuffers_for_renderpass_to_render_to_current_swapchain(*vulkan_context, render_pass, previous=*framebuffers);
        }

        // ## Get the framebuffer for the correct swapchain image
        framebuffer := framebuffers[swapchain_image_index];

        // ## Get and Begin Command Buffer
        command_buffer := vulkan_get_new_command_buffer_for_graphics_queue(*vulkan_context);
        {
            begin_info : VkCommandBufferBeginInfo;
            begin_info.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
            result := vkBeginCommandBuffer(command_buffer, *begin_info);
            assert(result == VK_SUCCESS);
        }

        // ## Record beginning of Render Pass
        {
            begin_info : VkRenderPassBeginInfo;
            begin_info.renderPass = render_pass;
            begin_info.framebuffer = framebuffer;
            begin_info.renderArea.extent = vulkan_context.current_swapchain_image_extents;
            begin_info.clearValueCount = 1;
            clear_value : VkClearValue;
            clear_value.color.float32_[0] = 0.9;
            clear_value.color.float32_[1] = 0.0;
            clear_value.color.float32_[2] = 0.0;
            clear_value.color.float32_[3] = 1.0;
            begin_info.pClearValues = *clear_value;
            vkCmdBeginRenderPass(command_buffer, *begin_info, VK_SUBPASS_CONTENTS_INLINE);
        }

        // ## Updating our buffer with per-frame data
        per_frame_data : Per_Frame_Data;
        per_frame_data.resolution_x = xx vulkan_context.current_swapchain_image_extents.width;
        per_frame_data.resolution_y = xx vulkan_context.current_swapchain_image_extents.height;
        per_frame_data.time = cast(float32) now;
        per_frame_data.delta_time = cast(float32) delta_time;
        per_frame_data.mouse_position_x = mouse_position_x;
        per_frame_data.mouse_position_y = mouse_position_y;

        per_view_data : Per_View_Data;
        camera_position := make_vector3(0,0,5);
        per_view_data.view_from_world_matrix = prepare_matrix_for_shader(make_translation_matrix4(-camera_position));
        per_view_data.projection_from_view_matrix = prepare_matrix_for_shader(
            make_projection_matrix_for_vulkan(fov_vertical_in_degrees = 90.0,
                                              aspect_ratio_horizontal_over_vertical = cast(float)per_frame_data.resolution_x / cast(float) per_frame_data.resolution_y,
                                              near = 0.1,
                                              far = 100.0));

        // ## Allocating a descriptor set for per-frame data, make it point to our buffer and record binding it
        vulkan_example_update_and_bind_uniform_buffer(*vulkan_context, 
                                                      command_buffer, 
                                                      common_pipeline_layout, 
                                                      per_frame_descriptor_set_layout, 
                                                      per_frame_uniform_buffers[swapchain_image_index], 
                                                      per_frame_uniform_buffer_memories[swapchain_image_index], 
                                                      per_frame_data, 
                                                      set = 0,
                                                      binding = 0);
                                                      
        vulkan_example_update_and_bind_uniform_buffer(*vulkan_context, 
                                                      command_buffer, 
                                                      common_pipeline_layout, 
                                                      per_view_descriptor_set_layout, 
                                                      per_view_uniform_buffers[swapchain_image_index], 
                                                      per_view_uniform_buffer_memories[swapchain_image_index], 
                                                      per_view_data, 
                                                      set = 1,
                                                      binding = 0);


        // ## Record the scissor and viewport we're going to use
        {
            scissor_rect : VkRect2D;
            scissor_rect.extent = vulkan_context.current_swapchain_image_extents;
            vkCmdSetScissor(command_buffer, 0, 1, *scissor_rect);
            viewport : VkViewport;
            viewport.x = 0.0;
            viewport.y = 0.0;
            viewport.width  = cast(float32) vulkan_context.current_swapchain_image_extents.width;
            viewport.height = cast(float32) vulkan_context.current_swapchain_image_extents.height;
            viewport.minDepth = 0.0;
            viewport.maxDepth = 1.0;
            vkCmdSetViewport(command_buffer, 0, 1, *viewport);
        }

        // ## Record the binding of our pipeline and drawing some fullscreen stuff
        {
            vkCmdBindPipeline(command_buffer, VK_PIPELINE_BIND_POINT_GRAPHICS, fullscreen_graphics_pipeline);
            vkCmdDraw(command_buffer, 3, 1, 0, 0);
        }

        // ## We record now drawing something with vertices
        {
            per_object_data : Per_Object_Data;
            per_object_data.world_from_model_matrix = prepare_matrix_for_shader(make_scale_matrix4(make_vector3(0.3,0.3,0.3)) * make_translation_matrix4(make_vector3(0,0,-3)));
            vulkan_example_update_and_bind_uniform_buffer(*vulkan_context, 
                                                          command_buffer, 
                                                          common_pipeline_layout, 
                                                          per_object_descriptor_set_layout, 
                                                          per_object_uniform_buffers[swapchain_image_index], 
                                                          per_object_uniform_buffer_memories[swapchain_image_index], 
                                                          per_object_data, 
                                                          set = 2,
                                                          binding = 0);
            
            vkCmdBindPipeline(command_buffer, VK_PIPELINE_BIND_POINT_GRAPHICS, model_graphics_pipeline);
            zero_device_size : VkDeviceSize = 0;
            vkCmdBindVertexBuffers(command_buffer,
                                   firstBinding = 0,
                                   bindingCount = 1,
                                   pBuffers = *vertex_buffer,
                                   pOffsets = *zero_device_size);
            vkCmdBindIndexBuffer(command_buffer,
                                 buffer = index_buffer,
                                 offset = zero_device_size,
                                 indexType = VK_INDEX_TYPE_UINT32);
            vkCmdDrawIndexed(command_buffer,
                             indexCount = cast(u32) indices.count,
                             instanceCount = cast(u32) 1,
                             firstIndex = cast(u32) 0,
                             vertexOffset = 0,
                             firstInstance = cast(u32) 0);
        }

        // ## Record ending of Render Pass
        vkCmdEndRenderPass(command_buffer);
        
        // ## End Command Buffer
        {
            end_result := vkEndCommandBuffer(command_buffer);
            assert(end_result == VK_SUCCESS);
        }

        // ## Submit the Command Buffer
        {
            semaphores_to_wait_for := new_temporary_array(VkSemaphore);
            wait_stages := new_temporary_array(VkPipelineStageFlags);
            array_add(*semaphores_to_wait_for, image_acquired_semaphore);
            array_add(*wait_stages, VK_PIPELINE_STAGE_ALL_COMMANDS_BIT);
            if !waited_for_vertex_buffer
            {
                array_add(*semaphores_to_wait_for, semaphore_vertex_data_is_ready);
                array_add(*wait_stages, VK_PIPELINE_STAGE_VERTEX_INPUT_BIT);
                waited_for_vertex_buffer = true;
            }
            assert(semaphores_to_wait_for.count == wait_stages.count);
            submit_info : VkSubmitInfo;
            submit_info.waitSemaphoreCount = cast(u32) semaphores_to_wait_for.count;
            submit_info.pWaitSemaphores = semaphores_to_wait_for.data;
            submit_info.pWaitDstStageMask = wait_stages.data;
            submit_info.commandBufferCount = 1;
            submit_info.pCommandBuffers = *command_buffer;
            submit_info.signalSemaphoreCount = 1;
            submit_info.pSignalSemaphores = *rendering_finished_semaphore;
            
            result := vkQueueSubmit(vulkan_context.graphics_queue,
                                    submitCount = 1,
                                    *submit_info,
                                    fence = rendering_finished_fence);
            assert(result == VK_SUCCESS);
        }

        // ## And presenting the image to the screen
        recreated_swapchain_when_presenting := vulkan_end_frame_and_present_image(*vulkan_context, swapchain_image_index, rendering_finished_semaphore);
        need_to_recreate_framebuffers = need_to_recreate_framebuffers || recreated_swapchain_when_presenting;
    }
    
    // # Wait for idle after exiting main loop to make sure we destroy things after we stopped using them
    vkDeviceWaitIdle(vulkan_context.device);
}



Per_Frame_Data :: struct
{
    resolution_x : s32;
    resolution_y : s32;
    time : float32;
    delta_time : float32;

    mouse_position_x : s32;
    mouse_position_y : s32;
    something : s32;
    something_else : s32;
}


Per_View_Data :: struct
{
    view_from_world_matrix : Matrix4;
    projection_from_view_matrix : Matrix4;
}


Per_Object_Data :: struct
{
    world_from_model_matrix : Matrix4;
}


Vertex :: struct
{
    position : Vector3;
    color : Vector3;
}


Assets :: struct
{
    #insert #run insert_array_of_bytes("Example_Fullscreen_Vertex_Shader_Code",   "src/shaders/built/fullscreen_example.vert.spv");
    #insert #run insert_array_of_bytes("Example_Fullscreen_Fragment_Shader_Code", "src/shaders/built/fullscreen_example.frag.spv");

    #insert #run insert_array_of_bytes("Example_Model_Vertex_Shader_Code",   "src/shaders/built/model_example.vert.spv");
    #insert #run insert_array_of_bytes("Example_Model_Fragment_Shader_Code", "src/shaders/built/model_example.frag.spv");
}


make_vertex_and_index_buffer_for_cube :: () -> [8] Vertex, [6*2*3] u32
{
    vertices : [8] Vertex;
    vertices[0].position = make_vector3(-1.0, +1.0, -1.0);
    vertices[1].position = make_vector3(+1.0, +1.0, -1.0);
    vertices[2].position = make_vector3(-1.0, +1.0, +1.0);
    vertices[3].position = make_vector3(+1.0, +1.0, +1.0);
    vertices[4].position = make_vector3(-1.0, -1.0, -1.0);
    vertices[5].position = make_vector3(+1.0, -1.0, -1.0);
    vertices[6].position = make_vector3(-1.0, -1.0, +1.0);
    vertices[7].position = make_vector3(+1.0, -1.0, +1.0);
    vertices[0].color = make_vector3(0.0, 1.0, 0.0);
    vertices[1].color = make_vector3(1.0, 1.0, 0.0);
    vertices[2].color = make_vector3(0.0, 1.0, 1.0);
    vertices[3].color = make_vector3(1.0, 1.0, 1.0);
    vertices[4].color = make_vector3(0.0, 0.0, 0.0);
    vertices[5].color = make_vector3(1.0, 0.0, 0.0);
    vertices[6].color = make_vector3(0.0, 0.0, 1.0);
    vertices[7].color = make_vector3(1.0, 0.0, 1.0);
    indices : [6*2*3] u32;  
    counter := 0;
    tri(0,2,1); tri(2,3,1);
    tri(2,6,3); tri(3,6,7);
    tri(1,5,0); tri(0,5,4);
    tri(0,4,2); tri(2,4,6);
    tri(3,5,1); tri(3,7,5);
    tri(6,4,5); tri(6,5,7);
    return vertices, indices;
    tri :: (a : u32, b : u32, c : u32) #expand
    {
        `indices[`counter] = a;
        `indices[`counter+1] = b;
        `indices[`counter+2] = c;
        `counter += 3;
    }
}
    
    



//
// @@NOTE: There's compile time code that will insert these extensions
// in the Extension_Data members of the Vulkan_Context. This means that
// selecting an extension we might want to use should be as easy as adding
// it to this array and then check, for example, for is_enabled.ray_tracing
//
Extensions_We_Might_Want :: string.[
    "VK_KHR_swapchain",
    "VK_KHR_ray_tracing",
    "VK_KHR_deferred_host_operations",
    "VK_KHR_pipeline_library",
    "VK_NV_mesh_shader"
];

using Vulkan_Context :: struct
{
    instance : VkInstance;
    allocator_callbacks : VkAllocationCallbacks;
    vulkan_allocator : *VkAllocationCallbacks = null;
    debug_utils_messenger : VkDebugUtilsMessengerEXT;
    current_frame : s64 = 0;

    using physical_device_data : Physical_Device_Data;
    Physical_Device_Data :: struct
    {
        physical_device : VkPhysicalDevice;
        physical_device_properties : VkPhysicalDeviceProperties;
        physical_device_properties_vulkan_1_2 : VkPhysicalDeviceVulkan12Properties;
        physical_device_features : VkPhysicalDeviceFeatures;
        physical_device_memory_properties : VkPhysicalDeviceMemoryProperties;

        queue_family_indices : Queue_Family_Indices;
        Queue_Family_Indices :: struct
        {
            graphics_family_index := -1;
            graphics_queue_index  := -1;
            async_family_index    := -1;
            async_queue_index     := -1;
            transfer_family_index := -1;
            transfer_queue_index  := -1;
        }
    }

    using surface_data : Surface_Data;
    Surface_Data :: struct
    {
        surface : VkSurfaceKHR;
        surface_capabilities : VkSurfaceCapabilitiesKHR;
        surface_formats : [] VkSurfaceFormatKHR;
        surface_present_modes : [] VkPresentModeKHR;
    }
    
    using extensions : Extension_Data;
    Extension_Data :: struct
    {
        is_enabled : Is_Set;
        is_supported : Is_Set;
        Is_Set :: struct
        {
            #insert #run () -> string
            {
                builder: String_Builder;
                defer free_buffers(*builder);
                for Extensions_We_Might_Want
                {
                    print_to_builder(*builder, "% := false;\n", cleanup_extension_name(it));
                }
                return builder_to_string(*builder);
            }();
        }
    }

    using logical_device_data : Logical_Device_Data;
    Logical_Device_Data :: struct
    {
        device : VkDevice;
        graphics_queue : VkQueue;
        async_queue    : VkQueue;
        transfer_queue : VkQueue;
    }

    using swapchain_data : Swapchain_Data;
    Swapchain_Data :: struct
    {
        swapchain : VkSwapchainKHR;
        present_mode : VkPresentModeKHR;
        swapchain_format : VkFormat;
        swapchain_color_space : VkColorSpaceKHR;
        swapchain_images : [] VkImage;
        swapchain_image_views : [] VkImageView;
        current_swapchain_image_extents : VkExtent2D;
        
        acquired_swapchain_image_semaphores : [] VkSemaphore;
        rendering_finished_to_swapchain_image_semaphores : [] VkSemaphore;
        rendering_finished_to_swapchain_image_fences : [] VkFence;
        frame_numbers_per_image : [] s64;
        current_swapchain_semaphore_index := 0;

        should_recreate_swapchain_when_we_get_a_chance := false;
    }

    Queue_Type :: enum
    {
        Graphics       :: 0;
        Async_Compute  :: 1;
        Transfer       :: 2;
    }

    using command_pool_data : Command_Pool_Data;
    Command_Pool_Data :: struct
    {
        current_command_pool_index := 0;

        command_pools_per_type : [3] Per_Type;
        Per_Type :: struct
        {
            command_pools : [] VkCommandPool;
            used_command_buffers : [] [..] VkCommandBuffer;
            free_command_buffers : [] [..] VkCommandBuffer;
        }
    }
    
    using descriptor_data : Descriptor_Data;
    Descriptor_Data :: struct
    {
        MAX_SETS_PER_POOL :: 1024;
        Pool_And_Frame :: struct
        {
            pool : VkDescriptorPool;
            last_frame_that_used_it : s64;
        }
        current_descriptor_pool : Pool_And_Frame;
        full_descriptor_pools : [..] Pool_And_Frame;
        empty_descriptor_pools : [..] Pool_And_Frame;
    }
}


vulkan_init :: (using vulkan_context : *Vulkan_Context, 
                window_handle : Window_Handle, 
                $want_validation_layers := true, 
                $want_debug_extensions := true)
{
    // # Loader Procedures
    #if OS == .WINDOWS
    {
        vulkan_library := LoadLibraryA("vulkan-1.dll");
        load_vulkan_loader_procedures(vulkan_library, GetProcAddress);
    }
    else #assert(false);


    // # Instance Layers
    enabled_layers := new_temporary_array(string);
    validation_enabled := false;
    {
        desired_instance_layers := new_temporary_array(string);
        #if want_validation_layers array_add(*desired_instance_layers, "VK_LAYER_KHRONOS_validation");

        properties := vulkan_fill_array(VkLayerProperties, vkEnumerateInstanceLayerProperties);
        for desired : desired_instance_layers
            for property : properties
                if desired == to_string(property.layerName.data)
                    array_add(*enabled_layers, desired);

        validation_enabled = array_contains_string(enabled_layers, "VK_LAYER_KHRONOS_validation");
    }


    // # Instance Extensions
    enabled_instance_extensions := new_temporary_array(string);
    debug_extension_enabled := false;
    {
        desired_instance_extensions := new_temporary_array(string);
        array_add(*desired_instance_extensions, "VK_KHR_surface");
        #if OS == .WINDOWS
            array_add(*desired_instance_extensions, "VK_KHR_win32_surface");
        else #assert(false);
        #if want_debug_extensions array_add(*desired_instance_extensions, "VK_EXT_debug_utils");

        instance_properties := vulkan_fill_array(VkExtensionProperties, vkEnumerateInstanceExtensionProperties, null);
        for desired : desired_instance_extensions
            for property : instance_properties 
                 if desired == to_string(property.extensionName.data)
                    array_add(*enabled_instance_extensions, desired);

        debug_extension_enabled = array_contains_string(enabled_instance_extensions, "VK_EXT_debug_utils");
        assert(array_contains_string(enabled_instance_extensions, "VK_KHR_surface"));
        #if OS == .WINDOWS
            assert(array_contains_string(enabled_instance_extensions, "VK_KHR_win32_surface"));
        else #assert(false);
    }
    

    // # Create Instance
    {
        app_info : VkApplicationInfo;
        app_info.pApplicationName = "Vulkan Example";
        app_info.pEngineName = "Unireal-Maker";
        app_info.apiVersion = VK_MAKE_API_VERSION(0,1,2,135);

        create_info : VkInstanceCreateInfo;
        create_info.pApplicationInfo = *app_info;
        create_info.enabledLayerCount = cast(u32) enabled_layers.count;
        create_info.ppEnabledLayerNames = strings_to_cstrings(enabled_layers).data;
        create_info.enabledExtensionCount = cast(u32) enabled_instance_extensions.count;
        create_info.ppEnabledExtensionNames = strings_to_cstrings(enabled_instance_extensions).data;

        result := vkCreateInstance(*create_info, vulkan_allocator, *instance);
        assert(result == VK_SUCCESS);
    }


    // # Instance Procedures
    load_vulkan_instance_procedures(instance);


    // # Set-up debug extensions
    if debug_extension_enabled
    {
        debug_utils_user_data := null;
        debug_utils_callback :: (message_severity : VkDebugUtilsMessageSeverityFlagBitsEXT,
                     message_types : VkDebugUtilsMessageTypeFlagsEXT,
                     callback_data : *VkDebugUtilsMessengerCallbackDataEXT,
                     user_data : *void) -> VkBool32 #c_call
        {            
            is_error   : bool = xx message_severity & VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT;
            is_warning : bool = xx message_severity & VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT;
            is_info    : bool = xx message_severity & VK_DEBUG_UTILS_MESSAGE_SEVERITY_INFO_BIT_EXT;
            is_verbose : bool = xx message_severity & VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT;
            is_general     : bool = xx message_types & VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT;
            is_validation  : bool = xx message_types & VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT;
            is_performance : bool = xx message_types & VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT;
            message := callback_data.pMessage;
            should_log := (!is_info && !is_verbose);
            if should_log
            {
                severity_string := ifx is_error "[ERROR]" 
                                   else ifx is_warning "[WARNING]" 
                                   else ifx is_info "[INFO]" 
                                   else ifx is_verbose "[VERBOSE]" 
                                   else "";
                type_string := ifx is_validation "[VALIDATION]" 
                               else ifx is_performance "[PERFORMANCE]" 
                               else ifx is_general "[GENERAL]" 
                               else "";

                temp_context : Context;
                push_context temp_context 
                {
                    print("\n\nVulkan Debug Message % %:\n\n%\n\n", 
                          severity_string, type_string, to_string(message));
                    if is_error breakpoint();
                }
            }
            return VK_FALSE;
        }
        debug_utils_create_info : VkDebugUtilsMessengerCreateInfoEXT;
        debug_utils_create_info.messageSeverity = VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT |
                                      VK_DEBUG_UTILS_MESSAGE_SEVERITY_INFO_BIT_EXT    |
                                      VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT |
                                      VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT;
        debug_utils_create_info.messageType =     VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT     |
                                      VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT  |
                                      VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT; 
        debug_utils_create_info.pfnUserCallback = debug_utils_callback;
        debug_utils_create_info.pUserData = debug_utils_user_data;

        debug_utils_result := vkCreateDebugUtilsMessengerEXT(instance, *debug_utils_create_info, vulkan_allocator, *debug_utils_messenger);
        assert(debug_utils_result == VK_SUCCESS);
    }


    // # Surface
    #if OS == .WINDOWS
    {
        surface_create_info : VkWin32SurfaceCreateInfoKHR;
        surface_create_info.hinstance = GetModuleHandleW(null);
        surface_create_info.hwnd = window_handle;
        surface_result := vkCreateWin32SurfaceKHR(instance, *surface_create_info, vulkan_allocator, *surface);
        assert(surface_result == VK_SUCCESS);
    }
    else #assert(false);


    // # Physical Device
    {
        // ## First we'll request a bunch of data about each device to see what they offer
        physical_devices := vulkan_fill_array(VkPhysicalDevice, vkEnumeratePhysicalDevices, instance);
        physical_devices_properties := new_temporary_array(VkPhysicalDeviceProperties2);
        for physical_devices
        {
            properties : VkPhysicalDeviceProperties2;
            vkGetPhysicalDeviceProperties2(it, *properties);
            array_add(*physical_devices_properties, properties);
        }
        physical_devices_properties_vulkan_1_2 := new_temporary_array(VkPhysicalDeviceVulkan12Properties);
        for physical_devices_properties
        {
            properties_1_2 : VkPhysicalDeviceVulkan12Properties;
            properties := it;
            properties.pNext = *properties_1_2;
            vkGetPhysicalDeviceProperties2(physical_devices[it_index], *properties);
            array_add(*physical_devices_properties_vulkan_1_2, properties_1_2);
        }
        physical_devices_memory_properties := new_temporary_array(VkPhysicalDeviceMemoryProperties);
        for physical_devices
        {
            properties : VkPhysicalDeviceMemoryProperties;
            vkGetPhysicalDeviceMemoryProperties(it, *properties);
            array_add(*physical_devices_memory_properties, properties);
        }
        physical_devices_device_local_memory_sizes := new_temporary_array(s64);
        for physical_device : physical_devices
        {
            size_for_device := 0;
            properties := physical_devices_properties[it_index];
            memory_properties := physical_devices_memory_properties[it_index];
            for 0..memory_properties.memoryHeapCount-1
            {
                heap := memory_properties.memoryHeaps[it];
                if heap.flags & VK_MEMORY_HEAP_DEVICE_LOCAL_BIT
                {
                    heap_size : s64 = xx heap.size;
                    size_for_device += heap_size;
                }
            }
            array_add(*physical_devices_device_local_memory_sizes, size_for_device);
        }
        physical_devices_features := new_temporary_array(VkPhysicalDeviceFeatures2);
        for physical_devices
        {
            features : VkPhysicalDeviceFeatures2;
            vkGetPhysicalDeviceFeatures2(it, *features);
            array_add(*physical_devices_features, features);
        }
        physical_devices_queue_properties := new_temporary_array([] VkQueueFamilyProperties2);
        for physical_devices
        {
            queues := vulkan_fill_array_no_result(VkQueueFamilyProperties2, vkGetPhysicalDeviceQueueFamilyProperties2, it);
            array_add(*physical_devices_queue_properties, queues);
        }
        physical_devices_available_extensions := new_temporary_array([] VkExtensionProperties);
        for physical_devices
        {
            extensions := vulkan_fill_array(VkExtensionProperties, vkEnumerateDeviceExtensionProperties, it, null);
            array_add(*physical_devices_available_extensions, extensions);
        }
        physical_devices_queue_family_indices := new_temporary_array(Queue_Family_Indices);
        for queue_properties_array : physical_devices_queue_properties
        {
            physical_device := physical_devices[it_index];
            queue_family_indices : Queue_Family_Indices;
            for queue_properties, queue_family_index : queue_properties_array
            {
                queue_count := queue_properties.queueFamilyProperties.queueCount;
                supports_graphics := cast(bool) queue_properties.queueFamilyProperties.queueFlags & VK_QUEUE_GRAPHICS_BIT;
                supports_compute  := cast(bool) queue_properties.queueFamilyProperties.queueFlags & VK_QUEUE_COMPUTE_BIT;
                supports_transfer := (queue_properties.queueFamilyProperties.queueFlags & VK_QUEUE_TRANSFER_BIT) || (supports_graphics || supports_compute);
                supports_present  := false;
                if surface  
                {
                    supports : VkBool32;
                    vkGetPhysicalDeviceSurfaceSupportKHR(physical_device, cast(u32) queue_family_index, surface, *supports);
                    supports_present = cast(bool) supports;
                }
                if supports_graphics && supports_compute && supports_transfer && supports_present && queue_family_indices.graphics_family_index == -1
                {
                    queue_family_indices.graphics_family_index = queue_family_index;
                    queue_family_indices.graphics_queue_index  = 0;
                }
                else if supports_compute && queue_family_indices.async_family_index == -1
                {
                    queue_family_indices.async_family_index = queue_family_index;
                    queue_family_indices.async_queue_index  = 0;
                }
                else if supports_transfer && queue_family_indices.transfer_family_index == -1
                {
                    queue_family_indices.transfer_family_index = queue_family_index;
                    queue_family_indices.transfer_queue_index  = 0;
                }
            }
            array_add(*physical_devices_queue_family_indices, queue_family_indices);
        }
        physical_devices_supported_extensions := new_temporary_array(Is_Set);
        for extensions : physical_devices_available_extensions
        {
            array_add(*physical_devices_supported_extensions, fill_extension_set(extensions));
        }
        physical_devices_surface_capabilities  := new_temporary_array(VkSurfaceCapabilitiesKHR);
        physical_devices_surface_formats       := new_temporary_array([] VkSurfaceFormatKHR);
        physical_devices_surface_present_modes := new_temporary_array([] VkPresentModeKHR);
        if surface
        {
            for physical_devices
            {
                capabilities : VkSurfaceCapabilitiesKHR;
                vkGetPhysicalDeviceSurfaceCapabilitiesKHR(it, surface, *capabilities);
                array_add(*physical_devices_surface_capabilities, capabilities);
            }
            for physical_devices
            {
                surface_formats := vulkan_fill_array(VkSurfaceFormatKHR, vkGetPhysicalDeviceSurfaceFormatsKHR, it, surface);
                array_add(*physical_devices_surface_formats, surface_formats);
            }
            for physical_devices
            {
                present_modes := vulkan_fill_array(VkPresentModeKHR, vkGetPhysicalDeviceSurfacePresentModesKHR, it, surface);
                array_add(*physical_devices_surface_present_modes, present_modes);
            }
        }

        // ## Then we assign a score to each available device
        scores := new_temporary_array(s64);
        array_resize(*scores, physical_devices.count);
        for physical_device, index : physical_devices
        {
            scores[index] = -1; 
            queue_family_indices := physical_devices_queue_family_indices[index];
            extensions := physical_devices_supported_extensions[index];
            device_local_memory := physical_devices_device_local_memory_sizes[index];
            properties := physical_devices_properties[index].properties;

            if queue_family_indices.graphics_family_index == -1 || !extensions.swapchain
                continue;

            if properties.deviceType == VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU
                scores[index] += 1000;

            if queue_family_indices.async_family_index != -1 
                scores[index] += 1000;

            if queue_family_indices.transfer_family_index != -1 
                scores[index] += 500;
            
            if extensions.mesh_shader
                scores[index] += 1000;

            if extensions.ray_tracing
                scores[index] += 1000;

            scores[index] += cast(s64) ((cast(float)device_local_memory) / (1024.0 * 1024.0 * 1024.0) * 100.0);
        }

        // ## Finally we choose a device and store the data about it in the context
        chosen_index := -1;
        max_score := -1;
        for score, index : scores
        {
            if score > max_score
            {
                max_score = score;
                chosen_index = index;
            } 
        }
        if chosen_index == -1
        {
            print("We couldn't find a suitable device!!!!\n");
            assert(false);
        }
        else
        {
            for properties : physical_devices_properties
            {
                print("% - % - %MB - score % %\n", 
                      to_string(properties.properties.deviceName.data), 
                      properties.properties.deviceType,
                      physical_devices_device_local_memory_sizes[it_index] / (1024 * 1024),
                      scores[it_index],
                      ifx it_index == chosen_index "(Chosen)" else "");
            }
        }
        physical_device                       = physical_devices[chosen_index];
        queue_family_indices                  = physical_devices_queue_family_indices[chosen_index];
        is_supported                          = physical_devices_supported_extensions[chosen_index];
        physical_device_properties            = physical_devices_properties[chosen_index].properties;
        physical_device_properties_vulkan_1_2 = physical_devices_properties_vulkan_1_2[chosen_index];
        physical_device_features              = physical_devices_features[chosen_index].features;
        surface_capabilities                  = physical_devices_surface_capabilities[chosen_index];
        surface_formats                       = alloc_and_copy_array(physical_devices_surface_formats[chosen_index]);
        surface_present_modes                 = alloc_and_copy_array(physical_devices_surface_present_modes[chosen_index]);
        vkGetPhysicalDeviceMemoryProperties(physical_device, *physical_device_memory_properties);
    }


    // # Logical Device
    {
        device_queue_create_infos := new_temporary_array(VkDeviceQueueCreateInfo);
        {
            graphics_priorities := new_temporary_array(float32);
            async_priorities    := new_temporary_array(float32);
            transfer_priorities := new_temporary_array(float32);

            array_add(*graphics_priorities, 1.0);

            async_uses_graphics_queue    := queue_family_indices.async_family_index == queue_family_indices.graphics_family_index;
            transfer_uses_graphics_queue := queue_family_indices.transfer_family_index == queue_family_indices.graphics_family_index;
            if async_uses_graphics_queue
                array_add(*graphics_priorities, 0.75);
            else
                array_add(*async_priorities, 0.75);
            if transfer_uses_graphics_queue
                array_add(*graphics_priorities, 0.5);
            else
                array_add(*transfer_priorities, 0.5);

            assert(queue_family_indices.graphics_family_index != -1);
            graphics_queue_create_info : VkDeviceQueueCreateInfo;
            graphics_queue_create_info.queueFamilyIndex = xx queue_family_indices.graphics_family_index;
            graphics_queue_create_info.queueCount = xx graphics_priorities.count;
            graphics_queue_create_info.pQueuePriorities = graphics_priorities.data;
            array_add(*device_queue_create_infos, graphics_queue_create_info);

            if !async_uses_graphics_queue && queue_family_indices.async_family_index != -1
            {
                async_queue_create_info : VkDeviceQueueCreateInfo;
                async_queue_create_info.queueFamilyIndex = xx queue_family_indices.async_family_index;
                async_queue_create_info.queueCount = xx async_priorities.count;
                async_queue_create_info.pQueuePriorities = async_priorities.data;
                array_add(*device_queue_create_infos, async_queue_create_info);
            }

            if !transfer_uses_graphics_queue && queue_family_indices.transfer_family_index != -1
            {
                transfer_queue_create_info : VkDeviceQueueCreateInfo;
                transfer_queue_create_info.queueFamilyIndex = xx queue_family_indices.transfer_family_index;
                transfer_queue_create_info.queueCount = xx transfer_priorities.count;
                transfer_queue_create_info.pQueuePriorities = transfer_priorities.data;
                array_add(*device_queue_create_infos, transfer_queue_create_info);
            }
        }

        is_enabled = is_supported;
        is_enabled.ray_tracing = is_enabled.ray_tracing && is_enabled.deferred_host_operations && is_enabled.pipeline_library;
        // @@NOTE: Ray Tracing extension cannot be enabled by itself. Needs to have deferred host operations and pipelie libraries.
        enabled_extension_names := get_set_extension_cstrings(is_enabled);

        create_info : VkDeviceCreateInfo;
        create_info.queueCreateInfoCount = xx device_queue_create_infos.count;
        create_info.pQueueCreateInfos = device_queue_create_infos.data;
        create_info.enabledExtensionCount = xx enabled_extension_names.count;
        create_info.ppEnabledExtensionNames = enabled_extension_names.data;

        result := vkCreateDevice(physical_device, *create_info, vulkan_allocator, *device);
        assert(result == VK_SUCCESS);
    }


    // # Device Procedures
    load_vulkan_device_procedures(device);


    // # Load Queues
    {
        vkGetDeviceQueue(device, cast(u32) queue_family_indices.graphics_family_index, cast(u32) queue_family_indices.graphics_queue_index, *graphics_queue);
        vkGetDeviceQueue(device, cast(u32) queue_family_indices.async_family_index,    cast(u32) queue_family_indices.async_queue_index,    *async_queue);
        vkGetDeviceQueue(device, cast(u32) queue_family_indices.transfer_family_index, cast(u32) queue_family_indices.transfer_queue_index, *transfer_queue);
    }

    // # Descriptor Pools
    {
        current_descriptor_pool.pool = vulkan_create_descriptor_pool(vulkan_context);
        current_descriptor_pool.last_frame_that_used_it = 0;
    }
}


vulkan_create_descriptor_pool :: (using vulkan_context : *Vulkan_Context) -> VkDescriptorPool
{
    create_info : VkDescriptorPoolCreateInfo;
    create_info.flags = 0;
    create_info.maxSets = MAX_SETS_PER_POOL;
    pool_sizes : [11] VkDescriptorPoolSize;
    pool_sizes[0].type,  pool_sizes[0].descriptorCount  = VK_DESCRIPTOR_TYPE_SAMPLER               , 4;
    pool_sizes[1].type,  pool_sizes[1].descriptorCount  = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 16;
    pool_sizes[2].type,  pool_sizes[2].descriptorCount  = VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE         , 16;
    pool_sizes[3].type,  pool_sizes[3].descriptorCount  = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE         , 4;
    pool_sizes[4].type,  pool_sizes[4].descriptorCount  = VK_DESCRIPTOR_TYPE_UNIFORM_TEXEL_BUFFER  , 4;
    pool_sizes[5].type,  pool_sizes[5].descriptorCount  = VK_DESCRIPTOR_TYPE_STORAGE_TEXEL_BUFFER  , 4;
    pool_sizes[6].type,  pool_sizes[6].descriptorCount  = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER        , 8;
    pool_sizes[7].type,  pool_sizes[7].descriptorCount  = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER        , 8;
    pool_sizes[8].type,  pool_sizes[8].descriptorCount  = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC, 3;
    pool_sizes[9].type,  pool_sizes[9].descriptorCount  = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER_DYNAMIC, 3;
    pool_sizes[10].type, pool_sizes[10].descriptorCount = VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT      , 2;
    create_info.poolSizeCount = cast(u32) pool_sizes.count;
    create_info.pPoolSizes = pool_sizes.data;
    pool : VkDescriptorPool;
    result := vkCreateDescriptorPool(device, *create_info, vulkan_allocator, *pool);
    assert(result == VK_SUCCESS);
    return pool;
}


vulkan_deinit :: (using vulkan_context : *Vulkan_Context)
{
    vkDeviceWaitIdle(device);
    vkDestroyDescriptorPool(device, current_descriptor_pool.pool, vulkan_allocator);
    for * full_descriptor_pools
        vkDestroyDescriptorPool(device, it.pool, vulkan_allocator);
    for * empty_descriptor_pools
        vkDestroyDescriptorPool(device, it.pool, vulkan_allocator);
    for * acquired_swapchain_image_semaphores
        vulkan_destroy_semaphore(vulkan_context, it);
    for * rendering_finished_to_swapchain_image_semaphores
        vulkan_destroy_semaphore(vulkan_context, it);
    for * rendering_finished_to_swapchain_image_fences
        vulkan_destroy_fence(vulkan_context, it);
    if swapchain
    {
        vkDestroySwapchainKHR(device, swapchain, vulkan_allocator);
        for * swapchain_image_views
        {
            vkDestroyImageView(device, <<it, vulkan_allocator);
            it = null;
        }
    }
    for * command_pools_per_type
        for it.command_pools
            vkDestroyCommandPool(device, it, vulkan_allocator);
    vkDestroyDevice(device, vulkan_allocator);
    device = null;
    vkDestroySurfaceKHR(instance, surface, vulkan_allocator);
    surface = null;
    vkDestroyDebugUtilsMessengerEXT(instance, debug_utils_messenger, vulkan_allocator);
    debug_utils_messenger = null;
    vkDestroyInstance(instance, vulkan_allocator);
    instance = null;

    reset(*surface_formats);
    reset(*surface_present_modes);
    for * command_pools_per_type
    {
        reset(*it.command_pools);
        reset(*it.used_command_buffers);
        reset(*it.free_command_buffers);
    }
    reset(*swapchain_images);
    reset(*swapchain_image_views);
    reset(*acquired_swapchain_image_semaphores);
    reset(*rendering_finished_to_swapchain_image_semaphores);
    reset(*rendering_finished_to_swapchain_image_fences);
    reset(*frame_numbers_per_image);
    reset :: (array : * [] $T)
    {
        array.count = 0;
        free(array.data);
        array.data = null;
    }
}


Presentation_Mode :: enum
{
    Mailbox;
    // Shows the latest available image on the next available blank
    //
    // This means that if between two blanks we render 3 full frames, only the 
    // last one will be shown. This prioritizes low latency but can end up consuming
    // power since we keep rendering frames we might now show.
    
    Strict_Fifo;
    // Has an internal queue to which we add images to, then each blank one image
    // gets taken from the queue to the frontbuffer while we add more images to the
    // back. If there's no image on the queue we wait for the next blank to check again.
    //
    // This prioritizes having no absolutely no tearing ever although the latency can
    // end up being high depending on how long the queue gets.
    
    Relaxed_Fifo;
    // Like Strict_Fifo, it has an internal queue but if at any point the queue was
    // empty when we tried to present an image, the next one available gets shown as
    // fast as possible, with possible tearing cause we're not doing it in a blank.
    //
    // This is good for when we want to present an image every frame but we might be
    // late from time to time and we want to show that one anyway.
    
    Immediate;
    // Just tries to show the image as soon as possible, without caring
    // about where the blank happens, low latency but suffers from tearing.
}


vulkan_create_swapchain :: (vulkan_context : *Vulkan_Context, 
                            width : int = -999, height : int = -999, 
                            presentation_mode := Presentation_Mode.Mailbox) -> success : bool #must
{
    using Presentation_Mode;
    using vulkan_context;
    assert(is_enabled.swapchain);
    assert(surface != null);

    vkDeviceWaitIdle(device);

    old_swapchain_data := swapchain_data;

    vkGetPhysicalDeviceSurfaceCapabilitiesKHR(physical_device, surface, *surface_capabilities);    
    if surface_capabilities.maxImageExtent.width == 0 || surface_capabilities.maxImageExtent.height == 0
    {
        // If width or height of the swapchain would have been 0 then we can't create one, so we don't
        // and we leave the old stuff around until we get a chance to recreate a new one with the proper size.
        return false;
    }

    // # Creating the Swapchain
    {
        format : VkSurfaceFormatKHR;
        {
            desired_format : VkSurfaceFormatKHR;
            desired_format.format = VK_FORMAT_B8G8R8A8_SRGB;
            desired_format.colorSpace = VK_COLOR_SPACE_SRGB_NONLINEAR_KHR;
            found := false;
            assert(surface_formats.count > 0);
            for surface_formats
            {
                if it.format == desired_format.format && it.colorSpace == desired_format.colorSpace
                {
                    format = it;
                    found = true;
                    break;
                }
            }
            if !found format = surface_formats[0];
        }

        extent : VkExtent2D;
        {
            user_gave_data := (width != -999 || height != -999);
            if surface_capabilities.currentExtent.width == 0xFF_FF_FF_FF && surface_capabilities.currentExtent.height == 0xFF_FF_FF_FF 
            {
                assert(user_gave_data);
                // @@NOTE Expecial case in the API where the size of the surface will be
                // determined by the size we set the swapchain here.
                extent.width  = xx width;
                extent.height = xx height;
            }
            else
            {
                if user_gave_data
                {
                    assert(width == surface_capabilities.currentExtent.width);
                    assert(height == surface_capabilities.currentExtent.height);
                }
                extent.width  = xx surface_capabilities.currentExtent.width;
                extent.height = xx surface_capabilities.currentExtent.height;
            }

            extent.width = clamp(extent.width, surface_capabilities.minImageExtent.width, surface_capabilities.maxImageExtent.width);
            extent.height = clamp(extent.height, surface_capabilities.minImageExtent.height, surface_capabilities.maxImageExtent.height);
        }
        assert(extent.width  != 0);
        assert(extent.height != 0);

        selected_present_mode : VkPresentModeKHR;
        {
            modes_by_priority : [4] VkPresentModeKHR;
            if #complete presentation_mode ==
            {
                case Mailbox;
                    modes_by_priority[0] = VK_PRESENT_MODE_MAILBOX_KHR;
                    modes_by_priority[1] = VK_PRESENT_MODE_IMMEDIATE_KHR;
                    modes_by_priority[2] = VK_PRESENT_MODE_FIFO_RELAXED_KHR;
                    modes_by_priority[3] = VK_PRESENT_MODE_FIFO_KHR;

                case Strict_Fifo;
                    modes_by_priority[0] = VK_PRESENT_MODE_MAILBOX_KHR;
                    modes_by_priority[1] = VK_PRESENT_MODE_IMMEDIATE_KHR;
                    modes_by_priority[2] = VK_PRESENT_MODE_FIFO_RELAXED_KHR;
                    modes_by_priority[3] = VK_PRESENT_MODE_FIFO_KHR;

                case Relaxed_Fifo;
                    modes_by_priority[0] = VK_PRESENT_MODE_FIFO_RELAXED_KHR;
                    modes_by_priority[1] = VK_PRESENT_MODE_FIFO_KHR;
                    modes_by_priority[2] = VK_PRESENT_MODE_MAILBOX_KHR;
                    modes_by_priority[3] = VK_PRESENT_MODE_IMMEDIATE_KHR;

                case Immediate;
                    modes_by_priority[0] = VK_PRESENT_MODE_FIFO_RELAXED_KHR;
                    modes_by_priority[1] = VK_PRESENT_MODE_FIFO_KHR;
                    modes_by_priority[2] = VK_PRESENT_MODE_MAILBOX_KHR;
                    modes_by_priority[3] = VK_PRESENT_MODE_IMMEDIATE_KHR;
            }

            found := false;
            for available_mode : surface_present_modes
            {
                for mode_we_want : modes_by_priority
                {
                    if available_mode == mode_we_want
                    {
                        found = true;
                        selected_present_mode = available_mode;
                        break available_mode;
                    }
                }
            }
            assert(found);
        }

        create_info : VkSwapchainCreateInfoKHR;
        create_info.surface = surface;
        create_info.minImageCount = max(cast(u32) 3, surface_capabilities.minImageCount);
        if surface_capabilities.maxImageCount != 0  create_info.minImageCount = min(create_info.minImageCount, surface_capabilities.maxImageCount);
        create_info.imageFormat = format.format;
        create_info.imageColorSpace = format.colorSpace;
        create_info.imageExtent = extent;
        create_info.imageArrayLayers = 1;
        create_info.imageUsage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | VK_IMAGE_USAGE_TRANSFER_DST_BIT | VK_IMAGE_USAGE_TRANSFER_SRC_BIT;
        create_info.imageSharingMode = VK_SHARING_MODE_EXCLUSIVE;
        create_info.preTransform = VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR;
        assert((create_info.preTransform & surface_capabilities.supportedTransforms) != 0);
        create_info.compositeAlpha = VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
        create_info.presentMode = selected_present_mode;
        create_info.clipped = VK_TRUE;
        create_info.oldSwapchain = old_swapchain_data.swapchain;

        result := vkCreateSwapchainKHR(device, *create_info, vulkan_allocator, *swapchain);
        assert(result == VK_SUCCESS);

        present_mode = create_info.presentMode;
        swapchain_format = create_info.imageFormat;
        swapchain_color_space = create_info.imageColorSpace;
        current_swapchain_image_extents = extent;

        if old_swapchain_data.swapchain
        {
            vkDestroySwapchainKHR(device, old_swapchain_data.swapchain, vulkan_allocator);
            old_swapchain_data.swapchain = null;
        }
    }


    // # Getting the images
    {
        images := vulkan_fill_array(VkImage, vkGetSwapchainImagesKHR, device, swapchain);
        if swapchain_images.count == 0
            swapchain_images = alloc_and_copy_array(images);
        else if swapchain_images.count == images.count
            copy_array_dst_src(swapchain_images, images);
        else
            assert(false);
    }


    // # Getting the image views from the images
    {
        for old_swapchain_data.swapchain_image_views
            vkDestroyImageView(device, it, vulkan_allocator);

        new_image_views := new_temporary_array(VkImageView);
        for swapchain_images
        {
            create_info : VkImageViewCreateInfo;
            create_info.image = it;
            create_info.viewType = VK_IMAGE_VIEW_TYPE_2D;
            create_info.format = swapchain_format;
            create_info.components.r = VK_COMPONENT_SWIZZLE_IDENTITY;
            create_info.components.g = VK_COMPONENT_SWIZZLE_IDENTITY;
            create_info.components.b = VK_COMPONENT_SWIZZLE_IDENTITY;
            create_info.components.a = VK_COMPONENT_SWIZZLE_IDENTITY;
            create_info.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
            create_info.subresourceRange.baseMipLevel = 0;
            create_info.subresourceRange.levelCount = 1;
            create_info.subresourceRange.baseArrayLayer = 0;
            create_info.subresourceRange.layerCount = 1;
            image_view : VkImageView;
            result := vkCreateImageView(device, *create_info, vulkan_allocator, *image_view);
            assert(result == VK_SUCCESS);
            array_add(*new_image_views, image_view);
        }

        if swapchain_image_views.count == 0
            swapchain_image_views = alloc_and_copy_array(new_image_views);
        else if swapchain_image_views.count == new_image_views.count
            copy_array_dst_src(swapchain_image_views, new_image_views);
        else    
            assert(false);
    }

    // # Creating the semaphores to control access to the images
    {
        // ## Semaphores to acquire the images from the swapchain
        {
            for * acquired_swapchain_image_semaphores
                vulkan_destroy_semaphore(vulkan_context, it);
            semaphores := new_temporary_array(VkSemaphore);
            for 0..swapchain_images.count-1
                array_add(*semaphores, vulkan_create_semaphore(vulkan_context));
            if acquired_swapchain_image_semaphores.count == 0
                acquired_swapchain_image_semaphores = alloc_and_copy_array(semaphores);
            else if acquired_swapchain_image_semaphores.count == swapchain_images.count
                copy_array_dst_src(acquired_swapchain_image_semaphores, semaphores);
            else
                assert(false);
        }

        // ## Semaphores to know if rendering has finished for an image
        {
            for * rendering_finished_to_swapchain_image_semaphores
                vulkan_destroy_semaphore(vulkan_context, it);
            semaphores := new_temporary_array(VkSemaphore);
            for 0..swapchain_images.count-1
                array_add(*semaphores, vulkan_create_semaphore(vulkan_context));
            if rendering_finished_to_swapchain_image_semaphores.count == 0
                rendering_finished_to_swapchain_image_semaphores = alloc_and_copy_array(semaphores);
            else if rendering_finished_to_swapchain_image_semaphores.count == swapchain_images.count
                copy_array_dst_src(rendering_finished_to_swapchain_image_semaphores, semaphores);
            else
                assert(false);
        }

        // ## Fences to know if rendering has finished for an image
        {
            for * rendering_finished_to_swapchain_image_fences
                vulkan_destroy_fence(vulkan_context, it);
            fences := new_temporary_array(VkFence);
            for 0..swapchain_images.count-1
                array_add(*fences, vulkan_create_fence(vulkan_context, signaled = true));
            if rendering_finished_to_swapchain_image_fences.count == 0
                rendering_finished_to_swapchain_image_fences = alloc_and_copy_array(fences);
            else if rendering_finished_to_swapchain_image_fences.count == swapchain_images.count
                copy_array_dst_src(rendering_finished_to_swapchain_image_fences, fences);
            else
                assert(false);
        }

        // ## Setting up the array of frame numbers per image
        {
            if frame_numbers_per_image.count == 0
            {
                temp := new_temporary_array(s64);
                for 0..swapchain_images.count-1
                    array_add(*temp, -1);
                frame_numbers_per_image = alloc_and_copy_array(temp);
            }
            else if frame_numbers_per_image.count != swapchain_images.count
            {
                assert(false);
            }
        }
    }

    should_recreate_swapchain_when_we_get_a_chance = false;

    return true;
}


#if OS == .WINDOWS
{
    Window_Handle :: HWND;
}
else #assert(false);


vulkan_create_command_pools :: (using vulkan_context : *Vulkan_Context)
{
    do_for_type(Queue_Type.Graphics, cast(u32) queue_family_indices.graphics_family_index);
    do_for_type(Queue_Type.Async_Compute,  cast(u32) queue_family_indices.async_family_index);
    do_for_type(Queue_Type.Transfer, cast(u32) queue_family_indices.transfer_family_index);
    do_for_type :: (type : Queue_Type, queue_family_index : u32) #expand
    {
        temp_command_pools := new_temporary_array(VkCommandPool);
        temp_used_command_buffers := new_temporary_array([..] VkCommandBuffer);
        temp_free_command_buffers := new_temporary_array([..] VkCommandBuffer);
        create_info : VkCommandPoolCreateInfo;
        create_info.queueFamilyIndex = queue_family_index;
        for 0..swapchain_images.count-1
        {
            command_pool : VkCommandPool;
            result := vkCreateCommandPool(device, *create_info, vulkan_allocator, *command_pool);
            assert(result == VK_SUCCESS);
            array_add(*temp_command_pools, command_pool);
            dynamic_array : [..] VkCommandBuffer;
            array_add(*temp_used_command_buffers, dynamic_array);
            another_dynamic_array : [..] VkCommandBuffer;
            array_add(*temp_free_command_buffers, another_dynamic_array);
        }
        command_pools_per_type[type].command_pools         = alloc_and_copy_array(temp_command_pools);
        command_pools_per_type[type].used_command_buffers  = alloc_and_copy_array(temp_used_command_buffers);
        command_pools_per_type[type].free_command_buffers  = alloc_and_copy_array(temp_free_command_buffers);
    }
}


vulkan_get_new_command_buffer_for_graphics_queue :: (using vulkan_context : *Vulkan_Context) -> VkCommandBuffer #must
{
    return vulkan_get_new_command_buffer_for_queue_type(vulkan_context, Queue_Type.Graphics);
}


vulkan_get_new_command_buffer_for_async_compute_queue :: (using vulkan_context : *Vulkan_Context) -> VkCommandBuffer #must
{
    return vulkan_get_new_command_buffer_for_queue_type(vulkan_context, Queue_Type.Async_Compute);
}


vulkan_get_new_command_buffer_for_transfer_queue :: (using vulkan_context : *Vulkan_Context) -> VkCommandBuffer #must
{
    return vulkan_get_new_command_buffer_for_queue_type(vulkan_context, Queue_Type.Transfer);
}


vulkan_get_new_command_buffer_for_queue_type :: (using vulkan_context : *Vulkan_Context, 
                                                 queue_type : Queue_Type) -> VkCommandBuffer #must
{
    per_type := *command_pools_per_type[queue_type];
    free_array := *per_type.free_command_buffers[current_command_pool_index];
    used_array := *per_type.used_command_buffers[current_command_pool_index];
    command_buffer : VkCommandBuffer;
    if free_array.count > 0
    {
        command_buffer = pop(free_array);
    }
    else
    {
        allocate_info : VkCommandBufferAllocateInfo;
        allocate_info.commandPool = per_type.command_pools[current_command_pool_index];
        allocate_info.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
        allocate_info.commandBufferCount = 1;
        result := vkAllocateCommandBuffers(device, *allocate_info, *command_buffer);
        assert(result == VK_SUCCESS);
    }
    array_add(used_array, command_buffer);
    return command_buffer;
}


vulkan_one_time_submit_to_graphics_queue :: (using vulkan_context : *Vulkan_Context, semaphores_to_wait_on : [] VkSemaphore, code : Code, semaphore_to_signal : *VkSemaphore = null, fence_to_signal : *VkFence = null) #expand
{
    `command_buffer : VkCommandBuffer;
    vulkan_one_time_submit_to_queue(vulkan_context, Queue_Type.Graphics, semaphores_to_wait_on, code, semaphore_to_signal, fence_to_signal);
}


vulkan_one_time_submit_to_async_queue :: (using vulkan_context : *Vulkan_Context, semaphores_to_wait_on : [] VkSemaphore, code : Code, semaphore_to_signal : *VkSemaphore = null, fence_to_signal : *VkFence = null) #expand
{
    `command_buffer : VkCommandBuffer;
    vulkan_one_time_submit_to_queue(vulkan_context, Queue_Type.Async_Compute, semaphores_to_wait_on, code, semaphore_to_signal, fence_to_signal);
}


vulkan_one_time_submit_to_transfer_queue :: (using vulkan_context : *Vulkan_Context, semaphores_to_wait_on : [] VkSemaphore, code : Code, semaphore_to_signal : *VkSemaphore = null, fence_to_signal : *VkFence = null) #expand
{
    `command_buffer : VkCommandBuffer;
    vulkan_one_time_submit_to_queue(vulkan_context, Queue_Type.Transfer, semaphores_to_wait_on, code, semaphore_to_signal, fence_to_signal);
}


//
// @@TODO: There is some weirdness here when handling how to pass things into the code we want
// to insert to record the command buffer. I'd like for the command_buffer, variable to make it
// cleanly to user code, so it's somehow explicit that you're getting this to use on your own code.
//
// There is also problems I'm having where I want the command_buffer to be declared in the inner-most
// macro but it doesn't seem to make it out since the backtick sends it only to the outer macro not to
// user code. Righ now I'm declaring the macro on all the outer macros but I'd like to not have to do that.
//


vulkan_one_time_submit_to_queue :: (using vulkan_context : *Vulkan_Context, queue_type : Queue_Type,  semaphores_to_wait_on : [] VkSemaphore, code : Code, semaphore_to_signal : *VkSemaphore = null, fence_to_signal : *VkFence = null) #expand
{
    queue := vulkan_get_queue_for_type(vulkan_context, queue_type);
    `command_buffer = vulkan_get_new_command_buffer_for_queue_type(vulkan_context, queue_type);
    {
        begin_info : VkCommandBufferBeginInfo;
        begin_info.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
        result := vkBeginCommandBuffer(`command_buffer, *begin_info);
        assert(result == VK_SUCCESS);
    }
    {
        #insert code;
    }
    {
        vkEndCommandBuffer(`command_buffer);
        
        submit_info : VkSubmitInfo;
        submit_info.commandBufferCount = 1;
        submit_info.pCommandBuffers = *`command_buffer;
        submit_info.waitSemaphoreCount = cast(u32) semaphores_to_wait_on.count;
        submit_info.pWaitSemaphores = semaphores_to_wait_on.data;
        wait_stage_masks := new_temporary_array(VkPipelineStageFlags);
        for semaphores_to_wait_on
        {
            array_add(*wait_stage_masks, VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT);
        }
        submit_info.pWaitDstStageMask = wait_stage_masks.data;
        assert(wait_stage_masks.count == semaphores_to_wait_on.count);
        //
        // @@IMPROVEMENT: We could improve performance here by saying how we should wait for the semaphore.
        // We have to be conservative here and wait at the beginning of the pipeline but if, for example,
        // we were waiting on a semaphore that transfers a texture to a GPU we only sample on the fragment shader
        // we could put VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT and vertex work could start earlier and get some
        // sweet overlap! :) 
        //
        // This would be maybe annoying for the user to have to set though, cause they would need to give us
        // a stage per semaphore. So maybe we can overload this procedure and default to TOP_OF_PIPE if we're not
        // given anything.
        //
        if semaphore_to_signal
        {
            submit_info.signalSemaphoreCount = 1;
            submit_info.pSignalSemaphores = semaphore_to_signal;
        }
        fence : VkFence = null;
        if fence_to_signal
        {
            fence = <<fence_to_signal;
        }
        result := vkQueueSubmit(queue,
                                submitCount = 1,
                                *submit_info,
                                fence = fence);
        assert(result == VK_SUCCESS);
    }
}


vulkan_get_queue_for_type :: (using vulkan_context : *Vulkan_Context, queue_type : Queue_Type) -> VkQueue
{
    if #complete queue_type ==
    {
        case Queue_Type.Graphics;      return graphics_queue;
        case Queue_Type.Async_Compute; return async_queue;
        case Queue_Type.Transfer;      return transfer_queue;
    }
    assert(false);
    return null;
}


vulkan_wait_for_all_graphics_operations_to_finish :: (using vulkan_context : *Vulkan_Context)
{
    vkQueueWaitIdle(graphics_queue);
}

vulkan_wait_for_all_async_compute_operations_to_finish :: (using vulkan_context : *Vulkan_Context)
{
    vkQueueWaitIdle(async_queue);
}

vulkan_wait_for_all_transfer_operations_to_finish :: (using vulkan_context : *Vulkan_Context)
{
    vkQueueWaitIdle(transfer_queue);
}


vulkan_create_shader_module :: (using vulkan_context : *Vulkan_Context, shader_spirv : [] u8) -> VkShaderModule
{
    create_info : VkShaderModuleCreateInfo;
    create_info.codeSize = cast(u64) shader_spirv.count;
    create_info.pCode = cast(*u32) shader_spirv.data;
    shader_module : VkShaderModule;
    result := vkCreateShaderModule(device, *create_info, vulkan_allocator, *shader_module);
    assert(result == VK_SUCCESS);
    return shader_module;
}


vulkan_destroy_shader_module :: (using vulkan_context : *Vulkan_Context, module : *VkShaderModule)
{
    vkDestroyShaderModule(device, <<module, vulkan_allocator);
    <<module = VK_NULL_HANDLE;
}


// @@NOTE: :example_specific
vulkan_example_create_graphics_pipeline :: (using vulkan_context : *Vulkan_Context,
                                            vertex_shader_module : VkShaderModule, 
                                            fragment_shader_module : VkShaderModule,
                                            $has_vertex_stuff : bool) -> VkPipeline            #must,
                                                                         VkRenderPass          #must,
                                                                         VkPipelineLayout      #must,
                                                                         [3] VkDescriptorSetLayout #must
{
    /*

    @@NOTE: If you wanted to use this to do some real stuff, you'd need to provide
    more inputs to configure the state of the fixed function stuff of the pipeline.
    
    Most of this fixed function stuff will depend on the inputs and outputs for the
    shaders you're using. We're hardcoding here most of it cause we'd end up with a full
    renderer if we tried to support all the configurations.

    Maybe eventually I'll try to provide a module that does this better, but that would be
    sort of a graphics library on top of Vulkan that would do stuff like creating a graphics
    pipeline purely from assets or something (since most of this stuff you can figure out from
    the SPIR-V refleced + some extra stuff). But this would be waaay outside the scope of adding
    vulkan bindings and a simple vulkan example, which is what this module is for :)


    
    @@IMPROVEMENT: Eventually I'd like to move away from giving the descriptor set layouts and pipeline layouts here
    and have those cached internally. The reasoning is that for shaders that will have the exact same pipeline
    layout and descriptor set layouts we're creating duplicated objects, which we then have to destroy. The other
    reason is that from looking at the usage it LOOKS like pipeline layouts and descriptor set layouts for the same shader
    but with just a code change are important when they are really not!!!

    If two shaders have slightly different code but they access the same kind of descriptor sets with the same stuff and
    the same push constant ranges, they effectively have the same pipeline layout and descriptor set layouts.



    @@IMPROVEMENT: The Render-Pass objects we create here all the time should also be cached really, especially so the user
    doesn't have to worry about destroying them. But mostly cause similar shaders are very likely to reuse the same ones
    constantly.

    All that matters for renderpasses (I think) to create the pipeline is which targets this actually writes to, how many
    MSAA samples they have and which format they have (rgba16, rgb32, whatever). All we need here is just a "compatible" render
    pass to be able to create the pipeline, not the actual renderpass that will be used during rendering which will be created
    in the middle of the frame when needed. For compatibility see: 
        - https://renderdoc.org/vkspec_chunked/chap7.html#renderpass-compatibility
    
    */

    vertex_shader_stage_create_info : VkPipelineShaderStageCreateInfo;
    {
        using vertex_shader_stage_create_info;
        stage = VK_SHADER_STAGE_VERTEX_BIT;
        module = vertex_shader_module;
        pName = "main";
    }
    fragment_shader_stage_create_info : VkPipelineShaderStageCreateInfo;
    {
        using fragment_shader_stage_create_info;
        stage = VK_SHADER_STAGE_FRAGMENT_BIT;
        module = fragment_shader_module;
        pName = "main";
    }

    // # Programmable Stages
    stage_create_infos : [2] VkPipelineShaderStageCreateInfo;
    stage_create_infos[0] = vertex_shader_stage_create_info;
    stage_create_infos[1] = fragment_shader_stage_create_info;

    // # Vertex Input
    vertex_input_state : VkPipelineVertexInputStateCreateInfo;
    vertex_binding_description : VkVertexInputBindingDescription;
    vertex_attribute_descriptions : [2] VkVertexInputAttributeDescription;
    #if has_vertex_stuff
    {
        vertex_binding_description.binding = 0;
        vertex_binding_description.stride = size_of(Vertex);
        vertex_binding_description.inputRate = VK_VERTEX_INPUT_RATE_VERTEX;

        // ## Position
        vertex_attribute_descriptions[0].location = 0;
        vertex_attribute_descriptions[0].binding = 0; 
        vertex_attribute_descriptions[0].format = VK_FORMAT_R32G32B32_SFLOAT; 
        vertex_attribute_descriptions[0].offset = #run offset_of(Vertex, "position");

        // ## Color
        vertex_attribute_descriptions[1].location = 1;
        vertex_attribute_descriptions[1].binding = 0; 
        vertex_attribute_descriptions[1].format = VK_FORMAT_R32G32B32_SFLOAT; 
        vertex_attribute_descriptions[1].offset = #run offset_of(Vertex, "color");

        vertex_input_state.vertexBindingDescriptionCount = 1; 
        vertex_input_state.pVertexBindingDescriptions = *vertex_binding_description;
        vertex_input_state.vertexAttributeDescriptionCount = vertex_attribute_descriptions.count;
        vertex_input_state.pVertexAttributeDescriptions = vertex_attribute_descriptions.data;
    }
    else
    {
        vertex_input_state.vertexBindingDescriptionCount = 0; 
        vertex_input_state.pVertexBindingDescriptions = null;
        vertex_input_state.vertexAttributeDescriptionCount = 0;
        vertex_input_state.pVertexAttributeDescriptions = null;
    }

    // # Input Assembly
    input_assembly_state : VkPipelineInputAssemblyStateCreateInfo;
    input_assembly_state.topology = VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST;
    input_assembly_state.primitiveRestartEnable = VK_FALSE;

    // # Viewport (also set as dynamic state so we'll set it when drawing)
    viewport_state : VkPipelineViewportStateCreateInfo;
    viewport_state.viewportCount = 1;
    viewport : VkViewport;
    viewport.x = 0.0;
    viewport.y = 0.0;
    viewport.width = 1920.0;
    viewport.height = 1080.0;
    viewport.minDepth = 0.0;
    viewport.maxDepth = 1.0;
    viewport_state.pViewports = *viewport;
    viewport_state.scissorCount = 1;
    scissor_rect : VkRect2D;
    scissor_rect.offset.x = 0;  
    scissor_rect.offset.y = 0;  
    scissor_rect.extent.width = 1920;
    scissor_rect.extent.height = 1080;
    viewport_state.pScissors = *scissor_rect;

    // # Rasterization
    rasterization_state : VkPipelineRasterizationStateCreateInfo;
    rasterization_state.depthClampEnable = VK_FALSE;
    rasterization_state.rasterizerDiscardEnable = VK_FALSE;
    rasterization_state.polygonMode = VK_POLYGON_MODE_FILL;
    rasterization_state.cullMode = VK_CULL_MODE_BACK_BIT;
    rasterization_state.frontFace = VK_FRONT_FACE_COUNTER_CLOCKWISE;
    rasterization_state.depthBiasEnable = VK_FALSE;
    rasterization_state.depthBiasConstantFactor = 0.0;
    rasterization_state.depthBiasClamp = 0.0;
    rasterization_state.depthBiasSlopeFactor = 0.0;
    rasterization_state.lineWidth = 1.0;

    // # Multisample 
    multisample_state : VkPipelineMultisampleStateCreateInfo;
    multisample_state.rasterizationSamples = VK_SAMPLE_COUNT_1_BIT;

    // # Depth/Stencil
    depth_stencil_state : VkPipelineDepthStencilStateCreateInfo;
    depth_stencil_state.depthTestEnable = VK_FALSE;
    depth_stencil_state.depthWriteEnable = VK_FALSE;
    depth_stencil_state.depthCompareOp = VK_COMPARE_OP_ALWAYS;
    depth_stencil_state.depthBoundsTestEnable = VK_FALSE;
    depth_stencil_state.stencilTestEnable = VK_FALSE;
    depth_stencil_state.minDepthBounds = 0.0;
    depth_stencil_state.maxDepthBounds = 1.0;
    depth_stencil_state.front.failOp = VK_STENCIL_OP_KEEP;
    depth_stencil_state.front.passOp = VK_STENCIL_OP_KEEP;
    depth_stencil_state.front.depthFailOp = VK_STENCIL_OP_KEEP;
    depth_stencil_state.front.compareOp = VK_COMPARE_OP_ALWAYS;
    depth_stencil_state.front.compareMask = 0x0;
    depth_stencil_state.front.writeMask = 0x0;
    depth_stencil_state.front.reference = 0x0;
    depth_stencil_state.back.failOp = VK_STENCIL_OP_KEEP;
    depth_stencil_state.back.passOp = VK_STENCIL_OP_KEEP;
    depth_stencil_state.back.depthFailOp = VK_STENCIL_OP_KEEP;
    depth_stencil_state.back.compareOp = VK_COMPARE_OP_ALWAYS;
    depth_stencil_state.back.compareMask = 0x0;
    depth_stencil_state.back.writeMask = 0x0;
    depth_stencil_state.back.reference = 0x0;

    // # Color Blend
    color_blend_state : VkPipelineColorBlendStateCreateInfo;
    color_blend_state.logicOpEnable = VK_FALSE;
    color_blend_state.logicOp = VK_LOGIC_OP_NO_OP;
    color_blend_state.attachmentCount = 1;
    attachment_data : VkPipelineColorBlendAttachmentState;
    attachment_data.blendEnable = VK_FALSE;
    attachment_data.srcColorBlendFactor = VK_BLEND_FACTOR_ONE;
    attachment_data.dstColorBlendFactor = VK_BLEND_FACTOR_ZERO;
    attachment_data.colorBlendOp = VK_BLEND_OP_ADD;
    attachment_data.srcAlphaBlendFactor = VK_BLEND_FACTOR_ONE;
    attachment_data.dstAlphaBlendFactor = VK_BLEND_FACTOR_ZERO;
    attachment_data.alphaBlendOp = VK_BLEND_OP_ADD;
    attachment_data.colorWriteMask = VK_COLOR_COMPONENT_R_BIT | VK_COLOR_COMPONENT_G_BIT | VK_COLOR_COMPONENT_B_BIT | VK_COLOR_COMPONENT_A_BIT;
    color_blend_state.pAttachments = *attachment_data;
    color_blend_state.blendConstants[0] = 1.0;
    color_blend_state.blendConstants[1] = 1.0;
    color_blend_state.blendConstants[2] = 1.0;
    color_blend_state.blendConstants[3] = 1.0;

    // # Dynamic state
    dynamic_state : VkPipelineDynamicStateCreateInfo;
    dynamic_states : [2] VkDynamicState;
    dynamic_states[0] = VK_DYNAMIC_STATE_VIEWPORT;
    dynamic_states[1] = VK_DYNAMIC_STATE_SCISSOR;
    dynamic_state.dynamicStateCount = cast(u32) dynamic_states.count;
    dynamic_state.pDynamicStates = dynamic_states.data;

    // # Pipeline Layout
    pipeline_layout : VkPipelineLayout;
    pipeline_layout_create_info : VkPipelineLayoutCreateInfo;
    // ## Descriptor Set Layout
    per_frame_descriptor_set_layout : VkDescriptorSetLayout;
    {
        create_info : VkDescriptorSetLayoutCreateInfo;
        create_info.flags = 0;
        create_info.bindingCount = 1;
        binding : VkDescriptorSetLayoutBinding;
        binding.binding = 0; // this is the "binding" in layout(set = 0, binding = 0) uniform ...
        binding.descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
        binding.descriptorCount = 1; // only 1 element on this buffer
        binding.stageFlags = VK_SHADER_STAGE_ALL_GRAPHICS; // could make this the actual stage, could improve performance.
        binding.pImmutableSamplers = null;
        create_info.pBindings = *binding;
        result := vkCreateDescriptorSetLayout(device, *create_info, vulkan_allocator, *per_frame_descriptor_set_layout);
        assert(result == VK_SUCCESS);
    }
    per_view_descriptor_set_layout : VkDescriptorSetLayout;
    {
        create_info : VkDescriptorSetLayoutCreateInfo;
        create_info.flags = 0;
        create_info.bindingCount = 1;
        binding : VkDescriptorSetLayoutBinding;
        binding.binding = 0; 
        binding.descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
        binding.descriptorCount = 1;
        binding.stageFlags = VK_SHADER_STAGE_ALL_GRAPHICS;
        binding.pImmutableSamplers = null;
        create_info.pBindings = *binding;
        result := vkCreateDescriptorSetLayout(device, *create_info, vulkan_allocator, *per_view_descriptor_set_layout);
        assert(result == VK_SUCCESS);
    }
    per_object_descriptor_set_layout : VkDescriptorSetLayout;
    {
        create_info : VkDescriptorSetLayoutCreateInfo;
        create_info.flags = 0;
        create_info.bindingCount = 1;
        binding : VkDescriptorSetLayoutBinding;
        binding.binding = 0; 
        binding.descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
        binding.descriptorCount = 1;
        binding.stageFlags = VK_SHADER_STAGE_ALL_GRAPHICS;
        binding.pImmutableSamplers = null;
        create_info.pBindings = *binding;
        result := vkCreateDescriptorSetLayout(device, *create_info, vulkan_allocator, *per_object_descriptor_set_layout);
        assert(result == VK_SUCCESS);
    }
    all_descriptor_set_layouts : [3] VkDescriptorSetLayout; 
    all_descriptor_set_layouts[0] = per_frame_descriptor_set_layout; 
    all_descriptor_set_layouts[1] = per_view_descriptor_set_layout; 
    all_descriptor_set_layouts[2] = per_object_descriptor_set_layout; 

    pipeline_layout_create_info.setLayoutCount = xx all_descriptor_set_layouts.count;
    pipeline_layout_create_info.pSetLayouts = all_descriptor_set_layouts.data;
    pipeline_layout_create_info.pushConstantRangeCount = 0;
    pipeline_layout_create_info.pPushConstantRanges = null;
    layout_result := vkCreatePipelineLayout(device, *pipeline_layout_create_info, vulkan_allocator, *pipeline_layout);
    assert(layout_result == VK_SUCCESS);

    // # Compatible Render Pass
    render_pass : VkRenderPass;
    render_pass_create_info : VkRenderPassCreateInfo;
    render_pass_create_info.flags = 0;
    render_pass_create_info.attachmentCount = 1;
    attachment_description : VkAttachmentDescription;
    attachment_description.flags = 0;
    attachment_description.format = swapchain_format;
    attachment_description.samples = VK_SAMPLE_COUNT_1_BIT;
    attachment_description.loadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
    attachment_description.storeOp = VK_ATTACHMENT_STORE_OP_STORE;
    attachment_description.stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
    attachment_description.stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
    attachment_description.initialLayout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
    attachment_description.finalLayout = VK_IMAGE_LAYOUT_GENERAL;
    render_pass_create_info.pAttachments = *attachment_description;
    render_pass_create_info.subpassCount = 1;
    subpass : VkSubpassDescription;
    subpass.flags = 0;
    subpass.pipelineBindPoint = VK_PIPELINE_BIND_POINT_GRAPHICS;
    subpass.inputAttachmentCount = 0;
    subpass.pInputAttachments = null;
    subpass.colorAttachmentCount = 1;
    color_attachment : VkAttachmentReference;
    color_attachment.attachment = 0; 
    color_attachment.layout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
    subpass.pColorAttachments = *color_attachment;
    subpass.pResolveAttachments = null;
    subpass.pDepthStencilAttachment = null;
    subpass.preserveAttachmentCount = 0;
    subpass.pPreserveAttachments = null;
    render_pass_create_info.pSubpasses = *subpass;
    render_pass_create_info.dependencyCount = 0;
    render_pass_create_info.pDependencies = null;
    render_pass_result := vkCreateRenderPass(device, *render_pass_create_info, vulkan_allocator, *render_pass);
    assert(render_pass_result == VK_SUCCESS);

    create_info : VkGraphicsPipelineCreateInfo;
    create_info.stageCount = xx stage_create_infos.count;
    create_info.pStages    = stage_create_infos.data; 
    create_info.pVertexInputState   = *vertex_input_state;
    create_info.pInputAssemblyState = *input_assembly_state;
    create_info.pViewportState      = *viewport_state;
    create_info.pRasterizationState = *rasterization_state;
    create_info.pMultisampleState   = *multisample_state;
    create_info.pDepthStencilState  = *depth_stencil_state;
    create_info.pColorBlendState    = *color_blend_state;
    create_info.pDynamicState       = *dynamic_state;
    create_info.layout = pipeline_layout;
    create_info.renderPass = render_pass;
    create_info.subpass = 0;
    create_info.pTessellationState = null;
    pipeline_cache : VkPipelineCache = VK_NULL_HANDLE;
    pipeline : VkPipeline;
    result := vkCreateGraphicsPipelines(device, pipeline_cache, 1, *create_info, vulkan_allocator, *pipeline);
    assert(result == VK_SUCCESS);
    return pipeline, render_pass, pipeline_layout, all_descriptor_set_layouts;
}


vulkan_destroy_graphics_pipeline :: (using vulkan_context : *Vulkan_Context, 
                                     graphics_pipeline : *VkPipeline, 
                                     render_pass : *VkRenderPass, 
                                     pipeline_layout : *VkPipelineLayout,
                                     descriptor_set_layout : [] VkDescriptorSetLayout)
{
    for descriptor_set_layout  vkDestroyDescriptorSetLayout(device, it, vulkan_allocator);
    if <<graphics_pipeline     vkDestroyPipeline(device, <<graphics_pipeline, vulkan_allocator);
    if <<pipeline_layout       vkDestroyPipelineLayout(device, <<pipeline_layout, vulkan_allocator);
    if <<render_pass           vkDestroyRenderPass(device, <<render_pass, vulkan_allocator);
    
    for descriptor_set_layout it = null;
    <<graphics_pipeline = null;
    <<render_pass =  null;
    <<pipeline_layout = null;
}


// @@NOTE: :example_specific
vulkan_example_create_render_pass :: (using vulkan_context : *Vulkan_Context) -> VkRenderPass #must
{
    /*

    @@NOTE: Same as the graphics pipeline procedure, a lot of this config you'd
    need to decide yourself when making the pass, but we're setting it up for this example
    only while showing the kind of parameters you'll need to setup.
    
    */    

    attachment_description : VkAttachmentDescription;
    attachment_description.flags = 0;
    attachment_description.format = swapchain_format;
    attachment_description.samples = VK_SAMPLE_COUNT_1_BIT;
    attachment_description.loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR;
    attachment_description.storeOp = VK_ATTACHMENT_STORE_OP_STORE;
    attachment_description.stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
    attachment_description.stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
    attachment_description.initialLayout =  VK_IMAGE_LAYOUT_UNDEFINED;
    attachment_description.finalLayout = VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;

    color_attachment : VkAttachmentReference;
    color_attachment.attachment = 0; 
    color_attachment.layout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;

    subpass : VkSubpassDescription;
    subpass.flags = 0;
    subpass.pipelineBindPoint = VK_PIPELINE_BIND_POINT_GRAPHICS;
    subpass.inputAttachmentCount = 0;
    subpass.pInputAttachments = null;
    subpass.colorAttachmentCount = 1;
    subpass.pColorAttachments = *color_attachment;
    subpass.pResolveAttachments = null;
    subpass.pDepthStencilAttachment = null;
    subpass.preserveAttachmentCount = 0;
    subpass.pPreserveAttachments = null;

    render_pass_create_info : VkRenderPassCreateInfo;
    render_pass_create_info.flags = 0;
    render_pass_create_info.attachmentCount = 1;
    render_pass_create_info.pAttachments = *attachment_description;
    render_pass_create_info.subpassCount = 1;
    render_pass_create_info.pSubpasses = *subpass;
    render_pass_create_info.dependencyCount = 0;
    render_pass_create_info.pDependencies = null;
    
    render_pass : VkRenderPass;
    render_pass_result := vkCreateRenderPass(device, *render_pass_create_info, vulkan_allocator, *render_pass);
    assert(render_pass_result == VK_SUCCESS);
    return render_pass;
}


vulkan_destroy_render_pass :: (using vulkan_context : *Vulkan_Context, render_pass : *VkRenderPass)
{
    vkDestroyRenderPass(device, <<render_pass, vulkan_allocator);
    <<render_pass =  null;
}


// @@NOTE: :example_specific but it almost isn't, the attachments are hardcoded to be 1, for the swapchain_image_view, people might want extra attachments or a depth buffer
vulkan_example_make_framebuffers_for_renderpass_to_render_to_current_swapchain :: (using vulkan_context : *Vulkan_Context, render_pass : VkRenderPass, previous : * [] VkFramebuffer = null) -> [] VkFramebuffer #must
{
    framebuffers := new_temporary_array(VkFramebuffer);
    create_info : VkFramebufferCreateInfo;
    create_info.renderPass = render_pass;
    create_info.width  = current_swapchain_image_extents.width;
    create_info.height = current_swapchain_image_extents.height;
    create_info.layers = 1;
    for swapchain_image_views
    {
        framebuffer : VkFramebuffer;
        create_info.attachmentCount = 1;
        create_info.pAttachments = *it;
        result := vkCreateFramebuffer(device, *create_info, vulkan_allocator, *framebuffer);
        assert(result == VK_SUCCESS);
        array_add(*framebuffers, framebuffer);
    }

    if previous
    {
        for <<previous
        {
            vkDestroyFramebuffer(device, it, vulkan_allocator);
        }
        assert(previous.count == framebuffers.count);
        to_return := <<previous;
        copy_array_dst_src(to_return, framebuffers);
        return to_return;
    }
    else
    {
        return alloc_and_copy_array(framebuffers);
    }
}


vulkan_destroy_framebuffers :: (using vulkan_context : *Vulkan_Context, framebuffers : * [] VkFramebuffer)
{
    for * <<framebuffers
    {
        vkDestroyFramebuffer(device, <<it, vulkan_allocator);
        <<it = null;
    }
    free(framebuffers.data);
    framebuffers.data = null;
    framebuffers.count = 0;
}


vulkan_create_semaphore :: (using vulkan_context : *Vulkan_Context) -> VkSemaphore #must
{
    create_info : VkSemaphoreCreateInfo;
    semaphore : VkSemaphore;
    result := vkCreateSemaphore(device, *create_info, vulkan_allocator, *semaphore);
    return semaphore;
}


vulkan_destroy_semaphore :: (using vulkan_context : *Vulkan_Context, semaphore : *VkSemaphore)
{
    vkDestroySemaphore(device, <<semaphore, vulkan_allocator);
    <<semaphore = null;
}


vulkan_create_fence :: (using vulkan_context : *Vulkan_Context, signaled : bool) -> VkFence #must
{
    create_info : VkFenceCreateInfo;
    if signaled create_info.flags = VK_FENCE_CREATE_SIGNALED_BIT;
    fence : VkFence;
    result := vkCreateFence(device, *create_info, vulkan_allocator, *fence);
    return fence;
}


vulkan_destroy_fence :: (using vulkan_context : *Vulkan_Context, fence : *VkFence)
{
    vkDestroyFence(device, <<fence, vulkan_allocator);
    <<fence = null;
}


vulkan_begin_frame_and_acquire_swapchain_image_to_render_to :: (using vulkan_context : *Vulkan_Context) -> can_render : bool #must, 
                                                                                                           image : VkImage #must, 
                                                                                                           image_view : VkImageView #must, 
                                                                                                           image_index : u32 #must, 
                                                                                                           image_acquired_semaphore : VkSemaphore #must, 
                                                                                                           finished_rendering_semaphore : VkSemaphore #must,
                                                                                                           finished_rendering_fence : VkFence #must,
                                                                                                           recreated_swapchain : bool #must
{
    // # Deal with needing to recreate the swapchain
    recreated_swapchain := false;
    if (should_recreate_swapchain_when_we_get_a_chance) ||
       (surface_capabilities.maxImageExtent.width == 0 || surface_capabilities.maxImageExtent.height == 0)
    {
        // @@NOTE: If the surface capabilities had a max extent for the image of 0 for width or height then
        // we can't render to those! In this case we try to create swapchain again to see if these image extents
        // have changed, which will create a new swapchain if they have, and just return if they haven't.
        success := vulkan_create_swapchain(vulkan_context);
        if !success
        {
            return can_render = false,
                   image = null, 
                   image_view = null, 
                   image_index = 0, 
                   image_acquired_semaphore = null, 
                   finished_rendering_semaphore = null,
                   finished_rendering_fence = null,
                   recreated_swapchain = false;
        }
        else
        {
            recreated_swapchain = true;
        }
    }

    // # Get the next swapchain image and the associated resources
    current_swapchain_semaphore_index = current_frame % acquired_swapchain_image_semaphores.count;
    image_acquired_semaphore := acquired_swapchain_image_semaphores[current_swapchain_semaphore_index];
    finished_rendering_semaphore := rendering_finished_to_swapchain_image_semaphores[current_swapchain_semaphore_index];
    frame_that_finished := frame_numbers_per_image[current_swapchain_semaphore_index];
    frame_numbers_per_image[current_swapchain_semaphore_index] = current_frame;
    {
        fence_that_should_have_finished := rendering_finished_to_swapchain_image_fences[current_swapchain_semaphore_index];
        fence_status_result := vkGetFenceStatus(device, fence_that_should_have_finished);
        if fence_status_result == VK_NOT_READY
        {
            wait_result := vkWaitForFences(device, fenceCount = 1, *fence_that_should_have_finished, waitAll = VK_TRUE, 0xFF_FF_FF_FF_FF_FF_FF_FF);
            assert(wait_result == VK_SUCCESS);
        }
        else
        {
            assert(fence_status_result == VK_SUCCESS);
        }
        reset_result := vkResetFences(device, fenceCount = 1, *fence_that_should_have_finished);
        assert(reset_result == VK_SUCCESS);
    }
    finished_rendering_fence := rendering_finished_to_swapchain_image_fences[current_swapchain_semaphore_index];
    image_index : u32 = 0xFF_FF_FF_FF;
    result := vkAcquireNextImageKHR(device, swapchain, 
                                    timeout = 0xFF_FF_FF_FF_FF_FF_FF_FF,
                                    image_acquired_semaphore,
                                    fence = null,
                                    *image_index);
    if result == VK_ERROR_OUT_OF_DATE_KHR
    {
        success := vulkan_create_swapchain(vulkan_context);
        if !success
        {
            return can_render = false,
                   image = null, 
                   image_view = null, 
                   image_index = 0, 
                   image_acquired_semaphore = null, 
                   finished_rendering_semaphore = null,
                   finished_rendering_fence = null,
                   recreated_swapchain = false;
        }
    }
    else if result == VK_SUBOPTIMAL_KHR
    {
        should_recreate_swapchain_when_we_get_a_chance = true;
    }
    else if result != VK_SUCCESS
    {
        assert(false, "%", result);
    }

    // # Reseting the command pools for this image
    {
        current_command_pool_index = image_index;
        for * command_pools_per_type
        {
            current_pool := it.command_pools[current_command_pool_index];
            reset_result := vkResetCommandPool(device, current_pool, flags = 0);
            assert(reset_result == VK_SUCCESS);
            used_command_buffers := *it.used_command_buffers[current_command_pool_index];
            free_command_buffers := *it.free_command_buffers[current_command_pool_index];
            while used_command_buffers.count > 0
            {
                array_add(free_command_buffers, pop(used_command_buffers));
            }
        }
    }

    // # Do work we can do when we know a frame number has finished
    if frame_that_finished > 0
    {
        // ## Reset the full descriptor pools whose frames have ended.
        for * full_descriptor_pools
        {
            if it.last_frame_that_used_it <= frame_that_finished
            {
                it.last_frame_that_used_it = -1;
                result := vkResetDescriptorPool(device, it.pool, flags=0);
                assert(result == VK_SUCCESS);
                array_add(*empty_descriptor_pools, <<it);
                remove it;
            }
        }
    }


    return can_render = true,
           swapchain_images[image_index], 
           swapchain_image_views[image_index], 
           image_index, 
           image_acquired_semaphore, 
           finished_rendering_semaphore, 
           finished_rendering_fence, 
           recreated_swapchain;
}


vulkan_end_frame_and_present_image :: (using vulkan_context : *Vulkan_Context, image_index : u32, semaphore_to_wait_on : VkSemaphore) -> recreated_swapchain : bool
{
    semaphores_to_wait_on : [1] VkSemaphore;
    semaphores_to_wait_on[0] = semaphore_to_wait_on;
    recreated := vulkan_end_frame_and_present_image(vulkan_context, image_index, semaphores_to_wait_on);
    return recreated;
}


vulkan_end_frame_and_present_image :: (using vulkan_context : *Vulkan_Context, image_index : u32, semaphores_to_wait_on : [] VkSemaphore) -> recreated_swapchain : bool
{
    recreated_swapchain := false;

    // # Presenting the image
    present_info : VkPresentInfoKHR;
    present_info.waitSemaphoreCount = cast(u32) semaphores_to_wait_on.count;
    present_info.pWaitSemaphores = semaphores_to_wait_on.data;
    present_info.swapchainCount = 1;
    present_info.pSwapchains = *swapchain;
    present_info.pImageIndices = *image_index;
    result := vkQueuePresentKHR(graphics_queue, *present_info);
    if result == VK_ERROR_OUT_OF_DATE_KHR
    {
        success := vulkan_create_swapchain(vulkan_context);
        recreated_swapchain = success;
    }
    else if result == VK_SUBOPTIMAL_KHR
    {
        should_recreate_swapchain_when_we_get_a_chance = true;
    }
    else if result != VK_SUCCESS
    {
        assert(false, "%", result);
    }

    // # Incrementing Frame Number
    current_frame += 1;

    return recreated_swapchain;
}


vulkan_allocate_descriptor_set :: (using vulkan_context : *Vulkan_Context, layout : VkDescriptorSetLayout) -> VkDescriptorSet
{
    allocate_info : VkDescriptorSetAllocateInfo;
    allocate_info.descriptorPool = current_descriptor_pool.pool;
    allocate_info.descriptorSetCount = 1;
    allocate_info.pSetLayouts = *layout;
    set : VkDescriptorSet;
    allocate_result := vkAllocateDescriptorSets(device, *allocate_info, *set);
    if allocate_result == VK_ERROR_OUT_OF_POOL_MEMORY
    {
        array_add(*full_descriptor_pools, current_descriptor_pool);
        if empty_descriptor_pools.count > 0
        {
            current_descriptor_pool = pop(*empty_descriptor_pools);
            current_descriptor_pool.last_frame_that_used_it = current_frame;
        }
        else
        {
            current_descriptor_pool.pool = vulkan_create_descriptor_pool(vulkan_context);
            current_descriptor_pool.last_frame_that_used_it = current_frame;
        }
        return vulkan_allocate_descriptor_set(vulkan_context, layout);
    }
    else
    {
        current_descriptor_pool.last_frame_that_used_it = current_frame;
    }
    return set;
}


vulkan_create_uniform_buffers :: (using vulkan_context : *Vulkan_Context, $Buffer_Type : Type) -> [] VkBuffer, [] VkDeviceMemory
{
    count := swapchain_images.count;
    buffers : [] VkBuffer;
    buffers.data = xx alloc(count * size_of(VkBuffer));
    buffers.count = count;
    memories : [] VkDeviceMemory;
    memories.data = xx alloc(count * size_of(VkDeviceMemory));
    memories.count = count;
    for 0..buffers.count-1
    {
        buffer, memory := vulkan_create_uniform_buffer(vulkan_context, Buffer_Type);
        buffers[it] = buffer;
        memories[it] = memory;
    }
    return buffers, memories;
}


vulkan_destroy_uniform_buffers :: (using vulkan_context : *Vulkan_Context, buffers : * [] VkBuffer, memories : * [] VkDeviceMemory)
{
    assert(buffers.count == memories.count);
    for 0..buffers.count-1
    {
        buffer := *(<<buffers)[it];
        memory := *(<<memories)[it];
        vulkan_destroy_buffer(vulkan_context, buffer, memory); 
    }
    free(buffers.data);
    free(memories.data);
    buffers.count = 0;
    memories.count = 0;
}


vulkan_create_uniform_buffer :: (using vulkan_context : *Vulkan_Context, $Buffer_Type : Type) -> VkBuffer, VkDeviceMemory
{
    size_of_buffer := size_of(Buffer_Type);
    assert(size_of_buffer & 15 == 0);
    buffer, memory := vulkan_create_buffer(vulkan_context, 
                                           size_of_buffer,
                                           desired_properties = VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, 
                                           usage = VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT);
    return buffer, memory;
}


vulkan_create_buffer :: (using vulkan_context : *Vulkan_Context, 
                         size_of_buffer : int,
                         desired_properties : VkMemoryPropertyFlagBits,
                         usage : VkBufferUsageFlagBits) -> VkBuffer, VkDeviceMemory
{
    // # First we create the buffer handle (but is no backed with memory yet!)
    create_info : VkBufferCreateInfo;
    create_info.flags = 0;
    create_info.size = cast(u32) size_of_buffer;
    create_info.usage = usage;
    create_info.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
    create_info.queueFamilyIndexCount = 0;
    create_info.pQueueFamilyIndices = null;
    buffer : VkBuffer;
    result := vkCreateBuffer(device, *create_info, vulkan_allocator, *buffer);
    assert(result == VK_SUCCESS);

    // # Now we need to calculate the memory requirements of it and allocate it
    memory_requirements : VkMemoryRequirements;
    vkGetBufferMemoryRequirements(device, buffer, *memory_requirements);
    allocate_info : VkMemoryAllocateInfo;
    allocate_info.allocationSize = memory_requirements.size;
    found_memory_type, memory_type_index := find_memory_type_index(vulkan_context, 
                                                                   memory_requirements.memoryTypeBits, 
                                                                   desired_properties);
    // This is the index on the physical device memoryTypes in physical_device_memory_properties that covers all the requirements
    // this buffer has, that is, it has to be one of the indices indicated by the memory_requirements.memoryTypeBits bit-field but also
    // needs to have available all the properties that we want from desired properties.
    assert(found_memory_type);
    allocate_info.memoryTypeIndex = memory_type_index;
    device_memory : VkDeviceMemory;
    allocate_result := vkAllocateMemory(device, *allocate_info, vulkan_allocator, *device_memory);
    assert(allocate_result == VK_SUCCESS);

    bind_result := vkBindBufferMemory(device, buffer, device_memory, memoryOffset=0);
    assert(bind_result == VK_SUCCESS);

    return buffer, device_memory;

    find_memory_type_index :: (using vulkan_context : *Vulkan_Context, 
                               memory_type_bits : u32, 
                               desired_properties : VkMemoryPropertyFlags) -> found : bool, u32
    {
        for 0..vulkan_context.physical_device_memory_properties.memoryTypeCount-1
        {
            if (memory_type_bits & (1 << it)) && 
               ((desired_properties & vulkan_context.physical_device_memory_properties.memoryTypes[it].propertyFlags) == desired_properties)
            {
                return true, it;
            }
        }
        return false, 0;
    }
}


vulkan_make_vertex_and_index_buffer :: (using vulkan_context : *Vulkan_Context, 
                                        vertices : [] $Vertex_Type, 
                                        indices : [] $Index_Type) -> vertex_buffer                   : VkBuffer       #must,
                                                                     vertex_buffer_memory            : VkDeviceMemory #must,
                                                                     index_buffer                    : VkBuffer       #must,
                                                                     index_buffer_memory             : VkDeviceMemory #must,
                                                                     semaphore_signalled_when_ending : VkSemaphore    #must,
                                                                     fence_signalled_when_ending     : VkFence        #must
{
    size_of_vertex_buffer := size_of(Vertex_Type) * vertices.count;
    size_of_index_buffer  := size_of(Index_Type) * indices.count;

    vertex_staging_buffer, vertex_staging_buffer_memory := vulkan_create_buffer(vulkan_context, 
                                                                                size_of_vertex_buffer,
                                                                                desired_properties = VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, 
                                                                                usage = VK_BUFFER_USAGE_TRANSFER_SRC_BIT);
    defer vulkan_destroy_buffer(vulkan_context, *vertex_staging_buffer, *vertex_staging_buffer_memory);
                                                                  
    index_staging_buffer, index_staging_buffer_memory := vulkan_create_buffer(vulkan_context, 
                                                                              size_of_index_buffer,
                                                                              desired_properties = VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, 
                                                                              usage = VK_BUFFER_USAGE_TRANSFER_SRC_BIT);
    defer vulkan_destroy_buffer(vulkan_context, *index_staging_buffer, *index_staging_buffer_memory);

    
    vertex_buffer, vertex_buffer_memory := vulkan_create_buffer(vulkan_context, 
                                                                size_of_vertex_buffer,
                                                                desired_properties = VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, 
                                                                usage = VK_BUFFER_USAGE_TRANSFER_DST_BIT | VK_BUFFER_USAGE_VERTEX_BUFFER_BIT);

                                                                  
    index_buffer, index_buffer_memory := vulkan_create_buffer(vulkan_context, 
                                                              size_of_index_buffer,
                                                              desired_properties = VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, 
                                                              usage = VK_BUFFER_USAGE_TRANSFER_DST_BIT | VK_BUFFER_USAGE_INDEX_BUFFER_BIT);

    mapped_vertex_data : *Vertex_Type;
    vkMapMemory(device, 
                vertex_staging_buffer_memory,
                offset = 0,
                size = cast(u64) size_of_vertex_buffer,
                flags = 0,
                ppData = xx *mapped_vertex_data);
    memcpy(mapped_vertex_data, vertices.data, size_of_vertex_buffer);
    vkUnmapMemory(device, vertex_staging_buffer_memory);
    
    mapped_index_data : *Index_Type;
    vkMapMemory(device, 
                index_staging_buffer_memory,
                offset = 0,
                size = cast(u64) size_of_index_buffer,
                flags = 0,
                ppData = xx *mapped_index_data);
    memcpy(mapped_index_data, indices.data, size_of_index_buffer);
    vkUnmapMemory(device, index_staging_buffer_memory);


    semaphore := vulkan_create_semaphore(vulkan_context);
    all_finished_fence := vulkan_create_fence(vulkan_context, signaled = false);

    //
    // @@TODO: Have to do an extra scope on this one time submits since both macros want to export
    // the variable "command_buffer" and I'd get an error saying it's already defined. I would like to
    // have a way to export "command_buffer" ONLY for the #code block we pass in.
    //

    {
        semaphores_to_wait_on : [0] VkSemaphore;
        vulkan_one_time_submit_to_transfer_queue(vulkan_context, semaphores_to_wait_on = semaphores_to_wait_on, #code 
        {
            vertex_copy_region : VkBufferCopy;
            vertex_copy_region.srcOffset = 0;
            vertex_copy_region.dstOffset = 0;
            vertex_copy_region.size = cast(u64) size_of_vertex_buffer;
            vkCmdCopyBuffer(command_buffer, srcBuffer = vertex_staging_buffer, dstBuffer = vertex_buffer, regionCount = 1, pRegions = *vertex_copy_region);

            index_copy_region : VkBufferCopy;
            index_copy_region.srcOffset = 0;
            index_copy_region.dstOffset = 0;
            index_copy_region.size = cast(u64) size_of_index_buffer;
            vkCmdCopyBuffer(command_buffer, srcBuffer = index_staging_buffer, dstBuffer = index_buffer, regionCount = 1, pRegions = *index_copy_region);
    
            vertex_buffer_memory_barrier : VkBufferMemoryBarrier;
            vertex_buffer_memory_barrier.srcAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;
            vertex_buffer_memory_barrier.dstAccessMask = 0;
            vertex_buffer_memory_barrier.srcQueueFamilyIndex = cast(u32) queue_family_indices.transfer_family_index;
            vertex_buffer_memory_barrier.dstQueueFamilyIndex = cast(u32) queue_family_indices.graphics_family_index;
            vertex_buffer_memory_barrier.buffer = vertex_buffer;
            vertex_buffer_memory_barrier.offset = 0;
            vertex_buffer_memory_barrier.size = VK_WHOLE_SIZE;

            index_buffer_memory_barrier : VkBufferMemoryBarrier;
            index_buffer_memory_barrier.srcAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;
            index_buffer_memory_barrier.dstAccessMask = 0;
            index_buffer_memory_barrier.srcQueueFamilyIndex = cast(u32) queue_family_indices.transfer_family_index;
            index_buffer_memory_barrier.dstQueueFamilyIndex = cast(u32) queue_family_indices.graphics_family_index;
            index_buffer_memory_barrier.buffer = index_buffer;
            index_buffer_memory_barrier.offset = 0;
            index_buffer_memory_barrier.size = VK_WHOLE_SIZE;

            buffer_memory_barriers : [2] VkBufferMemoryBarrier;
            buffer_memory_barriers[0] = vertex_buffer_memory_barrier;
            buffer_memory_barriers[1] = index_buffer_memory_barrier;

            vkCmdPipelineBarrier(command_buffer,
                                 srcStageMask = VK_PIPELINE_STAGE_TRANSFER_BIT,
                                 dstStageMask = VK_PIPELINE_STAGE_ALL_COMMANDS_BIT,
                                 dependencyFlags = 0,
                                 memoryBarrierCount = 0,
                                 pMemoryBarriers = null,
                                 bufferMemoryBarrierCount = buffer_memory_barriers.count,
                                 pBufferMemoryBarriers = buffer_memory_barriers.data,
                                 imageMemoryBarrierCount = 0,
                                 pImageMemoryBarriers = null);
        
        }, *semaphore);
    }

    {
        semaphores_to_wait_on : [1] VkSemaphore;
        semaphores_to_wait_on[0] = semaphore;
        vulkan_one_time_submit_to_graphics_queue(vulkan_context, semaphores_to_wait_on = semaphores_to_wait_on, #code 
        {
            vertex_buffer_memory_barrier : VkBufferMemoryBarrier;
            vertex_buffer_memory_barrier.srcAccessMask = 0;
            vertex_buffer_memory_barrier.dstAccessMask = VK_ACCESS_VERTEX_ATTRIBUTE_READ_BIT;
            vertex_buffer_memory_barrier.srcQueueFamilyIndex = cast(u32) queue_family_indices.transfer_family_index;
            vertex_buffer_memory_barrier.dstQueueFamilyIndex = cast(u32) queue_family_indices.graphics_family_index;
            vertex_buffer_memory_barrier.buffer = vertex_buffer;
            vertex_buffer_memory_barrier.offset = 0;
            vertex_buffer_memory_barrier.size = VK_WHOLE_SIZE;

            index_buffer_memory_barrier : VkBufferMemoryBarrier;
            index_buffer_memory_barrier.srcAccessMask = 0;
            index_buffer_memory_barrier.dstAccessMask = VK_ACCESS_VERTEX_ATTRIBUTE_READ_BIT;
            index_buffer_memory_barrier.srcQueueFamilyIndex = cast(u32) queue_family_indices.transfer_family_index;
            index_buffer_memory_barrier.dstQueueFamilyIndex = cast(u32) queue_family_indices.graphics_family_index;
            index_buffer_memory_barrier.buffer = index_buffer;
            index_buffer_memory_barrier.offset = 0;
            index_buffer_memory_barrier.size = VK_WHOLE_SIZE;

            buffer_memory_barriers : [2] VkBufferMemoryBarrier;
            buffer_memory_barriers[0] = vertex_buffer_memory_barrier;
            buffer_memory_barriers[1] = index_buffer_memory_barrier;

            vkCmdPipelineBarrier(command_buffer,
                                 srcStageMask = VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT,
                                 dstStageMask = VK_PIPELINE_STAGE_VERTEX_INPUT_BIT,
                                 dependencyFlags = 0,
                                 memoryBarrierCount = 0,
                                 pMemoryBarriers = null,
                                 bufferMemoryBarrierCount = buffer_memory_barriers.count,
                                 pBufferMemoryBarriers = buffer_memory_barriers.data,
                                 imageMemoryBarrierCount = 0,
                                 pImageMemoryBarriers = null);
        
        }, semaphore_to_signal = *semaphore, fence_to_signal = *all_finished_fence);
    }

    // @@IMPROVEMENT: Have to wait here since we're going to destroy the staging buffers at the
    // end of this procedure (see defer uses above). If we wanted to not have to wait
    // we could add these to a list with the associated fence and destroy them when the fence
    // is signalled or something.
    wait_result := vkWaitForFences(device, 
                                   fenceCount = 1, 
                                   pFences = *all_finished_fence, 
                                   waitAll = VK_TRUE, 
                                   timeout = 0xFF_FF_FF_FF_FF_FF_FF_FF);
    assert(wait_result == VK_SUCCESS);

    return vertex_buffer, vertex_buffer_memory,
           index_buffer,  index_buffer_memory,
           semaphore, all_finished_fence;
}


vulkan_destroy_buffer :: (using vulkan_context : *Vulkan_Context, buffer : *VkBuffer, device_memory : *VkDeviceMemory)
{
    vkFreeMemory(device, <<device_memory, vulkan_allocator);
    vkDestroyBuffer(device, <<buffer, vulkan_allocator);
    <<device_memory = null;
    <<buffer = null;
}


//
// @@NOTE: For a real application you'd want to split this up into multiple actions for flexibility.
//
// Right now it's use is VERY specific, it only allows to bind the one uniform buffer to the specified set
// and only if the set has no other bindings on it.
//
// To allow for better use of this it would need to split something like this:
//
// - Update the VkBuffer with the actual data of the uniform buffer
// - Allocate the descriptor set for the needed layout (we already have this).
// - Update the descriptor set with all the bindings it might need.
// - Then finally binding the descriptor set.
//
vulkan_example_update_and_bind_uniform_buffer :: (using vulkan_context : *Vulkan_Context, 
                                                  command_buffer : VkCommandBuffer,
                                                  pipeline_layout : VkPipelineLayout,
                                                  descriptor_set_layout : VkDescriptorSetLayout,
                                                  uniform_buffer : VkBuffer, uniform_buffer_memory : VkDeviceMemory,
                                                  buffer_data : $Buffer_Type,
                                                  set : u32,
                                                  binding : u32)
{
    // ## First map the buffer and update it with the provided data (could be done in separate operation really)
    data : *Buffer_Type;
    map_result := vkMapMemory(vulkan_context.device,
                              memory = uniform_buffer_memory,
                              offset = 0,
                              size = size_of(Buffer_Type),
                              flags = 0,
                              ppData = xx *data);
    assert(map_result == VK_SUCCESS);
    <<data = buffer_data;
    vkUnmapMemory(vulkan_context.device, uniform_buffer_memory);

    descriptor_set := vulkan_allocate_descriptor_set(vulkan_context, descriptor_set_layout);
    //
    // You could do a different setup and allocate descriptor sets at the beginning and not
    // free them every frame, which is better for performance maybe in mobile? This tends to
    // be the common solution these days though, allocate every frame and reset the whole pool
    // of descriptors sets when the frame has finished.
    //
    // Also when you use the descriptor set layout here, you're fine picking any that will use this exact set
    // even if you end up using the descriptor in multiple draw-calls. That means that different shaders
    // if they both have the following code for example:
    //
    // 
    //         layout(set = 0, binding = 0) uniform per_frame_data
    //         {
    //             ivec2 something;
    //             float and_something_more;
    //             float why_not_one_more_thing;
    //         };
    // 
    // You should be able to only have to bind this once. This is handy for what we're doing here for example, which is
    // binding a whole uniform buffer that is going to be long lived, in this case for the whole frame. We never
    // need to bind this again until the next frame. You can use this also for per-view data, per-model if you're going
    // to render it multiple times, shared textures that are always the same, anything really :)
    //         

    descriptor_buffer_info : VkDescriptorBufferInfo;
    descriptor_buffer_info.buffer = uniform_buffer;
    descriptor_buffer_info.offset = 0;
    descriptor_buffer_info.range = size_of(Buffer_Type);

    write_descriptor_set : VkWriteDescriptorSet;
    write_descriptor_set.dstSet = descriptor_set;
    write_descriptor_set.dstBinding = binding;
    write_descriptor_set.dstArrayElement = 0;
    write_descriptor_set.descriptorCount = 1;
    write_descriptor_set.descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER; 
    write_descriptor_set.pImageInfo = null; 
    write_descriptor_set.pBufferInfo = *descriptor_buffer_info;
    write_descriptor_set.pTexelBufferView = null;

    vkUpdateDescriptorSets(vulkan_context.device,
                           descriptorWriteCount = 1,
                           pDescriptorWrites = *write_descriptor_set,
                           descriptorCopyCount = 0,
                           pDescriptorCopies = null);
    
    vkCmdBindDescriptorSets(command_buffer, 
                            VK_PIPELINE_BIND_POINT_GRAPHICS, 
                            pipeline_layout,
                            firstSet = set,
                            descriptorSetCount = 1,
                            pDescriptorSets = *descriptor_set,
                            dynamicOffsetCount = 0,
                            pDynamicOffsets  = null);
}


#scope_file


new_temporary_array :: ($Element_Type : Type, initial_reserved_count := 16) -> [..] Element_Type #must
{
    array : [..] Element_Type;
    array.allocator = __temporary_allocator;
    array_reserve(*array, initial_reserved_count);
    return array;
}


strings_to_cstrings :: (array : [] string) -> [..] *u8 #must
{
    new_array := new_temporary_array(*u8);
    for array
        array_add(*new_array, it.data);
    return new_array;
}


fill_extension_set :: (array_of_extension_properties : [] $Extension_Properties_Type) -> Vulkan_Context.Extension_Data.Is_Set
{
    is_set : Vulkan_Context.Extension_Data.Is_Set;
    for properties : array_of_extension_properties
    {
        name := to_string(properties.extensionName.data);
        #insert #run () -> string
        {
            builder: String_Builder;
            defer free_buffers(*builder);
            for Extensions_We_Might_Want
            {
                og_name := it;
                clean_name := cleanup_extension_name(og_name);
                print_to_builder(*builder, "if name == \"%\" is_set.% = true;\n", og_name, clean_name);
            }
            return builder_to_string(*builder);
        }();
    }
    return is_set;
}


get_set_extension_cstrings :: (is_set : Vulkan_Context.Extension_Data.Is_Set) -> [] *u8 #must 
{
    names := new_temporary_array(*u8);
    #insert #run () -> string
    {
        builder: String_Builder;
        defer free_buffers(*builder);
        for Extensions_We_Might_Want
        {
            og_name := it;
            clean_name := cleanup_extension_name(og_name);
            print_to_builder(*builder, "if is_set.%  array_add(*names, \"%\");\n", clean_name, og_name);
        }
        return builder_to_string(*builder);
    }();
    return names;
}


cleanup_extension_name :: (name : string) -> string
{
    beg := "VK_";
    first_3 := name;
    first_3.count = 3;
    assert(beg == first_3);
    new := name;
    new.data += 3;
    new.count -= 3;
    while new[0] != #char "_"
    {
        new.data += 1;
        new.count -= 1;
    }
    new.data += 1;
    new.count -= 1;
    return new;
}



//
// Generates 
//
//      - vulkan_fill_array :: ($type : Type, procedure : $Procedure, WITH_ARGUMENTS_FOR_PROCEDURE_HERE) -> [] type {...}
//        // Use this one when the procedure passed in returns a VkResult so we assert on it.
//
//      - vulkan_fill_array_no_result :: ($type : Type, procedure : $Procedure, WITH_ARGUMENTS_FOR_PROCEDURE_HERE) -> [] type {...}
//        // Use this one when the procedure doesn't return a VkResult or you don't want to check anything.
//
// @@TODO: I would really like to use varargs here, but I found no way to "flatten" it to the be able to call "procedure"
// so for now I'm just generating versions of this procedure with different number of arguments.
//
#insert #run () -> string
{
    FILL_ARRAY_STRING :: #string DONE

    vulkan_fill_array :: ($type : Type, procedure : $Procedure%) -> [] type
    {
        array := new_temporary_array(type, 0);
        count : u32;
        result := procedure(%*count, null);
        assert(result == VK_SUCCESS);
        array_resize(*array, count);
        result = procedure(%*count, array.data);
        assert(result == VK_SUCCESS);
        array.count = xx count;
        return array;
    }

    vulkan_fill_array_no_result :: ($type : Type, procedure : $Procedure%) -> [] type
    {
        array := new_temporary_array(type, 0);
        count : u32;
        procedure(%*count, null);
        array_resize(*array, count);
        procedure(%*count, array.data);
        array.count = xx count;
        return array;
    }
    DONE

    builder : String_Builder;
    free_buffers(*builder);
    for 0..17 
    {
        arguments_builder : String_Builder;
        free_buffers(*arguments_builder);
        forwarding_args_builder : String_Builder;
        free_buffers(*forwarding_args_builder);

        for 0..it-1
        {
            print_to_builder(*arguments_builder, ", argument_% : $Type_%", it, it);
            print_to_builder(*forwarding_args_builder, "argument_%, ", it);
        }

        arguments       := builder_to_string(*arguments_builder);
        forwarding_args := builder_to_string(*forwarding_args_builder);
        print_to_builder(*builder, FILL_ARRAY_STRING, 
                         arguments, 
                         forwarding_args, forwarding_args, 
                         arguments, 
                         forwarding_args, forwarding_args);
    }

    /*
    
    @@NOTE: I would like to be able to derive the return type from the procedure they pass in. This
    would mean that we can get the type of the last argument and use it in the declaration of the procedure
    which I can't find a way to do right now for it to work with polymorphism. Essentially I would like to do something
    like the following:

    test :: ($procedure : $Procedure) -> #insert #run get_array_type(procedure)
    {
        // . . .
    }

    get_array_type :: ($procedure : Procedure) -> string
    {
        info := type_info(procedure);
        argument := info.return_types[info.return_types-1];
        assert(argument.type == Type_Info_Tag.POINTER);
        argument_pointer := cast(*Type_Info_Pointer) argument;
        type_pointed_to := argument_pointer.pointer_to;
        assert(type_pointed_to.type == Type_Info_Tag.STRUCT);
        type_pointed_to_struct := cast(*Type_Info_Struct) type_pointed_to;
        return type_pointer_to_struct.name;
    }

    */
    return builder_to_string(*builder);
}();

alloc_and_copy_array :: (array : [] $T, allocator := context.allocator, allocator_data := context.allocator_data) -> [] T #must
{
    new_array := array;
    new_array.data = xx alloc(array.count * size_of(T), allocator, allocator_data);
    memcpy(new_array.data, array.data, array.count * size_of(T));
    return new_array;
}


copy_array_dst_src :: (dst : [] $T, src : [] T)
{
    assert(dst.count == src.count);
    memcpy(dst.data, src.data, size_of(T) * dst.count);
}


array_contains_string :: (array : [] string, the_string : string) -> bool
{
    for array if it == the_string return true;
    return false;
} 


insert_array_of_bytes :: (name_of_constant : string, filename : string) -> string
{
    builder : String_Builder;
    init_string_builder(*builder);
    defer free_buffers(*builder);
    print_to_builder(*builder, "% :: u8.[ ", name_of_constant);
    data, success := read_entire_file(filename);
    if !success
    {
        print("Couldn't open file % to extract bytes from!!\n", filename);
        exit(0);
    }
    array : [] u8;
    array.data = data.data;
    array.count = data.count;
    for array
    {
        if it_index == array.count - 1
            print_to_builder(*builder, "%", it);
        else
            print_to_builder(*builder, "%, ", it);
    }
    print_to_builder(*builder, "];\n", name_of_constant);
    return builder_to_string(*builder);
}


offset_of :: ($struct_type : Type, name : string) -> offset : int, found : bool
{
    info := type_info(struct_type);
    for info.members
        if it.name == name
            return it.offset_in_bytes, true;
    return 0, false;
}


make_projection_matrix_for_vulkan :: (fov_vertical_in_degrees : float, 
                                      aspect_ratio_horizontal_over_vertical : float, 
                                      near : float, 
                                      far : float) -> Matrix4
{
    /*
    @@NOTE: Vulkan uses +X right, +Y DOWN, and +Z forward for clip space.
    They also have the clip space range being (0,1) instead of (-1,1) like
    other APIs (X and Y are still -1 to 1).

    We're using +X right, +Y up (so we need to negate) and +Z backwards
    (so we need to negate too).
    */
    matrix : Matrix4;
    fov_vertical := fov_vertical_in_degrees * (PI/180.0);
    half_fov_vertical := fov_vertical / 2.0;
    tan_half_fov := tan(half_fov_vertical);
    near_minus_far := near - far;
    matrix._11 = 1.0 / (tan_half_fov * aspect_ratio_horizontal_over_vertical);
    matrix._22 = -1.0 / tan_half_fov; // Negating Y
    matrix._33 = far / near_minus_far;  // Negating Z
    matrix._43 = -1.0; // Negating Z
    matrix._34 = (near * far) / near_minus_far;
    return matrix;
}


prepare_matrix_for_shader :: (matrix : Matrix4) -> Matrix4
{
    // @@NOTE: I have to do this since Vulkan is expecting to receive
    // the base vectors of the matrix contiguous in memory. In this case
    // we're working with column vectors so they expect to get the columns
    // all together. Matrix4 at the time of writing seems to be using
    // column vectors that are layed out in memory in rows, so need to
    // transpose here.
    return transpose(matrix);
}
