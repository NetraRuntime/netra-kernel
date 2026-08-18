from __future__ import annotations

from dataclasses import dataclass

from .types import Epilogue, Maturity


@dataclass(frozen=True)
class EpilogueCapability:
    epilogue: Epilogue
    assembly_value: int
    maturity: Maturity
    note: str


CAPABILITIES = {
    Epilogue.IDENTITY: EpilogueCapability(
        Epilogue.IDENTITY, 0, Maturity.VERIFIED,
        "Implemented by byte-identical dense M=1 templates; serving candidates remain rejected.",
    ),
    Epilogue.BIAS: EpilogueCapability(Epilogue.BIAS, 1, Maturity.EXPERIMENT, "No validated gfx950 raw dense implementation yet."),
    Epilogue.SILU: EpilogueCapability(Epilogue.SILU, 2, Maturity.EXPERIMENT, "No validated gfx950 raw dense implementation yet."),
    Epilogue.GELU: EpilogueCapability(Epilogue.GELU, 3, Maturity.EXPERIMENT, "No validated gfx950 raw dense implementation yet."),
    Epilogue.GATED_SILU: EpilogueCapability(Epilogue.GATED_SILU, 4, Maturity.EXPERIMENT, "No validated gfx950 raw dense implementation yet."),
}


def raw_epilogue_supported(epilogue: Epilogue) -> bool:
    return epilogue is Epilogue.IDENTITY
