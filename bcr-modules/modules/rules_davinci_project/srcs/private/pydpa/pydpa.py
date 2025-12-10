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
import argparse
import json
import logging
import subprocess
import sys
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path, PurePosixPath, PureWindowsPath
from zipfile import ZipFile


class CFG5_EXEC_NAMES:
    WIN_CMD = "DVCfgCmd.exe"
    WIN_GUI = "DaVinciCFG.exe"
    LIN_CMD = "DVCfgCmd"
    LIN_GUI = "DaVinciCFG"


@dataclass
class Cfg5ManifestModel:
    config_trace: dict

    @classmethod
    def load_from_file(cls, manifest: Path):
        return Cfg5ManifestModel(json.load(manifest))


@dataclass
class Harmonizer:
    xpath: str

    _LOGGER = logging.getLogger("Harmonizer")

    def harmonize(self, xml_root: ET.Element) -> list[tuple[Path, Path]]:
        pass

    @staticmethod
    def _clean_path(path: str) -> Path:
        if "\\" in path:
            # propably windows path
            _cleaned_path = PureWindowsPath(path)
        else:
            _cleaned_path = PurePosixPath(path)

        # ToDo: check for remaining strange symbols

        return Path(_cleaned_path)


@dataclass
class FileHarmonizer(Harmonizer):
    default_folder: Path

    _LOGGER = logging.getLogger("FileHarmonizer")

    def harmonize(
        self, xml_root: ET.Element, base_path: Path
    ) -> list[tuple[Path, Path]]:
        source_dest_tuples = []
        for element in xml_root.findall(self.xpath):
            base_source_path = base_path.joinpath(self.default_folder)

            source_path = self._clean_path(element.text)
            if not source_path.is_absolute():
                source_path = base_path.joinpath(source_path).resolve()

            if source_path.is_relative_to(base_source_path):
                dest_path = self.default_folder.joinpath(
                    source_path.relative_to(base_source_path)
                )
            else:
                dest_path = self.default_folder.joinpath(source_path.name)

            self._LOGGER.debug(
                "Found %s entry with path: '%s' and target: '%s'",
                element.tag,
                source_path,
                dest_path,
            )

            source_dest_tuples.append((source_path, dest_path))

            element.text = dest_path.as_posix()
        return source_dest_tuples


@dataclass
class FolderHarmonizer(Harmonizer):
    default_folder: Path

    _LOGGER = logging.getLogger("FolderHarmonizer")

    def harmonize(
        self, xml_root: ET.Element, base_path: Path
    ) -> list[tuple[Path, Path]]:
        source_dest_tuples = []
        for element in xml_root.findall(self.xpath):
            base_source_path = base_path.joinpath(self.default_folder)

            source_path = self._clean_path(element.text)
            if not source_path.is_absolute():
                source_path = base_path.joinpath(source_path).resolve()

            if source_path.is_relative_to(base_source_path):
                dest_path = self.default_folder.joinpath(
                    source_path.relative_to(base_source_path)
                )
            else:
                dest_path = self.default_folder

            self._LOGGER.debug(
                "Found %s entry with path: '%s' and target: '%s'",
                element.tag,
                source_path,
                dest_path,
            )

            source_dest_tuples.append((source_path, dest_path))

            element.text = dest_path.as_posix()
        return source_dest_tuples


@dataclass
class SIPHarmonizer(Harmonizer):
    sip_path: Path

    _LOGGER = logging.getLogger("SIPHarmonizer")

    def harmonize(self, xml_root: ET.Element):
        element = xml_root.findall(self.xpath)

        if len(element) != 1:
            return []

        element = element[0]

        old_path = element.text
        new_path = self.sip_path

        self._LOGGER.debug(
            "Found %s entry with path: '%s' and target: '%s'",
            element.tag,
            old_path,
            new_path,
        )

        element.text = new_path.as_posix()
        return [(old_path, new_path)]


