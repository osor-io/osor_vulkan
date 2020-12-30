#import "Basic";
#import "File";
#import "String";
#import "Hash_Table";
#import "Reflection";




assert_and_error :: (value : bool, format : string = "", args : ..Any, caller_location := #caller_location)
{
    if !value error(format, ..args, caller_location);
} @PrintLike

error :: (format : string = "", args : ..Any, caller_location := #caller_location)
{
    print("\nERROR in %:%\n\n", caller_location.fully_pathed_filename, caller_location.line_number);
    print(format, ..args);
    print("\n\n");
    debug_break();
    assert(false);
} @PrintLike




generate_jai_vulkan_code :: (vk_xml_contents : string) -> header : string, loader : string
{
    print_extension_address :: true;

    //
    // @@NOTE: All this code will probably assume that the text of the
    // tokens is al contiguous in memory, which hopefully it is since there
    // is no reason to copy token text to anywhere else since we read the read
    // the entire file up there.
    //
    // This allows us to concatenate tokens into longers strings easier by just
    // taking the beginning of the first token until the end of the
    // last one.
    //


    root_node := parse_xml(vk_xml_contents);
    // @@TODO: We could do with a way to visualize the tree from root_node
    // here. Just to see if we're missing things or something like that.


    prelude_builder: String_Builder;
    init_string_builder(*prelude_builder);
    append(*prelude_builder, VULKAN_PLATFORM_SELECTION_PRELUDE);
    print_to_builder(*prelude_builder, "% :: enum\n{\n", get_type_name(Vulkan_Platform));
    for get_enum_values(Vulkan_Platform)
    {
        platform := cast(Vulkan_Platform) it;
        print_to_builder(*prelude_builder, "    %;\n", get_enum_name(platform));
    }
    print_to_builder(*prelude_builder, "}\n\n\n\n");
    append(*prelude_builder, VULKAN_GENERAL_PRELUDE);
    defer reset(*prelude_builder);

    enums_builder: String_Builder;
    init_string_builder(*enums_builder);
    print_to_builder(*enums_builder, "// Vulkan Enums:\n\n");
    defer reset(*enums_builder);

    types_builder: String_Builder;
    init_string_builder(*types_builder);
    print_to_builder(*types_builder, "// Vulkan Types:\n\n");
    defer reset(*types_builder);




    Vulkan_Platform :: enum
    {
        None;
        X11;
        Wayland;
        Windows;
        XCB;
        Zircon;
        GGP;
        Android;
        MacOS;
        IDirectFB;
    }

    platform_count :: #run get_enum_count(Vulkan_Platform);
    
    requires_strings_to_platform : Table(string, Vulkan_Platform);
    defer uninit(*requires_strings_to_platform);
    table_add(*requires_strings_to_platform, "X11/Xlib.h",              .X11);
    table_add(*requires_strings_to_platform, "X11/extensions/Xrandr.h", .X11);
    table_add(*requires_strings_to_platform, "wayland-client.h",        .Wayland);
    table_add(*requires_strings_to_platform, "windows.h",               .Windows);
    table_add(*requires_strings_to_platform, "xcb/xcb.h",               .XCB);
    table_add(*requires_strings_to_platform, "zircon/types.h",          .Zircon);
    table_add(*requires_strings_to_platform, "ggp_c/vulkan_types.h",    .GGP);
    table_add(*requires_strings_to_platform, "directfb.h",              .IDirectFB);



    //
    // # Platform Specific Names
    //
    // This arrays per platform will hold the names of the types that are tied to that
    // platform. So if we then want to use them in any way they will need to be put in the
    // header behind an include guard.
    //
    Platform_Specific_Names :: struct
    {
        names : [..] string;
    }
    array_of_platform_specific_names : [platform_count] Platform_Specific_Names;

    add_platform_specific_name :: (requires_string : string, name : string) #expand
    {
        platform, found := table_find(requires_strings_to_platform, requires_string);
        assert(found);
        names := *array_of_platform_specific_names[platform];
        array_add(*names.names, name);
    }

    add_platform_specific_name :: (array_of_platform_specific_names : *[platform_count] Platform_Specific_Names, platform : Vulkan_Platform, name : string)
    {
        names := *((<<array_of_platform_specific_names)[platform]);
        for names.names
        {
            if it == name 
            {
                return;
            }
        }
        array_add(*names.names, name);
    }

    add_platform_specific_name(*array_of_platform_specific_names, .Android, "ANativeWindow");
    add_platform_specific_name(*array_of_platform_specific_names, .Android, "AHardwareBuffer");
    add_platform_specific_name(*array_of_platform_specific_names, .MacOS,   "CAMetalLayer");
    //
    // @@HACK: Have to add these ones here by hand cause they don't follow their own
    // standard as to how to say that a type requires certain platform code :)
    //



    //
    // @@IMPROVEMENT: I don't think this is the case, but I wonder if they can add a type that
    // has a requires="some_other_type" where some other type at the same time has a 
    // requires="windows.h" or something. Making both of them be platform specific. This would
    // make us have to keep that chain or requiring types that require types that require platform types, etc.
    //
    get_type_platform_requirements :: (array_of_names : [] Platform_Specific_Names, type : string) -> bool, Vulkan_Platform
    {
        for array_of_names
        {
            platform := cast(Vulkan_Platform) it_index;
            for it.names
            {
                if it == type
                {
                    assert(platform != .None);
                    return true, platform;
                }
            }
        }
        return false, .None;
    }
    

    Comments_In_Type :: struct
    {
        comments : [..] Comment;
        Comment :: struct
        {
            print_before_nth_member : int;
            text : string;
        }
    }

    Struct_Instance :: struct
    {
        name   : string;
        alias  : string;
        is_union := false;
        struct_extends : string;
        members : [..] Member;
        Member :: struct
        {
            name : string;
            type : string;
            only_value_possible : string;
            is_optional := false;
            pointer_count := 0;
            array_dimensions : [8] string;
            array_dimensions_used := 0;
            bit_field_count := -1;
            comment : string;
        }
        using comments_in_type : Comments_In_Type;
        requires_platform := Vulkan_Platform.None;
        extensions_that_reference_this : [..] string;
    }

    Enum_Instance :: struct
    {
        name   : string;
        alias  : string;
        is_bit_mask := false;
        values : [..] Value;
        Value :: struct
        {
            name  : string;
            value_type := Type.In_String;
            union
            {
                value_in_string : string;
                alias : string;
                value_in_int : s64;
            }
            comment : string;
            is_bit_position := false;

            Type :: enum
            {
                In_String;
                In_Int;
                Is_Alias;
            }
        }
        using comments_in_type : Comments_In_Type;
        who_extended_this : [..] *Node;
        extensions_that_reference_this : [..] string;
    }

    Procedure_Instance :: struct
    {
        name : string;
        alias : string;
        return_type : Type;
        arguments : [..] Argument;
        Argument :: struct
        {
            type : Type;
            name : string;
        }
        Type :: struct
        {
            name : string;
            pointer_count := 0;
            array_counts : [..] string;
        }
        
        requires_platform := Vulkan_Platform.None;
        
        extensions_that_reference_this : [..] string;
    }
    
    Command_Instance :: struct
    {
        using procedure_instance : Procedure_Instance;
        // Commands are treated kind of like an extended procedure
        // for our purposes.

        success_codes : [..] string;
        error_codes : [..] string;

        queues : [..] Queue;
        Queue :: enum
        {
            Transfer;
            Compute;
            Graphics;
        }

        renderpass : Render_Pass;
        Render_Pass :: enum_flags
        {
            Inside;
            Outside;
        }

        command_buffer_level : Command_Buffer_Level;
        Command_Buffer_Level :: enum_flags
        {
            Primary;
            Secondary;
        }

        pipeline : Pipeline;
        Pipeline :: enum
        {
            Graphics;
            Compute;
            Transfer;
        }

        command_kind := Command_Kind.None;
        Command_Kind :: enum
        {
            None;
            Device;
            Instance;
        }

        comment : string;
    }

    Base_Type_Instance :: struct
    {
        name : string;
        alias : string;
    };

    Bitmask_Instance :: struct
    {
        name : string;
        alias : string;
        requires : string;
    };

    Handle_Instance :: struct
    {
        name : string;
        alias : string;
        Type :: enum
        {
            Dispatchable;
            Non_Dispatchable;
        }
        type : Type;
    };

    Extension_Instance :: struct
    {
        name : string;
        number : int;
        type : string;
        author : string;
        contact : string;

        enabled := true;

        defines : [..] Define;
        Define :: struct
        {
            name : string;
            value : string; // Have to deal with &quot
        }
    }




    includes           : [..] string;
    defines            : [..] string;
    structs            : [..] Struct_Instance;
    enums              : [..] Enum_Instance;
    procedure_pointers : [..] Procedure_Instance;
    base_types         : [..] Base_Type_Instance;
    ignored_base_types : [..] string;
    bitmasks           : [..] Bitmask_Instance;
    handles            : [..] Handle_Instance;
    commands           : [..] Command_Instance;
    instance_commands  : [..] *Command_Instance;
    device_commands    : [..] *Command_Instance;
    loader_commands    : [..] *Command_Instance;
    extensions         : [..] Extension_Instance;




    registry_node := find_first_node_with_name_recursive(*root_node, "registry");
    assert(registry_node != null);
    feature_nodes := find_all_nodes_with_name(registry_node, "feature");
    defer array_reset(*feature_nodes);
    assert(feature_nodes.count > 0);
    for feature_node : feature_nodes
    {
        found_number, number := find_attribute_with_name_and_strip(feature_node, "number");
        assert(found_number);
        if string_to_float(number) > string_to_float(max_feature_level_found)
        {
            max_feature_level_found = number;
        }
    }


    // @@NOTE: Purely used to log all the discovered types
    Type_Instance :: struct
    {
        name : string;
        parent : string; // This is either the parent attribute or the alias one
        category : Category;
        index : int; // Index in the array for the category if it exists      

        Category :: enum
        {
            None;
            //
            // @@NOTE: The names of these enum values
            // are being used to compare against the values in the
            // XML so changing them affects that string comparison!
            //
            Include;
            Define;
            Basetype;
            Bitmask;
            Handle;
            Enum;
            Funcpointer;
            Struct;
            Union;
        }
    }
    types : [..] Type_Instance;
    find_parent_of_type :: (types : [] Type_Instance, name : string) -> string
    {
        for * types  if it.name == name  return it.parent;
        return "";
    }



    types_node := find_first_node_with_name_recursive(*root_node, "types");
    for * type : types_node.children
    {
        if type.name != "type" continue;


        using Type_Instance.Category;

        category := None;
        {
            has_category, category_string := find_attribute_with_name_and_strip(type, "category");
            if has_category 
            {
                for Include..Union
                {
                    if equal_nocase(get_enum_name(it), category_string)
                        category = it;
                }
            }
        }

        type_name : string;
        {
            has_name_attribute, name_attribute := find_attribute_with_name_and_strip(type, "name");
            name_node := find_first_node_with_name(type, "name");
            if has_name_attribute && name_node
            {
                error("This tag (%) has both a name attribute and a name child, dunno which one to use", <<type);
            }
            else if has_name_attribute
            {
                type_name = name_attribute;
            }
            else if name_node
            {
                assert(name_node.contents.count == 1);
                type_name = strip_quotes_and_whitespace(name_node.contents[0]);
            }
            
            if !type_name
            {
                error("<type> tag (%) inside <types> has no name when we should be defining it", type);
            }
        }

        has_alias_attribute, alias := find_attribute_with_name_and_strip(type, "alias");

        has_parent, parent_attribute := find_attribute_with_name_and_strip(type, "parent");

        assert(!(has_parent && has_alias_attribute));
        
        type_instance : Type_Instance;
        type_instance.name = type_name;
        if has_parent type_instance.parent = parent_attribute;
        else if has_alias_attribute type_instance.parent = alias;
        type_instance.category = category;

        if #complete category ==
        {
            case None;
            {
                jai_type, matches := c_basic_type_to_jai(type_name);
                if matches
                {
                    // We already deal with the type translation individually later
                }
                else
                {
                    found_requires, requires_attribute := find_attribute_with_name_and_strip(type, "requires");
                    assert(found_requires);
                    add_platform_specific_name(requires_attribute, type_name);
                }
            }

            case Include;
            {
                array_add(*includes, type_name);
                type_instance.index = includes.count - 1;
            }

            case Define;
            {
                if type_name == "VK_HEADER_VERSION"
                {
                    header_version := type.contents[type.contents.count - 1];
                    print_to_builder(*prelude_builder, "VK_HEADER_VERSION :: %;\n", header_version);
                }
                else if type_name == "VK_HEADER_VERSION_COMPLETE"
                {
                    complete_version := type.contents[type.contents.count - 1];
                    print_to_builder(*prelude_builder, "VK_HEADER_VERSION_COMPLETE :: #run VK_MAKE_VERSION%;\n", complete_version);
                }
                else
                {
                    array_add(*defines, type_name);
                    type_instance.index = defines.count - 1;
                }
            }

            case Union; #through;
            case Struct;
            {
                struct_instance : Struct_Instance;
                struct_instance.name = type_name;
                if category == Union
                {
                    struct_instance.is_union = true;
                }

                has_struct_extends, struct_extends := find_attribute_with_name(type, "structextends");
                if has_struct_extends
                {
                    struct_instance.struct_extends = struct_extends;
                }

                if has_alias_attribute
                {
                    struct_instance.alias = alias;
                }
                else
                {
                    for * child : type.children
                    {
                        if child.name == "comment"
                        {
                            comment : Struct_Instance.Comment;
                            comment.print_before_nth_member = struct_instance.members.count;
                            assert(child.contents.count == 1);
                            comment.text = strip_quotes_and_whitespace(child.contents[0]);
                            if comment.text
                                array_add(*struct_instance.comments, comment);
                            continue;
                        }

                        member : Struct_Instance.Member;
                        assert(child.name == "member");

                        {
                            has_value, value := find_attribute_with_name_and_strip(child, "values");
                            only_one_value_possible := has_value && !contains_any(value, ",");
                            if only_one_value_possible
                            {
                                member.only_value_possible = value;
                            }
                        }

                        {
                            has_optional, optional := find_attribute_with_name_and_strip(child, "optional");
                            if has_optional 
                            {
                                if optional == "true" member.is_optional = true;
                            }
                        }

                        type_of_member_node := find_first_node_with_name(child, "type");
                        assert(type_of_member_node.contents.count == 1);
                        member.type = strip_quotes_and_whitespace(type_of_member_node.contents[0]);
                        member.type = c_basic_type_to_jai(member.type);

                        // If any of the members of the struct require a platform then the struct 
                        // needs to inherit that requirement.
                        is_platform_type, platform := get_type_platform_requirements(array_of_platform_specific_names, member.type);
                        if is_platform_type
                        {
                            assert(struct_instance.requires_platform == .None || struct_instance.requires_platform == platform);
                            struct_instance.requires_platform = platform;
                        }

                        name_of_member_node := find_first_node_with_name(child, "name");
                        assert(name_of_member_node.contents.count == 1);
                        member.name = strip_quotes_and_whitespace(name_of_member_node.contents[0]);

                        {
                            comment_of_member_node := find_first_node_with_name(child, "comment");
                            if comment_of_member_node
                            {
                                assert(comment_of_member_node.contents.count == 1);
                                member.comment = strip_quotes_and_whitespace(comment_of_member_node.contents[0]);
                            }
                        }

                        string_after_type := find_contents_after_node(child, type_of_member_node);
                        string_after_name := find_contents_after_node(child, name_of_member_node);
                        
                        find_contents_after_node :: (parent : *Node, child : *Node) -> string
                        {
                            index := -1;
                            for parent.all_contents_or_children
                            {
                                if it.type == Node
                                {
                                    node := *parent.children[it.index];
                                    if node == child
                                    {
                                        index = it_index;
                                    }
                                }
                            }
                            if index == -1 return "";
                            potential_index_of_contents := index + 1;
                            if potential_index_of_contents < parent.all_contents_or_children.count
                            {
                                maybe_contents := parent.all_contents_or_children[potential_index_of_contents];
                                if maybe_contents.type == string
                                {
                                    contents := parent.contents[maybe_contents.index];
                                    return contents;
                                }
                            }
                            return "";
                        }

                        for 0..string_after_type.count-1
                            if string_after_type[it] == #char "*" member.pointer_count += 1;

                        if string_after_name
                        {
                            //
                            // @@NOTE: cause they can decide to slap a tag in the middle of the array
                            // to put an <enum> if we have a "[" we have to look for the closing "]" and
                            // make that the string we're going to use to look for the size. And there can
                            // be multiple [2][3] in a row, so we need to check that too :)
                            //
                            string_after_name = strip_quotes_and_whitespace(string_after_name);
                            {
                                current := string_after_name.data;
                                advanced := false;
                                while <<current == #char "["
                                {
                                    advanced = true;
                                    while <<current != #char "]"
                                    {
                                        current += 1;
                                    }
                                    current += 1;
                                    if <<current == #char " "
                                    {
                                        while <<current == #char " " current += 1;
                                    }
                                }
                                if advanced string_after_name.count = current - string_after_name.data;
                            }

                            // This can have at least bitfields and arrays
                            tokenizer : Tokenizer;
                            init_tokenizer(*tokenizer, string_after_name);
                            tokenize_whole_string(*tokenizer, do_comments=false);
                            defer free(*tokenizer);

                            tokens := tokenizer.tokens;
                            if (tokens.count > 1)
                            {
                                using Token.Type;
                                token := *tokens[0];

                                stop := false;

                                if token.type == Colon
                                {
                                    advance();
                                    assert(token.type == Integer);
                                    member.bit_field_count = string_to_int(token.text);
                                }
                                while !stop
                                {
                                    if token.type == Open_Brackets
                                    {
                                        advance_ignoring_tags();
                                        member.array_dimensions[member.array_dimensions_used] = token.text;
                                        member.array_dimensions_used += 1;
                                        advance_ignoring_tags();
                                        assert(token.type == Close_Brackets);
                                    }
                                    advance();
                                }

                                advance_ignoring_tags :: () #expand
                                {
                                    advance();
                                    if token.type == Less_Than
                                    {
                                        while token.type != More_Than advance();
                                        advance();
                                    }
                                }

                                advance :: () #expand
                                {
                                    keep_advancing := true;
                                    while keep_advancing
                                    {
                                        token += 1;
                                        if token >= tokens.data + tokens.count
                                        {
                                            stop = true;
                                        }

                                        if token.type != Whitespace keep_advancing = false; 
                                    }
                                }
                            }
                        }
                        array_add(*struct_instance.members, member);
                    }
                }
                array_add(*structs, struct_instance);
                type_instance.index = structs.count - 1;
            }

            case Basetype;
            {
                base_type_instance : Base_Type_Instance;
                type_node := find_first_node_with_name(type, "type");
                if type_node
                {
                    assert(type_node != null);
                    assert(type_node.contents.count > 0);
                    right_hand_type := strip_quotes_and_whitespace(type_node.contents[0]);
                    right_hand_type = c_basic_type_to_jai(right_hand_type);
                    base_type_instance.name  = type_name;
                    base_type_instance.alias = right_hand_type;
                    array_add(*base_types, base_type_instance);
                    type_instance.index = base_types.count - 1;
                }
                else
                {
                    array_add(*ignored_base_types, type.all_node_text_content);
                    type_instance.index = ignored_base_types.count - 1;
                    // @@NOTE: At the time of writing basetypes with no type have been included, these are only used
                    // currently for forward declarations of things which this language shouldn't need so we're ignoring
                    // them for now. You can check out the contents with the print below.
                    //print("Found a basetype with no type\nContents:\n%\n\n", type.all_node_text_content); 
                }
            }

            case Bitmask;
            {
                bitmask_instance : Bitmask_Instance;
                bitmask_instance.name  = type_name;
                found_requires, requires_attribute := find_attribute_with_name_and_strip(type, "requires");
                if found_requires
                    bitmask_instance.requires = requires_attribute;

                if has_alias_attribute
                {
                    bitmask_instance.alias = alias;
                }
                else
                {
                    type_node := find_first_node_with_name(type, "type");
                    assert(type_node != null);
                    assert(type_node.contents.count > 0);
                    right_hand_type := type_node.contents[0];
                    bitmask_instance.alias = right_hand_type;
                }
                array_add(*bitmasks, bitmask_instance);
                type_instance.index = bitmasks.count - 1;
            }

            case Handle;
            {
                handle_instance : Handle_Instance;
                handle_instance.name = type_name;
                if has_alias_attribute
                {
                    handle_instance.alias = alias;
                }
                else
                {
                    type_node := find_first_node_with_name(type, "type");
                    assert(type_node != null);
                    assert(type_node.contents.count > 0);
                    type_of_handle := strip_quotes_and_whitespace(type_node.contents[0]);
                    if type_of_handle == "VK_DEFINE_HANDLE"
                        handle_instance.type = Handle_Instance.Type.Dispatchable;
                    else if type_of_handle == "VK_DEFINE_NON_DISPATCHABLE_HANDLE"
                        handle_instance.type = Handle_Instance.Type.Non_Dispatchable;
                    else
                        assert(false);
                }
                array_add(*handles, handle_instance);
                type_instance.index = handles.count - 1;
            }

            case Enum;
                enum_instance : Enum_Instance;
                enum_instance.name = type_name;
                if has_alias_attribute
                {
                    enum_instance.alias = alias;
                }
                if contains(enum_instance.name, "FlagBits")
                {
                    //
                    // @@NOTE: We should be able to detect this later when
                    // reading the <enums> tags BUT this fantastic document that
                    // is vk.xml sometimes has enums defined as a type they never
                    // add any values to (which they don't put on the headers).
                    //
                    // I prefer to have them in the headers if they are on there so
                    // here I'm trying to at least have the correct type...
                    //
                    enum_instance.is_bit_mask = true;
                }
                array_add(*enums, enum_instance);
                type_instance.index = enums.count - 1;

            case Funcpointer;
            {
                using Token.Type;
                procedure_instance : Procedure_Instance;
                procedure_instance.name = type_name;
                contents_or_children := type.all_contents_or_children[0];
                assert(contents_or_children.type == string);

                // Return Value
                {
                    tokenizer : Tokenizer;
                    return_value_string := type.contents[contents_or_children.index];
                    init_tokenizer(*tokenizer, return_value_string);
                    defer free(*tokenizer);
                    tokenize_whole_string(*tokenizer, do_comments = false, ignore_whitespace = true);
                    tokens := tokenizer.tokens;
                    assert(tokens[0].type == Identifier);
                    assert(tokens[0].text == "typedef");
                    assert(tokens[1].type == Identifier);
                    procedure_instance.return_type.name = tokens[1].text;
                    for 0..return_value_string.count-1
                    {
                        if return_value_string[it] == 
                        {
                            case #char "*"; procedure_instance.return_type.pointer_count += 1;
                            case #char "("; break;
                        }
                    }
                }

                // Name of the procedure
                contents_or_children = type.all_contents_or_children[1];
                assert(contents_or_children.type == Node);
                assert(type.children[contents_or_children.index].name == "name");

                // Parentheses to start arguments, or ")(void)"
                has_arguments := true;
                contents_or_children = type.all_contents_or_children[2];
                assert(contents_or_children.type == string);
                {
                    tokenizer : Tokenizer;
                    init_tokenizer(*tokenizer, type.contents[contents_or_children.index]);
                    defer free(*tokenizer);
                    tokenize_whole_string(*tokenizer, do_comments = false, ignore_whitespace = true);
                    tokens := tokenizer.tokens;
                    index := 0;
                    assert(tokens[index].type == Close_Parentheses);
                    index += 1;
                    assert(tokens[index].type == Open_Parentheses);
                    index += 1;
                    if tokens[index].type == Identifier &&
                       tokens[index].text == "void" &&
                       tokens[index+1].type == Close_Parentheses &&
                       tokens[index+2].type == Semicolon
                    {
                        has_arguments = false; // The argument list is "(void)", so no arguments
                    }
                    else
                    {
                        has_arguments = true;
                    }
                }

                // Arguments
                if has_arguments
                {
                    index_of_arguments := 3;
                    while true
                    {
                        argument : Procedure_Instance.Argument;

                        // First we have the <type> tag with the type name inside
                        contents_or_children = type.all_contents_or_children[index_of_arguments];
                        index_of_arguments += 1;
                        assert(contents_or_children.type == Node);
                        node := type.children[contents_or_children.index];
                        assert(node.name == "type");
                        assert(node.contents.count == 1);
                        argument.type.name = strip_quotes_and_whitespace(node.contents[0]);
                    
                        // After the <type> tag we can have pointers, the type, the name and a comma maybe
                        contents_or_children = type.all_contents_or_children[index_of_arguments];
                        index_of_arguments += 1;
                        assert(contents_or_children.type == string);
                        content := type.contents[contents_or_children.index];                    
                        tokenizer : Tokenizer;
                        init_tokenizer(*tokenizer, content);
                        defer free(*tokenizer);
                        tokenize_whole_string(*tokenizer, do_comments = false, ignore_whitespace = true);
                        tokens := tokenizer.tokens;
                        index := 0;
                        for 0..content.count-1
                        {
                            char := content[it];
                            if char == 
                            {
                                case #char "*"; argument.type.pointer_count += 1;
                                case #char ","; break;
                                case #char ";"; break;
                            }
                        }
                        // Go until the comma or semicolon since the name should be before it, if it's not
                        // (because there's arrays or something) then we'll assert and we can look to do 
                        // something better here.
                        while true
                        {
                            if tokens[index].type == Comma
                            {
                                index -= 1;
                                break;
                            }
                            else if tokens[index].type == Semicolon
                            {
                                index -= 2;
                                break;
                            }
                            else
                            {
                                index += 1;
                            }
                        }
                        assert(tokens[index].type == Identifier);
                        argument.name = tokens[index].text;
                        index += 1;

                        while tokens[index].type == Open_Brackets
                        {
                            index += 1;
                            assert(tokens[index].type == Identifier);
                            array_add(*argument.type.array_counts, tokens[index].text);
                            index += 1;
                            assert(tokens[index].type == Close_Brackets);
                            index += 1;
                        }

                        array_add(*procedure_instance.arguments, argument);

                        if tokens[index].type == Comma
                        {
                            // continue iterating, there's more arguments
                        }
                        else if tokens[index].type == Close_Parentheses && tokens[index+1].type == Semicolon
                        {
                            break;
                        }
                    }
                }

                // If any of the arguments or the return type require a platform, then the procedure itself
                // also requires that same platform.
                is_platform_type, platform := get_type_platform_requirements(array_of_platform_specific_names, procedure_instance.return_type.name);
                if is_platform_type
                {
                    assert(procedure_instance.requires_platform == .None || procedure_instance.requires_platform == platform);
                    procedure_instance.requires_platform = platform;
                }
                for * procedure_instance.arguments
                {
                    is_platform_type, platform := get_type_platform_requirements(array_of_platform_specific_names, it.type.name);
                    if is_platform_type
                    {
                        assert(procedure_instance.requires_platform == .None || procedure_instance.requires_platform == platform);
                        procedure_instance.requires_platform = platform;
                    }
                }
    
                array_add(*procedure_pointers, procedure_instance);
                type_instance.index = procedure_pointers.count - 1;
            }
        }

        array_add(*types, type_instance);
    }


    api_constants_attribute : Attribute;
    api_constants_attribute.name = "name";
    api_constants_attribute.value = "API Constants";
    api_constants_node := find_first_node_with_name_and_attribute_value_recursive(*root_node, "enums", api_constants_attribute);
    assert(api_constants_node != null);
    for * constant_tag : api_constants_node.children
    {
        has_alias, alias := find_attribute_with_name_and_strip(constant_tag, "alias");
        has_value, value := find_attribute_with_name_and_strip(constant_tag, "value");
        has_name, name := find_attribute_with_name_and_strip(constant_tag, "name");
        assert(has_name);
        if name == "VK_TRUE"
        {
            // We handle this with out own enum
        }
        else if name == "VK_FALSE"
        {
            // We handle this with out own enum
        }
        else if has_alias
        {
            print_to_builder(*prelude_builder, "% :: %;\n", name, alias);
        }
        else if has_value
        {
            SIZE :: 64;
            buffer : [SIZE] u8;
            value_parsed : string;
            value_parsed.data = buffer.data;

            found_float := false;
            found_unsigned := false;
            found_long := false;

            for 0..value.count
            {
                char := value.data[it];
                if  is_number(char)   ||
                    char == #char ")" ||
                    char == #char "(" ||
                    char == #char "+" ||
                    char == #char "-" ||
                    char == #char "~" ||
                    char == #char "/" ||
                    char == #char "*" 
                {
                    assert(value_parsed.count < SIZE);
                    value_parsed.count += 1;
                    value_parsed[value_parsed.count - 1] = char;
                }
                else if char == #char "."
                {
                    found_float = true;
                    assert(value_parsed.count < SIZE);
                    value_parsed.count += 1;
                    value_parsed[value_parsed.count - 1] = char;
                }
                else if char == #char "f"
                {
                    found_float = true;
                }
                else if char == #char "U" || char == #char "u"
                {
                    found_unsigned = true;
                }
                else if char == #char "L" || char == #char "l"
                {
                    found_long = true;
                }
            }
            if found_float
            {
                print_to_builder(*prelude_builder, "% :float: %;\n", name, value_parsed);
            }
            else if found_unsigned && !found_long
            {
                print_to_builder(*prelude_builder, "% :u32: cast,trunc(u32) %;\n", name, value_parsed);
            }
            else if found_unsigned && found_long
            {
                print_to_builder(*prelude_builder, "% :u64: cast(u64) %;\n", name, value_parsed);
            }
            else
            {
                print_to_builder(*prelude_builder, "% :: %;\n", name, value);
            }
        }
        else
        {
            assert(false);
        }
    }
    print_to_builder(*prelude_builder, "\n\n");
    


    // Parse enums

    for * enums_node : registry_node.children
    {
        if enums_node.name != "enums" continue;

        found_name, name := find_attribute_with_name_and_strip(enums_node, "name");
        assert(found_name);

        if name == "API Constants" continue;

        found_type, type := find_attribute_with_name_and_strip(enums_node, "type");
        assert(found_type);

        enum_instance : *Enum_Instance;
        for * enums
        {
            if it.name == name enum_instance = it;
        }
        
        if enum_instance == null
        {
            //
            // @@HACK: Oh ffs, they have some enums that are not defined in the
            // types section so we have to patch them here... great job guys :)
            //
            new_enum_instance := array_add(*enums);
            new_enum_instance.name = name;
            enum_instance = new_enum_instance;
        }

        if type == 
        {
            case "enum";
            case "bitmask"; enum_instance.is_bit_mask |= true;
            case; assert(false);
        }

        for * enum_node : enums_node.children
        {
            if enum_node.name == "unused" continue; 
            else if enum_node.name == "comment"
            {
                comment : Enum_Instance.Comment;
                comment.print_before_nth_member = enum_instance.values.count;
                assert(enum_node.contents.count == 1);
                comment.text = strip_quotes_and_whitespace(enum_node.contents[0]);
                if comment.text
                    array_add(*enum_instance.comments, comment);
            }
            else if enum_node.name == "enum"
            {
                enum_value : Enum_Instance.Value;

                found_alias, alias := find_attribute_with_name_and_strip(enum_node, "alias");
                found_value, value := find_attribute_with_name_and_strip(enum_node, "value");
                found_bitpos, bitpos := find_attribute_with_name_and_strip(enum_node, "bitpos");
                found_a_value := found_value || found_bitpos;

                assert(  found_a_value || found_alias);   // We need one of them
                assert(!(found_a_value && found_alias));  // But not both of them
                assert(!(found_bitpos && found_value));   // We can only have either a value of a bit position

                if found_alias 
                {
                    enum_value.value_type = Enum_Instance.Value.Type.Is_Alias;
                    enum_value.alias = alias;
                }
                else if found_value 
                {
                    enum_value.value_type = Enum_Instance.Value.Type.In_String;
                    enum_value.value_in_string = value;
                }
                else if found_bitpos
                {
                    assert(type == "bitmask");
                    enum_value.value_type = Enum_Instance.Value.Type.In_String;
                    enum_value.value_in_string = bitpos;
                    enum_value.is_bit_position = true;
                }

                found_name, name := find_attribute_with_name_and_strip(enum_node, "name");
                assert(found_name);
                enum_value.name = name;

                found_comment, comment := find_attribute_with_name_and_strip(enum_node, "comment");
                if found_comment
                {
                    enum_value.comment = comment;
                }
                array_add(*enum_instance.values, enum_value);
            }
            else
            {
                error("Unsupported tag inside <enums> [%]\n", enum_node.name);
                assert(false);
            }
        }
    }

    find_enum :: (enums : *[..] Enum_Instance, name : string) -> *Enum_Instance
    {
        for * enum_instance : <<enums
        {
            if enum_instance.name == name return enum_instance;
        }
        return null;
    }

    extend_enum :: (node_that_owns_extension : *Node, enum_name : string, value_name : string, value : string, dir := "", comment := "") #expand
    {
        using Enum_Instance.Value.Type;
        instance := find_enum(*enums, enum_name);
        if !enum_value_already_on_enum(instance, value_name)
        {
            register_who_modified_enum(instance, node_that_owns_extension);
            enum_value : Enum_Instance.Value;
            enum_value.name = value_name;
            enum_value.value_type = In_Int;
            int_value, success := string_to_int(value);
            assert(int_value >= 0);
            if dir == "-" int_value = -int_value;
            assert(success);
            enum_value.value_in_int = int_value;
            enum_value.comment = comment;
            array_add(*instance.values, enum_value);
        }
    }

    extend_enum :: (node_that_owns_extension : *Node, enum_name : string, value_name : string, extension_number : string, offset : string, dir := "", comment := "") #expand
    {
        using Enum_Instance.Value.Type;
        instance := find_enum(*enums, enum_name);
        if !enum_value_already_on_enum(instance, value_name)
        {
            register_who_modified_enum(instance, node_that_owns_extension);
            enum_value : Enum_Instance.Value;
            enum_value.name = value_name;

            enum_value.value_type = In_Int;

            offset_value, offset_success := string_to_int(offset);
            assert(offset_success);
            assert(offset_value >= 0);

            extension_number_value, extension_number_success := string_to_int(extension_number);
            assert(extension_number_success);
            assert(extension_number_value >= 0);

            int_value := 1_000_000_000 + ((extension_number_value-1) * 1_000) + offset_value;
            assert(int_value >= 0);

            if dir == "-" int_value = -int_value;

            enum_value.value_in_int = int_value;
            enum_value.comment = comment;
            array_add(*instance.values, enum_value);
        }
    }

    extend_enum :: (node_that_owns_extension : *Node, enum_name : string, value_name : string, alias : string, comment := "") #expand
    {
        using Enum_Instance.Value.Type;
        instance := find_enum(*enums, enum_name);
        if !enum_value_already_on_enum(instance, value_name)
        {
            register_who_modified_enum(instance, node_that_owns_extension);
            enum_value : Enum_Instance.Value;
            enum_value.name = value_name;
            enum_value.value_type = Is_Alias;
            enum_value.alias = alias;
            enum_value.comment = comment;
            array_add(*instance.values, enum_value);
        }
    }

    extend_enum_flags :: (node_that_owns_extension : *Node, enum_name : string, value_name : string, bit_position : string, comment := "") #expand
    {
        using Enum_Instance.Value.Type;
        instance := find_enum(*enums, enum_name);
        if !enum_value_already_on_enum(instance, value_name)
        {
            register_who_modified_enum(instance, node_that_owns_extension);
            instance.is_bit_mask |= true;
            enum_value : Enum_Instance.Value;
            enum_value.name = value_name;
            enum_value.value_type = In_String;
            enum_value.value_in_string = bit_position;
            enum_value.is_bit_position = true;
            enum_value.comment = comment;
            array_add(*instance.values, enum_value);
        }
    }

    enum_value_already_on_enum :: (instance : *Enum_Instance, name : string) -> bool
    {
        //
        // @@HACK: Sigh... they add the same enum values from multiple extensions/feature levels
        // 
        for * instance.values
            if it.name == name 
                return true;

        return false;
    }

    register_who_modified_enum :: (instance : *Enum_Instance, node : *Node)
    {
        for instance.who_extended_this
            if it == node return;
        
        array_add(*instance.who_extended_this, node);
        comment : Enum_Instance.Comment;
        comment.print_before_nth_member = instance.values.count;

        builder: String_Builder;    // @@ Declare this inside Log to avoid reallocation? @@ It would have to be thread local.
        defer free_buffers(*builder);

        if node.name == "feature"
        {
            found_api, api := find_attribute_with_name_and_strip(node, "api");
            found_number, number := find_attribute_with_name_and_strip(node, "number");
            assert(found_api);
            assert(found_number);
            print_to_builder(*builder, "Added in % %", api, number);
        }
        else if node.name == "extension"
        {
            found_name, name := find_attribute_with_name_and_strip(node, "name");
            assert(found_name);
            print_to_builder(*builder, "Added for extension %\n", name);
            #if print_extension_address
            {
                print_address_of_manual_for_extension(*builder, name);
            }
        }
        else
        {
            assert(false);
        }
        comment.text = builder_to_string(*builder, __temporary_allocator);
        array_add(*instance.comments, comment);
    }



    // Parse commands

    commands_node := find_first_node_with_name_recursive(*root_node, "commands");
    command_nodes := find_all_nodes_with_name(commands_node, "command");
    defer array_reset(*command_nodes);

    printed_attributes : [..] string;
    for command_node : command_nodes
    {
        command_instance : Command_Instance;
        
        found_name , name_attribute  := find_attribute_with_name_and_strip(command_node, "name");
        found_alias, alias_attribute := find_attribute_with_name_and_strip(command_node, "alias");

        found_successcodes , successcodes_attribute   := find_attribute_with_name_and_strip(command_node, "successcodes");
        found_errorcodes   , errorcodes_attribute     := find_attribute_with_name_and_strip(command_node, "errorcodes");
        if found_successcodes
            for split(successcodes_attribute, ",")
                array_add(*command_instance.success_codes, it);
        if found_errorcodes
            for split(errorcodes_attribute, ",")
                array_add(*command_instance.error_codes, it);

        found_queues, queues_attribute := find_attribute_with_name_and_strip(command_node, "queues");
        if found_queues
            for split(queues_attribute, ",")
            {
                if it ==
                {
                    case "graphics"; array_add(*command_instance.queues, Command_Instance.Queue.Graphics);
                    case "transfer"; array_add(*command_instance.queues, Command_Instance.Queue.Transfer);
                    case "compute";  array_add(*command_instance.queues, Command_Instance.Queue.Compute);
                    case "sparse_binding"; // @@HACK: Not sure what this means but doesn't make sense to be in the "queues" attribute
                    case; assert(false);
                }
            }
        
        found_renderpass, renderpass_attribute := find_attribute_with_name_and_strip(command_node, "renderpass");
        if found_renderpass
            if renderpass_attribute ==
            {
                case "inside";  command_instance.renderpass |= Command_Instance.Render_Pass.Inside;
                case "outside"; command_instance.renderpass |= Command_Instance.Render_Pass.Outside;
                case "both";    
                    command_instance.renderpass |= Command_Instance.Render_Pass.Inside;
                    command_instance.renderpass |= Command_Instance.Render_Pass.Outside;
                case; assert(false);
            }

        found_cmdbufferlevel, cmdbufferlevel_attribute := find_attribute_with_name_and_strip(command_node, "cmdbufferlevel");
        if found_cmdbufferlevel
            for split(cmdbufferlevel_attribute, ",")
            {
                if it ==
                {
                    case "primary";    command_instance.command_buffer_level |= Command_Instance.Command_Buffer_Level.Primary;
                    case "secondary";  command_instance.command_buffer_level |= Command_Instance.Command_Buffer_Level.Secondary;
                    case; assert(false);
                }
            }
        
        found_pipeline, pipeline_attribute := find_attribute_with_name_and_strip(command_node, "pipeline");
        if found_pipeline
            if pipeline_attribute ==
            {
                case "graphics"; command_instance.pipeline = Command_Instance.Pipeline.Graphics;
                case "compute";  command_instance.pipeline = Command_Instance.Pipeline.Compute;
                case "transfer"; command_instance.pipeline = Command_Instance.Pipeline.Transfer;
                case; assert(false);
            }

        found_comment, comment_attribute := find_attribute_with_name_and_strip(command_node, "comment");
        if found_comment
            command_instance.comment = comment_attribute;

        if found_alias
        {
            assert(found_name);
            command_instance.name = name_attribute;
            command_instance.alias = alias_attribute;
        }
        else
        {
            parse_argument :: (root : *Node) -> Command_Instance.Argument
            {
                using Token.Type;
                argument : Command_Instance.Argument;

                index_of_arguments := 0;
                contents_or_children := root.all_contents_or_children[index_of_arguments];
                if contents_or_children.type == string
                {
                    contents := strip_quotes_and_whitespace(root.contents[contents_or_children.index]);
                    assert(contents == "const" || contents == "struct" || contents == "const struct");
                    // But really we don't care about const :)
                    index_of_arguments += 1;
                }

                // The <type> tag with the type name inside
                contents_or_children = root.all_contents_or_children[index_of_arguments];
                index_of_arguments += 1;
                assert(contents_or_children.type == Node);
                node := root.children[contents_or_children.index];
                assert(node.name == "type");
                assert(node.contents.count == 1);
                argument.type.name = strip_quotes_and_whitespace(node.contents[0]);
            
                // After the <type> tag we can have pointers ("*") before the name
                contents_or_children = root.all_contents_or_children[index_of_arguments];
                if contents_or_children.type == string
                {
                    // We have some text after the type!
                    content := strip_quotes_and_whitespace(root.contents[contents_or_children.index]);
                    tokenizer : Tokenizer;
                    init_tokenizer(*tokenizer, content);
                    defer free(*tokenizer);
                    tokenize_whole_string(*tokenizer, do_comments = false, ignore_whitespace = true);
                    tokens := tokenizer.tokens;
                    for tokens
                    {
                        if      it.type == Asterisk  argument.type.pointer_count += 1;
                        else if it.type == Identifier
                        {
                            // If we find a "const" we just ignore it, if it's something else
                            // there might be something needed we're not accounting for!!
                            assert(it.text == "const");
                        }
                    }

                    index_of_arguments += 1;
                }
                
                // Now we get the "name" node and get the name of the argument
                contents_or_children = root.all_contents_or_children[index_of_arguments];
                index_of_arguments += 1;
                node = root.children[contents_or_children.index];
                assert(contents_or_children.type == Node);
                assert(node.name == "name");
                assert(node.contents.count == 1);
                argument.name = strip_quotes_and_whitespace(node.contents[0]);

                // After the name of the argument we may have array declarations!
                if index_of_arguments < root.all_contents_or_children.count
                {
                    contents_or_children = root.all_contents_or_children[index_of_arguments];
                    index_of_arguments += 1;
                    assert(contents_or_children.type == string);
                    content := strip_quotes_and_whitespace(root.contents[contents_or_children.index]);
                    tokenizer : Tokenizer;
                    init_tokenizer(*tokenizer, content);
                    defer free(*tokenizer);
                    tokenize_whole_string(*tokenizer, do_comments = false, ignore_whitespace = true);
                    tokens := tokenizer.tokens;
                    index := 0;
                    while tokens[index].type == Open_Brackets
                    {
                        index += 1;
                        array_add(*argument.type.array_counts, tokens[index].text);
                        index += 1;
                        assert(tokens[index].type == Close_Brackets);
                        index += 1;
                    }
                }

                return argument;
            }
            proto_node := find_first_node_with_name(command_node, "proto");
            assert(proto_node != null);

            argument_that_is_just_the_return_type_and_name := parse_argument(proto_node);
            // Taking advantage that the return type and name of the procedure in the xml
            // are exactly set-up as the arguments, just that the name of the "argument" would
            // be the name of the procedure.

            command_instance.return_type = argument_that_is_just_the_return_type_and_name.type;
            command_instance.name = argument_that_is_just_the_return_type_and_name.name;

            param_nodes := find_all_nodes_with_name(command_node, "param");
            defer array_reset(*param_nodes);
            for param_node : param_nodes
            {
                argument := parse_argument(param_node);
                array_add(*command_instance.arguments, argument);
            }

            // If the command's return type or arguments require a platform, then the command itself
            // requires that platform too.
            is_platform_type, platform := get_type_platform_requirements(array_of_platform_specific_names, command_instance.return_type.name);
            if is_platform_type
            {
                assert(command_instance.requires_platform == .None || command_instance.requires_platform == platform);
                command_instance.requires_platform = platform;
            }
            for * command_instance.arguments
            {
                is_platform_type, platform := get_type_platform_requirements(array_of_platform_specific_names, it.type.name);
                if is_platform_type
                {
                    assert(command_instance.requires_platform == .None || command_instance.requires_platform == platform);
                    command_instance.requires_platform = platform;
                }
            }

        }
        array_add(*commands, command_instance);
    }



    // Look at feature nodes (for Vulkan 1.0, 1.1, 1.2, etc.) to extend enums
    
    for feature_node : feature_nodes
    {
        all_enum_extends := find_all_nodes_with_name_and_attribute_recursive(feature_node, "enum", "extends");
        defer array_reset(*all_enum_extends);
        for enum_extend_node : all_enum_extends
        {
            found_value,     value_string      := find_attribute_with_name_and_strip(enum_extend_node, "value");
            found_offset,    offset_string     := find_attribute_with_name_and_strip(enum_extend_node, "offset");
            found_alias,     alias_string      := find_attribute_with_name_and_strip(enum_extend_node, "alias");
            found_bitpos,    bitpos_string     := find_attribute_with_name_and_strip(enum_extend_node, "bitpos");
            found_dir,       dir_string        := find_attribute_with_name_and_strip(enum_extend_node, "dir");
            found_extends,   extends_string    := find_attribute_with_name_and_strip(enum_extend_node, "extends");
            found_extnumber, extnumber_string  := find_attribute_with_name_and_strip(enum_extend_node, "extnumber");
            found_name,      name_string       := find_attribute_with_name_and_strip(enum_extend_node, "name");
            found_comment,   comment_string    := find_attribute_with_name_and_strip(enum_extend_node, "comment");

            if found_alias
            {
                assert(found_name);
                assert(found_alias);
                assert(found_extends);
                assert(!found_dir);
                extend_enum(node_that_owns_extension = feature_node,
                            enum_name = extends_string, 
                            value_name = name_string, 
                            alias = alias_string,
                            comment = comment_string);
            }
            else if found_bitpos
            {
                assert(found_name);
                assert(found_bitpos);
                assert(found_extends);
                assert(!found_dir);
                extend_enum_flags(node_that_owns_extension = feature_node,
                                  enum_name = extends_string, 
                                  value_name = name_string, 
                                  bit_position = bitpos_string,
                                  comment = comment_string);
            }
            else if found_value
            {
                assert(found_name);
                assert(found_extends);
                assert(found_value);
                extend_enum(node_that_owns_extension = feature_node,
                            enum_name = extends_string, 
                            value_name = name_string, 
                            value = value_string, 
                            dir = dir_string,
                            comment = comment_string);
            }
            else
            {
                assert(found_name);
                assert(found_extnumber);
                assert(found_extends);
                assert(found_offset);
                extend_enum(node_that_owns_extension = feature_node,
                            enum_name = extends_string, 
                            value_name = name_string, 
                            extension_number = extnumber_string, 
                            offset = offset_string, 
                            dir = dir_string,
                            comment = comment_string);
            }
        }
    }



    // Parse extensions

    parent_extensions_node := find_first_node_with_name(registry_node, "extensions");
    assert(parent_extensions_node != null);
    extensions_nodes := find_all_nodes_with_name(parent_extensions_node, "extension");
    defer array_reset(*extensions_nodes);
    for extension_node : extensions_nodes
    {
        found_extension_name, extension_name := find_attribute_with_name_and_strip(extension_node, "name");
        found_extension_number, extension_number := find_attribute_with_name_and_strip(extension_node, "number");
        found_extension_type, extension_type := find_attribute_with_name_and_strip(extension_node, "type");
        found_extension_author, extension_author := find_attribute_with_name_and_strip(extension_node, "author");
        found_extension_contact, extension_contact := find_attribute_with_name_and_strip(extension_node, "contact");
        found_extension_supported, extension_supported := find_attribute_with_name_and_strip(extension_node, "supported");
        if found_extension_type assert(extension_type == "instance" || extension_type == "device");
        
        extension_instance : Extension_Instance;
        assert(found_extension_name);
        extension_instance.name = extension_name;
        assert(found_extension_number);
        extension_instance.number = string_to_int(extension_number);
        if found_extension_type     extension_instance.type = extension_type;
        if found_extension_author   extension_instance.author = extension_author;
        if found_extension_contact  extension_instance.contact = extension_contact;

        all_enum_extends := find_all_nodes_with_name_and_attribute_recursive(extension_node, "enum", "extends");
        defer array_reset(*all_enum_extends);
        found_number, number_string := find_attribute_with_name_and_strip(extension_node, "number");
        for enum_extend_node : all_enum_extends
        {
            found_value,     value_string      := find_attribute_with_name_and_strip(enum_extend_node, "value");
            found_offset,    offset_string     := find_attribute_with_name_and_strip(enum_extend_node, "offset");
            found_alias,     alias_string      := find_attribute_with_name_and_strip(enum_extend_node, "alias");
            found_bitpos,    bitpos_string     := find_attribute_with_name_and_strip(enum_extend_node, "bitpos");
            found_dir,       dir_string        := find_attribute_with_name_and_strip(enum_extend_node, "dir");
            found_extends,   extends_string    := find_attribute_with_name_and_strip(enum_extend_node, "extends");
            found_extnumber, extnumber_string  := find_attribute_with_name_and_strip(enum_extend_node, "extnumber");
            found_name,      name_string       := find_attribute_with_name_and_strip(enum_extend_node, "name");
            found_comment,   comment_string    := find_attribute_with_name_and_strip(enum_extend_node, "comment");

            if !found_extnumber
            {
                assert(found_number);
                extnumber_string = number_string;
                found_extnumber = true;
            }

            if found_alias
            {
                assert(found_name);
                assert(found_alias);
                assert(found_extends);
                assert(!found_dir);
                extend_enum(node_that_owns_extension = extension_node,
                            enum_name = extends_string, 
                            value_name = name_string, 
                            alias = alias_string,
                            comment = comment_string);
            }
            else if found_bitpos
            {
                assert(found_name);
                assert(found_bitpos);
                assert(found_extends);
                assert(!found_dir);
                extend_enum_flags(node_that_owns_extension = extension_node,
                                  enum_name = extends_string, 
                                  value_name = name_string, 
                                  bit_position = bitpos_string,
                                  comment = comment_string);
            }
            else if found_value
            {
                assert(found_name);
                assert(found_extends);
                assert(found_value);
                extend_enum(node_that_owns_extension = extension_node,
                            enum_name = extends_string, 
                            value_name = name_string, 
                            value = value_string, 
                            dir = dir_string,
                            comment = comment_string);
            }
            else
            {
                assert(found_name);
                assert(found_extnumber);
                assert(found_extends);
                assert(found_offset);
                extend_enum(node_that_owns_extension = extension_node,
                            enum_name = extends_string, 
                            value_name = name_string, 
                            extension_number = extnumber_string, 
                            offset = offset_string, 
                            dir = dir_string,
                            comment = comment_string);
            }
        }

        all_type_references := find_all_nodes_with_name_and_attribute_recursive(extension_node, "type", "name");
        defer array_reset(*all_type_references);
        for type_reference_node : all_type_references
        {
            found_name, name := find_attribute_with_name_and_strip(type_reference_node, "name");
            assert(found_name);

            for * struct_instance : structs
                if struct_instance.name == name
                    array_add(*struct_instance.extensions_that_reference_this, extension_name);

            for * enum_instance : enums
                if enum_instance.name == name
                    array_add(*enum_instance.extensions_that_reference_this, extension_name);

            for * procedure_pointer_instance : procedure_pointers
                if procedure_pointer_instance.name == name
                    array_add(*procedure_pointer_instance.extensions_that_reference_this, extension_name);
                    
        }

        all_command_references := find_all_nodes_with_name_and_attribute_recursive(extension_node, "command", "name");
        defer array_reset(*all_command_references);
        for command_reference_node : all_command_references
        {
            found_name, name := find_attribute_with_name_and_strip(command_reference_node, "name");
            assert(found_name);
            
            found_command_instance : *Command_Instance;
            for * command_instance : commands
            {
                if command_instance.name == name
                {
                    found_command_instance = command_instance;
                    array_add(*command_instance.extensions_that_reference_this, extension_name);
                }
            }
            assert(found_command_instance != null);

            if found_extension_type
            {
                if extension_type == "device"
                    found_command_instance.command_kind = Command_Instance.Command_Kind.Device;
                else if extension_type == "instance"
                    found_command_instance.command_kind = Command_Instance.Command_Kind.Instance;
                else
                    assert(false);
            }
        }



        if found_extension_supported && extension_supported == "disabled"
        {
            extension_instance.enabled = false;
        }

        all_enum_non_extends := find_all_nodes_with_name_and_not_attribute_recursive(extension_node, "enum", "extends");
        defer array_reset(*all_enum_non_extends );

        for enum_node : all_enum_non_extends
        {
            found_name, name_attribute := find_attribute_with_name_and_strip(enum_node, "name");
            found_value, value_attribute := find_attribute_with_name_and_strip(enum_node, "value");
            found_alias, alias_attribute := find_attribute_with_name_and_strip(enum_node, "alias");
            assert(found_name);

            define_instance : Extension_Instance.Define;
            define_instance.name  = name_attribute;

            if found_value
                define_instance.value = fix_xml_ampersand_shit_in_place(value_attribute);
            else if found_alias
                define_instance.value = strip_quotes_and_whitespace(alias_attribute);
            else
            {
                assert_and_error(enum_node.attributes.count == 1);
                assert_and_error(enum_node.all_contents_or_children.count == 0);
                // @@NOTE: If the node only has a name it must be defined somewhere else, which
                // seems like it's in the "API Constants" <enums> node.
            }

            array_add(*extension_instance.defines, define_instance);
        }

        array_add(*extensions, extension_instance);
    }



    // Fixing platform requirements and type aliasing

    //
    // @@NOTE @@IMPROVEMENT
    //
    // There's multiple things we need to care about, types and alias other types and types can contain or
    // reference types that require a platform. So we have to handle both problems. We need to look at all the
    // types that are aliases of other types and make them inherit their requirements. But we also need to
    // look at all the types involved in a type (struct) or a command (arguments) and update the requirements of these.
    //
    // The problem is that when we do any of those two things we might need to repeat the other, since if a type that
    // aliases another should be updated if that other one changes.
    //
    // We could do with a system that has references to the aliased types. So when we encounter an alias, instead of
    // just working with names we can point at the type that we're aliasing, and the "parent" type can point to all types
    // that alias it. This would make it so when we need to update a type we just have to traverse the "alias" chain of all
    // the types it has and check if any of them hit a "requires" for a platform.
    //
    // In practice, alias levels tend to be just 1, and type requirements don't have to trickle down very deep, so doing
    // this only once does the trick.
    //

    fix_platform_requirements_of_all_aliased_types :: () #expand
    {
        fixup_platform_requirements_of_aliased_types(structs);
        fixup_platform_requirements_of_aliased_types(procedure_pointers);
        fixup_platform_requirements_of_aliased_types(commands);
        fixup_platform_requirements_of_aliased_types :: (instances : [] $Instance_Type)
        {
            for * instance : instances
            {
                if instance.alias
                {
                    non_aliased := find_non_aliased_instance(instances, instance.alias);
                    assert_and_error(non_aliased != null);
                    assert_and_error(instance.requires_platform == .None);
                    assert_and_error(!non_aliased.alias);
                    instance.requires_platform = non_aliased.requires_platform;
                }
            }
        }
    }
    find_non_aliased_instance :: (instances : [] $Instance_Type, alias : string) -> *Instance_Type
    {
        for * instance : instances
        {
            if alias == instance.name
            {
                if instance.alias
                    return find_non_aliased_instance(instances, instance.alias);
                else
                    return instance;
            }
        }
        return null;
    }

    // First we fix the aliased types to update them with the current platform requirements of the type they alias
    fix_platform_requirements_of_all_aliased_types();

    // Then we iterate through the members of the structs to find out if because of their members they need to be a platform
    // specific type
    for * struct_instance : structs
    {
        for * member : struct_instance.members
        {
            name := member.type;
            requires_platform, platform := get_type_platform_requirements(array_of_platform_specific_names, name);
            if requires_platform
            {
                add_platform_specific_name(*array_of_platform_specific_names, platform, struct_instance.name);
                fixup_requirements_after_changing_type(structs, *array_of_platform_specific_names, struct_instance.name, platform);
            }
        }
    }
    
    fixup_requirements_after_changing_type :: (structs : [] Struct_Instance, array_of_platform_specific_names : *[platform_count] Platform_Specific_Names, name_of_type : string, now_requires_platform : Vulkan_Platform)
    {
        for * struct_instance : structs
        {
            for * member : struct_instance.members
            {
                if name_of_type == member.type
                {
                    requires_platform, platform := get_type_platform_requirements(<<array_of_platform_specific_names, member.type);
                    if requires_platform
                    {
                        assert(platform == now_requires_platform);
                    }
                    else
                    {
                        assert(platform == .None || platform == now_requires_platform);
                        add_platform_specific_name(array_of_platform_specific_names, now_requires_platform, struct_instance.name);
                        fixup_requirements_after_changing_type(structs, array_of_platform_specific_names, struct_instance.name, now_requires_platform);
                    }
                }
            }
        }
    }

    // Then here we iterate through all the commands and procedure pointers to see if any of the arguments they use are of a platform specific type, 
    // in which case they need to be updated to say they are also tied to a platform.
    for * command_instance : commands
    {
        update_requiremens_for_type(command_instance, command_instance.return_type.name, array_of_platform_specific_names);
        for * command_instance.arguments
               update_requiremens_for_type(command_instance, it.type.name, array_of_platform_specific_names);
    }
    for * procedure_instance : procedure_pointers
    {
        update_requiremens_for_type(procedure_instance, procedure_instance.return_type.name, array_of_platform_specific_names);
        for * procedure_instance.arguments
               update_requiremens_for_type(procedure_instance, it.type.name, array_of_platform_specific_names);
    }

    update_requiremens_for_type :: (instance : $Instance_Type, type_name : string, array_of_platform_specific_names : [] Platform_Specific_Names)
    {
        requires_platform, platform := get_type_platform_requirements(array_of_platform_specific_names, type_name);
        if requires_platform
        {
            assert(instance.requires_platform == platform || instance.requires_platform == .None);
            instance.requires_platform = platform;
        }
    }

    // And finally since some types might have changed requirements that were aliased by someone
    // we do this again just to catch those.
    fix_platform_requirements_of_all_aliased_types();



    // Finding out which commands are loader, instance or device commands

    for * command_instance : commands
    {
        //
        // @@HACK: Ok so the way these people decide if a command is instance or device (or none) is a bit
        // fucked up. First, if they are in an extension and said extension is either device or instance then
        // all the commands there become device/instance. But you are also instructed to look at the first argument
        // of the command and see if the "parent" of it is VkInstance or VkDevice to decide if it is.
        //
        // Well, guess what, there is a list of commands which seem to be the following ones at least
        //
        //       -  vkGetPhysicalDevicePresentRectanglesKHR                           -> extension said device first argument indicates instance
        //       -  vkGetPhysicalDeviceMultisamplePropertiesEXT                       -> extension said device first argument indicates instance
        //       -  vkGetPhysicalDeviceCalibrateableTimeDomainsEXT                    -> extension said device first argument indicates instance
        //       -  vkSetDebugUtilsObjectNameEXT                                      -> extension said instance first argument indicates device
        //       -  vkSetDebugUtilsObjectTagEXT                                       -> extension said instance first argument indicates device
        //       -  vkQueueBeginDebugUtilsLabelEXT                                    -> extension said instance first argument indicates device
        //       -  vkQueueEndDebugUtilsLabelEXT                                      -> extension said instance first argument indicates device
        //       -  vkQueueInsertDebugUtilsLabelEXT                                   -> extension said instance first argument indicates device
        //       -  vkCmdBeginDebugUtilsLabelEXT                                      -> extension said instance first argument indicates device
        //       -  vkCmdEndDebugUtilsLabelEXT                                        -> extension said instance first argument indicates device
        //       -  vkCmdInsertDebugUtilsLabelEXT                                     -> extension said instance first argument indicates device
        //       -  vkGetPhysicalDeviceCooperativeMatrixPropertiesNV                  -> extension said device first argument indicates instance
        //       -  vkGetPhysicalDeviceSurfacePresentModes2EXT                        -> extension said device first argument indicates instance
        //       -  vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR   -> extension said device first argument indicates instance
        //       -  vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR           -> extension said device first argument indicates instance
        //       -  vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV -> extension said device first argument indicates instance
        //       -  vkGetPhysicalDeviceToolPropertiesEXT                              -> extension said device first argument indicates instance
        //
        // were the extension sais one thing and the first argument says another! Yayyyy!! Great job!
        //
        // So for this case I'm trying to evaluate how Volk from Zeux (https://github.com/zeux/volk/blob/master/generate.py) does this. Although
        // it looks to me when looking at the list that the first argument seems to be right? Not the extension type. So I'm going to go for that
        // for now and see where we end up.
        // 
        //
        og_command := command_instance;
        if command_instance.alias
        {
            command_instance = find_non_aliased_instance(commands, command_instance.alias);
            assert(command_instance != null);
        }
        if command_instance.arguments.count == 0
        {
            assert(false);
        }
        else
        {
            type_of_first_argument := command_instance.arguments[0].type;
            parent := type_of_first_argument.name;
            while parent && !(parent == "VkInstance" || parent == "VkDevice")
            {
                parent = find_parent_of_type(types, parent);
            }

            if parent == "VkDevice"
            {
                og_command.command_kind = Command_Instance.Command_Kind.Device;
            }
            else if parent == "VkInstance"
            {
                og_command.command_kind = Command_Instance.Command_Kind.Instance;
            }
            else    
            {
                og_command.command_kind = Command_Instance.Command_Kind.None;
            }

        }
    }

    for * command_instance : commands
    {
        if command_instance.name == "vkGetInstanceProcAddr"
            command_instance.command_kind = Command_Instance.Command_Kind.None;
        else if command_instance.name == "vkGetDeviceProcAddr"
            command_instance.command_kind = Command_Instance.Command_Kind.Instance;
    }

    for * command_instance : commands
    {
        if command_instance.command_kind == Command_Instance.Command_Kind.Instance
            array_add(*instance_commands, command_instance);
        else if command_instance.command_kind == Command_Instance.Command_Kind.Device
            array_add(*device_commands, command_instance);
        else
            array_add(*loader_commands, command_instance);
    }



    // Fixup Bitmasks

    for * bitmask : bitmasks
    {
        //
        // If the bitmask requires an enum that also has FlagBits in the name
        // then we alias the handle directly to the enum since it's going to be
        // an enum flags. Which means that we can use them directly and not have
        // to cast the bitmask type to the u32 type.
        //
        if bitmask.requires
        {
            enum_instance := find_enum(*enums, bitmask.requires);
            has_flag_bits_in_name := contains(bitmask.requires, "FlagBits");
            assert((enum_instance != null) == has_flag_bits_in_name);
            if enum_instance != null && has_flag_bits_in_name
            {
                bitmask.alias = enum_instance.name;
            }
        }
        else
        {
            // If it doesn't have a requires attribute it seems to mean that
            // the value is just supposed to be zero just now since the enums
            // that would hold the flags (named with "FlagBits") are just empty
        }
    }



    // Output enums

    for * enum_instance : enums
    {
        print_to_builder(*enums_builder, "// Enum %\n", enum_instance.name);
        print_address_of_manual_for_enum_comment(*enums_builder, enum_instance.name);
        print_extensions_that_reference(*enums_builder, enum_instance.extensions_that_reference_this);
        if enum_instance.alias
        {
            assert(enum_instance.values.count == 0);
            print_to_builder(*enums_builder, "% :: %;\n\n\n", enum_instance.name, enum_instance.alias);
            //
            // @@NOTE: Aliased enums cannot be have "using" because the values will already be pulled
            // into the global namespace by the enum they are aliasing.
            //
        }
        else
        {
            if enum_instance.is_bit_mask
            {
                print_to_builder(*enums_builder, "using % :: enum_flags u32 #specified \n", enum_instance.name);
            }
            else
            {
                print_to_builder(*enums_builder, "using % :: enum s32 #specified\n", enum_instance.name);
            }
            print_to_builder(*enums_builder, "{\n");
            if enum_instance.values.count == 0
            {
                print_to_builder(*enums_builder, "    // empty\n");
            }
            current_comment_index := 0;
            for * value, value_index : enum_instance.values
            {
                if current_comment_index < enum_instance.comments.count &&
                   value_index == enum_instance.comments[current_comment_index].print_before_nth_member
                {
                    if value_index != 0 print_to_builder(*enums_builder, "\n");
                    comment := enum_instance.comments[current_comment_index].text;
                    newline := has_newline(comment);
                    if newline
                    {
                        parts := split(comment, "\n");
                        for parts
                        {
                            part := strip_quotes_and_whitespace(it);
                            if part print_to_builder(*enums_builder, "    // %\n", part);
                        }
                    }
                    else
                    {
                        print_to_builder(*enums_builder, "    // %\n", comment);
                    }
                    current_comment_index += 1;
                }

                if value.is_bit_position
                {
                    using Enum_Instance.Value.Type;
                    if value.value_type ==
                    {
                        case In_String;
                            print_to_builder(*enums_builder, "    % :: (1 << %);", value.name, value.value_in_string);
                        case In_Int;
                            print_to_builder(*enums_builder, "    % :: (1 << %);", value.name, value.value_in_int);
                        case Is_Alias;
                            print_to_builder(*enums_builder, "    % :: %;", value.name, value.alias);
                    }
                }
                else
                {
                    using Enum_Instance.Value.Type;
                    if value.value_type ==
                    {
                        case In_String;
                            print_to_builder(*enums_builder, "    % :: %;", value.name, value.value_in_string);
                        case In_Int;
                            print_to_builder(*enums_builder, "    % :: %;", value.name, value.value_in_int);
                        case Is_Alias;
                            print_to_builder(*enums_builder, "    % :: %;", value.name, value.alias);
                    }
                }
                if value.comment print_to_builder(*enums_builder, " // %", value.comment);
                print_to_builder(*enums_builder, "\n");
            }
            print_to_builder(*enums_builder, "}\n\n\n");
        }
    }

    output_all_procedure_pointers :: (procedure_pointers : [] Procedure_Instance, builder : *String_Builder, platform := Vulkan_Platform.None)
    {
        for * procedure_pointer : procedure_pointers
        {
            if procedure_pointer.requires_platform != platform continue;

            assert(!procedure_pointer.alias); 
            // @@NOTE: Not handling aliases for these cause they just don't exist, shouldn't be hard to support
            // if this assert ever triggers.

            print_to_builder(builder, "// Procedure Pointer Type %\n", procedure_pointer.name);
            print_address_of_manual_for_procedure_pointer_comment(builder, procedure_pointer.name);
            print_extensions_that_reference(builder, procedure_pointer.extensions_that_reference_this);
            print_to_builder(builder, "% :: #type (", procedure_pointer.name);
            spaces_to_pad := 0;
            {
                string_so_far := builder_to_string(builder);
                defer free(string_so_far);
                //
                // @@IMPROVEMENT @@NOTE @@UGLY: Allocating here this string only to figure out how much space there
                // is between it's end and the first newline before so we can align the members.
                // We could do much better if print_to_builder returned the amount of chars written.
                //
                end := string_so_far.data + string_so_far.count - 1;
                current := end;
                while current > string_so_far.data && <<current != #char "\n"
                {
                    current -= 1;
                }
                spaces_to_pad = end - current;
            }
            for * argument : procedure_pointer.arguments
            {
                if it_index != 0
                {
                    for 0..spaces_to_pad-1 print_to_builder(builder, " ");
                }
                print_to_builder(builder, "% : ", argument.name);
                for argument.type.array_counts
                {
                    print_to_builder(builder, "[%]", it);
                    if it_index == argument.type.array_counts.count-1 
                        print_to_builder(builder, " ");
                }
                for 0..argument.type.pointer_count-1
                {
                    print_to_builder(builder, "*");
                }
                print_to_builder(builder, "%", c_basic_type_to_jai(argument.type.name));
                if it_index != procedure_pointer.arguments.count - 1
                    print_to_builder(builder, ",\n");
            }
            print_to_builder(builder, ")");
            return_type := procedure_pointer.return_type;
            if return_type.name == "void" && return_type.pointer_count == 0 && return_type.array_counts.count == 0
            {
                // No return type, nothing to print
            }
            else
            {
                print_to_builder(builder, " -> ");
                for return_type.array_counts
                {
                    print_to_builder(builder, "[%]", it);
                    if it_index == return_type.array_counts.count-1 
                        print_to_builder(builder, " ");
                }
                for 0..return_type.pointer_count-1
                {
                    print_to_builder(builder, "*");
                }
                print_to_builder(builder, "%", c_basic_type_to_jai(return_type.name));
            }
            print_to_builder(builder, " #c_call;\n\n\n");
        }
    }



    // Output the rest of the types

    // First non-platform specific stuff
    {
        // The base types, bitmasks and handles we're defining them
        // as if they weren't platform specific.
        append(*types_builder, VK_BOOL_CODE);
        for * base_types
        {
            if it.name != "VkBool32"
                print_to_builder(*types_builder, "% :: %;\n", it.name, it.alias);
        }
        append(*types_builder, "\n");
        for * bitmasks
        {
            print_to_builder(*types_builder, "% :: %;\n", it.name, it.alias);
        }
        append(*types_builder, "\n");
        for * handles
        {
            if it.alias
            {
                print_to_builder(*types_builder, "% :: %;\n\n", it.name, it.alias);
            }
            else
            {
                if it.type == 
                {
                    case Handle_Instance.Type.Dispatchable;
                        print_to_builder(*types_builder, "// Dispatchable Handle\n", it.name, it.name, it.name);
                    case Handle_Instance.Type.Non_Dispatchable;
                        print_to_builder(*types_builder, "// Non-Dispatchable Handle\n", it.name, it.name, it.name);
                    case; error();
                }
                print_to_builder(*types_builder, "%_T :: struct {};\n% :: *%_T;\n\n", it.name, it.name, it.name);
            }
        }
        append(*types_builder, "\n");
        output_all_structs(structs, *types_builder);
        output_all_procedure_pointers(procedure_pointers, *types_builder);
        output_all_commands(loader_commands, *types_builder);
        output_all_commands(instance_commands, *types_builder);
        output_all_commands(device_commands, *types_builder);
    }

    // Then here all the platform specific stuff inside the #if guard
    for get_enum_values(Vulkan_Platform)
    {
        platform := cast(Vulkan_Platform) it;
        if platform == .None  continue;
        print_to_builder(*types_builder, "#if VULKAN_PLATFORM == .%\n{\n\n", get_enum_name(platform));
        output_all_structs(structs, *types_builder, platform);
        output_all_procedure_pointers(procedure_pointers, *types_builder, platform);
        output_all_commands(loader_commands, *types_builder, platform);
        output_all_commands(instance_commands, *types_builder, platform);
        output_all_commands(device_commands, *types_builder, platform);
        if it == platform_count - 1
            print_to_builder(*types_builder, "}\n\n\n");
        else
            print_to_builder(*types_builder, "}\nelse ");
    }
    
    
    output_all_structs :: (structs : [] Struct_Instance, builder : *String_Builder, platform := Vulkan_Platform.None)
    {
        for * struct_instance : structs
        {
            if struct_instance.requires_platform != platform continue;

            print_to_builder(builder, "// Type %\n", struct_instance.name);
            print_address_of_manual_for_struct_comment(builder, struct_instance.name);
            print_extensions_that_reference(builder, struct_instance.extensions_that_reference_this);

            if struct_instance.alias
            {
                print_to_builder(builder, "% :: %;", struct_instance.name, struct_instance.alias);
                if struct_instance.struct_extends
                    print_to_builder(builder, " // Can be in the pNext chain of %", struct_instance.struct_extends);
                print_to_builder(builder, "\n\n\n");
            }
            else
            {
                if struct_instance.is_union
                    print_to_builder(builder, "% :: union", struct_instance.name);
                else
                    print_to_builder(builder, "% :: struct", struct_instance.name);

                if struct_instance.struct_extends
                {
                    print_to_builder(builder, " // Can be in the pNext chain of %\n{\n", struct_instance.struct_extends);
                }
                else
                {
                    print_to_builder(builder, "\n{\n");
                }

                current_comment_index := 0;

                current_bit_field_accum := 0;
                bit_field_counts : [..] int;
                defer array_reset(*bit_field_counts);
                bit_field_member_names : [..] string;
                defer array_reset(*bit_field_member_names);
                for * member, member_index : struct_instance.members
                {
                    if current_comment_index < struct_instance.comments.count &&
                       member_index == struct_instance.comments[current_comment_index].print_before_nth_member
                    {
                        if member_index != 0 print_to_builder(builder, "\n");
                        comment := struct_instance.comments[current_comment_index].text;
                        newline := has_newline(comment);
                        if newline
                        {
                            parts := split(comment, "\n");
                            for parts
                            {
                                print_to_builder(builder, "    // %\n", strip_quotes_and_whitespace(it));
                            }
                        }
                        else
                        {
                            print_to_builder(builder, "    // %\n", comment);
                        }
                        current_comment_index += 1;
                    }

                    if member.bit_field_count > 0
                    {
                        current_bit_field_accum += member.bit_field_count;
                        array_add(*bit_field_member_names, member.name);
                        array_add(*bit_field_counts, member.bit_field_count);
                    }

                    if current_bit_field_accum > 0
                    {
                        if current_bit_field_accum == 32 || current_bit_field_accum == 64
                        {
                            if current_bit_field_accum == 32
                            {
                                member.type = "u32";
                            }
                            else if current_bit_field_accum == 64
                            {
                                member.type = "u64";
                            }
                            print_to_builder(builder, "    ");
                            print_to_builder(builder, "merged_bitfield");
                            for bit_field_member_names
                            {
                                print_to_builder(builder, "_%_bits_for_%", bit_field_counts[it_index], it);
                            }
                            print_to_builder(builder, " : ");
                            current_bit_field_accum = 0;
                            array_reset(*bit_field_member_names);
                            array_reset(*bit_field_counts);
                        }
                        else
                        {
                            continue;
                        }
                    }
                    else
                    {
                        member.name = patch_name_if_its_called_like_a_jai_type_god_damn(member.name);
                        print_to_builder(builder, "    % : ", member.name);
                    }

                    for 0..member.array_dimensions_used-1
                    {
                        print_to_builder(builder, "[%]", member.array_dimensions[it]);
                    }
                    if member.array_dimensions_used > 0 print_to_builder(builder, " ");

                    for 0..member.pointer_count-1 print_to_builder(builder, "*");
                    print_to_builder(builder, "%", member.type);
                    if member.only_value_possible print_to_builder(builder, " = %", member.only_value_possible);
                    print_to_builder(builder, ";");
                    if member.comment print_to_builder(builder, " // %", member.comment);
                    print_to_builder(builder, "\n");
                }
                print_to_builder(builder, "}\n\n\n");
            }
        }
    }


    output_kind_of_command_comment :: true;
    output_command_instance :: (builder : *String_Builder, command_instance : *Command_Instance)
    {
        command_kind_string : string;
        if command_instance.command_kind ==
        {
            case Command_Instance.Command_Kind.Instance;
                command_kind_string = "Instance Command";
            case Command_Instance.Command_Kind.Device;
                command_kind_string = "Device Command";
            case Command_Instance.Command_Kind.None;
                command_kind_string = "Loader Command";
            case; assert(false);
        }
        print_to_builder(builder, "// Command % (%)\n", command_instance.name, command_kind_string);
        print_address_of_manual_for_command_comment(builder, command_instance.name);
        if command_instance.queues.count > 0
        {
            print_to_builder(builder, "// Can be submitted to a ");
            print_array_of_enum_values(builder, command_instance.queues);
            if command_instance.queues.count > 1
                print_to_builder(builder, " queues\n");
            else 
                print_to_builder(builder, " queue\n");
        }
        if command_instance.renderpass != 0
        {
            inside  := command_instance.renderpass & Command_Instance.Render_Pass.Inside;
            outside := command_instance.renderpass & Command_Instance.Render_Pass.Outside;
            if inside && outside
                print_to_builder(builder, "// Can be used both inside and outside a renderpass\n");
            else if inside
                print_to_builder(builder, "// Has to be used inside a rendepass\n");
            else if outside
                print_to_builder(builder, "// Has to be used outside a rendepass\n");
        }
        if command_instance.command_buffer_level != 0
        {
            primary   := command_instance.command_buffer_level& Command_Instance.Command_Buffer_Level.Primary;
            secondary := command_instance.command_buffer_level& Command_Instance.Command_Buffer_Level.Secondary;
            if primary && secondary
                print_to_builder(builder, "// Can be recorded to both a primary and secondary command buffer\n");
            else if primary
                print_to_builder(builder, "// Has to be recorded to a primary command buffer\n");
            else if secondary
                print_to_builder(builder, "// Has to be recorded to a secondary command buffer\n");
        }
        print_extensions_that_reference(builder, command_instance.extensions_that_reference_this);
        if command_instance.alias
        {
            print_to_builder(builder, "PFN_% :: PFN_%;\n\n\n", command_instance.name, command_instance.alias);
        }
        else
        {
            print_to_builder(builder, "PFN_% :: #type (", command_instance.name);
            spaces_to_pad := 0;
            {
                string_so_far := builder_to_string(builder);
                defer free(string_so_far);
                //
                // @@IMPROVEMENT @@NOTE @@UGLY: Allocating here this string only to figure out how much space there
                // is between it's end and the first newline before so we can align the members.
                // We could do much better if print_to_builder returned the amount of chars written.
                //
                end := string_so_far.data + string_so_far.count - 1;
                current := end;
                while current > string_so_far.data && <<current != #char "\n"
                {
                    current -= 1;
                }
                spaces_to_pad = end - current;
            }
            for * argument : command_instance.arguments
            {
                if it_index != 0
                {
                    for 0..spaces_to_pad-1 print_to_builder(builder, " ");
                }
                print_to_builder(builder, "% : ", argument.name);
                for argument.type.array_counts
                {
                    print_to_builder(builder, "[%]", it);
                    if it_index == argument.type.array_counts.count-1 
                        print_to_builder(builder, " ");
                }
                for 0..argument.type.pointer_count-1
                {
                    print_to_builder(builder, "*");
                }
                print_to_builder(builder, "%", c_basic_type_to_jai(argument.type.name));
                if it_index != command_instance.arguments.count - 1
                    print_to_builder(builder, ",\n");
            }
            print_to_builder(builder, ")");
            return_type := command_instance.return_type;
            if return_type.name == "void" && return_type.pointer_count == 0 && return_type.array_counts.count == 0
            {
                // No return type, nothing to print
            }
            else
            {
                print_to_builder(builder, " -> ");
                for return_type.array_counts
                {
                    print_to_builder(builder, "[%]", it);
                    if it_index == return_type.array_counts.count-1 
                        print_to_builder(builder, " ");
                }
                for 0..return_type.pointer_count-1
                {
                    print_to_builder(builder, "*");
                }
                print_to_builder(builder, "%", c_basic_type_to_jai(return_type.name));
            }
            print_to_builder(builder, " #c_call;\n\n\n");
        }
    }

    output_all_commands :: (command_instances : [] *Command_Instance, builder : *String_Builder, platform := Vulkan_Platform.None)
    {
        for command_instance : command_instances
        {
            if command_instance.requires_platform != platform continue;
            output_command_instance(builder, command_instance);
        }
    }

    
    // Writing the loader code
    loader_builder : String_Builder;
    init_string_builder(*loader_builder);
    defer reset(*loader_builder);

    initial_loader_code := #string DONE
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


    DONE
    append(*loader_builder, initial_loader_code);
    // Output the command variables into a struct and instantiate it
    {
        write("using _vulkan_all_commands : Vulkan_All_Commands;\n");
        write("Vulkan_All_Commands :: struct\n{\n");
        
        write("    using _vulkan_loader_commands : Vulkan_Loader_Commands;\n");
        write("    Vulkan_Loader_Commands :: struct\n    {\n");
        do_it_for_commands(loader_commands);
        write("    }\n\n");
        
        write("    using _vulkan_instance_commands : Vulkan_Instance_Commands;\n");
        write("    Vulkan_Instance_Commands :: struct\n    {\n");
        do_it_for_commands(instance_commands);
        write("    }\n\n");

        write("    using _vulkan_device_commands : Vulkan_Device_Commands;\n");
        write("    Vulkan_Device_Commands :: struct\n    {\n");
        do_it_for_commands(device_commands);
        write("    }\n");

        write("}\n");

        do_it_for_commands :: (commands : [] *Command_Instance) #expand
        {
            did_first_if := false;
            write_all_commands(commands);
            for get_enum_values(Vulkan_Platform)
            {
                platform := cast(Vulkan_Platform) it;
                if platform == .None  continue;
                if !has_commands(commands, platform) continue;
                if !did_first_if
                {
                    did_first_if = true;
                    write("        #if VULKAN_PLATFORM == .%\n        {\n", get_enum_name(platform));
                }
                else
                {
                    write("        else #if VULKAN_PLATFORM == .%\n        {\n", get_enum_name(platform));
                }
                write_all_commands(commands, platform, "            ");
                write("        }\n");
            }
        }

        has_commands :: (commands : [] *Command_Instance, platform := Vulkan_Platform.None) -> bool
        {
            for command : commands
                if platform == command.requires_platform
                    return true;
            return false;
        }

        write_all_commands :: (commands : [] *Command_Instance, platform := Vulkan_Platform.None, before_each_line := "        ") #expand
        {            
            for command : commands
            {
                if platform != command.requires_platform continue;
                write_command(command, before_each_line);
            }
        }
        write_command :: (command : *Command_Instance, before_each_line := "") #expand
        {
            write(before_each_line);
            write("% : PFN_%;\n", command.name, command.name);
        }
        write :: (format : string, args : ..Any) #expand
        {
            print_to_builder(*loader_builder, format, ..args);
        }
    }




    //
    // These we don't handle, we count on the platform specific preludes
    // to handle them. For example, we don't want to be including Windows.h
    // (cause we're not C/C++ duh) but we need HWND, so we need to deal with that
    // in the platform specific preludes.
    //
    print_ignored_stuff :: false;
    #if print_ignored_stuff
    {
        print("Includes (% items):\n", includes.count);
        for includes print("  %\n", it);
        // These we'll need to write by hand since vulkan does too
        // although it should be mostly just including the platform code for
        // a specific platform and maybe define a type here and there.
        
        print("\n");
        print("Defines (% items):\n", defines.count);
        for defines print("  %\n", it);
        // These we should have handled in our hand written prelude

        print("\n");
        print("Ignored Basetypes (% items):\n", ignored_base_types.count);
        for ignored_base_types print("  Contents of node:\n%\n\n", it);
    }


    
    //
    // Adding a platform specific prelude in which we should handle all the types
    // and functionality that the rest of the header relies upon for their platform
    // specific code. For example, for windows, we should export here things like
    // what's HANDLE, HWND, etc.
    //
    platform_preludes : [platform_count] string;
    {
        using Vulkan_Platform;

        platform_preludes[X11]       = VULKAN_LINUX_PRELUDE;
        platform_preludes[Wayland]   = VULKAN_LINUX_PRELUDE;
        // @@NOTE: On these we probably will need more stuff since
        // I doubt that the generic prelude will work for all the
        // different ways linux has to deal with presentation.

        platform_preludes[Windows]   = VULKAN_WINDOWS_PRELUDE;

        platform_preludes[XCB]       = "";
        platform_preludes[Zircon]    = "";
        platform_preludes[GGP]       = "";
        platform_preludes[Android]   = "";
        platform_preludes[MacOS]     = "";
    }
    for get_enum_values(Vulkan_Platform)
    {
        platform := cast(Vulkan_Platform) it;
        if platform == .None  continue;
        prelude_to_add := platform_preludes[platform];
        if prelude_to_add
        {
            print_to_builder(*prelude_builder, "#if VULKAN_PLATFORM == .%\n{\n", get_enum_name(platform));
            append(*prelude_builder, prelude_to_add);
            print_to_builder(*prelude_builder, "} // %\n\n", get_enum_name(platform));
        }
    }

    extensions_builder : String_Builder;
    init_string_builder(*extensions_builder);
    defer reset(*extensions_builder);
    {
        builder := *extensions_builder;
        print_to_builder(builder, "// Vulkan Extensions\n\n");
        for * extension : extensions
        {
            if !extension.enabled continue;
            
            type_string : string;
            if !extension.type
                type_string = "Extension";
            else if extension.type == "instance"
                type_string = "Instance Extension";
            else if extension.type == "device"
                type_string = "Device Extension";
            else
                error();
            print_to_builder(builder, "// % % (%)\n", type_string, extension.name, extension.number);
            if extension.author || extension.contact
            {
                print_to_builder(builder, "//");
                if extension.author
                    print_to_builder(builder, " author %", extension.author);
                if extension.author && extension.contact
                    print_to_builder(builder, ",");
                if extension.contact
                    print_to_builder(builder, " contact %", extension.contact);
                print_to_builder(builder, "\n");
            }
            print_address_of_manual_for_extension_comment(builder, extension.name);
            print_to_builder(builder, "% :: true;\n", extension.name);
            for * define : extension.defines
            {
                if define.value
                    print_to_builder(builder, "% :: %;\n", define.name, define.value);
            }
            print_to_builder(builder, "\n\n");
        }
    }



    prelude_code    := builder_to_string(*prelude_builder);
    enums_code      := builder_to_string(*enums_builder);
    types_code      := builder_to_string(*types_builder);
    extensions_code := builder_to_string(*extensions_builder);
    
    header_builder : String_Builder;
    init_string_builder(*header_builder);
    defer reset(*header_builder);

    print_to_builder(*header_builder, "%\n\n%\n\n%\n\n%\n\n", prelude_code, enums_code, types_code, extensions_code);

    return builder_to_string(*header_builder), builder_to_string(*loader_builder);





    // # Some stuff help with the implementation of the generate procedure:


    print_extensions_that_reference :: (builder : *String_Builder, extension_names : [] string)
    {
        if extension_names.count > 0
        {
            print_to_builder(builder, "// Referenced by ");
            for extension_names
            {
                if it_index == 0 
                    print_to_builder(builder, "%", it);
                else
                    print_to_builder(builder, ", %", it);
            }
            print_to_builder(builder, "\n");
            
            #if print_extension_address
            {
                for extension_names
                {
                    print_address_of_manual_for_extension_comment(builder, it);
                }
            }
        }
    }



    print_address_of_manual_for_extension :: (builder : *String_Builder, extension_name : string) #expand
    {
        print_to_builder(builder, "(https://www.khronos.org/registry/vulkan/specs/%-extensions/man/html/%.html)\n", max_feature_level_found, extension_name);
    }

    print_address_of_manual_for_extension_comment :: (builder : *String_Builder, extension_name : string) #expand
    {
        print_to_builder(builder, "//  - ");
        print_address_of_manual_for_extension(builder, extension_name);
    }

    print_address_of_manual_for_command_comment :: (builder : *String_Builder, command_name : string) #expand
    {
        print_to_builder(builder, "//  - (https://www.khronos.org/registry/vulkan/specs/%-extensions/man/html/%.html)\n", max_feature_level_found, command_name);
    }

    print_address_of_manual_for_enum_comment :: (builder : *String_Builder, enum_name : string) #expand
    {
        print_to_builder(builder, "//  - (https://www.khronos.org/registry/vulkan/specs/%-extensions/man/html/%.html)\n", max_feature_level_found, enum_name);
    }

    print_address_of_manual_for_struct_comment :: (builder : *String_Builder, struct_name : string) #expand
    {
        print_to_builder(builder, "//  - (https://www.khronos.org/registry/vulkan/specs/%-extensions/man/html/%.html)\n", max_feature_level_found, struct_name);
    }

    print_address_of_manual_for_procedure_pointer_comment :: (builder : *String_Builder, struct_name : string) #expand
    {
        print_to_builder(builder, "//  - (https://www.khronos.org/registry/vulkan/specs/%-extensions/man/html/%.html)\n", max_feature_level_found, struct_name);
    }
    

VULKAN_PLATFORM_SELECTION_PRELUDE :: #string DONE
#module_parameters(VULKAN_PLATFORM : Vulkan_Platform = DEFAULT_VULKAN_PLATFORM);

#if      OS == .WINDOWS DEFAULT_VULKAN_PLATFORM :: Vulkan_Platform.Windows;
else #if OS == .LINUX   DEFAULT_VULKAN_PLATFORM :: Vulkan_Platform.X11;
else #if OS == .MACOS   DEFAULT_VULKAN_PLATFORM :: Vulkan_Platform.MacOS;
else                    DEFAULT_VULKAN_PLATFORM :: Vulkan_Platform.None;

DONE

VULKAN_GENERAL_PRELUDE :: #string DONE
VK_MAKE_VERSION :: (major: u32, minor: u32, patch: u32) -> u32
{
    return (major << 22) | (minor << 12) | patch;
}

VK_VERSION_MAJOR :: (version: u32) -> u32
{
    return version >> 22;
}
VK_VERSION_MINOR :: (version: u32) -> u32
{
    return (version >> 22) & 0x3ff;
}
VK_VERSION_PATCH :: (version: u32) -> u32
{
    return version & 0xfff;
}

VK_API_VERSION_1_0 :: #run VK_MAKE_VERSION(1, 0, 0);
VK_API_VERSION_1_1 :: #run VK_MAKE_VERSION(1, 1, 0);
VK_API_VERSION_1_2 :: #run VK_MAKE_VERSION(1, 2, 0);

VK_NULL_HANDLE :: null;

DONE

VULKAN_WINDOWS_PRELUDE :: #string DONE
    #import "Windows";
DONE

VULKAN_LINUX_PRELUDE :: #string DONE
    #import "Linux";
    // @@TODO: We probably need more things here
DONE

VK_BOOL_CODE :: #string DONE
using VkBool32 :: enum u32 #specified
{
    VK_FALSE :: 0;
    VK_TRUE  :: 1;
}
DONE


} // end of generate procedure



max_feature_level_found := "1.0";
//
// @@TODO: Clean this up
// @@NOTE: Making this a global cause it has to get in pretty deep
// into callstacks when generating the code. We could investigate putting it
// into some sort of user expandable context, or if the language supports
// closures it would work as a normal variable too
//





main :: ()
{
    arguments := get_command_line_arguments();
    if arguments.count != 2  error("We want a command line argument with the vk.xml file!");
    filename := arguments[1];

    vk_xml_string, success := read_entire_file(filename);
    defer free(vk_xml_string);
    if !success error("Couldn't open filename %, should be an accessible vk.xml file", filename);

    vulkan_header, vulkan_loader := generate_jai_vulkan_code(vk_xml_string);
    defer free(vulkan_header);
    defer free(vulkan_loader);

    header_filename := "../vulkan_header.jai";
    loader_filename := "../vulkan_loader.jai";
    success_header := write_entire_file(header_filename, vulkan_header);
    success_loader := write_entire_file(loader_filename, vulkan_loader);
    assert_and_error(success_header, "Couldn't write header file to %", header_filename);
    assert_and_error(success_header, "Couldn't write loader file to %", loader_filename);
}





#scope_file



Line :: struct
{
    number := -1;
    text := "not available";
}

Token :: struct
{
    Type :: enum
    {
        Invalid;
        Whitespace;
        Identifier;
        Comment;
        Integer;
        Bool;
        String;

        Open_Parentheses; 
        Close_Parentheses;
        Open_Braces; 
        Close_Braces;
        Open_Brackets; 
        Close_Brackets;
        Less_Than;
        More_Than;
        Interrogation;
        Exclamation;
        At_Sign;
        Equals;
        Plus;
        Minus;
        Asterisk;
        Forward_Slash;
        Back_Slash;
        Vertical_Slash;
        Dot;
        Comma;
        Semicolon;
        Colon;
        Hash;
        Apostrophe;
        Ampersand;

        End;
    }
    type := Type.Invalid;
    text := "not available";
    line : Line;
}

Tokenizer :: struct
{
    text : string;
    current : string;
    beginning_of_current_token : *u8;
    current_line : Line;
    tokens : [..] Token;

    default_error_handler :: (format : string, args : ..Any)
    {
        print("Error while Tokenizing!! ");
        print(format, ..args);
        print("\n");
        assert(false);
    } @PrintLike
    // @@TODO Replace this by setting up the logger in the context

    error := default_error_handler;

}

init_tokenizer :: (tokenizer : *Tokenizer, text : string)
{
    tokenizer.text = text;
    tokenizer.current = text;
    tokenizer.current_line.text.data = text.data;
    tokenizer.beginning_of_current_token = tokenizer.current.data;
    tokenizer.current_line.text.count = count_till_end_of_line(tokenizer.current_line.text.data);
    tokenizer.current_line.number = 1;
}

tokenize_whole_string :: (tokenizer : *Tokenizer, do_comments : bool, ignore_whitespace := false)
{
    using Token.Type;
    while tokenizer.current.count > 0
    {
        if is_whitespace(get(tokenizer))
        {
            advance(tokenizer);
            while is_whitespace(get(tokenizer))
            {
                advance(tokenizer);
            }
            found_token(Whitespace, ignore_whitespace);
        }
        else if do_comments && get(tokenizer) == #char "/" && peek(tokenizer) == #char "/"
        {
            while get(tokenizer) != #char "\n" && get(tokenizer) != 0 advance(tokenizer);
            found_token(Comment);
        }
        // @@TODO: Block Comments?
        // @@TODO: Preprocessor Directives?
        else if is_alpha(get(tokenizer))
        {
            advance(tokenizer);
            while is_alphanumeric(get(tokenizer)) advance(tokenizer);
            found_token(Identifier);
            token := *tokenizer.tokens[tokenizer.tokens.count - 1];
            if token.text == "true" || token.text == "false"
            {
                token.type = Bool;
            }
        }
        else if is_number(get(tokenizer))
        {
            // @@TODO: Parse floats, hex, binary, scientific notation, all that jazz
            advance(tokenizer);
            while is_number(get(tokenizer))
            {
                advance(tokenizer);
            }
            found_token(Integer);
        }
        else if get(tokenizer) == #char "\""
        {
            advance(tokenizer, allow_end = false);
            while true
            {
                if get(tokenizer) == #char "\\"
                {
                    advance(tokenizer, allow_end = false);
                }
                else if get(tokenizer) == #char "\""
                {
                    break;
                }
                advance(tokenizer);
            }
            advance(tokenizer);
            found_token(String);
        }
        else if is_operator(tokenizer, "(")  advance_and_found(Open_Parentheses); 
        else if is_operator(tokenizer, ")")  advance_and_found(Close_Parentheses);
        else if is_operator(tokenizer, "{")  advance_and_found(Open_Braces); 
        else if is_operator(tokenizer, "}")  advance_and_found(Close_Braces);
        else if is_operator(tokenizer, "[")  advance_and_found(Open_Brackets); 
        else if is_operator(tokenizer, "]")  advance_and_found(Close_Brackets);
        else if is_operator(tokenizer, "<")  advance_and_found(Less_Than); 
        else if is_operator(tokenizer, ">")  advance_and_found(More_Than);
        else if is_operator(tokenizer, "?")  advance_and_found(Interrogation);
        else if is_operator(tokenizer, "!")  advance_and_found(Exclamation);
        else if is_operator(tokenizer, "@")  advance_and_found(At_Sign);
        else if is_operator(tokenizer, "=")  advance_and_found(Equals);
        else if is_operator(tokenizer, "+")  advance_and_found(Plus);
        else if is_operator(tokenizer, "-")  advance_and_found(Minus);
        else if is_operator(tokenizer, "*")  advance_and_found(Asterisk);
        else if is_operator(tokenizer, "/")  advance_and_found(Forward_Slash);
        else if is_operator(tokenizer, "\\") advance_and_found(Back_Slash);
        else if is_operator(tokenizer, "|")  advance_and_found(Vertical_Slash);
        else if is_operator(tokenizer, ".")  advance_and_found(Dot);
        else if is_operator(tokenizer, ",")  advance_and_found(Comma);
        else if is_operator(tokenizer, ";")  advance_and_found(Semicolon);
        else if is_operator(tokenizer, ":")  advance_and_found(Colon);
        else if is_operator(tokenizer, "#")  advance_and_found(Hash);
        else if is_operator(tokenizer, "'")  advance_and_found(Apostrophe);
        else if is_operator(tokenizer, "&")  advance_and_found(Ampersand);
        else
        {
            tokenizer.error("Don't know what the hell this was: (%) in %", one_char(tokenizer.current), tokenizer.current_line.text);
        }
    }
    found_token(End);
    return;
    
    advance :: (tokenizer : *Tokenizer, allow_end := true) -> u8
    {
        advancing_line := <<tokenizer.current.data == #char "\n";
        
        tokenizer.current.data  += 1;
        tokenizer.current.count -= 1;

        if advancing_line
        {
            tokenizer.current_line.number += 1;
            tokenizer.current_line.text.data = tokenizer.current.data;
            tokenizer.current_line.text.count = count_till_end_of_line(tokenizer.current.data);
        }

        if !allow_end && tokenizer.current.count == 0
        {
            tokenizer.error("Unexpected end of text to tokenize in line %", tokenizer.current_line);
        }
        else if tokenizer.current.count <= -1
        {
            tokenizer.error("Wend outside the text to tokenize in line %", tokenizer.current_line);
        }

        return <<tokenizer.current.data;
    }

    get :: (tokenizer : *Tokenizer) -> u8
    {
        if tokenizer.current.count <= 0 return 0;
        return <<tokenizer.current.data;
    }

    peek :: (tokenizer : *Tokenizer, forward := 1) -> u8
    {
        if forward > tokenizer.current.count return 0;
        return <<(tokenizer.current.data + forward);
    }

    found_token :: (type : Token.Type, ignore := false) #expand
    {
        token : Token;
        token.type = type;
        token.line = tokenizer.current_line;
        token.text.data = tokenizer.beginning_of_current_token;
        token.text.count = tokenizer.current.data - tokenizer.beginning_of_current_token;
        tokenizer.beginning_of_current_token = tokenizer.current.data;
        if !ignore
            array_add(*tokenizer.tokens, token);
    }

    is_operator :: (tokenizer : *Tokenizer, $operator_string : string) -> bool
    {
        #assert(operator_string.count == 1);
        return get(tokenizer) == <<operator_string.data;
    }
    
    advance_and_found :: (type : Token.Type) #expand
    {
        advance(tokenizer);
        found_token(type);
    }
}

free :: (tokenizer : *Tokenizer)
{
    array_reset(*tokenizer.tokens);
}

get_text_between_tokens_inclusive :: (first_token : Token, last_token : Token) -> string
{
    value : string;
    value.data = first_token.text.data;
    value.count = last_token.text.data + last_token.text.count - value.data;
    return value;
}

get_text_between_tokens :: (first : Token, one_past_last : Token) -> string
{
    value : string;
    value.data = first.text.data;
    value.count = one_past_last.text.data - value.data;
    return value;
}

count_till_end_of_line :: (s_ : *u8) -> int
{
    s := s_;
    count := 0;
    while ( <<s != #char "\n" && <<s != 0)
    {
        s += 1;
        count += 1;
    }
    return count;
}

one_char :: (s : string) -> string
{
    o := s;
    o.count = 1;
    return o;
}

is_whitespace :: (c : u8) -> bool
{        
    return (c == #char " "  ||
            c == #char "\t" ||
            c == #char "\n" ||
            c == #char "\r");
}

is_whitespace_no_newline :: (c : u8) -> bool
{        
    return (c == #char " "  ||
            c == #char "\t");
}

is_alpha :: (c : u8) -> bool
{
    return (#char "a" <= c && c <= #char "z") ||
           (#char "A" <= c && c <= #char "Z") ||
           (c == #char "_");
}

is_number :: (c : u8) -> bool
{
    return #char "0" <= c && c <= #char "9";
}

is_alphanumeric :: (c : u8) -> bool
{
    return is_alpha(c) || is_number(c);
}

is_number_or_underscore :: (c : u8) -> bool
{
    return is_number(c) || c == #char "_";
}


strip_quotes_and_whitespace :: (s : string) -> string
{
    if s.count == 0 return s;

    Quote :: #char "\"";
    result := s;

    while is_whitespace(<<result.data)
    {
        result.data += 1;
        result.count -= 1;
        if result.count == 0 return result;
    }

    found_quote := false;
    if <<result.data == Quote
    {
        found_quote = true;
        result.data += 1;
        result.count -= 1;
        if result.count == 0 return result;
    }

    if found_quote
    {
        current := result.data;
        while true
        {
            if <<current == Quote break;
            if <<current == #char "\\" current += 1;
            current += 1;
            assert(current < result.data + result.count);
        }
        result.count = current - result.data;
    }
    else
    {
        current := result.data + result.count - 1;

        while is_whitespace(<<current)
        {
            current -= 1;
            if current < result.data
            {
                result.count = 0;
                return result;
            }
        }
        result.count = current - result.data + 1;
    }

    return result;
}

RUN_TESTS :: false;
#if RUN_TESTS
{
    #run
    {
        print("[%]\n", strip_quotes_and_whitespace("test"));
        print("[%]\n", strip_quotes_and_whitespace("\"test\""));
        print("[%]\n", strip_quotes_and_whitespace("\"test\\\"test\""));
        print("[%]\n", strip_quotes_and_whitespace("    asdfasd asdfa gafadf  "));
        print("[%]\n", strip_quotes_and_whitespace("   "));
        print("[%]\n", strip_quotes_and_whitespace("   x  "));
        print("[%]\n", strip_quotes_and_whitespace(""));
    }
}

c_basic_type_to_jai :: (input : string) -> value : string, success : bool
{
    if input ==
    {
        case "uint64_t";  return "u64",      true;
        case "uint32_t";  return "u32",      true;
        case "uint16_t";  return "u16",      true;
        case "uint8_t";   return "u8",       true;
        case "int64_t";   return "s64",      true;
        case "int32_t";   return "s32",      true;
        case "int16_t";   return "s16",      true;
        case "int8_t";    return "s8",       true;
        case "char";      return "u8",       true;
        case "size_t";    return "u64",      true;
        case "void";      return "void",     true;
        case "float";     return "float32",  true;
        case "double";    return "float64",  true;
        case "int";       return "s32",      true;
        case;             return input, false;
    }
}

patch_name_if_its_called_like_a_jai_type_god_damn :: (name : string) -> string
{
    if name ==
    {
        case "u64"; return "u64_";
        case "u32"; return "u32_";
        case "u16"; return "u16_";
        case "u8";  return "u8_";
        case "s64"; return "s64_";
        case "s32"; return "s32_";
        case "s16"; return "s16_";
        case "s8";  return "s8_";
        case "float32"; return "float32_";
        case "float64"; return "float64_";
        case; return name;
    }
}

has_newline :: (s : string) -> bool
{
    for 0..s.count - 1
    {
        if s[it] == #char "\n" return true;
    }
    return false;
}

get_type_name :: ($type : Type) -> string
{
    info := type_info(type);
    if info.type == Type_Info_Tag.STRUCT
    {
        info_struct := cast(*Type_Info_Struct) info;
        return info_struct.name;
    }
    else if info.type == Type_Info_Tag.ENUM
    {
        info_enum := cast(*Type_Info_Enum) info;
        return info_enum.name;
    }
    else
    {
        assert(false);
        return "";
    }
}

get_enum_names :: ($enum_type : Type) -> [] string
{
    info := type_info(enum_type);
    assert(info.type == Type_Info_Tag.ENUM);
    info_enum := cast(*Type_Info_Enum) info;
    return info_enum.names;
}

get_enum_values :: ($enum_type : Type) -> [] s64
{
    info := type_info(enum_type);
    assert(info.type == Type_Info_Tag.ENUM);
    info_enum := cast(*Type_Info_Enum) info;
    return info_enum.values;
}

get_enum_count :: ($enum_type : Type) -> s64
{
    info := type_info(enum_type);
    assert(info.type == Type_Info_Tag.ENUM);
    info_enum := cast(*Type_Info_Enum) info;
    return info_enum.values.count;
}

print_array_of_enum_values :: (builder : *String_Builder, values : [] $Enum_Type)
{
    for values
    {
        print_to_builder(builder, get_enum_name(it));
        if it_index == values.count - 2
            print_to_builder(builder, " and ");
        else if it_index != values.count - 1
            print_to_builder(builder, ", ");
    }
}





// Shittiest XML parser you'll ever see incoming over here, be careful :) 


Node :: struct
{
    name      : string;
    attributes: [..] Attribute;
    contents  : [..] string;
    parent    : *Node;
    children  : [..] Node;
    Contents_Or_Children :: struct
    {
        type: Type;
        index: int;
    }
    all_contents_or_children : [..] Contents_Or_Children;

    all_node_text_content : string;

    line : Line;
}

Attribute :: struct
{
    name: string;
    value: string;
}
find_first_node_with_name_recursive :: (root : *Node, name : string) -> *Node
{
    for * root.children
        if it.name == name return it;
    for * root.children
    {
        node := find_first_node_with_name(it, name);
        if node return node;
    }
    return null;
}

find_first_node_with_name_and_attribute_value_recursive :: (root : *Node, name : string, attribute : Attribute) -> *Node
{
    for * root.children
    {
        found, node_attribute := find_attribute_with_name(it, attribute.name);
        if !found continue;
        node_attribute = strip_quotes_and_whitespace(node_attribute);
        if node_attribute == attribute.value && it.name == name
            return it;
    }
    for * root.children
    {
        node := find_first_node_with_name_and_attribute_value_recursive(it, name, attribute);
        if node return node;
    }
    return null;
}

find_all_nodes_with_name_and_attribute_recursive :: (root : *Node, name : string, attribute : string) -> [..] *Node #must
{
    nodes : [..] *Node;
    recurse(root, name, attribute, *nodes);
    return nodes;

    recurse :: (root : *Node, name : string, attribute : string, nodes : * [..] *Node)
    {
        for * root.children
        {
            found_attribute, node_attribute := find_attribute_with_name(it, attribute);
            found_name := it.name == name;
            if !(found_attribute && found_name) continue;
            array_add(nodes, it);
        }
        for * root.children
        {
            node := recurse(it, name, attribute, nodes);
        }
    }
}

find_all_nodes_with_name_and_not_attribute_recursive :: (root : *Node, name : string, attribute : string) -> [..] *Node #must
{
    nodes : [..] *Node;
    recurse(root, name, attribute, *nodes);
    return nodes;

    recurse :: (root : *Node, name : string, attribute : string, nodes : * [..] *Node)
    {
        for * root.children
        {
            found_attribute, node_attribute := find_attribute_with_name(it, attribute);
            found_name := it.name == name;
            if !(!found_attribute && found_name) continue;
            array_add(nodes, it);
        }
        for * root.children
        {
            node := recurse(it, name, attribute, nodes);
        }
    }
}

find_first_node_with_name :: (root : *Node, name : string) -> *Node
{
    for * root.children
        if it.name == name return it;
    return null;
}

find_all_nodes_with_name :: (root : *Node, name : string) -> [..] *Node #must
{
    nodes : [..] *Node;
    for * root.children
        if it.name == name array_add(*nodes, it);

    return nodes;
}

find_attribute_with_name :: (node : *Node, name : string) -> found: bool, content: string 
{
    for node.attributes
    {
        if it.name == name return true, it.value;
    }
    return false, "";
}

find_attribute_with_name_and_strip :: (node : *Node, name : string) -> found: bool, content: string 
{
    found, content := find_attribute_with_name(node, name);
    if found content = strip_quotes_and_whitespace(content);
    return found, content;
}

aggregate_all_contents_of_node_and_children :: (node : *Node, buffer : [] u8) -> string #must
{
    raw_text_content := node.all_node_text_content;

    result : string;
    result.data = buffer.data;
    result.count = 0;

    while raw_text_content.count > 0
    {
        if <<raw_text_content.data == #char "<"
        {
            advance();
            while <<raw_text_content.data != #char ">" advance();
            advance();
            continue;
        }
        result.count += 1;
        assert(result.count <= buffer.count);
        result[result.count - 1] = <<raw_text_content.data;
        advance();
    }

    return result;
    advance :: () #expand
    {
        assert(`raw_text_content.count > 0);
        `raw_text_content.data  += 1;
        `raw_text_content.count -= 1;
    }
}

print_node :: (node : *Node)
{
    using node;
    print("% ",name);
    print("attributes:\n");
    for attributes print("    % = %\n", it.name, it.value);
    print("children and contents:\n");
    for all_contents_or_children
    {
        if it.type ==
        {
            case string;
                print("    content: %\n", contents[it.index]);
            case Node;
                print("    node: %\n", children[it.index].name);
        }
    }
}

parse_xml :: (contents : string) -> root_node : Node
{
    tokenizer : Tokenizer;
    init_tokenizer(*tokenizer, contents);
    defer free(*tokenizer);
    tokenize_whole_string(*tokenizer, do_comments = false);

    root_node : Node;
    root_node.name = "root";
    current_parent := *root_node;


    tokens := tokenizer.tokens;

    token := tokens.data;
    index := 0;
    while index < tokens.count
    {
        using Token.Type;
        if token.type == Whitespace
        {
            advance(allow_end = true);
            continue;
        }

        if token.type == Less_Than
        {
            first_token := token;
            advance();
            if token.type == Interrogation
            {
                advance();
                name_token := token;
                while token.type != Interrogation && (token+1).type != More_Than advance();
                advance();
                text := get_text_between_tokens_inclusive(<<first_token, <<token);
                node : Node;
                node.name = name_token.text; 
                node.line = name_token.line;
                node.all_node_text_content.data = first_token.text.data; 
                node.all_node_text_content.count = token.text.data + token.text.count - node.all_node_text_content.data;
                add_child(current_parent, node);
            }
            else if token.type == Identifier
            {
                node : Node;
                node.name = token.text;
                node.line = token.line;
                advance();

                while true // Reading all the attributes
                {
                    if token.type == Identifier
                    {
                        attribute : Attribute;
                        attribute.name = token.text;
                        advance();
                        assert_and_error(token.type == Equals, "Something that's not en equals is following an attribute? %", token);
                        advance();

                        if token.type == String
                        {
                            attribute.value = token.text;
                        }
                        else
                        {
                            error("Attribute has a value we didn't expect (vk.xml seems to have all the attribute values being a string) and it was %", <<token);
                        }
                        array_add(*node.attributes, attribute);
                        advance();
                    }
                    else
                    {
                        break;
                    }
                }

                token_closes_in_place := false;
                if token.type == Forward_Slash
                {
                    advance();
                    if token.type == More_Than
                    {
                        token_closes_in_place = true;
                    }
                    else
                    {
                        error("Unexpected token (%) after forward slash in a tag, we though we were closing the tag!", token.text);
                    }
                }
                else if token.type == More_Than
                {
                    // Expected
                }
                else
                {
                    error("Unexpected token (%) after when finishing a tag!", token.text);
                }

                node.all_node_text_content.data = first_token.text.data; 
                added_node := add_child(current_parent, node);

                if !token_closes_in_place
                {
                    current_parent = added_node;
                }
                else
                {
                    added_node.all_node_text_content.count = token.text.data + token.text.count - node.all_node_text_content.data;
                }
            }
            else if token.type == Forward_Slash
            {
                advance();
                old_parent := current_parent;
                if current_parent.name == token.text
                {
                    current_parent = current_parent.parent;
                }
                else
                {
                    error("Closing tag with name that doesn't match current opened tag\n\nClosing tag is \"%\" (in line %)\nOpened tag was \"%\" (in line %)",
                          token.text, token.line,
                          current_parent.name, current_parent.line);
                }
                advance();
                if token.type != More_Than
                {
                    error("We expected to close the closing tag here and we found %", token.text);
                }
                old_parent.all_node_text_content.count = token.text.data + token.text.count - old_parent.all_node_text_content.data;
            }
            advance(ignore_whitespace = false, allow_end = true);
        }
        else // We're outside a tag so this should just be contents of the current parent
        {
            first := token;
            while token.type != Less_Than && token.type != End
            {
                advance(ignore_whitespace = false, allow_end = true);
            }
            contents := get_text_between_tokens(<<first, <<token);
            add_contents(current_parent, contents);
        }
        if (token.type == End) break;
    }

    return root_node;

    add_child :: (parent : *Node, child : Node) -> *Node
    {
        array_add(*parent.children, child);
        contents_or_children : Node.Contents_Or_Children;
        contents_or_children.type = type_of(child);
        contents_or_children.index = parent.children.count - 1;
        array_add(*parent.all_contents_or_children, contents_or_children);
        added_child := *parent.children[parent.children.count - 1];
        added_child.parent = parent;
        return added_child;
    }

    add_contents :: (parent : *Node, contents : string)
    {
        array_add(*parent.contents, contents);
        contents_or_children : Node.Contents_Or_Children;
        contents_or_children.type = type_of(contents);
        contents_or_children.index = parent.contents.count - 1;
        array_add(*parent.all_contents_or_children, contents_or_children);
    }

    advance :: (ignore_whitespace := true, allow_end := false) #expand
    {
        `token += 1;
        `index += 1;
        if ignore_whitespace
        {
            while `token.type == Token.Type.Whitespace
            {
                `token += 1;
                `index += 1;
            }
        }
        if (!allow_end && `index == `tokens.count)
        {
            error("Unexpected end of file while advancing to next token");
        }
    }
}

fix_xml_ampersand_shit_in_place :: (original : string) -> string #must
{
    new_string := original;
    chars_to_ignore := 0;
    writing := new_string.data;
    for 0..original.count-1
    {
        original[it];
        if chars_to_ignore > 0
        {
            chars_to_ignore -= 1;
        }
        else if original[it] == #char "&"
        {
            next := *original[it+1];
            if string_matches_at_beginning(next, "amp;")
            {
                <<writing = #char "&";
                writing += 1;
                chars_to_ignore = 4;
            }
            else if string_matches_at_beginning(next, "lt;")
            {
                <<writing = #char "<";
                writing += 1;
                chars_to_ignore = 3;
            }
            else if string_matches_at_beginning(next, "gt;")
            {
                <<writing = #char ">";
                writing += 1;
                chars_to_ignore = 3;
            }
            else if string_matches_at_beginning(next, "quot;")
            {
                <<writing = #char "\"";
                writing += 1;
                chars_to_ignore = 5;
            }
            else if string_matches_at_beginning(next, "apos;")
            {
                <<writing = #char "'";
                writing += 1;
                chars_to_ignore = 5;
            }
        }
        else
        {
            <<writing = original[it];
            writing += 1;
        }
    }

    new_string.count = writing - new_string.data;
    return new_string;

    string_matches_at_beginning :: (ptr : *u8, b : string) -> bool
    {
        for 0..b.count-1
            if ptr[it] != b[it] return false;
        return true;
    }
}


/*
Ampersand	&amp;	&
Less-than	&lt;	<
Greater-than	&gt;	>
Quotes	&quot;	"
Apostrophe	&apos;	'

*/
