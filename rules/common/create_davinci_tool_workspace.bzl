# MIT License

# Copyright (c) 2025 Vector Group

# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


"""Function for creating tool workspaces, circumventing the usual way that these tools are being executed"""

load("//rules/common:copy_file.bzl", "copy_file")

def DaVinciToolWorkspaceInfo(files, workspace_prefix, addtional_workspace_files = []):
    """Creates a DaVinciToolWorkspaceInfo object that contains all the necessary information for the DaVinci tool workspace

    Args:
        files: A List of config files that are available inside the davinci tool workspace (list of File)
        workspace_prefix: The name of the created workspace (string)
        addtional_workspace_files: (Optional) The copied files that is available inside the davinci tool workspace (File, default is []])

    Returns:
        A DaVinci tool workspace information object
    """
    if type(files) != "list":
        fail("Should be of type list", "files")

    if len(files) < 1:
        fail("Should contain at least one File", "files")

    if type(workspace_prefix) != "string":
        fail("Should be of type string", "workspace_prefix")

    for copy in addtional_workspace_files:
        if copy != None:
            if not hasattr(copy, "basename") or not hasattr(copy, "dirname"):
                fail("Should be of type File", "copy")

    return struct(
        files = files,
        workspace_prefix = workspace_prefix,
        addtional_workspace_files = addtional_workspace_files,
    )

def create_davinci_tool_workspace(ctx, workspace_name, addtional_workspace_files = [], is_windows = False, config_files = [], config_folders = ["Config"]):
    """Creates a separate workspace in the bazel-bin directory where the execution of the corresponding tool is supposed to be done. This copies all the available configuration files aswell as a potentially given dpa file

    Args:
        ctx: current rule ctx that is creating the workspace
        workspace_name: any string is allowed, this will create the workspace under this name
        addtional_workspace_files: (Optional) can also provide a additional files that will be added into the workspace aside from the config_files, this will be handled differently than the remaining config
        is_windows: execution platform of the rule
        config_files: List of config files that will be used to create the workspace
        config_folders: (Optional) List of config folders that the path will be checked for in each file to create a nested Config folder structure, default is ["Config"]

    Returns:
        DaVinciToolWorkspaceInfo
    """

    addtional_workspace_files_copy = []
    for file in addtional_workspace_files:
        file_copy = file
        if hasattr(file, "basename"):
            file_copy = ctx.actions.declare_file(workspace_name + "/" + file.basename)

            # copies the file and renames it with an xml extension, this is to workaround the bazel restrictions of having readonly files in its output directory if the files are an action output
            # this way we can run dvteam on the dpa file without running into a problem as the copy is used for execution
            copy_file(ctx, file, file_copy, is_windows)
            addtional_workspace_files_copy.append(file_copy)

    tool_workspace_config_files = []

    # this copies all the config files
    for file in config_files:
        # this will put the config files inside the Config folder, this might need to be changed later on
        # but is needed to make sure that no deep paths are created in the workspace creation phase
        if hasattr(file, "path"):
            for config_folder in config_folders:
                if (config_folder + "/" in file.path):
                    base_path = config_folder + "/" + file.path.split("/" + config_folder + "/")[1]
                    config_file_copy = ctx.actions.declare_file(workspace_name + "/" + base_path)
                    tool_workspace_config_files.append(config_file_copy)
                    copy_file(ctx, file, config_file_copy, is_windows)
        else:
            fail("Config file cannot be copied as it is not a valid File")

    # Check if everything worked
    if len(config_files) != len(tool_workspace_config_files):
        fail("Config was not copied successfully")

    return DaVinciToolWorkspaceInfo(files = tool_workspace_config_files, workspace_prefix = workspace_name, addtional_workspace_files = addtional_workspace_files_copy)