@dataclass
class DevWSHarmonizer(Harmonizer):
    default_folder: Path

    _LOGGER = logging.getLogger("DevWSHarmonizer")

    def harmonize(
        self, xml_root: ET.Element, base_path: Path
    ) -> list[tuple[Path, Path]]:
        elements = xml_root.findall(self.xpath)

        if len(elements) != 1:
            return []

        element = elements[0]
        base_source_path = base_path.joinpath(self.default_folder)

        source_path = self._clean_path(element.text)
        if not source_path.is_absolute():
            source_path = base_path.joinpath(source_path)

        if source_path.is_relative_to(base_source_path):
            dest_path = self.default_folder.joinpath(
                source_path.relative_to(base_source_path)
            )
        else:
            dest_path = self.default_folder.joinpath(source_path.name)

        element.text = dest_path.as_posix()

        return [(source_path.parent, dest_path.parent)]


@dataclass
class ToolHarmonizer(Harmonizer):
    tool_path: Path

    _LOGGER = logging.getLogger("ToolHarmonizer")

    def harmonize(self, xml_root: ET.Element):
        source_dest_tuples = []
        for element in xml_root.findall(self.xpath):
            old_path = element.text
            new_path = self.tool_path

            self._LOGGER.debug(
                "Found %s entry with path: '%s' and target: '%s'",
                element.tag,
                old_path,
                new_path,
            )
            element.text = new_path.as_posix()
            source_dest_tuples.append(old_path, new_path)
        return source_dest_tuples


@dataclass
class SplitterHarmonizer(Harmonizer):
    ecuc_folder: Path

    _LOGGER = logging.getLogger("SplitterHarmonizer")

    def harmonize(self, xml_root: ET.Element):
        source_dest_tuples = []

        for element in xml_root.findall(self.xpath):
            old_path = self._clean_path(element.get("File"))
            new_path = self.ecuc_folder.joinpath(old_path.name)

            self._LOGGER.debug(
                "Found %s entry with path: '%s' and target: '%s'",
                element.tag,
                old_path,
                new_path,
            )
            element.text = new_path.as_posix()
            source_dest_tuples.append(old_path, new_path)
        return source_dest_tuples


