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

"""Helper macros for the cfg5 components refs"""

MSRC_COMPONENTS_CONFIG = {
    # Special Mappings that are not generated through patterns
    "Can": {
        "component_ref": "/MICROSAR/Can_Mpc5700Mcan/Can",
        "supported_use_cases": ["RT"],
    },
    "Aurix_Can": {
        "component_ref": "/AURIX2G/EcucDefs/Can",
        "supported_use_cases": ["RT"],
    },
    "CanTrcv_GenericCan": {
        "component_ref": "/MICROSAR/CanTrcv_GenericCan/CanTrcv",
        "supported_use_cases": ["RT"],
    },
    "CanTrcv_Tja1040": {
        "component_ref": "/MICROSAR/CanTrcv_Tja1040/CanTrcv",
        "supported_use_cases": ["RT"],
    },
    "CanTrcv_Tja1043": {
        "component_ref": "/MICROSAR/CanTrcv_Tja1043/CanTrcv",
        "supported_use_cases": ["RT"],
    },
    "Aurix_V9251_CanTrcv": {
        "component_ref": "/AURIX2G_V9251/EcucDefs/CanTrcv",
        "supported_use_cases": ["RT"],
    },
    "Aurix_W9255_CanTrcv": {
        "component_ref": "/AURIX2G_W9255/EcucDefs/CanTrcv",
        "supported_use_cases": ["RT"],
    },
}

# Components List Defintions

# Base components that are compatible with VTT and RT
BASE_MSRC_COMPONENTS = [
    "BswM",
    "CanIf",
    "CanNm",
    "CanSM",
    "CanTSyn",
    "CanTp",
    "Com",
    "ComM",
    "ComXf",
    "Crc",
    "CryIf",
    "Csm",
    "Dbg",
    "Dcm",
    "Dem",
    "Det",
    "DiagXf",
    "Dlt",
    "DoIP",
    "E2EPW",
    "E2EXf",
    "EcuC",
    "EcuM",
    "EthFw",
    "EthIf",
    "EthSM",
    "EthTSyn",
    "Etm",
    "Fee",
    "FiM",
    "IpduM",
    "LdCom",
    "MemIf",
    "MemMap",
    "Nm",
    "NvM",
    "Os",
    "PduR",
    "Rte",
    "Rtm",
    "Sbc/Sbc",
    "Sd",
    "SecOC",
    "SoAd",
    "SomeIpTp",
    "SomeIpXf",
    "StbM",
    "TcpIp",
    "UdpNm",
    "WdgIf",
    "WdgM",
    "Xcp",
    "vBRS",
    "vBaseEnv",
    "vDem42",
    "vIKE",
    "vItaSip",
    "vLinkGen",
    "vMemAccM",
    "vSecPrim",
    "vSet",
]

# MSRC VTT Components
VTT_MSRC_COMPONENTS = [
    "VTTAdc",
    "VTTCan",
    "VTTCntrl",
    "VTTDio",
    "VTTEcuC",
    "VTTEep",
    "VTTEth",
    "VTTEthTrcv",
    "VTTFls",
    "VTTGpt",
    "VTTMcu",
    "VTTMemMap",
    "VTTOs",
    "VTTPort",
    "VTTSpi",
    "VTTvSet",
]

# MSRC MCAL Components
MCAL_MSRC_COMPOENTNS = [
    "Crypto_30_LibCv",
    "Crypto_30_vHsm",
    "Eth_Generic",
    "Eth_Tc3xx",
    "EthTrcv_88Q2112",
    "EthTrcv_Ethmii",
    "EthTrcv_Generic",
    "Fee_30_FlexNor",
    "Sbc_Tlf35584",
    "Wdg_30_Sbc",
]

# AURIX MCAL COMPONENTS
AURIX_MCAL_MSRC_COMPONENTS = [
    "Adc",
    "Can",
    "Crc",
    "Dio",
    "Dma",
    "Dsadc",
    "Fls",
    "FlsLoader",
    "Gpt",
    "Icu",
    "Irq",
    "McalLib",
    "Mcu",
    "Ocu",
    "Port",
    "Pwm",
    "Smu",
    "Spi",
    "Uart",
    "Wdg",
]

BASE_MSRC_COMPONENTS_CONFIG = {
    component: {
        "component_ref": "/MICROSAR/" + component,
        "supported_use_cases": ["RT", "VTT"],
    }
    for component in BASE_MSRC_COMPONENTS
}

VTT_MSCR_COMPONENTS_CONFIG = {
    component: {
        "component_ref": "/MICROSAR/" + component,
        "supported_use_cases": ["VTT"],
    }
    for component in VTT_MSRC_COMPONENTS
}
MCAL_MSCR_COMPONENTS_CONFIG = {
    component: {
        "component_ref": "/MICROSAR/" + component,
        "supported_use_cases": ["RT"],
    }
    for component in MCAL_MSRC_COMPOENTNS
}
AURIX_MCAL_MSCR_COMPONENTS_CONFIG = {
    component: {
        "component_ref": "/AURIX2G/EcucDefs/" + component,
        "supported_use_cases": ["RT"],
    }
    for component in AURIX_MCAL_MSRC_COMPONENTS
}

MSRC_COMPONENTS_CONFIG.update(BASE_MSRC_COMPONENTS_CONFIG)
MSRC_COMPONENTS_CONFIG.update(VTT_MSCR_COMPONENTS_CONFIG)
MSRC_COMPONENTS_CONFIG.update(MCAL_MSCR_COMPONENTS_CONFIG)
MSRC_COMPONENTS_CONFIG.update(AURIX_MCAL_MSCR_COMPONENTS_CONFIG)

def get_component_ref(component, use_case = None):
    """Get component ref for component if it is supported.

    Args:
        component: Name of the component
        use_case: Use case to check for or None (default)

    Returns:
        A component ref or None if not supported
    """
    return MSRC_COMPONENTS_CONFIG[component]["component_ref"] if (not use_case or use_case in MSRC_COMPONENTS_CONFIG[component]["supported_use_cases"]) else None

def get_supported_component_refs(components_list, use_case):
    """Get component refs for supported components in compoents_list.

    Args:
        components_list: A dictionary of components
        use_case: The current build use_case

    Returns:
        The list of supported component:refs.
    """
    component_refs = []
    for component in components_list:
        c_ref = get_component_ref(component, use_case)
        if c_ref:
            component_refs.append(c_ref)
    return component_refs
