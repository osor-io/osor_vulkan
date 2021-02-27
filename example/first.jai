#import "Basic";
#import "String";
#import "File";
#import "Compiler";
#import "Process";

#run
{
    print("\n");
    
    if shader_compiler_available()
    {
        build_shader("src/shaders/fullscreen_example.vert", "src/shaders/built/fullscreen_example.vert.spv");
        build_shader("src/shaders/fullscreen_example.frag", "src/shaders/built/fullscreen_example.frag.spv");
        build_shader("src/shaders/model_example.vert", "src/shaders/built/model_example.vert.spv");
        build_shader("src/shaders/model_example.frag", "src/shaders/built/model_example.frag.spv");
    }
    else
    {
        print("Not building shaders because we couldn't find a compiler to do it\n");
    }

    build_options := get_build_options();
    build_options.output_type = .NO_OUTPUT;
    set_build_options(build_options);
    
    main_workspace := compiler_create_workspace();
    if !main_workspace 
    {
        print("Couldn't create workspace to build the application!!!\n");
        exit(0);
    }
    build_options.output_type = .EXECUTABLE;
    build_options.output_executable_name = "vulkan_example";
    build_options.output_path = concatenate(#filepath, "run_tree/");
	make_directory_if_it_does_not_exist(build_options.output_path);

    new_import_path := string.[
        "../../", // @@NOTE: Relative path to wherever this module is
        "",  
    ];
    new_import_path[1] = build_options.import_path[0];
    build_options.import_path = new_import_path;

    print("\n");
    
    set_build_options(build_options, main_workspace);
    
    compiler_begin_intercept(main_workspace);
    {
        add_build_file("./src/main.jai", main_workspace);

        success_building := false;
        while true {
            message := compiler_wait_for_message();
            if !message  break;

            if message.kind == .COMPLETE 
            {
                success_building = true;
                break;
            }
        }

        if !success_building
        {
            print("We didn't succeed at building our program in workspace\n\n%\n\n", main_workspace);
            exit(0);
        }
    }
    compiler_end_intercept(main_workspace);

}



shader_compiler_available :: () -> bool
{
    success, 
    exit_code, 
    output_string, 
    error_string := os_run_command("glslc", "--version");
    if success print("\n");
    return success;
}

build_shader :: (filename : string, output : string) #expand
{
    success, 
    exit_code, 
    output_string, 
    error_string := os_run_command("glslc", filename, "-o", output);
    if !success
        print("Couldn't build shader %!! Error: %\n", filename, error_string);
    else
        print("Built % to %\n", filename, output);
}