class DPAProject:
    """Class to represent a cfg5 project."""

    name: str
    dpa_file: Path
    dpa_tree: ET.ElementTree
    manifest: Cfg5ManifestModel
    included_module_defs: list[str]
    excluded_module_defs: list[str]

    _HARMONIZER_LIST = [
        FolderHarmonizer("./Folders/ECUC", Path("Config/ECUC")),
        SplitterHarmonizer("./EcucSplitter/Splitter", Path("Config/ECUC")),
        FileHarmonizer("./EcucSplitter/Configuration", Path("Config/ECUC")),
        FolderHarmonizer("./Folders/GenData", Path("Appl/GenData")),
        FolderHarmonizer("./Folders/GenDataVtt", Path("Appl/GenDataVtt")),
        FolderHarmonizer("./Folders/Source", Path("Appl/Source")),
        FolderHarmonizer(
            "./Folders/ServiceComponents", Path("Config/ServiceComponents")
        ),
        FolderHarmonizer("./Folders/Logs", Path("Log")),
        FolderHarmonizer(
            "./Folders/BswInternalBehaviour", Path("Config/InternalBehavior")
        ),
        FolderHarmonizer("./Folders/McData", Path("Config/McData")),
        FolderHarmonizer("./Folders/DefRestrict", Path("DefRestrict")),
        FolderHarmonizer("./Folders/AUTOSAR", Path("Config/AUTOSAR")),
        FolderHarmonizer(
            "./Folders/ApplicationComponents/ApplicationComponent",
            Path("Config/ApplicationComponents"),
        ),
        FolderHarmonizer(
            "Folders/TimingExtensionFolders/TimingExtensionFolder",
            Path("Config/TimingExtensions"),
        ),
        FolderHarmonizer("./Input/ECUEX", Path("Config/System")),
        FileHarmonizer("./References/FlatMap", Path("Config/System")),
        FileHarmonizer("./References/FlatECUEX", Path("Config/System")),
        FolderHarmonizer("./References/VttProject", Path("Config/VTT")),
        DevWSHarmonizer("./References/DVWorkspace", Path("Config/Developer")),
        FolderHarmonizer(
            "./Miscellaneous/A2LGenerator/A2LMasterFile", Path("Config/A2L")
        ),
        FolderHarmonizer(
            "./References/EcucFileReferences/EcucFileReference",
            Path("Config/EcucFileReferences"),
        ),
    ]

    _LOGGER = logging.getLogger("DPAProject")

    def __init__(
        self,
        name: str,
        dpa_file: Path,
        included_modules: list[str] = [],
        excluded_modules: list[str] = [],
        manifest: Path | None = None,
        cfg5_base_dir: Path | None = None,
        tool_dev: Path | None = None,
        tool_vtt: Path | None = None,
        cfg5_params_folder: Path | None = None,
    ):
        """Creates a DPAProject instance from a DPA file."""
        self._LOGGER.debug("Initializing DPAProject with name: %s", name)
        self._LOGGER.debug("Resolving paths from DPA file %s", dpa_file)
        self.name = name

        self.dpa_file = dpa_file.resolve()
        self.dpa_tree = ET.parse(self.dpa_file)

        self._MODULE_DEFS = self._get_modules_list()

        self.included_module_defs = [
            self._MODULE_DEFS[mod]
            for mod in included_modules
            if mod in self._MODULE_DEFS
        ]

        self.excluded_module_defs = [
            self._MODULE_DEFS[mod]
            for mod in excluded_modules
            if mod in self._MODULE_DEFS
        ]

        if cfg5_base_dir is not None:
            sip_path = self._resolve_cfg5_paths(cfg5_base_dir)
            self._HARMONIZER_LIST.append(SIPHarmonizer("./Folders/SIP", sip_path))

        if tool_dev is not None:
            dev_path = self._resolve_tool_path(tool_dev)
            self._HARMONIZER_LIST.append(ToolHarmonizer("./Tools/DEV", dev_path))

        if tool_vtt is not None:
            vtt_path = self._resolve_tool_path(tool_vtt)
            self._HARMONIZER_LIST.append(ToolHarmonizer("./Tools/VTT", vtt_path))

        if manifest is not None:
            self.manifest = Cfg5ManifestModel.load_from_file(manifest)

        if cfg5_params_folder is None:
            cfg5_params_folder = self.dpa_file.parent.joinpath(".cfg5").resolve()
        else:
            cfg5_params_folder = Path(cfg5_params_folder).resolve()

        self.cfg5_params_folder = cfg5_params_folder

    def _resolve_cfg5_paths(self, cfg5_base_dir: Path):
        if not cfg5_base_dir.exists():
            raise FileNotFoundError(
                f"Provided SIP path {cfg5_base_dir} does not exist."
            )

        self.cfg5_cmd_windows = cfg5_base_dir.joinpath(CFG5_EXEC_NAMES.WIN_CMD)
        self.cfg5_gui_windows = cfg5_base_dir.joinpath(CFG5_EXEC_NAMES.WIN_GUI)
        self.cfg5_cmd_linux = cfg5_base_dir.joinpath(CFG5_EXEC_NAMES.LIN_CMD)

        return cfg5_base_dir.resolve().parent

    def _resolve_tool_path(self, tool_path: Path):
        if not tool_path.exists():
            if not self.dpa_file.joinpath(tool_path).exists():
                raise FileNotFoundError(
                    f"Provided tool path {tool_path} does not exist."
                )
            tool_path = self.dpa_file.joinpath(tool_path)
        return tool_path

    def _get_modules_list(self) -> dict[str, str]:
        """Get the list of supported modules from the DPA file."""
        modules = {}
        for module in self.dpa_tree.findall(
            "./Display/ModuleDefinitionMappings/ModuleDefinitionMapping"
        ):
            modules[module.get("ModuleConfigName")] = module.get("ModuleDefinitionRef")

        return modules

    @classmethod
    def from_archive(
        cls,
        name: str,
        cfg5_project_zip: Path,
        dpa_name: str,
        workdir: Path,
        included_modules: list[str] = [],
        excluded_modules: list[str] = [],
        cfg5_base_dir: Path | None = None,
        tool_dev: Path | None = None,
        tool_vtt: Path | None = None,
    ):
        """Creates a DPAProject instance from a cfg5 project zip file."""
        if not cfg5_project_zip.exists():
            raise FileNotFoundError(
                f"Project zip file {cfg5_project_zip} does not exist."
            )

        with ZipFile(cfg5_project_zip, "r") as zip_ref:
            zip_ref.extractall(workdir)

        cls._LOGGER.debug("Unzipped project to %s", workdir)

        dpa_path = workdir / dpa_name
        if not dpa_path.exists():
            raise FileNotFoundError(f"DPA file {dpa_name} does not exist in the zip.")

        manifest_path = workdir / f"{name}.cfg5.manifest"
        if not manifest_path.exists():
            manifest_path = None

        cfg5_params_folder = workdir / ".cfg5"
        if not cfg5_params_folder.exists():
            cfg5_params_folder = None

        return cls(
            name,
            dpa_path,
            included_modules,
            excluded_modules,
            manifest_path,
            cfg5_base_dir,
            tool_dev,
            tool_vtt,
            cfg5_params_folder,
        )

    def create_harmonized_zip(self, output_path: Path):
        """Creates a harmonized zip file from current project setup."""

        self._LOGGER.debug("Creating harmonized zip file at %s", output_path)

        with ZipFile(output_path, "w") as zip_file:
            for harmonizer in self._HARMONIZER_LIST:
                if isinstance(harmonizer, FolderHarmonizer) or isinstance(
                    harmonizer, DevWSHarmonizer
                ):
                    source_dest_pairs = harmonizer.harmonize(
                        self.dpa_tree.getroot(), self.dpa_file.parent
                    )

                    for source, dest in source_dest_pairs:
                        for source_file in source.glob("**/*"):
                            if source_file.is_file():
                                dest_file = dest.joinpath(
                                    source_file.relative_to(source)
                                )
                                zip_file.write(
                                    source_file,
                                    dest_file.as_posix(),
                                )
                elif isinstance(harmonizer, SIPHarmonizer) or isinstance(
                    harmonizer, ToolHarmonizer
                ):
                    harmonizer.harmonize(self.dpa_tree.getroot())
                elif isinstance(harmonizer, FileHarmonizer):
                    source_dest_pairs = harmonizer.harmonize(
                        self.dpa_tree.getroot(), self.dpa_file.parent
                    )

                    for source, dest in source_dest_pairs:
                        zip_file.write(source, dest.as_posix())

            zip_file.mkdir(".cfg5")
            for file in self.cfg5_params_folder.glob("**/*"):
                if file.is_file():
                    dest_path = Path(".cfg5").joinpath(
                        file.relative_to(self.cfg5_params_folder)
                    )
                    zip_file.write(file, dest_path.as_posix())

            ET.indent(self.dpa_tree)
            zip_file.writestr(
                f"{self.dpa_file.name}", ET.tostring(self.dpa_tree.getroot())
            )

    def _run_cfg5(self, command: str, args: list[str], gui: bool = False):
        """Run the Cfg5 tool with the specified command and arguments."""

        if sys.platform.startswith("win"):
            executable = self.cfg5_cmd_windows if not gui else self.cfg5_gui_windows
        else:
            executable = self.cfg5_cmd_linux if not gui else None

        if not executable:
            raise ValueError("Cfg5 executable path is not set.")

        cmd = [str(executable), command] + args
        cmd += ["-configuration", str(self.cfg5_params_folder)]
        self._LOGGER.debug("Running command: %s", " ".join(cmd))

        def _process_log_output():
            while True:
                output = process.stdout.readline().decode("utf-8").strip()
                if output:
                    self._LOGGER.getChild(executable.name).debug(output)
                else:
                    break

        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
        while process.poll() is None:
            _process_log_output()
        if process.returncode != 0:
            raise subprocess.CalledProcessError(process.returncode, cmd)

    def _update_dpa_file(self):
        for harmonizer in self._HARMONIZER_LIST:
            if isinstance(harmonizer, FolderHarmonizer):
                harmonizer.harmonize(self.dpa_tree.getroot(), self.dpa_file.parent)
            elif isinstance(harmonizer, SIPHarmonizer) or isinstance(
                harmonizer, ToolHarmonizer
            ):
                harmonizer.harmonize(self.dpa_tree.getroot())
            elif isinstance(harmonizer, FileHarmonizer):
                harmonizer.harmonize(self.dpa_tree.getroot(), self.dpa_file.parent)

        ET.indent(self.dpa_tree)
        self.dpa_tree.write(self.dpa_file)

    def generate_config(self, output_path: Path):
        """Generate a Cfg5 project configuration."""

        self._update_dpa_file()

        args = ["-p", str(self.dpa_file.resolve()), "-g", "--verbose"]
        if len(self.included_module_defs) > 0:
            args += ["--modulesToInclude", ",".join(self.included_module_defs)]
        if len(self.excluded_module_defs) > 0:
            args += ["--modulesToExclude", ",".join(self.excluded_module_defs)]
        self._run_cfg5("generate", args)

    def run_gui(self):
        command = ""
        args = ["-p", str(self.dpa_file.resolve()), "--verbose"]

        self._run_cfg5(command=command, args=args, gui=True)


class CLI:
    _OPTION_ARGUMENTS = {
        "__COMMON__": {
            "verbose": {
                "default": False,
                "help": "Enable verbose output.",
                "action": "store_true",
            },
        },
        "create_zip": {
            "name": {
                "type": str,
                "help": "Name of the project.",
                "required": True,
            },
            "output": {
                "type": Path,
                "help": "The output zip file path.",
                "required": True,
            },
            "dpa": {
                "type": Path,
                "help": "Path to the DPA file.",
                "required": True,
            },
            "cfg5_base_dir": {
                "type": Path,
                "help": "Path to the MSR SIP.",
                "required": False,
                "default": None,
            },
            "vtt": {
                "type": Path,
                "help": "Path to the vtt tool.",
                "required": False,
                "default": None,
            },
            "developer": {
                "type": Path,
                "help": "Path to the developer tool.",
                "required": False,
                "default": None,
            },
            "_call": "_call_create_zip",
        },
        "generate": {
            "name": {
                "type": str,
                "help": "Name of the project.",
                "required": True,
            },
            "output": {
                "type": Path,
                "help": "Folder to contain the outputs",
                "required": True,
            },
            "dpa": {
                "type": Path,
                "help": "Path to the DPA file.",
            },
            "zip": {
                "type": Path,
                "help": "Path to the cfg5 project zip file.",
            },
            "dpa_name": {
                "type": str,
                "help": "The name of the dpa file inside the zip.",
            },
            "modules_to_include": {
                "type": str,
                "help": "Modules to include - multiple allowed",
                "required": False,
                "action": "append",
                "default": [],
            },
            "modules_to_exclude": {
                "type": str,
                "help": "Modules to exlcude - multiple allowed",
                "required": False,
                "action": "append",
                "default": [],
            },
            "cfg5_base_dir": {
                "type": Path,
                "help": "Path to the MSR SIP.",
                "required": True,
            },
            "vtt": {
                "type": Path,
                "help": "Path to the vtt tool.",
                "required": False,
                "default": None,
            },
            "developer": {
                "type": Path,
                "help": "Path to the developer tool.",
                "required": False,
                "default": None,
            },
        },
        "open": {
            "name": {
                "type": str,
                "help": "Name of the project.",
                "required": True,
            },
            "output": {
                "type": Path,
                "help": "Folder to contain the outputs",
                "required": False,
            },
            "dpa": {
                "type": Path,
                "help": "Path to the DPA file.",
            },
            "zip": {
                "type": Path,
                "help": "Path to the cfg5 project zip file.",
            },
            "dpa_name": {
                "type": str,
                "help": "The name of the dpa file inside the zip.",
            },
            "modules_to_include": {
                "type": str,
                "help": "Modules to include - multiple allowed",
                "required": False,
                "action": "append",
                "default": [],
            },
            "modules_to_exclude": {
                "type": str,
                "help": "Modules to exlcude - multiple allowed",
                "required": False,
                "action": "append",
                "default": [],
            },
            "cfg5_base_dir": {
                "type": Path,
                "help": "Path to the MSR SIP.",
                "required": True,
            },
            "vtt": {
                "type": Path,
                "help": "Path to the vtt tool.",
                "required": False,
                "default": None,
            },
            "developer": {
                "type": Path,
                "help": "Path to the developer tool.",
                "required": False,
                "default": None,
            },
        },
    }

    def _call_create_zip(self, args):
        """Validate and Call the create_zip command."""
        if not args.name:
            raise ValueError("Project name is required.")
        if not args.output or not args.output.suffix == ".zip":
            raise ValueError("Output must be a valid zip file path.")
        if not args.dpa or not args.dpa.exists():
            raise ValueError("DPA file must be provided and must exist.")
        project = DPAProject(
            name=args.name,
            dpa_file=args.dpa,
            cfg5_base_dir=args.cfg5_base_dir,
            tool_vtt=args.vtt,
            tool_dev=args.developer,
        )
        project.create_harmonized_zip(args.output)

    def _call_generate(self, args):
        """Validate and Call the generate command."""
        if not args.name:
            raise ValueError("Project name is required.")
        if not args.cfg5_base_dir or not args.cfg5_base_dir.exists():
            raise ValueError("SIP path must be provided and must exist.")
        if args.zip:
            if not args.dpa_name:
                raise ValueError(
                    "When loading from zip, the name of the dpa file has to be provided."
                )
            cfg5_project_zip = Path(args.zip).resolve()
            if not cfg5_project_zip.exists():
                raise FileNotFoundError(
                    f"Cfg5 project zip file does not exist: {cfg5_project_zip}"
                )
            if not args.output:
                raise ValueError("Output must be a valid directory path.")
            args.output.mkdir(parents=True, exist_ok=True)

            project = DPAProject.from_archive(
                name=args.name,
                cfg5_project_zip=cfg5_project_zip,
                dpa_name=args.dpa_name,
                included_modules=args.modules_to_include,
                excluded_modules=args.modules_to_exclude,
                workdir=args.output,
                cfg5_base_dir=args.cfg5_base_dir,
                tool_vtt=args.vtt,
                tool_dev=args.developer,
            )
        elif args.dpa:
            dpa_path = Path(args.dpa).resolve()
            if not dpa_path.exists():
                raise FileNotFoundError(f"DPA file does not exist: {dpa_path}")
            project = DPAProject(
                name=args.name,
                dpa_file=dpa_path,
                included_modules=args.modules_to_include,
                excluded_modules=args.modules_to_exclude,
                cfg5_base_dir=args.cfg5_base_dir,
                tool_vtt=args.vtt,
                tool_dev=args.developer,
            )
        else:
            raise ValueError("Either DPA or zip file must be provided.")

        project.generate_config(args.output)

    def _call_open(self, args):
        """Validate and Call the open command."""
        if not args.name:
            raise ValueError("Project name is required.")
        if not args.cfg5_base_dir or not args.cfg5_base_dir.exists():
            raise ValueError("SIP path must be provided and must exist.")
        if not (args.dpa or args.zip):
            raise ValueError("Either DPA or project zip file must be provided.")
        if not args.zip:
            raise ValueError("Running GUI is only supported using the zip.")
        if not args.dpa_name:
            raise ValueError(
                "When loading from zip, the name of the dpa file has to be provided."
            )
        cfg5_project_zip = Path(args.zip).resolve()
        if not cfg5_project_zip.exists():
            raise FileNotFoundError(
                f"Cfg5 project zip file does not exist: {cfg5_project_zip}"
            )
        if not args.output:
            raise ValueError("Output must be a valid directory path.")
        args.output.mkdir(parents=True, exist_ok=True)

        project = DPAProject.from_archive(
            name=args.name,
            cfg5_project_zip=cfg5_project_zip,
            dpa_name=args.dpa_name,
            workdir=args.output,
            cfg5_base_dir=args.cfg5_base_dir,
            tool_vtt=args.vtt,
            tool_dev=args.developer,
        )

        project.run_gui()

    def _parser_add_arguments(self, parser: argparse.ArgumentParser, command: str):
        """Create a parser for a specific command."""
        for arg_name, arg_info in self._OPTION_ARGUMENTS[command].items():
            kwargs = {}
            if "help" in arg_info:
                kwargs["help"] = arg_info["help"]
            if "type" in arg_info:
                kwargs["type"] = arg_info["type"]
            if "required" in arg_info:
                kwargs["required"] = arg_info["required"]
            if "default" in arg_info:
                kwargs["default"] = arg_info["default"]
            if "action" in arg_info:
                kwargs["action"] = arg_info["action"]
            kwargs["dest"] = arg_name
            parser.add_argument(f"--{arg_name}", **kwargs)
        return parser

    def _parse_args(self, args=None):
        """Parse command line arguments."""
        parser = argparse.ArgumentParser(description="Handle Cfg5 projects.")
        subparsers = parser.add_subparsers(
            dest="command", title="command", required=True
        )

        # Create parsers for each command
        for command in self._OPTION_ARGUMENTS.keys():
            if command == "__COMMON__":
                self._parser_add_arguments(parser, command)
                continue
            else:
                subparser = subparsers.add_parser(
                    command, help=f"Handle {command} command."
                )
                self._parser_add_arguments(subparser, command)
                self._parser_add_arguments(subparser, "__COMMON__")

        return parser.parse_args(args)

    def _setup_logging(self, verbose: bool):
        """Setup logging configuration."""
        if verbose:
            logging.basicConfig(level=logging.DEBUG)
        else:
            logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(self.__class__.__name__)
        return self.logger

    def run(self):
        """Run the CLI with the provided arguments."""
        cmd_args = sys.argv[1:]

        if len(cmd_args) == 1:
            # Try to find call config file
            call_config = Path(cmd_args[0]).resolve()
            if call_config.exists():
                print("Using arguments file: {call_config}")
                cmd_args = call_config.read_text(encoding="utf-8").split()

        args = self._parse_args(cmd_args)
        logger = self._setup_logging(args.verbose)

        logger.info("This is pydpa - the call wrapper for DaVinci Projects.")
        logger.info(f"Current workdir: {Path.cwd()}")

        if args.command == "create_zip":
            logger.info("Creating harmonized zip file...")
            self._call_create_zip(args)
            logger.info("Harmonized zip file created successfully.")
        elif args.command == "generate":
            logger.info("Generating Cfg5 project...")
            self._call_generate(args)
            logger.info("Cfg5 project generated successfully.")
        elif args.command == "open":
            logger.info("Opening Cfg5 project in GUI...")
            self._call_open(args)
            logger.info("Cfg5 project opened successfully.")
        else:
            logger.error(f"Unknown command: {args.command}")


def main():
    """Main entry point for the CLI."""
    cli = CLI()
    cli.run()


if __name__ == "__main__":
    main()
